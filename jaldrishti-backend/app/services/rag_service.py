import os
import re
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from groq import AsyncGroq
from app.core.config import settings
from app.db.database import SessionLocal
import app.models.user
from app.models.chat_history import ChatConversation, ChatMessage
from app.services.cache_service import CacheService
from app.services.vector_search_service import VectorSearchService

logger = logging.getLogger("jaldrishti.rag")


class StructuredDualSolution(BaseModel):
    chemical_treatment: Optional[str] = Field(default=None, description="Exact chemical treatment and dosage per acre")
    organic_alternative: Optional[str] = Field(default=None, description="Natural or bio-organic treatment alternative")
    preventative_cultural_tip: Optional[str] = Field(default=None, description="Preventative cultural or field management tip")


class ChatbotAnalysisResponse(BaseModel):
    reply_text: str = Field(..., description="Main advisory reply in requested target language and script")
    weather_alert: Optional[str] = Field(default=None, description="Live weather alert if rain/heat wave expected")
    solution: Optional[StructuredDualSolution] = Field(default=None, description="Dual treatment solution if query asks about disease/pest/fertilizer")


class RAGService:
    """
    Production-Grade Multilingual Agronomy RAG Engine powered by Groq Llama-3.3-70B
    with Vector Embeddings, Session History, and Structured Output.
    """
    WEATHER_KEYWORDS = {
        "weather", "rain", "temperature", "forecast", "humidity", "monsoon", "storm", "sun", "hot", "dry",
        "বৃষ্টি", "আবহাওয়া", "তাপমাত্রা", "ঝড়", "মেঘ", "জল", "সেচ",
        "मौसम", "बारिश", "तापमान", "आंधी", "सिंचाई", "पानी",
        "irrigate", "irrigation", "spray", "spraying"
    }

    def __init__(self):
        self.docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'pop_docs'))
        
        # Initialize vector store embeddings if not already populated
        try:
            VectorSearchService.initialize_and_index_docs(self.docs_dir)
        except Exception as e:
            logger.warning(f"[RAGService] Vector search initialization notice: {e}")
        
        self.client: Optional[AsyncGroq] = None
        if settings.GROQ_API_KEY and settings.GROQ_API_KEY != "your_groq_api_key_here":
            try:
                self.client = AsyncGroq(api_key=settings.GROQ_API_KEY)
                logger.info("[RAGService] AsyncGroq client initialized successfully!")
            except Exception as e:
                logger.warning(f"[RAGService] Failed to initialize AsyncGroq client: {e}")

    def _is_weather_relevant(self, query: str) -> bool:
        q_lower = query.lower()
        return any(kw in q_lower for kw in self.WEATHER_KEYWORDS)

    def _get_or_create_session(self, session_id: Optional[str], user_id: int, db) -> tuple[str, ChatConversation]:
        if not session_id:
            session_id = f"sess_{uuid.uuid4().hex[:16]}"

        conversation = db.query(ChatConversation).filter(
            ChatConversation.session_id == session_id,
            ChatConversation.user_id == user_id
        ).first()

        if not conversation:
            conversation = ChatConversation(session_id=session_id, user_id=user_id)
            db.add(conversation)
            db.commit()
            db.refresh(conversation)

        return session_id, conversation

    def _load_chat_history(self, session_id: str, conversation_id: int, db) -> List[Dict[str, str]]:
        # 1. Try Redis cache first
        cache_key = f"chat_history:{session_id}"
        cached = CacheService.get(cache_key)
        if cached and isinstance(cached, list):
            return cached

        # 2. Database fallback
        msgs = db.query(ChatMessage).filter(
            ChatMessage.conversation_id == conversation_id
        ).order_by(ChatMessage.created_at.desc()).limit(6).all()

        msgs.reverse()
        formatted = [{"role": m.role, "content": m.content} for m in msgs]
        
        if formatted:
            CacheService.set(cache_key, formatted, expire_seconds=86400)
        return formatted

    def _save_chat_turn(self, session_id: str, conversation_id: int, user_query: str, assistant_reply: str, db):
        # Save to DB
        msg_user = ChatMessage(conversation_id=conversation_id, role="user", content=user_query)
        msg_bot = ChatMessage(conversation_id=conversation_id, role="assistant", content=assistant_reply)
        db.add_all([msg_user, msg_bot])
        db.commit()

        # Update Redis cache
        history = self._load_chat_history(session_id, conversation_id, db)
        history.extend([
            {"role": "user", "content": user_query},
            {"role": "assistant", "content": assistant_reply}
        ])
        # Keep last 6 messages
        history = history[-6:]
        CacheService.set(f"chat_history:{session_id}", history, expire_seconds=86400)

    async def answer_farmer_query_async(
        self,
        query: str,
        user_id: int,
        session_id: Optional[str] = None,
        language: str = "English",
        farmer_name: Optional[str] = None,
        location_name: Optional[str] = None,
        current_crop: Optional[str] = None,
        farm_area_acres: Optional[float] = None,
        weather_data: Optional[dict] = None
    ) -> Dict[str, Any]:
        """
        Async Non-Blocking Personalized Agronomy Companion with Vector Retrieval,
        Multi-turn Session Memory, and Pydantic-Validated Structured Output.
        """
        clean_q = query.strip().lower()
        farmer_name_greet = farmer_name if farmer_name else "Farmer"

        db = SessionLocal()
        try:
            active_session_id, conversation = self._get_or_create_session(session_id, user_id, db)

            # Check gratitude/closure
            gratitude_phrases = ["thanks", "thank you", "ok thanks", "no thanks", "dhanyabad", "dhanyavaad", "bye", "goodbye"]
            if any(phrase in clean_q for phrase in gratitude_phrases):
                reply = (
                    f"You're very welcome, **{farmer_name_greet}**! 🌾\n\n"
                    f"Wishing you a healthy and prosperous harvest. Feel free to reach out anytime if you have more questions about your fields!"
                )
                self._save_chat_turn(active_session_id, conversation.id, query, reply, db)
                return {
                    "session_id": active_session_id,
                    "response": reply,
                    "structured_analysis": None
                }

            # 1. Build Farmer Profile Context
            farmer_ctx_parts = []
            if farmer_name:
                farmer_ctx_parts.append(f"Farmer Name: {farmer_name}")
            if location_name:
                farmer_ctx_parts.append(f"Location: {location_name}")
            if current_crop:
                farmer_ctx_parts.append(f"Active Crop: {current_crop}")
            if farm_area_acres:
                farmer_ctx_parts.append(f"Farm Area: {farm_area_acres} Acres")
            farmer_context_str = ", ".join(farmer_ctx_parts) if farmer_ctx_parts else "General Farmer"

            # 2. Weather Context Relevance Filtering
            weather_context_str = "No weather forecast requested for this query type."
            if self._is_weather_relevant(clean_q) and weather_data and "daily_weather" in weather_data:
                today_str = datetime.now().strftime("%Y-%m-%d")
                tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
                daily = weather_data["daily_weather"]
                lines = []
                for date_key, metrics in daily.items():
                    max_t = metrics.get("temp_max_c", 0.0)
                    min_t = metrics.get("temp_min_c", 0.0)
                    hum = metrics.get("humidity_percent", 0.0)
                    rain = metrics.get("precipitation_mm", 0.0)
                    wind_kmh = metrics.get("wind_speed_m_s", 0.0) * 3.6
                    
                    day_tag = " [TODAY]" if date_key == today_str else (" [TOMORROW]" if date_key == tomorrow_str else "")
                    rain_text = f"🌧️ RAIN EXPECTED ({rain:.1f} mm)" if rain >= 1.5 else f"☀️ Dry ({rain:.1f} mm)"
                    lines.append(f"- {date_key}{day_tag}: Max {max_t:.1f}°C, Min {min_t:.1f}°C, Hum {hum:.0f}%, Wind {wind_kmh:.1f} km/h, {rain_text}")
                weather_context_str = "\n".join(lines)

            # 3. Dense Vector Semantic Retrieval
            semantic_chunks = VectorSearchService.search_semantic_chunks(query, top_k=3, db=db)
            if semantic_chunks:
                context_text = "\n\n".join([f"[{c['doc_name']}] {c['content']}" for c in semantic_chunks])
            else:
                context_text = "No localized Package of Practices document context matched."

            # 4. Multi-Turn Session History
            past_turns = self._load_chat_history(active_session_id, conversation.id, db)

            # 5. System Prompt with Structured Output Request
            system_prompt = (
                "You are JalSathi AI (জলসাথী AI) 🌾, an expert, warm Agronomy Assistant for Indian farmers.\n\n"
                f"FARMER PROFILE:\n{farmer_context_str}\n\n"
                f"LIVE WEATHER FORECAST (INJECTED ONLY IF WEATHER-RELEVANT):\n{weather_context_str}\n\n"
                f"SEMANTIC KNOWLEDGE BASE (Package of Practices):\n{context_text}\n\n"
                "STRICT RESPONSE INSTRUCTIONS:\n"
                f"1. LANGUAGE SCRIPT: Respond ENTIRELY in target language ({language}).\n"
                "   - Bengali: Respond ONLY in natural Bengali script (বাংলা).\n"
                "   - Hindi: Respond ONLY in Hindi Devanagari script (हिंदी).\n"
                "   - English: Respond in clear English.\n"
                "2. OUTPUT FORMAT: You MUST return a JSON object matching this schema:\n"
                "   {\n"
                '     "reply_text": "Comprehensive, clear response in farmer\'s script",\n'
                '     "weather_alert": "Optional weather warning string or null",\n'
                '     "solution": {\n'
                '        "chemical_treatment": "Exact chemical dosage per acre (e.g. Cartap 4G @ 10 kg/acre)",\n'
                '        "organic_alternative": "Natural bio-organic alternative (e.g. Neem Oil 10,000 ppm)",\n'
                '        "preventative_cultural_tip": "Field management or drainage tip"\n'
                "     }\n"
                "   }\n"
            )

            if not self.client:
                fallback_reply = (
                    f"🌾 **Advisory for {query}**\n\n"
                    f"• **Active Crop**: {current_crop if current_crop else 'Paddy Rice'}\n"
                    f"• **Recommended Action**: Monitor soil moisture using the JalDrishti dashboard.\n"
                    f"• **Tip**: Apply recommended fertilizer dosages according to crop growth stage."
                )
                self._save_chat_turn(active_session_id, conversation.id, query, fallback_reply, db)
                return {
                    "session_id": active_session_id,
                    "response": fallback_reply,
                    "structured_analysis": None
                }

            # Build LLM Messages array
            messages = [{"role": "system", "content": system_prompt}]
            for turn in past_turns:
                messages.append({"role": turn["role"], "content": turn["content"]})
            messages.append({"role": "user", "content": query})

            # Multi-Model Fallback Chain for Groq API (strictly active verified models)
            fallback_models = [
                settings.GROQ_MODEL_NAME,
                "openai/gpt-oss-120b",
                "openai/gpt-oss-20b",
                "groq/compound-mini",
                "qwen/qwen3.6-27b"
            ]

            model_chain = []
            for m in fallback_models:
                if m and m not in model_chain:
                    model_chain.append(m)

            response = None
            last_err = None

            for model_id in model_chain:
                try:
                    logger.info(f"[RAGService] Invoking Groq LLM model: {model_id}")
                    response = await self.client.chat.completions.create(
                        model=model_id,
                        messages=messages,
                        response_format={"type": "json_object"},
                        temperature=0.3,
                        max_tokens=1000
                    )
                    if response:
                        logger.info(f"[RAGService] Successfully generated advisory using model: {model_id}")
                        break
                except Exception as model_err:
                    last_err = model_err
                    logger.warning(f"[RAGService] Groq model '{model_id}' failed: {model_err}. Trying next fallback model...")

            if not response:
                raise last_err or Exception("All Groq LLM models in fallback chain failed.")

            raw_json = response.choices[0].message.content
            parsed_resp = json.loads(raw_json)

            reply_text = parsed_resp.get("reply_text", "")
            if not reply_text:
                reply_text = str(parsed_resp)

            # Append formatted structured solution to reply_text if present for rich display
            sol = parsed_resp.get("solution")
            if sol and isinstance(sol, dict):
                chem = sol.get("chemical_treatment")
                org = sol.get("organic_alternative")
                prev = sol.get("preventative_cultural_tip")

                additions = []
                if chem:
                    additions.append(f"🧪 **Chemical Treatment**: {chem}")
                if org:
                    additions.append(f"🌿 **Organic / Bio-Alternative**: {org}")
                if prev:
                    additions.append(f"💡 **Preventative Cultural Tip**: {prev}")

                if additions:
                    reply_text += "\n\n" + "\n\n".join(additions)

            self._save_chat_turn(active_session_id, conversation.id, query, reply_text, db)

            return {
                "session_id": active_session_id,
                "response": reply_text,
                "structured_analysis": parsed_resp
            }

        except Exception as e:
            logger.error(f"[RAGService Error]: {e}")
            fallback = f"🌾 **Advisory for {query}**: Please keep soil at healthy field capacity and monitor dashboard recommendations."
            return {
                "session_id": session_id or "default_session",
                "response": fallback,
                "structured_analysis": None
            }
        finally:
            db.close()

    def answer_farmer_query(self, *args, **kwargs) -> Dict[str, Any]:
        """Synchronous wrapper for backward compatibility."""
        import asyncio
        return asyncio.run(self.answer_farmer_query_async(*args, **kwargs))