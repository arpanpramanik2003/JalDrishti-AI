# Prompt Engineering & Grounding Safeguards

> **Audience**: AI safety researchers, prompt engineers, and backend developers.  
> **Source Modules**:  
> - [`app/services/rag_service.py:191-231, 390-415`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L191-L231)  
> **Testing Suite**: `tests/test_rag_pipeline.py` (Passing in CI)

---

## 1. System Prompt Architecture

In Phase 5 ([`PHASE5_CHANGELOG.md`](file:///d:/jaldrishti/PHASE5_CHANGELOG.md)), the system prompt was completely rewritten to enforce strict factual grounding against official agricultural guidelines.

### Grounding Prompt Structure ([`rag_service.py:390-414`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L390-L414))
```text
You are JalSathi AI (জলসাথী AI) 🌾, an expert, warm Agronomy Assistant for Indian farmers.

FARMER PROFILE:
{farmer_context_str}

LIVE WEATHER FORECAST (INJECTED ONLY IF WEATHER-RELEVANT):
{weather_context_str}

SEMANTIC KNOWLEDGE BASE (Package of Practices):
{context_text}

CRITICAL GROUNDING & SAFETY CONSTRAINTS:
- Only state a chemical name and dosage if it explicitly appears in the SEMANTIC KNOWLEDGE BASE context above.
- If the context does not contain a specific dosage, say so explicitly and advise the farmer to consult their local Krishi Vigyan Kendra (KVK) / agricultural extension officer — do not invent or estimate a dosage.
- Always prioritize practical, organic, and preventative management alongside or prior to chemical intervention.

RESPONSE INSTRUCTIONS:
1. LANGUAGE SCRIPT: Respond ENTIRELY in target language ({language}).
   - Bengali: Respond ONLY in natural Bengali script (বাংলা).
   - Hindi: Respond ONLY in Hindi Devanagari script (हिंदी).
   - English: Respond in clear English.
2. OUTPUT FORMAT: You MUST return a JSON object matching this schema:
   {
     "reply_text": "Comprehensive, clear response in farmer's script",
     "weather_alert": "Optional weather warning string or null",
     "solution": {
        "chemical_treatment": "Exact chemical dosage per acre from context only, or advice to consult local KVK",
        "organic_alternative": "Natural bio-organic alternative (e.g. Neem Oil 10,000 ppm)",
        "preventative_cultural_tip": "Field management or drainage tip"
     }
   }
```

---

## 2. Pydantic Structured Output Validation

To prevent malformed LLM responses from crashing the mobile client, Groq inference uses `response_format={"type": "json_object"}`. The JSON payload is validated using Pydantic v2 models:

```python
# app/services/rag_service.py:20-30
class StructuredDualSolution(BaseModel):
    chemical_treatment: Optional[str] = Field(default=None, description="Exact chemical treatment and dosage per acre")
    organic_alternative: Optional[str] = Field(default=None, description="Natural or bio-organic treatment alternative")
    preventative_cultural_tip: Optional[str] = Field(default=None, description="Preventative cultural or field management tip")

class ChatbotAnalysisResponse(BaseModel):
    reply_text: str = Field(..., description="Main advisory reply in requested target language and script")
    weather_alert: Optional[str] = Field(default=None, description="Live weather alert if rain/heat wave expected")
    solution: Optional[StructuredDualSolution] = Field(default=None, description="Dual treatment solution if query asks about disease/pest/fertilizer")
```

---

## 3. Post-Generation Chemical Verification Guardrail

Even with strict system prompts, Large Language Models can occasionally hallucinate chemical brand names or unverified dosages. Phase 5 introduced an automated post-generation guardrail function: `_verify_and_guard_chemicals()` ([`rag_service.py:191-231`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L191-L231)).

```mermaid
graph TD
    LLM["Groq LLM Generates JSON Output"] --> EXTRACT["Extract solution.chemical_treatment"]
    EXTRACT --> SCAN["Scan for 45+ Curated Active Ingredients<br/>(Cartap, Fipronil, Imidacloprid, etc.)"]
    
    SCAN --> DETECT{"Chemicals<br/>Detected?"}
    DETECT -->|No| PASS["Pass Output Cleanly"]
    DETECT -->|Yes| CHECK{"All Detected Chemicals<br/>Present in Retrieved PoP Context?"}
    
    CHECK -->|Yes| PASS
    CHECK -->|No (Ungrounded Chemical Found)| REPLACE["REPLACE with Safety Warning:<br/>'Specific dosage could not be validated against official PoP guides. Please consult your local KVK.'"]
```

### Curated Active Ingredients List
The engine scans against a registry of 45+ registered Indian agrochemicals ([`rag_service.py:46-55`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L46-L55)), including *Cartap hydrochloride*, *Chlorantraniliprole*, *Flubendiamide*, *Fipronil*, *Imidacloprid*, *Thiamethoxam*, *Buprofezin*, *Triflumezopyrim*, *Pymetrozine*, *Azoxystrobin*, *Difenoconazole*, *Tricyclazole*, *Hexaconazole*, *Propiconazole*, *Carbendazim*, *Mancozeb*, *Copper oxychloride*, *Streptomycin*, and *Validamycin*.

---

## 4. Honest Technical Caveats & Limitations

To maintain engineering integrity, the current implementation limitations of this guardrail are openly documented:

1. **Presence Check vs. Semantic Numerical Verification**:
   - The current guardrail verifies that the **chemical name** exists in the retrieved context.
   - However, it relies on string presence matching, not deep semantic Natural Language Inference (NLI). If the LLM mentions an authentic chemical name found in the context, but hallucinates an exaggerated numerical dosage (e.g. *100 kg/acre* instead of *10 kg/acre*), the keyword check will pass.
2. **Mitigation**: The system prompt explicitly instructs the LLM to output exact text from the context. Furthermore, all chemicals display a safety disclaimer advising farmers to confirm container labels and consult their local Krishi Vigyan Kendra (KVK).
3. **Future Enhancement**: Subsequent phases should integrate regex-based numerical dosage extraction against structured dosage tables.
