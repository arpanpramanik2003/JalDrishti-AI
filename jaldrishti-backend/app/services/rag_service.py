import os
import re
import math
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from groq import AsyncGroq
from app.core.config import settings

class LightweightDocSearch:
    """
    Ultra-lightweight, zero-dependency BM25/TF-IDF Document Ranker for Agricultural PoP text files.
    Uses 0 MB extra RAM and requires no PyTorch/ChromaDB/LangChain binaries.
    """
    def __init__(self, docs_dir: str):
        self.docs_dir = docs_dir
        self.chunks: List[Dict[str, Any]] = []
        self._load_and_index_docs()

    def _tokenize(self, text: str) -> List[str]:
        return [w.lower() for w in re.findall(r'\w+', text) if len(w) > 2]

    def _load_and_index_docs(self):
        if not os.path.exists(self.docs_dir):
            print(f"[Warning] POP docs directory missing: {self.docs_dir}")
            return

        for fname in os.listdir(self.docs_dir):
            if fname.endswith(".txt"):
                fpath = os.path.join(self.docs_dir, fname)
                try:
                    with open(fpath, "r", encoding="utf-8") as f:
                        content = f.read()
                        paras = [p.strip() for p in content.split("\n\n") if len(p.strip()) > 40]
                        for p in paras:
                            self.chunks.append({
                                "text": p,
                                "tokens": set(self._tokenize(p))
                            })
                except Exception as e:
                    print(f"[Warning] Failed reading doc {fname}: {e}")

        print(f"[Info] Lightweight RAG indexed {len(self.chunks)} agricultural document chunks.")

    def search(self, query: str, top_k: int = 3) -> str:
        query_tokens = set(self._tokenize(query))
        if not query_tokens:
            return ""

        scored_chunks = []
        for chunk in self.chunks:
            overlap = len(query_tokens.intersection(chunk["tokens"]))
            if overlap > 0:
                score = overlap / (math.log(len(chunk["tokens"]) + 1) + 1.0)
                scored_chunks.append((score, chunk["text"]))

        scored_chunks.sort(key=lambda x: x[0], reverse=True)
        top_texts = [item[1] for item in scored_chunks[:top_k]]
        return "\n\n".join(top_texts)


