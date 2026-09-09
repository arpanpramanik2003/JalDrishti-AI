# Mobile Application Reference: Flutter Client Architecture

> **Notice for Readers**: This section is written for mobile software engineers, Flutter developers, and QA test engineers. For a plain-language explanation of the farmer's experience across these screens, see [End-to-End Farmer Journey](../01-concepts-and-workflows/end-to-end-farmer-journey.md).

---

## Overview

The JalDrishti mobile client (`jaldrishti_mobile/`) is built using **Flutter 3.x** and **Dart 3.x**, targeting Android and iOS devices. The application is architected around reactive state management via **Provider**, offline persistence via **Hive**, localized error handling with a centralized HTTP 401 interceptor, and multilingual voice interaction.

Following Phase 3 (contract alignment) and Phase 6 (mobile functional completeness), all broken modals, fake fallback statistics, and dead localization delegates have been resolved.

---

## Documents in this Section & Conceptual Equivalents

| Mobile Document | Focus & Scope | Conceptual Equivalent |
|:----------------|:--------------|:----------------------|
| [`screen-by-screen-reference.md`](screen-by-screen-reference.md) | Comprehensive reference for all 10 major screens (auth, dashboard, plot management, analytics with 5 tabs, pest advisory, chat, settings), API calls made, backing providers, and post-Phase-6 functional status. | [`01-concepts-and-workflows/end-to-end-farmer-journey.md`](../01-concepts-and-workflows/end-to-end-farmer-journey.md) |
| [`state-management-and-providers.md`](state-management-and-providers.md) | Deep dive into the 6 Providers (`AuthProvider`, `FarmPlotProvider`, `IrrigationProvider`, `ChatProvider`, `NotificationProvider`, `ThemeProvider`), state lifecycles, and the Phase 3 401 interceptor. | [`03-system-architecture/high-level-architecture.md`](../03-system-architecture/high-level-architecture.md) |
| [`offline-and-sync-behavior.md`](offline-and-sync-behavior.md) | Hive local database caching, `OfflineSyncManager` queued actions (plots, logs), sync replay mechanics, and the `FLAG-P4-01` date serialization finding. | [`01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md`](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md) |
| [`localization-status.md`](localization-status.md) | ARB translation key coverage (14/14 keys translated in `app_en.arb`, `app_bn.arb`, `app_hi.arb`), honest audit of remaining hardcoded English strings, and guide for future contributors. | [`01-concepts-and-workflows/jalsathi-ai-explained.md`](../01-concepts-and-workflows/jalsathi-ai-explained.md) |

---

## Core Codebase Structure

```
jaldrishti_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/       # API endpoints, asset paths, theme colors
│   │   ├── services/        # ApiService (with 401 interceptor), OfflineCacheService, OfflineSyncManager
│   │   └── theme/           # AppTheme, typography, color palettes
│   ├── l10n/                # app_en.arb, app_bn.arb, app_hi.arb
│   ├── models/              # User, FarmPlot, IrrigationResponse, ChatMessage
│   ├── providers/           # Auth, FarmPlot, Irrigation, Chat, Notification, Theme
│   ├── screens/             # UI views & analytics tabs
│   └── widgets/             # Reusable UI cards, gauges, dials, buttons
```
