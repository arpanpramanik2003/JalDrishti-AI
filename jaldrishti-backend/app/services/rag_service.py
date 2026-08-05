import os
from typing import Optional
from langchain_community.document_loaders import TextLoader, DirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate
from app.core.config import settings

class RAGService:
    def __init__(self):
        self.docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'pop_docs'))
        self.chroma_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'chroma_db'))
        
        self.embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
        
        self.llm = None
        if settings.GROQ_API_KEY and settings.GROQ_API_KEY != "your_groq_api_key_here":
            try:
                self.llm = ChatGroq(
                    groq_api_key=settings.GROQ_API_KEY,
                    model_name=settings.GROQ_MODEL_NAME,
                    temperature=0.3
                )
            except Exception as e:
                print(f"[Warning] Failed to initialize ChatGroq: {e}")
        
        self.vector_store = None
        self._initialize_vector_store()

    def _initialize_vector_store(self):
        """Loads agricultural documents and indexes them into ChromaDB."""
        if not os.path.exists(self.docs_dir):
            os.makedirs(self.docs_dir)

        loader = DirectoryLoader(self.docs_dir, glob="*.txt", loader_cls=TextLoader)
        documents = loader.load()

        if not documents:
            print(f"[Warning] No agricultural documents found in {self.docs_dir}")
            return

        text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        chunks = text_splitter.split_documents(documents)

        self.vector_store = Chroma.from_documents(
            documents=chunks,
            embedding=self.embeddings,
            persist_directory=self.chroma_dir
        )
        print("[Info] Vector DB initialized with Package of Practices!")

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

        # Search localized vector DB
        context_text = ""
        if self.vector_store:
            try:
                retriever = self.vector_store.as_retriever(search_kwargs={"k": 3})
                relevant_docs = await retriever.ainvoke(query)
                if relevant_docs:
                    context_text = "\n\n".join([doc.page_content for doc in relevant_docs])
            except Exception as e:
                print(f"[Warning] Vector DB retrieval error: {e}")

        # Warm, Smart Agronomic Companion System Prompt
        system_prompt = (
            "You are JalSathi AI (জলসাথী AI) 🌾, an expert, warm, and highly practical Agronomy Assistant for Indian farmers.\n\n"
            "FARMER PROFILE:\n"
            "{farmer_context}\n\n"
            "STRICT MULTILINGUAL & CONVERSATIONAL RULES:\n"
            "1. LANGUAGE SCRIPT: Respond ENTIRELY in the requested target language ({language}).\n"
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
            "AGRICULTURAL KNOWLEDGE BASE (Package of Practices):\n{context}\n"
        )

        if not self.llm:
            return (
                f"🌾 **Advisory for {query}**\n\n"
                f"• **Active Crop**: {current_crop if current_crop else 'Paddy Rice'}\n"
                f"• **Recommended Action**: Monitor soil moisture using the JalDrishti dashboard.\n"
                f"• **Tip**: Apply **recommended N-P-K dosages** according to crop growth stage."
            )

        prompt = ChatPromptTemplate.from_messages([
            ("system", system_prompt),
            ("human", "{question}")
        ])

        try:
            chain = prompt | self.llm
            response = await chain.ainvoke({
                "farmer_context": farmer_context_str,
                "farmer_name_greet": farmer_name_greet,
                "context": context_text if context_text else "No localized document context matched.",
                "language": language,
                "question": query
            })
            return response.content
        except Exception as e:
            print(f"[Error in RAG LLM async call]: {e}")
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