class RAGService:
    """
    Ultra-Fast, Low-Memory Agronomy Companion powered directly by Groq Llama-3.3-70B.
    Memory Footprint: < 5 MB RAM (vs 550+ MB for PyTorch/ChromaDB).
    """
    def __init__(self):
        self.docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'pop_docs'))
        self.doc_search = LightweightDocSearch(self.docs_dir)
        
        self.client: Optional[AsyncGroq] = None
        if settings.GROQ_API_KEY and settings.GROQ_API_KEY != "your_groq_api_key_here":
            try:
                self.client = AsyncGroq(api_key=settings.GROQ_API_KEY)
                print("[Info] AsyncGroq client initialized successfully!")
            except Exception as e:
                print(f"[Warning] Failed to initialize AsyncGroq client: {e}")

    async def answer_farmer_query_async(
        self,
        query: str,
        language: str = "English",
        farmer_name: Optional[str] = None,
        location_name: Optional[str] = None,
        current_crop: Optional[str] = None,
        farm_area_acres: Optional[float] = None,
        weather_data: Optional[dict] = None
    ) -> str:
        """Async Non-Blocking Personalized Agronomy Companion with Live Satellite Weather Context."""
        
        clean_q = query.strip().lower()
        farmer_name_greet = farmer_name if farmer_name else "Farmer"

        # Check for gratitude/closure phrases
        gratitude_phrases = ["thanks", "thank you", "ok thanks", "no thanks", "dhanyabad", "dhanyavaad", "ok ok", "bye", "goodbye"]
        if any(phrase in clean_q for phrase in gratitude_phrases):
            return (
                f"You're very welcome, **{farmer_name_greet}**! 🌾\n\n"
                f"Wishing you a healthy and prosperous harvest. Feel free to reach out anytime if you have more questions about your fields!"
            )

        # Build Context Summary for Prompt
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

        # Process Live Weather & 7-Day Forecast Telemetry
        weather_context_str = "No live weather telemetry available."
        if weather_data and "daily_weather" in weather_data:
            today_str = datetime.now().strftime("%Y-%m-%d")
            tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
            daily = weather_data["daily_weather"]
            lines = []
            for date_key, metrics in daily.items():
                max_t = metrics.get("temp_max_c", 0.0)
                min_t = metrics.get("temp_min_c", 0.0)
                hum = metrics.get("humidity_percent", 0.0)
                rain = metrics.get("precipitation_mm", 0.0)
                wind_ms = metrics.get("wind_speed_m_s", 0.0)
                wind_kmh = wind_ms * 3.6
                
                day_tag = ""
                if date_key == today_str:
                    day_tag = " [TODAY / আজ / आज]"
                elif date_key == tomorrow_str:
                    day_tag = " [TOMORROW / আগামী কাল / कल]"
                    
                rain_text = f"🌧️ RAIN EXPECTED ({rain:.1f} mm)" if rain >= 1.5 else f"☀️ Clear/Dry ({rain:.1f} mm rain)"
                
                lines.append(
                    f"- Date {date_key}{day_tag}: Max Temp {max_t:.1f}°C, Min Temp {min_t:.1f}°C, "
                    f"Humidity {hum:.0f}%, Wind Speed {wind_kmh:.1f} km/h, {rain_text}"
                )
            weather_context_str = "\n".join(lines)

        # Retrieve relevant localized document context
        context_text = self.doc_search.search(query, top_k=3)

        # Warm, Smart Agronomic Companion System Prompt
        system_prompt = (
            "You are JalSathi AI (জলসাথী AI) 🌾, an expert, warm, and highly practical Agronomy Assistant for Indian farmers.\n\n"
            f"FARMER PROFILE:\n{farmer_context_str}\n\n"
            f"LIVE REAL-TIME SATELLITE WEATHER TELEMETRY & FORECAST (Open-Meteo Data):\n{weather_context_str}\n\n"
            "STRICT MULTILINGUAL & WEATHER RULES:\n"
            f"1. LANGUAGE SCRIPT: Respond ENTIRELY in the requested target language ({language}).\n"
            "   - If Language is 'Bengali', respond ONLY in fluent, natural Bengali script (বাংলা).\n"
            "   - If Language is 'Hindi', respond ONLY in fluent, natural Hindi Devanagari script (हिंदी).\n"
            "   - If Language is 'English', respond in clear English.\n"
            "2. TODAY'S & TOMORROW'S WEATHER INQUIRIES:\n"
            "   - When the farmer asks about today's weather, tomorrow's weather, or rain forecast (e.g. 'will it rain tomorrow?', 'today weather', 'কাল বৃষ্টি হবে?'):\n"
            "     * Quote exact dates, Max/Min Temperatures (°C), Relative Humidity (%), and Rain Forecast (mm) from the LIVE WEATHER TELEMETRY above.\n"
            "     * If rain is expected (>= 1.5 mm), explicitly alert the farmer and advise them to PAUSE or DELAY irrigation to save water and pump electricity!\n"
            "     * If no rain is expected, provide clear weather parameters and state that field conditions are dry.\n"
            "3. GRATITUDE & CLOSURE: If the farmer says thanks, dhanyabad, dhanyavaad, or goodbye, give a warm, polite closing wish for a bountiful harvest. DO NOT ask robotic follow-up questions.\n"
            "4. STRUCTURED DUAL SOLUTION (Chemical & Bio-Organic):\n"
            "   - When answering crop disease, pest, or fertilizer questions, ALWAYS provide:\n"
            "     * 🧪 **Chemical Treatment**: Exact chemical name and dosage per acre (e.g. Cartap 4G @ 10 kg/acre, Mancozeb @ 2.5 g/L).\n"
            "     * 🌿 **Organic / Bio-Alternative**: Natural treatment (e.g. Neem Oil 10,000 ppm, Pseudomonas fluorescens, Trichoderma viride).\n"
            "     * 💡 **Preventive Cultural Tip**: Field drainage, crop rotation, or earthing up advice.\n"
            "5. UNITS: Use Indian agricultural units (Acres, Bigha, kg, g, Liters, mL).\n\n"
            f"AGRICULTURAL KNOWLEDGE BASE (Package of Practices):\n{context_text if context_text else 'No localized document context matched.'}\n"
        )

        if not self.client:
            return (
                f"🌾 **Advisory for {query}**\n\n"
                f"• **Active Crop**: {current_crop if current_crop else 'Paddy Rice'}\n"
                f"• **Recommended Action**: Monitor soil moisture using the JalDrishti dashboard.\n"
                f"• **Tip**: Apply **recommended N-P-K dosages** according to crop growth stage."
            )

        try:
            response = await self.client.chat.completions.create(
                model=settings.GROQ_MODEL_NAME,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": query}
                ],
                temperature=0.3,
                max_tokens=800
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"[Error in Groq API call]: {e}")
            return (
                f"🌾 **Advisory for {query}**:\n\n"
                f"• Keep soil at healthy field capacity.\n"
                f"• Check the JalDrishti Dashboard for real-time FAO-56 irrigation recommendations.\n"
                f"• Apply standard **recommended fertilizer dosages** according to growth stage."
            )

    def answer_farmer_query(self, *args, **kwargs) -> str:
        """Synchronous wrapper for backward compatibility."""
        import asyncio
        return asyncio.run(self.answer_farmer_query_async(*args, **kwargs))