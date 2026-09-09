# Offline Architecture and Data Synchronization

> **Audience**: Mobile software engineers and field deployment leads.  
> **Source Modules**:  
> - [`jaldrishti_mobile/lib/core/services/offline_cache_service.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/core/services/offline_cache_service.dart)  
> - [`jaldrishti_mobile/lib/core/services/offline_sync_manager.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/core/services/offline_sync_manager.dart)  
> **Underlying Storage**: `package:hive/hive.dart` (Binary NoSQL key-value store)

---

## 1. Offline Architectural Philosophy

Indian agricultural plots are frequently situated in rural low-bandwidth or zero-connectivity pockets. JalDrishti implements a two-tier offline strategy:
1. **Passive Read Caching (`OfflineCacheService`)**: Serializes latest successful API responses to local Hive storage so the farmer can view existing plots, past irrigation logs, and recent weather advisories without internet access.
2. **Active Operation Queueing (`OfflineSyncManager`)**: Intercepts mutating actions (logging irrigation, adding plots, updating hardware parameters) when the device is disconnected, writes them to a persistent FIFO sync queue, and automatically uploads them when connectivity resumes.

---

## 2. Local Hive Storage Boxes

The application initializes two distinct Hive boxes on startup ([`lib/main.dart:26-27`](file:///d:/jaldrishti/jaldrishti_mobile/lib/main.dart#L26-L27)):

| Hive Box Name | Managing Service | Stored Entities | Eviction Policy |
|:--------------|:-----------------|:----------------|:----------------|
| `jaldrishti_cache` | `OfflineCacheService` | `plots_list`, `irrigation_data`, `notification_feed`, `notification_settings` | Overwritten on every successful network fetch. |
| `jaldrishti_sync_queue` | `OfflineSyncManager` | FIFO queue of mutating operations (`create_plot`, `update_plot`, `delete_plot`, `log_irrigation`) | Deleted sequentially upon confirmed HTTP 200/201 response from backend. |

---

## 3. Online vs. Offline Capability Matrix

| Capability / Workflow | Supported Offline? | Underlying Mechanism |
|:----------------------|:-------------------|:---------------------|
| **View Dashboard & Last Advisory** | **YES** | Loads cached `IrrigationResponse` from Hive `jaldrishti_cache`. Displays offline badge. |
| **View Registered Plots** | **YES** | Loads cached `List<FarmPlotModel>` from Hive. |
| **Log Pump / Irrigation Event** | **YES** | Action is written to `jaldrishti_sync_queue`. Optimistically reduces displayed deficit. Uploads on reconnect. |
| **Add / Edit / Delete Farm Plot** | **YES** | Mutation is written to `jaldrishti_sync_queue`. Changes render locally and sync on reconnect. |
| **View Past Irrigation Logs** | **YES** | Loaded from local Hive log cache. |
| **Re-calculate Live Hydrology Telemetry** | **NO** | Requires live Open-Meteo numerical weather fetch. Fails gracefully to cached metrics. |
| **JalSathi AI Conversational Chat** | **NO** | Requires active Groq Cloud LLM and vector search connection. Shows offline alert. |
| **Live Pest & Disease Risk Evaluation** | **NO** | Requires live satellite temperature and humidity fetch. |

---

## 4. Sync Replay Engine (`syncPendingData`)

When network connectivity is restored (or on application resume), the application invokes `OfflineSyncManager.syncPendingData(authToken)` ([`offline_sync_manager.dart:88-157`](file:///d:/jaldrishti/jaldrishti_mobile/lib/core/services/offline_sync_manager.dart#L88-L157)):

```dart
// Execution Trace:
1. Iterates over all keys in 'jaldrishti_sync_queue'.
2. Inspects item['type']:
   - 'log_irrigation' -> ApiService.logIrrigationEvent(...)
   - 'create_plot'    -> ApiService.createPlot(...)
   - 'update_plot'    -> ApiService.updatePlot(...)
   - 'delete_plot'    -> ApiService.deletePlot(...)
3. If the backend responds successfully (HTTP 200/201):
   - Key is added to keysToDelete.
4. On HTTP 409 Conflict:
   - Operation discarded or flagged to avoid blocking subsequent items.
5. Deletes all successfully uploaded keys from Hive box.
```

---

## 5. Known Open Risk: Date Serialization Format (`FLAG-P4-01`)

During the Phase 3 contract cross-check audit ([`PHASE3_CHANGELOG.md:155`](file:///d:/jaldrishti/PHASE3_CHANGELOG.md#L155)), a potential serialization edge-case was flagged for offline irrigation logs:

> [!WARNING]
> **Open Implementation Finding (`FLAG-P4-01`)**:
> - **Backend Requirement**: The FastAPI backend endpoint `POST /api/v1/irrigation/log` requires `applied_date` formatted as an ISO-8601 calendar string: `"YYYY-MM-DD"` (e.g. `"2026-09-09"`).
> - **Mobile Serialization Check**: In `offline_sync_manager.dart:66`, items record `timestamp: DateTime.now().toIso8601String()`, which includes full time fractions (`"2026-09-09T14:30:00.000Z"`).
> - **Operational Guidance**: While Pydantic v2's `datetime.date` parser successfully coerces ISO-8601 timestamp strings down to date objects, mobile developers should explicitly format offline payloads with `applied_date: DateFormat('yyyy-MM-dd').format(date)` to prevent any timezone-offset date drift during midnight synchronizations.
