# System Limitations, Open Questions & Engineering Roadmap

> **Plain-Language Summary for Farmers, Stakeholders & Investors**:  
> JalDrishti has undergone six phases of rigorous engineering remediation to fix broken formulas, eliminate fake numbers, secure accounts, and make its AI assistant genuinely useful. However, like all satellite-based technologies operating without physical in-ground hardware, it has real physical limits. It cannot "see" individual soil meters, its rain forecasts can fail during satellite internet outages, and parts of its mobile screens are still in English. We believe honesty about what a tool *cannot* do is just as important as celebrating what it can. This section is the single, unfiltered catalog of every known limitation, open developer question, and historical bug fix.

---

## Overview of this Section

This directory consolidates the engineering audit findings, known scientific approximations, open DevOps questions, and remediation history across the entire JalDrishti project into one transparent reference.

---

## Documents in this Section

| Document | Focus & Content | Target Audience |
|:---------|:----------------|:----------------|
| [`known-limitations-consolidated.md`](known-limitations-consolidated.md) | The master catalog of all active scientific, architectural, and mobile limitations. Each item is strictly classified as **RESOLVED**, **PARTIALLY MITIGATED**, or **UNRESOLVED**, highlighting the critical satellite outage fallback safety risk. | Agronomists, system architects, safety auditors, product leads |
| [`open-questions-for-the-developer.md`](open-questions-for-the-developer.md) | A consolidated, de-duplicated list of unresolved engineering decisions across hydrology, deployment/DevOps, localization, and AI/RAG, with direct citations to original remediation phases. | Software engineers, DevOps leads, open-source contributors |
| [`remediation-history.md`](remediation-history.md) | A definitive timeline and matrix tracking every audit finding (`F-01` through `F-23`, plus numbered findings `5.2`, `5.3`, `6.3`, `6.4`, `FLAG-P4-01`) from discovery to final status. | Engineering leadership, auditors, technical evaluators |
| [`PHASE7D_NOTES.md`](PHASE7D_NOTES.md) | Documentation close-out build notes, repository integrity verification, and explicit safety assessment of satellite outage fallback behavior. | Engineering internal |
