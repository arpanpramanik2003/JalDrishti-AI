from typing import List, Dict, Any

class PestDiseaseEngine:
    """
    Comprehensive ICAR Package of Practices (PoP) & FAO Agronomic Rule Engine.
    Evaluates real-time satellite weather telemetry against micro-climate risk triggers.
    """
    PEST_DISEASE_RULES: Dict[str, List[Dict[str, Any]]] = {
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
                "organic_treatment": "Install Pheromone traps @ 5/acre and release Trichogramma japonicum parasitoid @ 20,000/acre.",
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
        "maize": [
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
        ],
        "banana": [
            {
                "id": "sigatoka_leaf_spot",
                "name": "Sigatoka Leaf Spot (Mycosphaerella musicola)",
                "category": "Fungal Disease",
                "min_humidity": 80.0,
                "min_temp": 23.0,
                "max_temp": 32.0,
                "severity": "HIGH",
                "symptoms": "Small pale yellow spots expanding into dark brown elliptical streaks with yellow halos.",
                "chemical_treatment": "Propiconazole 25 EC @ 1 mL/L OR Carbendazim 50 WP @ 1 g/L mixed with mineral oil.",
                "organic_treatment": "Spray Pseudomonas fluorescens @ 10g/L or Neem oil 1% with sticking agent.",
                "preventive_tip": "Remove infected lower leaves and improve field drainage during monsoon."
            }
        ],
        "cotton": [
            {
                "id": "pink_bollworm",
                "name": "Pink Bollworm (Pectinophora gossypiella)",
                "category": "Insect Pest",
                "min_humidity": 60.0,
                "min_temp": 24.0,
                "max_temp": 36.0,
                "severity": "CRITICAL",
                "symptoms": "Rosetted flowers, bored holes in bolls with lint staining.",
                "chemical_treatment": "Profenofos 50 EC @ 2 mL/L OR Chlorantraniliprole 18.5 SC @ 0.3 mL/L.",
                "organic_treatment": "Install Pheromone traps @ 8/acre; spray Bacillus thuringiensis (Bt) @ 2g/L.",
                "preventive_tip": "Destroy crop residues after harvest to prevent diapause."
            }
        ],
        "chilli": [
            {
                "id": "chilli_anthracnose",
                "name": "Anthracnose / Fruit Rot (Colletotrichum capsici)",
                "category": "Fungal Disease",
                "min_humidity": 75.0,
                "min_temp": 22.0,
                "max_temp": 32.0,
                "severity": "HIGH",
                "symptoms": "Circular sunken spots on ripe fruits with black concentric rings.",
                "chemical_treatment": "Azoxystrobin 23% SC @ 1 mL/L OR Copper Oxychloride @ 3 g/L.",
                "organic_treatment": "Foliar spray of Trichoderma viride @ 5g/L or Garlic extract 5%.",
                "preventive_tip": "Use disease-free certified seeds and treat with Thiram before sowing."
            }
        ],
        "eggplant": [
            {
                "id": "brinjal_shoot_borer",
                "name": "Shoot and Fruit Borer (Leucinodes orbonalis)",
                "category": "Insect Pest",
                "min_humidity": 65.0,
                "min_temp": 25.0,
                "max_temp": 35.0,
                "severity": "CRITICAL",
                "symptoms": "Wilting shoots in early growth, bored holes with excreta in developing fruits.",
                "chemical_treatment": "Emamectin Benzoate 5% SG @ 0.4 g/L OR Cyantraniliprole 10.26 OD @ 1.8 mL/L.",
                "organic_treatment": "Release Trichogramma chilonis @ 50,000/acre; erect light traps.",
                "preventive_tip": "Clip and destroy infested shoots weekly."
            }
        ],
        "tomato": [
            {
                "id": "tomato_early_blight",
                "name": "Early Blight (Alternaria solani)",
                "category": "Fungal Disease",
                "min_humidity": 75.0,
                "min_temp": 20.0,
                "max_temp": 30.0,
                "severity": "HIGH",
                "symptoms": "Concentric target-board ring spots on older leaves leading to defoliation.",
                "chemical_treatment": "Mancozeb 75 WP @ 2.5 g/L OR Difenoconazole 25 EC @ 0.5 mL/L.",
                "organic_treatment": "Spray Neem oil 5 mL/L or Copper Hydroxide 53.8% WP @ 2 g/L.",
                "preventive_tip": "Mulch soil around plants to prevent fungal spores from splashing up."
            }
        ],
        "sugarcane": [
            {
                "id": "red_rot_sugarcane",
                "name": "Red Rot (Colletotrichum falcatum)",
                "category": "Fungal Disease",
                "min_humidity": 80.0,
                "min_temp": 25.0,
                "max_temp": 34.0,
                "severity": "CRITICAL",
                "symptoms": "Reddening of internal stalk tissue with transverse white patches and alcoholic odor.",
                "chemical_treatment": "Set treatment: Carbendazim 50 WP @ 2 g/L for 15 mins before planting.",
                "organic_treatment": "Soil application of Trichoderma harzianum @ 2.5 kg/acre with vermicompost.",
                "preventive_tip": "Plant red-rot resistant varieties like Co 0238 or Co 86032."
            }
        ],
        "onion": [
            {
                "id": "purple_blotch_onion",
                "name": "Purple Blotch (Alternaria porri)",
                "category": "Fungal Disease",
                "min_humidity": 80.0,
                "min_temp": 20.0,
                "max_temp": 30.0,
                "severity": "HIGH",
                "symptoms": "Purple-centered oval lesions on leaves turning brown and girdling the leaf.",
                "chemical_treatment": "Tebuconazole 25.9 EC @ 1.5 mL/L OR Mancozeb 75 WP @ 2.5 g/L.",
                "organic_treatment": "Foliar spray of Pseudomonas fluorescens @ 10g/L.",
                "preventive_tip": "Avoid overhead sprinkler irrigation late in the evening."
            }
        ],
        "groundnut": [
            {
                "id": "tikka_leaf_spot",
                "name": "Tikka Leaf Spot (Cercospora arachidicola)",
                "category": "Fungal Disease",
                "min_humidity": 75.0,
                "min_temp": 22.0,
                "max_temp": 31.0,
                "severity": "HIGH",
                "symptoms": "Dark brown circular spots surrounded by bright yellow halos on leaves.",
                "chemical_treatment": "Tebuconazole 50% + Trifloxystrobin 25% WG @ 0.7 g/L OR Hexaconazole 5 EC @ 2 mL/L.",
                "organic_treatment": "Spray Panchagavya 3% or Neem seed kernel extract (NSKE 5%).",
                "preventive_tip": "Crop rotation with non-leguminous cereals like sorghum or maize."
            }
        ],
        "cucumber": [
            {
                "id": "powdery_mildew_cucumber",
                "name": "Powdery Mildew (Erysiphe cichoracearum)",
                "category": "Fungal Disease",
                "min_humidity": 65.0,
                "min_temp": 20.0,
                "max_temp": 32.0,
                "severity": "HIGH",
                "symptoms": "White powdery talc-like growth covering upper leaf surfaces.",
                "chemical_treatment": "Dinocap 48 EC @ 1 mL/L OR Wettable Sulphur 80 WP @ 3 g/L.",
                "organic_treatment": "Spray Milk + Baking soda solution (10% milk + 0.5% sodium bicarbonate).",
                "preventive_tip": "Ensure adequate sunlight penetration and vine spacing."
            }
        ],
        "black_gram": [
            {
                "id": "yellow_mosaic_urad",
                "name": "Mungbean Yellow Mosaic Virus (MYMV)",
                "category": "Viral Disease (Whitefly-transmitted)",
                "min_humidity": 60.0,
                "min_temp": 26.0,
                "max_temp": 36.0,
                "severity": "CRITICAL",
                "symptoms": "Alternating green and yellow irregular patches on trifoliate leaves.",
                "chemical_treatment": "Vector control: Imidacloprid 17.8 SL @ 0.5 mL/L OR Thiamethoxam 25 WG @ 0.3 g/L.",
                "organic_treatment": "Install Yellow Sticky Traps @ 10/acre; spray Neem oil (10,000 ppm) @ 3 mL/L.",
                "preventive_tip": "Sow YMV resistant varieties like Pant Urad 31 or Vamban 8."
            }
        ],
        "cauliflower": [
            {
                "id": "black_rot_cauliflower",
                "name": "Black Rot (Xanthomonas campestris)",
                "category": "Bacterial Disease",
                "min_humidity": 80.0,
                "min_temp": 24.0,
                "max_temp": 32.0,
                "severity": "HIGH",
                "symptoms": "V-shaped yellow lesions starting from leaf margins, blackened veins.",
                "chemical_treatment": "Streptocycline @ 0.1 g/L + Copper Oxychloride 50 WP @ 2.5 g/L.",
                "organic_treatment": "Seed soak in hot water at 50°C for 30 minutes before sowing.",
                "preventive_tip": "Avoid field operations when foliage is wet."
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
        # Alias matching
        crop_key = crop_id.lower().replace('-', '_').replace(' ', '_')
        if crop_key == "maize_corn":
            crop_key = "maize"
        elif crop_key == "green_gram":
            crop_key = "black_gram"
        elif crop_key == "pulses":
            crop_key = "black_gram"
        elif crop_key == "chickpea":
            crop_key = "black_gram"
        elif crop_key == "turmeric" or crop_key == "ginger":
            crop_key = "chilli"
        elif crop_key == "papaya" or crop_key == "watermelon":
            crop_key = "cucumber"

        # Fallback to general high-humidity fungal/insect rule if custom key not explicitly matched
        rules = PestDiseaseEngine.PEST_DISEASE_RULES.get(crop_key)
        
        if not rules:
            # Smart Universal Agronomic Rule for any other crop
            rules = [
                {
                    "id": "high_humidity_fungal_risk",
                    "name": "Fungal Leaf Spot & Blight Risk",
                    "category": "Fungal Spore Dispersal",
                    "min_humidity": 75.0,
                    "min_temp": 18.0,
                    "max_temp": 34.0,
                    "severity": "HIGH",
                    "symptoms": "Water-soaked foliar lesions and wilting under high canopy humidity.",
                    "chemical_treatment": "Prophylactic: Mancozeb 75 WP @ 2.5 g/L OR Copper Oxychloride @ 3 g/L.",
                    "organic_treatment": "Spray Trichoderma viride @ 5g/L or Neem oil (10,000 ppm) @ 3 mL/L.",
                    "preventive_tip": "Ensure adequate field aeration and avoid water stagnation around roots."
                }
            ]

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
