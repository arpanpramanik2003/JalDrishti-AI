# JalDrishti REST API Reference

> **Notice for Readers**: This section is written for mobile developers, backend integrators, and API test automation engineers. For a plain-language explanation of how the farmer interacts with these features, see [`01-concepts-and-workflows/`](../01-concepts-and-workflows/).

---

## Overview

The JalDrishti backend exposes a RESTful API powered by **FastAPI** with **Pydantic v2** validation. Following the comprehensive security audit and contract synchronization in Phases 2 and 3, all operational endpoints are strictly authenticated via JSON Web Tokens (JWT) or administrative headers.

This reference documents the complete inventory of 24 application endpoints and infrastructure health routes verified across the codebase.

---

## Endpoint Catalog by Domain

| Category Document | Focus & Endpoints Covered | Primary Client Consumer |
|:------------------|:--------------------------|:------------------------|
| [`authentication-and-security.md`](authentication-and-security.md) | User registration, login, JWT rotation, logout with Redis token blacklisting, phone-based OTP password recovery, profile retrieval/update, and FCM device registration (11 endpoints). | `AuthProvider`, `OnboardingSurveyScreen`, `SettingsScreen` |
| [`farm-plots-and-crops.md`](farm-plots-and-crops.md) | CRUD lifecycle for farm plots, coordinate mapping, setting primary plot, and public agricultural crop catalog (6 endpoints). | `FarmPlotProvider`, `AddEditFarmPlotScreen`, `HomeDashboardScreen` |
| [`irrigation-and-recommendations.md`](irrigation-and-recommendations.md) | Dynamic FAO-56 irrigation recommendation engine, manual water application logging, and historical irrigation logs (3 endpoints). | `IrrigationProvider`, `HomeDashboardScreen`, `AnalyticsScreen` |
| [`chatbot-and-advisory.md`](chatbot-and-advisory.md) | JalSathi AI conversational RAG queries with session memory, and authenticated pest & disease risk evaluation (2 endpoints). | `ChatProvider`, `ChatScreen`, `PestAdvisoryScreen` |
| [`admin-and-internal-endpoints.md`](admin-and-internal-endpoints.md) | Admin regional electricity/diesel tariff management, manual batch cron execution, and root/health probes (7 endpoints). | Admin dashboard, cron runners, infrastructure load balancers |

---

## Global Authentication Standards

1. **User Authentication (`get_current_user`)**:
   - Header: `Authorization: Bearer <access_token>`
   - Format: HS256-signed JWT containing user ID in subject claim (`sub`).
   - Rejection: Unauthenticated requests return HTTP `401 Unauthorized`.
   - Token Lifecycle: Access tokens expire after 24 hours. The client uses `POST /api/v1/auth/refresh` to obtain renewed tokens seamlessly.

2. **Administrative Authorization (`require_admin_api_key`)**:
   - Header: `X-Admin-API-Key: <ADMIN_API_KEY>`
   - Rejection: Invalid or missing keys return HTTP `403 Forbidden`.
   - Consumer Notice: Admin endpoints are strictly internal/administrative and are **intentionally not called by the mobile client**.

---

## Base URLs

- **Production Target**: `https://jaldrishti-ai.onrender.com/api/v1`
- **Local Development**: `http://localhost:8000/api/v1`
