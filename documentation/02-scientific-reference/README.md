# Scientific Reference: Hydrology & Agronomic Engine

> **Notice for Readers**: This section is written for engineers, agronomists, and technically literate readers. For a plain-language explanation of these same concepts, see [`01-concepts-and-workflows/`](../01-concepts-and-workflows/).

---

## Overview

JalDrishti operates a sensorless, satellite-driven agricultural hydrology engine designed to calculate crop-specific evapotranspiration, track root-zone soil water depletion day-by-day, evaluate rainfall forecast opportunities, and generate defensible irrigation schedules without in-situ soil moisture probes.

This folder documents the exact mathematical derivations, empirical constants, boundary conditions, and algorithms implemented in the backend hydrology engine as validated and corrected in Phases 1–5 of system remediation.

---

## Documents in this Section & Conceptual Equivalents

| Scientific Reference Document | Primary Focus | Plain-Language Equivalent |
|:------------------------------|:--------------|:--------------------------|
| [`evapotranspiration-and-eto.md`](evapotranspiration-and-eto.md) | Full FAO-56 Penman-Monteith derivation, psychrometric calculations, Stefan-Boltzmann net radiation, and logarithmic wind height reduction. | [`01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md`](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md) |
| [`crop-coefficient-and-growth-stages.md`](crop-coefficient-and-growth-stages.md) | Dynamic crop coefficient interpolation $K_c(t)$, late-season linear decay, root depth expansion $Z_r(t)$, and boundary state handling (`NOT_YET_SOWN`, `HARVEST_OVERDUE`). | [`01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md`](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md) |
| [`soil-water-balance-model.md`](soil-water-balance-model.md) | Persistent daily root-zone mass balance step ($D_i$), pedotransfer functions for soil retention ($\theta_{FC}, \theta_{WP}, TAW, RAW$), and database state persistence. | [`01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md`](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md) |
| [`rain-hold-and-roi-formulas.md`](rain-hold-and-roi-formulas.md) | Smart Rain Hold threshold evaluation ($3.0\text{ mm}/24\text{h}$, $5.0\text{ mm}/48\text{h}$, $4.0\text{ mm}$ today), idempotent skipped-runs accounting, and regional economic ROI derivations. | [`01-concepts-and-workflows/rain-hold-and-savings-explained.md`](../01-concepts-and-workflows/rain-hold-and-savings-explained.md) |
| [`known-scientific-limitations.md`](known-scientific-limitations.md) | Transparent documentation of coordinate binning (~5.5 km grid), lack of physical sensor ground-truthing, static rain thresholds, and satellite outage fallback risks. | [`00-start-here/what-is-jaldrishti.md`](../00-start-here/what-is-jaldrishti.md) |

---

## Core Source Code Directory

All implementations documented in this section reside in:
- Penman-Monteith Reference Evapotranspiration: [`app/engine/penman_monteith.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py)
- Soil Moisture & Water Balance Engine: [`app/engine/water_bucket_model.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py)
- Physical, Agronomic & Economic Constants: [`app/core/constants.py`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py)
- Recommendation & ROI Execution Layer: [`app/api/v1/endpoints/irrigation.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py)
