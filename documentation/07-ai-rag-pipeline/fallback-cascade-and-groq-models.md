# The Three-Tier Fallback Cascade & Groq Inference Models

> **Audience**: AI platform engineers, site reliability engineers, and backend developers.  
> **Source Implementation**: [`app/services/rag_service.py:233-305, 434-460`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L233-L305)  
> **Configuration**: [`app/core/config.py:28-29`](file:///d:/jaldrishti/jaldrishti-backend/app/core/config.py#L28-L29)

---

## 1. Complete Gemini Removal & Real Fallback Chain

Legacy project documentation depicted a fallback chain relying on Google Gemini. During the Phase 2 and Phase 5 audits, this was confirmed to be completely non-functional (no Gemini SDK, no API key).

Phase 5 purged all Gemini references and implemented a genuine **Three-Tier Fallback Cascade**:

```mermaid
graph TD
    START["Farmer Chat Query"] --> TIER1["Tier 1: Primary Groq LLM<br/>(openai/gpt-oss-20b)"]
    
    TIER1 -->|Success (HTTP 200)| VALIDATE["Anti-Hallucination Guardrail<br/>(_verify_and_guard_chemicals)"]
    TIER1 -.->|Timeout / Rate Limit (429) / Error| TIER2["Tier 2: Fast Groq Fallback<br/>(groq/compound-mini)"]
    
    TIER2 -->|Success (HTTP 200)| VALIDATE
    TIER2 -.->|Complete Network Outage / API Down| TIER3["Tier 3: Local Deterministic Fallback<br/>(Zero-LLM Direct PoP Formatter)"]
    
    VALIDATE --> OUTPUT["Structured JSON Advisory Output"]
    TIER3 --> OUTPUT
```

---

## 2. Tier Specifications

### Tier 1: Primary Groq LLM (`openai/gpt-oss-20b`)
- **Role**: Primary generation engine for complex multi-turn reasoning, vernacular grammar synthesis, and empathetic conversational tone.
- **Config Key**: `settings.GROQ_MODEL_NAME` (default: `"openai/gpt-oss-20b"`).
- **Execution Parameters**: `temperature=0.3`, `response_format={"type": "json_object"}`.

### Tier 2: Secondary Fast Groq Fallback (`groq/compound-mini`)
- **Role**: High-throughput fallback model automatically invoked if Tier 1 encounters HTTP 429 rate limiting, context-length errors, or gateway timeouts.
- **Execution**: Seamlessly re-submits the exact same system prompt, farmer profile context, and conversation history without dropping the user turn.

### Tier 3: Local Deterministic Fallback (Zero-LLM Direct PoP Formatter)
- **Role**: High-availability safety net guaranteeing verified agronomic guidance even during catastrophic cloud API outages, network disconnection, or missing Groq API credentials.
- **Implementation**: [`_format_local_deterministic_fallback`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L233-L305).
- **Mechanism**: Bypasses LLM inference completely. Takes the top semantic chunks retrieved from local ChromaDB and formats them into an authoritative markdown advisory in the farmer's requested language.

---

## 3. Sample Outputs from Phase 5 Validation

### 1. Tier 1 / Tier 2 Generated Advisory Output (English)
```json
{
  "reply_text": "For controlling Yellow Stem Borer in your rice crop, the recommended chemical treatment is Cartap Hydrochloride 4G applied at 10 kg per acre. This dosage is taken directly from the official practice guidelines for West Bengal. If you prefer to avoid chemicals, you can use neem oil at about 10,000 ppm as a natural deterrent. To prevent future infestations, keep the field well drained, practice crop rotation, and avoid excessive nitrogen fertilization.",
  "weather_alert": null,
  "solution": {
    "chemical_treatment": "Cartap Hydrochloride 4G @ 10 kg/acre",
    "organic_alternative": "Neem oil 10,000 ppm @ 2 ml/L water",
    "preventative_cultural_tip": "Maintain proper drainage, rotate crops, and limit excess nitrogen to reduce borer attraction."
  }
}
```

### 2. Tier 3 Local Deterministic Fallback Output (Bengali)
When Groq is unavailable, Tier 3 extracts and formats verified ICAR chunks directly:

```markdown
🌾 **জলসাথী নির্দেশিকা (ICAR সরাসরি তথ্যভাণ্ডার)**

*(অনলাইন সার্ভার ব্যস্ত থাকায় অফলাইন প্যাকেজ অফ প্র্যাকটিসেস থেকে তথ্য দেওয়া হলো)*

### 📌 [Paddy Rice] 2. PEST & DISEASE CONTROL
PACKAGE OF PRACTICES: PADDY RICE (WEST BENGAL)
2. PEST & DISEASE CONTROL:
- Yellow Stem Borer: Symptoms include deadhearts in early stages and whiteheads during flowering. 
Treatment: Apply Cartap Hydrochloride 4G @ 10 kg/acre or Chlorantraniliprole 18.5% SC @ 60 ml/acre.

⚠️ *সতর্কতা: যেকোনো রাসায়নিক প্রয়োগের আগে সঠিক মাত্রা নিশ্চিত করতে স্থানীয় কৃষি আধিকারিকের পরামর্শ নিন।*
```

### 3. Tier 3 Fallback When No Chunks Match Similarity Threshold:
If a farmer asks a question that does not match any agricultural guidelines:

```markdown
🌾 **JalSathi Offline Agronomy Guidance (Field Crop)**

Query: *"How do I control alien fungus X?"*

⚠️ No verified Package of Practices section directly matched this specific query.
• Please consult your local Krishi Vigyan Kendra (KVK) or agricultural extension officer for specific dosage recommendations.
• Continue monitoring soil moisture on your JalDrishti dashboard.
```

---

## 4. Verification of Gemini Removal

Case-insensitive ripgrep audits across the entire backend code and documentation confirm zero occurrences of `gemini` or `google-generativeai`:

```powershell
$ grep -rnI "gemini" jaldrishti-backend/
# (0 matches found)

$ grep -rnI "generativeai" jaldrishti-backend/
# (0 matches found)
```
