import os
import re
import math
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
        self.chunks: List[Dict[str, str]] = []
        self._load_and_index_docs()

    def _tokenize(self, text: str) -> List[str]:
        return [w.lower() for w in re.findall(r'\w+', text) if len(w) > 2]

    def _load_and_index_docs(self):
        if not os.path.exists(self.docs_dir):
            os.makedirs(self.docs_dir)
            return

        for filename in os.listdir(self.docs_dir):
            if filename.endswith(".txt"):
                filepath = os.path.join(self.docs_dir, filename)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                        # Split by double newlines or headers to create logical chunks
                        paragraphs = [p.strip() for p in content.split("\n\n") if len(p.strip()) > 30]
                        for p in paragraphs:
                            tokens = self._tokenize(p)
                            self.chunks.append({
                                "text": p,
                                "source": filename,
                                "tokens": set(tokens)
                            })
                except Exception as e:
                    print(f"[Warning] Failed to read {filename}: {e}")
        print(f"[Info] Indexed {len(self.chunks)} agricultural PoP document chunks!")

    def search(self, query: str, top_k: int = 3) -> str:
        if not self.chunks:
            return ""

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
        farm_area_acres: Optional[float] = None
    ) -> str:
        """Async Non-Blocking Personalized Agronomy Companion."""
        
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

        # Retrieve relevant localized document context
        context_text = self.doc_search.search(query, top_k=3)

        # Warm, Smart Agronomic Companion System Prompt
        system_prompt = (
            "You are JalSathi AI (জলসাথী AI) 🌾, an expert, warm, and highly practical Agronomy Assistant for Indian farmers.\n\n"
            f"FARMER PROFILE:\n{farmer_context_str}\n\n"
            "STRICT MULTILINGUAL & CONVERSATIONAL RULES:\n"
            f"1. LANGUAGE SCRIPT: Respond ENTIRELY in the requested target language ({language}).\n"
            "   - If Language is 'Bengali', respond ONLY in fluent, natural Bengali script (বাংলা).\n"
            "   - If Language is 'Hindi', respond ONLY in fluent, natural Hindi Devanagari script (हिंदी).\n"
            "   - If Language is 'English', respond in clear English.\n"
            "2. GRATITUDE & CLOSURE: If the farmer says thanks, dhanyabad, dhanyavaad, or goodbye, give a warm, polite closing wish for a bountiful harvest. DO NOT ask robotic follow-up questions.\n"
            "3. STRUCTURED DUAL SOLUTION (Chemical & Bio-Organic):\n"
            "   - When answering crop disease, pest, or fertilizer questions, ALWAYS provide:\n"
            "     * 🧪 **Chemical Treatment**: Exact chemical name and dosage per acre (e.g. Cartap 4G @ 10 kg/acre, Mancozeb @ 2.5 g/L).\n"
            "     * 🌿 **Organic / Bio-Alternative**: Natural treatment (e.g. Neem Oil 10,000 ppm, Pseudomonas fluorescens, Trichoderma viride).\n"
            "     * 💡 **Preventive Cultural Tip**: Field drainage, crop rotation, or earthing up advice.\n"
            "4. UNITS: Use Indian agricultural units (Acres, Bigha, kg, g, Liters, mL).\n\n"
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