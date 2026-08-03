from typing import List, Dict, Any

class PestDiseaseEngine:
    PEST_DISEASE_RULES = {
        "paddy_rice": [
            {
                "id": "paddy_blast",
                "name": "Rice Blast (Pyricularia oryzae)",
                "category": "Fungal Disease",
                "min_humidity": 80.0,
                "min_temp": 18.0,
                "max_temp": 28.0,
                "severity": "HIGH",
                "symptoms": "Spindle-shaped brown lesions with grayish centers on leaves and collar neck.",
                "chemical_treatment": "Tricyclazole 75 WP @ 0.6 g/L water (120g/acre) OR Isoprothiolane 40 EC @ 1.5 mL/L.",
                "organic_treatment": "Spray Pseudomonas fluorescens @ 10g/L or Neem Oil (10,000 ppm) @ 3 mL/L.",
                "preventive_tip": "Avoid excess Nitrogen fertilizer application during cloudy, high humidity periods."
            },
            {
                "id": "sheath_blight",
                "name": "Sheath Blight (Rhizoctonia solani)",
                "category": "Fungal Disease",
                "min_humidity": 85.0,
                "min_temp": 28.0,
                "max_temp": 35.0,
                "severity": "CRITICAL",
                "symptoms": "Oval or spotty greenish-gray lesions on leaf sheaths near water line.",
                "chemical_treatment": "Hexaconazole 5 EC @ 2.0 mL/L OR Azoxystrobin 18.2% + Difenoconazole 11.4% SC @ 1 mL/L.",
                "organic_treatment": "Apply Trichoderma viride bio-fungicide @ 2.5 kg/acre mixed with well-rotted FYM.",
                "preventive_tip": "Maintain proper field drainage and avoid dense plant spacing."
            },
            {
                "id": "stem_borer",
                "name": "Yellow Stem Borer (Scirpophaga incertulas)",
                "category": "Insect Pest",
                "min_humidity": 60.0,
                "min_temp": 25.0,
                "max_temp": 36.0,
                "severity": "MEDIUM",
                "symptoms": "Dead hearts in vegetative stage and white heads (empty panicles) in reproductive stage.",
                "chemical_treatment": "Chlorantraniliprole 18.5% SC @ 60 mL/acre OR Cartap Hydrochloride 4G @ 7.5 kg/acre.",
                "organic_treatment": "Install Pheromone traps @ 5/acre and release Trichogramma japonicum egg parasitoid @ 20,000/acre.",
                "preventive_tip": "Clip leaf tips before transplanting to eliminate egg masses."
            }
        ],
        "potato": [
            {
                "id": "late_blight_potato",
                "name": "Late Blight (Phytophthora infestans)",
                "category": "Fungal Blight",
                "min_humidity": 85.0,
                "min_temp": 10.0,
                "max_temp": 22.0,
                "severity": "CRITICAL",
                "symptoms": "Water-soaked dark lesions on leaf margins with white mildew underneath during morning dew.",
                "chemical_treatment": "Prophylactic: Mancozeb 75 WP @ 2.5 g/L. Curative: Cymoxanil 8% + Mancozeb 64% WP @ 3.0 g/L.",
                "organic_treatment": "Copper Oxychloride 50 WP @ 3 g/L or Trichoderma viride foliar spray.",
                "preventive_tip": "Earthing up soil to cover exposed tubers and destroy infected haulms."
            }
        ],
        "wheat": [
            {
                "id": "yellow_rust",
                "name": "Stripe / Yellow Rust (Puccinia striiformis)",
                "category": "Fungal Rust",
                "min_humidity": 75.0,
                "min_temp": 8.0,
                "max_temp": 20.0,
                "severity": "HIGH",
                "symptoms": "Bright yellow pustules arranged in linear stripes along leaf veins.",
                "chemical_treatment": "Propiconazole 25 EC @ 1.0 mL/L (200 mL/acre) OR Tebuconazole 25.9 EC @ 1.5 mL/L.",
                "organic_treatment": "Foliar application of Cow urine (10%) + Sour buttermilk solution.",
                "preventive_tip": "Monitor fields regularly during cold, foggy winter mornings."
            }
        ],
        "mustard": [
            {
                "id": "mustard_aphid",
                "name": "Mustard Aphid (Lipaphis erysimi)",
                "category": "Sucking Pest",
                "min_humidity": 55.0,
                "min_temp": 15.0,
                "max_temp": 26.0,
                "severity": "HIGH",
                "symptoms": "Clusters of small green/black insects sucking sap from inflorescence, curling leaves.",
                "chemical_treatment": "Thiamethoxam 25% WG @ 80 g/acre OR Dimethoate 30% EC @ 1.7 mL/L.",
                "organic_treatment": "Spray Neem seed kernel extract (NSKE 5%) @ 50 mL/L or Azadirachtin 10,000 ppm @ 2 mL/L.",
                "preventive_tip": "Early sowing before October 25 significantly escapes aphid infestation."
            }
        ],
        "maize_corn": [
            {
                "id": "fall_armyworm",
                "name": "Fall Armyworm (Spodoptera frugiperda)",
                "category": "Lepidopteran Pest",
                "min_humidity": 65.0,
                "min_temp": 22.0,
                "max_temp": 34.0,
                "severity": "CRITICAL",
                "symptoms": "Ragged whorl feeding holes, heavy frass (poop) in central leaf funnel.",
                "chemical_treatment": "Emamectin Benzoate 5% SG @ 0.4 g/L OR Spinetoram 11.7% SC @ 0.5 mL/L directed into whorls.",
                "organic_treatment": "Apply Metarhizium anisopliae @ 5g/L or sand + neem cake mixture (9:1) into plant funnels.",
                "preventive_tip": "Deep autumn plowing to expose pupae to predatory birds."
            }
        ]
    }

    @staticmethod
    def evaluate_pest_risk(
        crop_id: str,
        max_temp_c: float,
        min_temp_c: float,
        humidity_percent: float,
        precipitation_mm: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Evaluates real-time micro-climate weather conditions against agronomic pest & disease rules.
        """
        crop_key = crop_id if crop_id in PestDiseaseEngine.PEST_DISEASE_RULES else "paddy_rice"
        rules = PestDiseaseEngine.PEST_DISEASE_RULES.get(crop_key, PestDiseaseEngine.PEST_DISEASE_RULES["paddy_rice"])

        active_advisories = []
        mean_temp = (max_temp_c + min_temp_c) / 2.0

        for r in rules:
            # Check humidity and temperature windows
            temp_match = r["min_temp"] <= mean_temp <= r["max_temp"]
            humidity_match = humidity_percent >= r["min_humidity"]

            if temp_match and humidity_match:
                risk_score = 85.0
                if precipitation_mm > 2.0:
                    risk_score += 10.0
                
                status_level = r["severity"]

                active_advisories.append({
                    "id": r["id"],
                    "disease_name": r["name"],
                    "category": r["category"],
                    "risk_level": status_level,
                    "risk_score": min(risk_score, 99.0),
                    "trigger_weather": f"Humidity {humidity_percent:.0f}% + Temp {mean_temp:.1f}°C",
                    "symptoms": r["symptoms"],
                    "chemical_treatment": r["chemical_treatment"],
                    "organic_treatment": r["organic_treatment"],
                    "preventive_tip": r["preventive_tip"]
                })

        return active_advisories
