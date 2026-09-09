# End-to-End Farmer Journey

This document describes the end-to-end journey of an Indian smallholder farmer using JalDrishti, based on the **actual, operational workflows** verified across Phases 1 through 6 of remediation.

---

## 📱 The Five Stages of the Farmer Journey

```text
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   STAGE 1    │     │   STAGE 2    │     │   STAGE 3    │     │   STAGE 4    │     │   STAGE 5    │
│ Registration │ ──> │ Plot Setup & │ ──> │ Daily Home   │ ──> │ Logging Pump │ ──> │ JalSathi AI  │
│    & Login   │     │ Soil Profiling│    │  Dashboard   │     │     Runs     │     │ Voice Advice │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

---

### Stage 1: Registration & Secure Login

1. **Opening the App**: The farmer downloads the lightweight Flutter application (`jaldrishti_mobile`).
2. **Account Creation**: The farmer registers using their mobile phone number, an optional username, and a password.
3. **SMS Verification & Password Recovery**: If a farmer forgets their password, a fast OTP workflow verifies their identity via the integrated SMS gateway (Fast2SMS / Twilio) and allows secure password reset without requiring an email address.
4. **JWT Security & Refresh Interceptor**: Once logged in, the app securely stores a JSON Web Token (JWT) in device hardware storage. If the access token expires while the farmer is in the field, a background 401 interceptor automatically refreshes the session seamlessly.

---

### Stage 2: Plot Setup & Soil Profiling

1. **Plot Registration**: The farmer taps **"Add Plot"** and enters:
   - **Plot Name**: e.g., *"North Paddy Field"*.
   - **Crop Type**: Selected from regional crops (Paddy Rice, Wheat, Potato, Maize, Mustard).
   - **Sowing Date**: The date seeds were planted or nursery seedlings were transplanted.
   - **Plot Area**: Area in acres (e.g., *2.5 acres*).
   - **Pump Specifications**: Pump horsepower (HP) and flow rate (e.g., *5.0 HP tube-well*).
   - **Field Location**: Pinned via phone GPS or district selection (e.g., *Burdwan, West Bengal*).
2. **Instant Satellite Profiling**: In the background, the server contacts the **ISRIC SoilGrids API** for the plot's coordinates. It downloads clay and sand percentages, determines the soil texture class (e.g., *Clay Loam*), and calculates the baseline Field Capacity and Wilting Point. This data is cached on Redis for 30 days.

---

### Stage 3: Daily Home Dashboard Advisory

Every morning, the farmer opens the app and immediately sees the **Dynamic Advisory Card**:
- **Weather Overview**: Today's forecasted maximum temperature, relative humidity, solar radiation, and rainfall probability.
- **Hydration Gauge**: A clear visual indicator showing whether soil moisture is:
  - 🟢 **Optimal** (Roots comfortable, no watering needed).
  - 🟡 **Depletion Approaching** (Prepare to irrigate in 1–2 days).
  - 🔴 **Stress Alert: Irrigate Today** (Soil has dried past safe bounds).
- **Exact Pump Runtime**: If watering is required, the app shows the exact duration to run the pump (e.g., *"Run 5 HP pump for 2 hours 15 minutes"*).
- **Smart Rain Hold Banner**: If rain is imminent, a blue rain banner informs the farmer: *"Rain Expected (~18 mm tomorrow). Keep pump off to save fuel."*

---

### Stage 4: Logging Pump Runs & Tracking Real ROI

1. **Flipping the Switch**: After the farmer finishes running their pump, they tap **"Log Irrigation"**.
2. **Recording Runtime**: They enter the actual time run (e.g., *2.0 hours*) or water volume.
3. **Instant Accounting**:
   - The backend converts the runtime into millimeters of water added.
   - The water is immediately credited to the plot's soil bucket balance.
   - The depletion gauge on the dashboard resets back to full.
4. **Viewing Precision ROI**: Under the **Analytics** tab, the farmer sees real, honest cumulative savings:
   - Total cubic meters (or kL) of water saved compared to traditional flood routines.
   - Total money saved in electricity or diesel tariffs (calculated using official state tariffs).
   - Total carbon footprint reduction (kg of avoided $CO_2$).
   - *If the farmer has just started and has no logs, the app displays a calm zero-state: "0 kL saved — start logging irrigation to track your savings."*

---

### Stage 5: JalSathi AI Voice & Agronomy Chat

When faced with crop pests, leaf discoloration, or fertilizer questions:
1. **Vernacular Voice Input**: The farmer taps the microphone button and speaks their question in **Bengali**, **Hindi**, or **English**:
   - *Sample (Bengali)*: "ধান গাছে বাদামী শোষক পোকা হলে কী ওষুধ দেব?" (*"What medicine should I apply for Brown Plant Hopper in rice?"*)
2. **Smart Preliminary Translation**: The server rapidly translates the query into concise English agronomic terms to search verified regional agricultural university guides (ICAR Package of Practices).
3. **Strictly Grounded Retrieval**: The assistant retrieves verified chemical and organic treatments directly from the document collection.
4. **Safe, Multi-lingual Audio Reply**:
   - The answer is generated in natural Bengali or Hindi script with precise dosages (e.g., *Imidacloprid 17.8% SL @ 50 ml/acre*).
   - If a requested chemical is not verified in official documents, the assistant explicitly warns the farmer to consult their local Krishi Vigyan Kendra (KVK) officer rather than guessing.
   - The farmer can tap **"Listen 🔊"** to have the advisory read aloud via native text-to-speech.

---

## 🛠️ For Technical Readers

The workflows in this journey correspond to verified frontend and backend components:
- **Plot Management**: Supported by endpoints in [`app/api/v1/endpoints/farm_plots.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/farm_plots.py) and Dart screens in [`jaldrishti_mobile/lib/screens/`](file:///d:/jaldrishti/jaldrishti_mobile/lib/screens/).
- **Irrigation Calculation & Logging**: Handled via `POST /api/v1/irrigation/calculate` and `POST /api/v1/irrigation/log` in [`app/api/v1/endpoints/irrigation.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py).
- **RAG Voice Chat**: Handled via `POST /api/v1/chatbot/query` in [`app/api/v1/endpoints/chatbot.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/chatbot.py) and [`app/services/rag_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py).
