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
    Production-Grade Multilingual Agronomy RAG Engine powered exclusively by Groq API
    with Dense ChromaDB Vector Embeddings, Session History, Strict Grounding,
    and a Genuine 3-Tier Fallback Cascade (Groq Tier 1 -> Groq Tier 2 -> Local PoP Fallback).
    """
    WEATHER_KEYWORDS = {
        "weather", "rain", "temperature", "forecast", "humidity", "monsoon", "storm", "sun", "hot", "dry",
        "বৃষ্টি", "আবহাওয়া", "তাপমাত্রা", "ঝড়", "মেঘ", "জল", "সেচ",
        "मौसम", "बारिश", "तापमान", "आंधी", "सिंचाई", "पानी",
        "irrigate", "irrigation", "spray", "spraying"
    }

    # Curated agronomic chemical patterns / active ingredients in ICAR PoP docs
    COMMON_AGROCHEMICALS = [
        "cartap", "chlorantraniliprole", "flubendiamide", "fipronil", "imidacloprid",
        "thiamethoxam", "buprofezin", "triflumezopyrim", "pymetrozine", "azoxystrobin",
        "difenoconazole", "tricyclazole", "hexaconazole", "propiconazole", "carbendazim",
        "mancozeb", "copper oxychloride", "streptomycin", "validamycin", "dimethoate",
        "chlorpyriphos", "quinalphos", "acephate", "emamectin benzoate", "spinosad",
        "indoxacarb", "coragen", "bavistin", "dithane", "confidor", "alika", "virtako",
        "rogor", "monocrotophos", "atrazine", "pendimethalin", "glyphosate", "paraquat",
        "2,4-d", "pretilachlor", "pyrazosulfuron", "bispyribac-sodium", "metribuzin"
    ]

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

    def _get_or_create_session(self, session_id: Optional[str], user_id: int, db) -> tuple[str, int]:
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

        return session_id, int(conversation.id)

    async def _load_chat_history(self, session_id: str, conversation_id: int, db) -> List[Dict[str, str]]:
        # 1. Try Redis cache first
        cache_key = f"chat_history:{session_id}"
        try:
            cached = await CacheService.get(cache_key)
            if cached and isinstance(cached, list):
                return cached
        except Exception as ce:
            logger.debug(f"[RAGService] Redis cache lookup skipped: {ce}")

        # 2. Database fallback
        try:
            msgs = db.query(ChatMessage).filter(
                ChatMessage.conversation_id == conversation_id
            ).order_by(ChatMessage.created_at.desc()).limit(6).all()

            msgs.reverse()
            formatted = [{"role": m.role, "content": m.content} for m in msgs]
            
            if formatted:
                try:
                    await CacheService.set(cache_key, formatted, expire_seconds=86400)
                except Exception:
                    pass
            return formatted
        except Exception as e:
            logger.warning(f"[RAGService] Load chat history warning: {e}")
            return []

    async def _save_chat_turn(self, session_id: str, conversation_id: int, user_query: str, assistant_reply: str, db):
        # Save to DB with exception safety
        try:
            msg_user = ChatMessage(conversation_id=conversation_id, role="user", content=user_query)
            msg_bot = ChatMessage(conversation_id=conversation_id, role="assistant", content=assistant_reply)
            db.add_all([msg_user, msg_bot])
            db.commit()
        except Exception as e:
            logger.warning(f"[RAGService] Save chat turn DB warning: {e}")
            try:
                db.rollback()
            except Exception:
                pass

        # Update Redis cache
        try:
            history = await self._load_chat_history(session_id, conversation_id, db)
            history.extend([
                {"role": "user", "content": user_query},
                {"role": "assistant", "content": assistant_reply}
            ])
            # Keep last 6 messages
            history = history[-6:]
            await CacheService.set(f"chat_history:{session_id}", history, expire_seconds=86400)
        except Exception as ce:
            logger.debug(f"[RAGService] Redis save chat turn warning: {ce}")

    async def _translate_query_to_english(self, query: str, language: str) -> str:
        """
        Translates a non-English query into English agronomy search terms using a lightweight Groq call.
        Does NOT introduce any external translation libraries or third-party APIs.
        """
        # If language is English or text has no Indic characters, return as is
        is_indic = any('\u0900' <= char <= '\u097F' or '\u0980' <= char <= '\u09FF' for char in query)
        if not is_indic and language.strip().lower() == "english":
            return query

        if not self.client:
            return query

        try:
            logger.info(f"[RAGService] Translating query to English for vector search: '{query}'")
            resp = await self.client.chat.completions.create(
                model=settings.GROQ_MODEL_NAME or "openai/gpt-oss-20b",
                messages=[
                    {
                        "role": "system",
                        "content": "You are an agricultural translation assistant. Translate the following farmer query into clear, concise English agronomic search terms. Output ONLY the English translation, without explanation or quotes."
                    },
                    {
                        "role": "user",
                        "content": query
                    }
                ],
                temperature=0.1
            )
            translated = resp.choices[0].message.content.strip()
            # Clean possible markdown or enclosing quotes
            translated = re.sub(r'^["\']|["\']$', '', translated).strip()
            if translated:
                logger.info(f"[RAGService] Translated query: '{translated}'")
                return translated
        except Exception as e:
            logger.warning(f"[RAGService] Preliminary translation failed ({e}), proceeding with original query.")

        return query

    def _verify_and_guard_chemicals(
        self,
        reply_text: str,
        solution: Optional[dict],
        context_chunks: List[Dict[str, Any]]
    ) -> tuple[str, Optional[dict]]:
        """
        [F-22] Anti-hallucination guardrail:
        Verifies whether chemical recommendations mentioned in the generated solution
        actually appear in the retrieved context chunks. If an ungrounded chemical or dosage
        is detected, replaces it with a warning advising consultation with the local KVK.
        """
        if not context_chunks:
            # If no context was retrieved, no chemical should be claimed with dosage
            kvk_notice = "Specific chemical dosage not confirmed in regional guides. Please consult your local Krishi Vigyan Kendra (KVK) or agricultural extension officer."
            if solution and isinstance(solution, dict):
                if solution.get("chemical_treatment") and solution["chemical_treatment"].lower() not in ["n/a", "none", "not applicable"]:
                    solution["chemical_treatment"] = kvk_notice
            return reply_text, solution

        context_full_text = " ".join([c.get("content", "") for c in context_chunks]).lower()

        if solution and isinstance(solution, dict):
            chem_text = solution.get("chemical_treatment")
            if chem_text and chem_text.lower() not in ["n/a", "none", "not applicable"]:
                # Check known chemical names
                chem_lower = chem_text.lower()
                detected_chemicals = [
                    chem for chem in self.COMMON_AGROCHEMICALS
                    if chem in chem_lower
                ]
                # If chemicals found in the recommendation, verify they are in the retrieved context
                ungrounded = [c for c in detected_chemicals if c not in context_full_text]
                if ungrounded:
                    logger.warning(f"[RAGService Guardrail] Flagged ungrounded chemical(s): {ungrounded} not found in retrieved PoP context.")
                    solution["chemical_treatment"] = (
                        f"Specific dosage for {', '.join([u.title() for u in ungrounded])} could not be validated against official regional PoP guides. "
                        "Please consult your local Krishi Vigyan Kendra (KVK) or Block Agriculture Officer before spraying."
                    )

        return reply_text, solution

    def _format_local_deterministic_fallback(
        self,
        query: str,
        retrieved_chunks: List[Dict[str, Any]],
        language: str,
        current_crop: Optional[str]
    ) -> str:
        """
        [F-10 Tier 3]: Genuine Local Deterministic Fallback.
        Directly extracts and formats retrieved Package of Practices (PoP) knowledge chunks
        without using any LLM, providing grounded, verified agronomic advice during outages.
        """
        crop_title = current_crop.title() if current_crop else "Field Crop"
        lang_lower = language.strip().lower()

        if not retrieved_chunks:
            if lang_lower == "bengali":
                return (
                    f"🌾 **জলসাথী অফলাইন কৃষি নির্দেশিকা ({crop_title})**\n\n"
                    f"আপনার প্রশ্ন: *\"{query}\"*\n\n"
                    f"⚠️ আঞ্চলিক কৃষি নির্দেশিকায় এই বিষয়ে সরাসরি তথ্য মেলেনি।\n"
                    f"• অনুগ্রহ করে সঠিক রাসায়নিক মাত্রা ও সুপারিশের জন্য আপনার স্থানীয় **কৃষি বিজ্ঞান কেন্দ্র (KVK)** বা ব্লক কৃষি আধিকারিকের সাথে যোগাযোগ করুন।\n"
                    f"• সেচ ও মাটির আর্দ্রতা পর্যবেক্ষণের জন্য জলদৃষ্টি ড্যাশবোর্ড অনুসরণ করুন।"
                )
            elif lang_lower == "hindi":
                return (
                    f"🌾 **जलसाथी ऑफलाइन कृषि परामर्श ({crop_title})**\n\n"
                    f"आपका प्रश्न: *\"{query}\"*\n\n"
                    f"⚠️ क्षेत्रीय पैकेज ऑफ प्रैक्टिसेज में इस पर विशिष्ट जानकारी उपलब्ध नहीं है।\n"
                    f"• कृपया सटीक कीटनाशक और खुराक के लिए अपने नजदीकी **कृषि विज्ञान केंद्र (KVK)** या कृषि अधिकारी से संपर्क करें।\n"
                    f"• मिट्टी की नमी और सिंचाई के लिए जलदृष्टि डैशबोर्ड की निगरानी करें।"
                )
            else:
                return (
                    f"🌾 **JalSathi Offline Agronomy Guidance ({crop_title})**\n\n"
                    f"Query: *\"{query}\"*\n\n"
                    f"⚠️ No verified Package of Practices section directly matched this specific query.\n"
                    f"• Please consult your local **Krishi Vigyan Kendra (KVK)** or agricultural extension officer for specific dosage recommendations.\n"
                    f"• Continue monitoring soil moisture on your JalDrishti dashboard."
                )

        # Chunks are available: format directly
        sections_content = []
        for idx, chunk in enumerate(retrieved_chunks, 1):
            crop = chunk.get("crop", crop_title)
            sec = chunk.get("section", "Recommended Practices")
            content = chunk.get("content", "").strip()
            sections_content.append(f"### 📌 [{crop}] {sec}\n{content}")

        extracted_text = "\n\n".join(sections_content)

        if lang_lower == "bengali":
            return (
                f"🌾 **জলসাথী নির্দেশিকা (ICAR সরাসরি তথ্যভাণ্ডার)**\n\n"
                f"*(অনলাইন সার্ভার ব্যস্ত থাকায় অফলাইন প্যাকেজ অফ প্র্যাকটিসেস থেকে তথ্য দেওয়া হলো)*\n\n"
                f"{extracted_text}\n\n"
                f"⚠️ *সতর্কতা: যেকোনো রাসায়নিক প্রয়োগের আগে সঠিক মাত্রা নিশ্চিত করতে স্থানীয় কৃষি আধিকারিকের পরামর্শ নিন।*"
            )
        elif lang_lower == "hindi":
            return (
                f"🌾 **जलसाथी परामर्श (ICAR प्रत्यक्ष ज्ञान भंडार)**\n\n"
                f"*(सर्वर व्यस्त होने के कारण ऑफलाइन पैकेज ऑफ प्रैक्टिसेज से सीधे जानकारी दी जा रही है)*\n\n"
                f"{extracted_text}\n\n"
                f"⚠️ *चेतावनी: किसी भी रसायन का छिड़काव करने से पहले स्थानीय कृषि अधिकारी या KVK से खुराक की पुष्टि करें।*"
            )
        else:
            return (
                f"🌾 **JalSathi Verified PoP Advisory (Direct Extraction)**\n\n"
                f"*(Derived directly from ICAR / State Agricultural University Package of Practices)*\n\n"
                f"{extracted_text}\n\n"
                f"⚠️ *Safety Notice: Only apply chemicals and dosages explicitly stated above. For unlisted symptoms, consult your local Krishi Vigyan Kendra (KVK).*"
            )

    async def answer_farmer_query_async(
        self,
        query: str,
        user_id: int = 1,
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
            active_session_id, conv_id = self._get_or_create_session(session_id, user_id, db)

            # Check gratitude/closure
            gratitude_phrases = ["thanks", "thank you", "ok thanks", "no thanks", "dhanyabad", "dhanyavaad", "bye", "goodbye"]
            if any(phrase in clean_q for phrase in gratitude_phrases):
                reply = (
                    f"You're very welcome, **{farmer_name_greet}**! 🌾\n\n"
                    f"Wishing you a healthy and prosperous harvest. Feel free to reach out anytime if you have more questions about your fields!"
                )
                await self._save_chat_turn(active_session_id, conv_id, query, reply, db)
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

            # 3. [F-09] Preliminary Query Translation & Dense Vector Semantic Retrieval
            search_query = await self._translate_query_to_english(query, language)
            semantic_chunks = VectorSearchService.search_semantic_chunks(
                query=search_query,
                top_k=3,
                crop_filter=current_crop
            )
            if semantic_chunks:
                context_text = "\n\n".join([f"[{c['crop']} - {c['section']}] {c['content']}" for c in semantic_chunks])
            else:
                context_text = "No localized Package of Practices document context matched above the minimum similarity threshold."

            # 4. Multi-Turn Session History
            past_turns = await self._load_chat_history(active_session_id, conv_id, db)

            # 5. [F-22] System Prompt with Strict Grounding & Anti-Hallucination Constraints
            system_prompt = (
                "You are JalSathi AI (জলসাথী AI) 🌾, an expert, warm Agronomy Assistant for Indian farmers.\n\n"
                f"FARMER PROFILE:\n{farmer_context_str}\n\n"
                f"LIVE WEATHER FORECAST (INJECTED ONLY IF WEATHER-RELEVANT):\n{weather_context_str}\n\n"
                f"SEMANTIC KNOWLEDGE BASE (Package of Practices):\n{context_text}\n\n"
                "CRITICAL GROUNDING & SAFETY CONSTRAINTS:\n"
                "- Only state a chemical name and dosage if it explicitly appears in the SEMANTIC KNOWLEDGE BASE context above.\n"
                "- If the context does not contain a specific dosage, say so explicitly and advise the farmer to consult their local Krishi Vigyan Kendra (KVK) / agricultural extension officer — do not invent or estimate a dosage.\n"
                "- Always prioritize practical, organic, and preventative management alongside or prior to chemical intervention.\n\n"
                "RESPONSE INSTRUCTIONS:\n"
                f"1. LANGUAGE SCRIPT: Respond ENTIRELY in target language ({language}).\n"
                "   - Bengali: Respond ONLY in natural Bengali script (বাংলা).\n"
                "   - Hindi: Respond ONLY in Hindi Devanagari script (हिंदी).\n"
                "   - English: Respond in clear English.\n"
                "2. OUTPUT FORMAT: You MUST return a JSON object matching this schema:\n"
                "   {\n"
                '     "reply_text": "Comprehensive, clear response in farmer\'s script",\n'
                '     "weather_alert": "Optional weather warning string or null",\n'
                '     "solution": {\n'
                '        "chemical_treatment": "Exact chemical dosage per acre from context only, or advice to consult local KVK",\n'
                '        "organic_alternative": "Natural bio-organic alternative (e.g. Neem Oil 10,000 ppm)",\n'
                '        "preventative_cultural_tip": "Field management or drainage tip"\n'
                "     }\n"
                "   }\n"
            )

            # If client is not configured, fall back to Tier 3 Local Deterministic Fallback immediately
            if not self.client:
                logger.warning("[RAGService] AsyncGroq client unavailable. Using Tier 3 Local Fallback.")
                fallback_reply = self._format_local_deterministic_fallback(query, semantic_chunks, language, current_crop)
                await self._save_chat_turn(active_session_id, conv_id, query, fallback_reply, db)
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

            # [F-10] Multi-Tier Groq Cascade (Tier 1 Primary -> Tier 2 Fast Fallback)
            model_chain = [
                settings.GROQ_MODEL_NAME or "openai/gpt-oss-20b",
                "groq/compound-mini",
                "openai/gpt-oss-120b"
            ]
            # Deduplicate preserving order
            seen_models = set()
            ordered_chain = []
            for m in model_chain:
                if m and m not in seen_models:
                    seen_models.add(m)
                    ordered_chain.append(m)

            response = None
            last_err = None

            for model_id in ordered_chain:
                try:
                    logger.info(f"[RAGService] Invoking Groq LLM model: {model_id}")
                    response = await self.client.chat.completions.create(
                        model=model_id,
                        messages=messages,
                        response_format={"type": "json_object"},
                        temperature=0.3
                    )
                    if response:
                        logger.info(f"[RAGService] Successfully generated advisory using model: {model_id}")
                        break
                except Exception as model_err:
                    last_err = model_err
                    logger.warning(f"[RAGService] Groq model '{model_id}' failed: {model_err}. Trying next fallback tier...")

            # If all Groq models failed, proceed to Tier 3: Local Deterministic Fallback
            if not response:
                logger.error(f"[RAGService] All Groq API tiers failed ({last_err}). Invoking Tier 3 Local Fallback.")
                local_fallback_reply = self._format_local_deterministic_fallback(
                    query=query,
                    retrieved_chunks=semantic_chunks,
                    language=language,
                    current_crop=current_crop
                )
                await self._save_chat_turn(active_session_id, conv_id, query, local_fallback_reply, db)
                return {
                    "session_id": active_session_id,
                    "response": local_fallback_reply,
                    "structured_analysis": None
                }

            raw_json = response.choices[0].message.content
            parsed_resp = json.loads(raw_json)

            reply_text = parsed_resp.get("reply_text", "")
            if not reply_text:
                reply_text = str(parsed_resp)

            sol = parsed_resp.get("solution")
            # [F-22] Post-generation chemical guardrail check
            reply_text, sol = self._verify_and_guard_chemicals(
                reply_text=reply_text,
                solution=sol,
                context_chunks=semantic_chunks
            )
            parsed_resp["solution"] = sol

            # Append formatted structured solution to reply_text if present for rich display
            if sol and isinstance(sol, dict):
                chem = sol.get("chemical_treatment")
                org = sol.get("organic_alternative")
                prev = sol.get("preventative_cultural_tip")

                def _is_valid_tip(val):
                    if not val or not isinstance(val, str):
                        return False
                    v = val.strip().lower().rstrip('.')
                    return v not in ["n/a", "none", "null", "not applicable", "no treatment needed", "no treatment required", "not required"]

                additions = []
                if _is_valid_tip(chem):
                    additions.append(f"🧪 **Chemical Treatment**: {chem}")
                if _is_valid_tip(org):
                    additions.append(f"🌿 **Organic / Bio-Alternative**: {org}")
                if _is_valid_tip(prev):
                    additions.append(f"💡 **Preventative Cultural Tip**: {prev}")

                if additions:
                    reply_text += "\n\n" + "\n\n".join(additions)

            await self._save_chat_turn(active_session_id, conv_id, query, reply_text, db)

            return {
                "session_id": active_session_id,
                "response": reply_text,
                "structured_analysis": parsed_resp
            }

        except Exception as e:
            logger.error(f"[RAGService Error]: {e}")
            fallback = self._format_local_deterministic_fallback(query, [], language, current_crop)
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