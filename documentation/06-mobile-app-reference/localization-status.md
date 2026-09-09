# Localization Status & Multi-Language Readiness

> **Audience**: Mobile developers, UI/UX designers, and open-source contributors.  
> **Source Directory**: [`jaldrishti_mobile/lib/l10n/`](file:///d:/jaldrishti/jaldrishti_mobile/lib/l10n/)  
> **Supported Locales**: English (`en`), Bengali (`bn`), Hindi (`hi`)

---

## 1. Executive Summary & Honest Framing

Following Phase 6 remediation ([`PHASE6_CHANGELOG.md`](file:///d:/jaldrishti/PHASE6_CHANGELOG.md)), the foundational infrastructure for localization is fully connected:
1. `AppLocalizations.delegate` and `AppLocalizations.supportedLocales` are wired into `MaterialApp` in [`main.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/main.dart).
2. Locale state is dynamically managed and persisted via `ThemeProvider.locale` and `SharedPreferences`.
3. **100% of defined ARB keys (14 of 14) are fully translated** into both Bengali and Hindi.

However, in the mobile settings language dialog, Bengali and Hindi remain tagged with `"Coming Soon"`. This document honestly explains why, provides a screen-by-screen audit of hardcoded English strings, and outlines the precise roadmap for completing full app localization.

---

## 2. ARB Translation File Audit

| File Path | Language / Script | Total Defined Keys | Translated vs Base | Coverage % | Status |
|:----------|:------------------|:-------------------|:-------------------|:-----------|:-------|
| `lib/l10n/app_en.arb` | English (Base) | 14 | 14 / 14 | **100.0%** | Complete |
| `lib/l10n/app_bn.arb` | Bengali (বাংলা) | 14 | 14 / 14 | **100.0%** | Complete |
| `lib/l10n/app_hi.arb` | Hindi (हिंदी) | 14 | 14 / 14 | **100.0%** | Complete |

### Currently Translated Keys (14 Keys)
`appTitle`, `welcomeTitle`, `welcomeSubtitle`, `loginButton`, `registerButton`, `phoneNumberLabel`, `passwordLabel`, `dashboardTitle`, `irrigationAdvisoryTitle`, `waterNow`, `rainHold`, `soilMoistureOptimal`, `analyticsTitle`, `settingsTitle`.

---

## 3. Screen-by-Screen Localization Audit

While the 14 foundational navigation headers are translated, the mobile repository contains **53 Dart files** where detailed forms, error messages, and telemetry cards still use hardcoded English strings:

| Screen / Component | File Path | `AppLocalizations` Usage | Hardcoded Strings Remaining | Readiness Status |
|:-------------------|:----------|:-------------------------|:----------------------------|:-----------------|
| **Main Navigation** | `main_navigation_screen.dart` | Yes (Tab labels) | None | **100% Ready** |
| **Login Screen** | `login_screen.dart` | Partial (Buttons) | Form validation errors, "Forgot Password?", "Don't have an account?" | ~60% Hardcoded |
| **Register Screen** | `register_screen.dart` | Partial (Buttons) | Form validation errors, password strength requirements | ~65% Hardcoded |
| **Forgot Password** | `forgot_password_screen.dart` | None | OTP instruction text, resend countdown, password match alerts | **100% Hardcoded** |
| **Onboarding Survey**| `onboarding_survey_screen.dart`| None | Crop choices, farming experience radio buttons, land area hints | **100% Hardcoded** |
| **Home Dashboard** | `home_dashboard_screen.dart` | Partial (Advisories) | Weather parameter labels, pump hours breakdown, quick action modal | ~70% Hardcoded |
| **Add/Edit Plot** | `add_edit_farm_plot_screen.dart`| None | Hardware flow rates, soil type preset names, GPS button text | **100% Hardcoded** |
| **Smart Insights Tab**| `smart_insights_tab.dart` | None | ROI savings headers, carbon explanation text, empty-state banner | **100% Hardcoded** |
| **Water Balance Tab**| `water_balance_tab.dart` | None | Depletion gauge legends, Field Capacity descriptions | **100% Hardcoded** |
| **Pest Advisory** | `pest_advisory_screen.dart` | None | Disease names, symptom descriptions, chemical treatment tips | **100% Hardcoded** |
| **Settings Screen** | `settings_screen.dart` | Partial (Header) | Update name modal, notification toggle titles, language labels | ~75% Hardcoded |
| **Chat Screen** | `chat_screen.dart` | Dynamic | Chat bubbles are dynamically generated in farmer's target script | **100% Dynamic** |

---

## 4. Why "Coming Soon" Was Maintained for UI

If a farmer switches the language to Bengali or Hindi today:
- The bottom navigation bar and primary card titles translate cleanly.
- However, 85% of surrounding text (crop names, telemetry details, dialog bodies, error banners) immediately reverts to English.

This mixed-language experience can confuse rural users. Therefore:
- **JalSathi AI Voice & Chat Assistant**: Operates with **100% native fluency in Bengali and Hindi** because the LLM prompt and speech engines natively generate Indic scripts.
- **Visual Mobile Shell**: Kept as `"Coming Soon"` until the remaining strings are extracted into ARB keys.

---

## 5. Guide for Future Contributors: Adding ARB Keys

To complete multi-screen localization:
1. Open [`lib/l10n/app_en.arb`](file:///d:/jaldrishti/jaldrishti_mobile/lib/l10n/app_en.arb) and add your new string key:
   ```json
   "saveChanges": "Save Changes",
   "@saveChanges": {
     "description": "Button label to commit profile changes"
   }
   ```
2. Add the corresponding Bengali and Hindi translations in `app_bn.arb` and `app_hi.arb`:
   - `app_bn.arb`: `"saveChanges": "পরিবর্তন সংরক্ষণ করুন"`
   - `app_hi.arb`: `"saveChanges": "बदलाव सहेजें"`
3. Run code generation:
   ```bash
   flutter gen-l10n
   ```
4. Replace the hardcoded string in your Dart file:
   ```dart
   // Before: Text("Save Changes")
   // After:
   Text(AppLocalizations.of(context)!.saveChanges)
   ```
