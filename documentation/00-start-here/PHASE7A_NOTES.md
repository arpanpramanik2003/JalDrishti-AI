# Phase 7A Build Notes & Editorial Decisions

**Document Type**: Engineering Build Notes & Documentation Provenance  
**Date**: September 9, 2026  
**Status**: COMPLETE  
**Author**: Technical Writing Specialist (`agency-technical-writer`)  
**Scope**: `documentation/` (Phases 00 & 01)  

---

## 1. Summary of Files Created

The brand new `documentation/` directory was created without modifying, renaming, moving, or deleting any file within the legacy `docs/` folder:

```text
documentation/
├── README.md
├── 00-start-here/
│   ├── what-is-jaldrishti.md
│   ├── how-to-navigate-this-documentation.md
│   └── PHASE7A_NOTES.md (This file)
└── 01-concepts-and-workflows/
    ├── the-irrigation-problem.md
    ├── how-jaldrishti-decides-when-to-water.md
    ├── end-to-end-farmer-journey.md
    ├── rain-hold-and-savings-explained.md
    └── jalsathi-ai-explained.md
```

---

## 2. Confirmation of Legacy `docs/` Integrity

Per the strict requirement of the user request, the legacy `docs/` directory was left completely untouched as an archival historical record:

```powershell
$ git status -s docs/
# Output: (Empty - zero files modified, added, or deleted)
```

---

## 3. Editorial Judgment Calls & Honest Framing Decisions

During the drafting of these conceptual and workflow documents, the technical writer made several deliberate editorial choices to ensure radical truthfulness, avoiding the marketing exaggerations found in the original documentation set:

### Decision 1: "Sensorless Satellite" vs. "IoT Sensor-Equivalent Accuracy"
- **Legacy Claim**: Original docs claimed "IoT-equivalent precision at zero cost."
- **Editorial Decision**: Replaced with an honest trade-off analysis. We clearly explain that using satellite grids (1 km Open-Meteo and 250 m ISRIC SoilGrids) costs ₹0 in field hardware, making it affordable for smallholders, but explicitly state that regional satellite grids cannot measure localized village micro-bursts or subsurface hardpans.

### Decision 2: 5 mm / 48-Hour Rain Hold Threshold
- **Legacy Claim**: Presented as an omniscient, dynamic weather decision engine.
- **Editorial Decision**: Explicitly documented as a **fixed operational heuristic**. We explain that `5 mm / 48 hours` is a practical rule of thumb that catches most major monsoon rain events, but honestly note in a highlighted box that it does not yet adjust dynamically for soil infiltration rates (e.g. clay vs sand).

### Decision 3: Zero-State ROI vs. Arbitrary Offsets
- **Legacy Claim**: Previous code added `+3` or `+4` offsets to irrigation runs, showing fake savings to brand new users.
- **Editorial Decision**: Documented the real post-fix behavior. New farmers see an honest `0 kL saved (₹0)` accompanied by an inviting prompt to begin logging their pump runs.

### Decision 4: Complete Removal of Google Gemini Mentions
- **Legacy Claim**: A three-tier fallback involving Google Gemini 1.5 Flash.
- **Editorial Decision**: Completely omitted Gemini. Accurately documented the real Groq multi-model cascade (Tier 1 Primary Groq $\rightarrow$ Tier 2 Fast Groq $\rightarrow$ Tier 3 Local Deterministic Fallback using direct PoP chunk extraction).

### Decision 5: Language Support Framing
- **Legacy Claim**: Claimed full end-to-end multi-lingual mobile UI.
- **Editorial Decision**: Clarified the distinction: JalSathi AI voice/chat is 100% functional in Bengali and Hindi (translating and generating in natural Bengali/Hindi script with TTS audio), while mobile screen labels remain in English with 14 ARB keys translated, leaving full screen UI labeled as "Coming Soon" to maintain translation consistency.
