# Database Reference & Schema Models

> **Notice for Readers**: This section is written for database administrators, backend developers, and data engineers. For a plain-language explanation of how data persists across the farmer's journey, see [End-to-End Farmer Journey](../01-concepts-and-workflows/end-to-end-farmer-journey.md).

---

## Overview

JalDrishti uses an operational relational database schema managed via SQLAlchemy ORM models. The database persists farmer credentials, field plot agronomic parameters, logged irrigation pumping events, persistent root-zone depletion states, regional economic tariffs, and chat history.

This section provides an audited reference of every model, field type, nullability constraint, foreign key relationship, and index in the current database schema after the Phase 1–5 fixes.

---

## Documents in this Section & Conceptual Equivalents

| Database Document | Primary Focus | Plain-Language Equivalent |
|:------------------|:--------------|:--------------------------|
| [`entity-relationship-diagram.md`](entity-relationship-diagram.md) | Corrected Mermaid Entity-Relationship Diagram (ERD) capturing all 9 active SQLAlchemy models, foreign key relationships, and cardinalities. | [`01-concepts-and-workflows/end-to-end-farmer-journey.md`](../01-concepts-and-workflows/end-to-end-farmer-journey.md) |
| [`table-by-table-reference.md`](table-by-table-reference.md) | Field-by-field reference for every table (`users`, `user_profiles`, `password_resets`, `farm_plots`, `irrigation_logs`, `soil_depletion_state`, `regional_tariffs`, `chat_conversations`, `chat_messages`). | [`01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md`](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md) |

---

## Source Model Directory

All models documented in this section reside in:
- Farmer Accounts & Profiles: [`app/models/user.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py)
- Plots, Irrigation Logs & Depletion State: [`app/models/farm_plot.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py)
- Regional Energy & Emissions Tariffs: [`app/models/regional_tariff.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/regional_tariff.py)
- JalSathi AI Chat Sessions: [`app/models/chat_history.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/chat_history.py)
- Legacy Embeddings Table: [`app/models/document_embedding.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/document_embedding.py)
