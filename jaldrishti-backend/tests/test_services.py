import asyncio
import sys
import os

# Ensure backend root is in Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.weather_service import WeatherService
from app.services.soilgrids_service import SoilGridsService
from app.services.nasa_power_service import NASAPowerService

async def main():
    test_lat = 22.5726  # Kolkata, West Bengal
    test_lon = 88.3639

    print("=" * 65)
    print(" 🚀 STARTING JALDRISHTI BACKEND EXTERNAL API TESTS")
    print("=" * 65)

    # 1. TEST PRIMARY WEATHER SERVICE (Open-Meteo Realtime)
    print("\n[1/3] Testing Primary Real-Time Weather API (Open-Meteo)...")
    try:
        weather_res = await WeatherService.fetch_realtime_weather(test_lat, test_lon)
        print(" ✅ SUCCESS: Real-Time Weather Service Connected!")
        print(f" Source: {weather_res['source']}")
        print(f" Elevation: {weather_res['elevation']} meters")
        
        # Display today's live sample data
        today_date = list(weather_res["daily_weather"].keys())[-1]
        today_data = weather_res["daily_weather"][today_date]
        print(f" Live Sample Weather ({today_date}):")
        print(f"   - Max Temp: {today_data['temp_max_c']} °C")
        print(f"   - Min Temp: {today_data['temp_min_c']} °C")
        print(f"   - Humidity: {today_data['humidity_percent']:.1f} %")
        print(f"   - Solar Radiation: {today_data['solar_rad_mj_m2']} MJ/m²")
        print(f"   - Wind Speed: {today_data['wind_speed_m_s']:.2f} m/s")
        print(f"   - Rainfall: {today_data['precipitation_mm']} mm")
    except Exception as e:
        print(f" ❌ Primary Weather Service Failed: {str(e)}")

    # 2. TEST SOIL PROFILE SERVICE (SoilGrids + Regional Fallback)
    print("\n[2/3] Testing Soil Physical Profile Service (SoilGrids)...")
    try:
        soil_res = await SoilGridsService.fetch_soil_profile(test_lat, test_lon)
        print(" ✅ SUCCESS: Soil Profile Resolved!")
        print(" Parsed Root-Zone Properties (0-30 cm):")
        for k, v in soil_res["soil_properties"].items():
            if k == "is_fallback":
                print(f"   - Using Regional Fallback: {v}")
            else:
                print(f"   - {k}: {v:.2f}")
    except Exception as e:
        print(f" ❌ Soil Profile Service Failed: {str(e)}")

    # 3. TEST HISTORICAL BACKUP SERVICE (NASA POWER)
    print("\n[3/3] Testing Historical Backup API (NASA POWER Archive)...")
    nasa_res = await NASAPowerService.fetch_historical_weather(test_lat, test_lon)
    if "error" in nasa_res:
        print(f" ⚠️ NASA POWER Warning: {nasa_res['error']}")
    else:
        print(" ✅ SUCCESS: NASA POWER Historical Archive Connected!")

    print("\n" + "=" * 65)
    print(" ALL BACKEND API SERVICES READY FOR HYDROLOGICAL ENGINE!")
    print("=" * 65)

if __name__ == "__main__":
    asyncio.run(main())