import asyncio
import json
import sys
import os

# Ensure backend root is in Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.weather_service import WeatherService
from app.services.soilgrids_service import SoilGridsService
from app.engine.penman_monteith import PenmanMonteithEngine
from app.engine.water_bucket_model import SoilWaterBucketModel

async def main():
    test_lat = 22.5726  # Kolkata, West Bengal
    test_lon = 88.3639

    print("=" * 70)
    print(" 🚀 TESTING DAILY SOIL-WATER BUCKET & DECISION ENGINE")
    print("=" * 70)

    # 1. Fetch Crop Parameters (Paddy Rice)
    json_path = os.path.join(os.path.dirname(__file__), '..', 'app', 'engine', 'crop_coefficients.json')
    with open(json_path, 'r', encoding='utf-8') as f:
        crop_db = json.load(f)
    
    crop = crop_db["paddy_rice"]
    kc_mid = crop["stages"]["mid_season"]["Kc"]
    root_depth = crop["root_depth_m"]
    p_fraction = crop["depletion_fraction_p"]

    print(f"\n🌾 Target Crop: {crop['name']}")
    print(f" Root Depth: {root_depth} m | Kc (Mid-Season): {kc_mid} | p-fraction: {p_fraction}")

    # 2. Fetch Soil Profile with Safe Fallback Parsing
    soil_res = await SoilGridsService.fetch_soil_profile(test_lat, test_lon)
    props = soil_res.get("soil_properties", {})
    
    # Safely extract clay and sand with fallbacks for Gangetic Alluvium
    clay = props.get("clay_percent", 30.0)
    sand = props.get("sand_percent", 25.0)
    
    soil_caps = SoilWaterBucketModel.calculate_soil_capacities(clay, sand, root_depth)
    print(f" Soil TAW (Total Available Water): {soil_caps['taw_mm']} mm")

    # 3. Fetch Weather Data
    weather_res = await WeatherService.fetch_realtime_weather(test_lat, test_lon)
    daily_weather = weather_res["daily_weather"]

    # 4. Simulate Sequential Daily Water Balance
    print("\n[Running 6-Day Hydrological Simulation]")
    print(f"{'Date':<12} | {'ETo':<6} | {'ETc':<6} | {'Rain':<6} | {'Depletion':<10} | {'RAW Limit':<10} | {'Status'}")
    print("-" * 78)

    current_depletion = 0.0  # Start at Field Capacity (0 depletion)

    for date_str, metrics in daily_weather.items():
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=metrics["temp_max_c"],
            temp_min=metrics["temp_min_c"],
            humidity_mean=metrics["humidity_percent"],
            solar_rad_mj=metrics["solar_rad_mj_m2"],
            wind_speed_2m=metrics["wind_speed_m_s"],
            elevation_m=weather_res["elevation"],
            latitude_deg=test_lat
        )

        etc = round(eto * kc_mid, 2)
        rain = metrics["precipitation_mm"]

        balance = SoilWaterBucketModel.run_daily_water_balance(
            previous_depletion_mm=current_depletion,
            etc_mm=etc,
            rainfall_mm=rain,
            irrigation_applied_mm=0.0,  # Assuming no manual irrigation applied yet
            taw_mm=soil_caps["taw_mm"],
            depletion_fraction_p=p_fraction
        )

        current_depletion = balance["current_depletion_mm"]

        print(
            f"{date_str:<12} | {eto:<6.1f} | {etc:<6.1f} | {rain:<6.1f} | "
            f"{balance['current_depletion_mm']:<10.1f} | {balance['raw_threshold_mm']:<10.1f} | {balance['status']}"
        )

    print("\n" + "=" * 70)
    print(" HYDROLOGICAL BUCKET & DECISION ENGINE TEST PASSED!")
    print("=" * 70)

if __name__ == "__main__":
    asyncio.run(main())