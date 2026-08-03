import asyncio
import sys
import os

# Ensure backend root is in Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.weather_service import WeatherService
from app.engine.penman_monteith import PenmanMonteithEngine

async def main():
    test_lat = 22.5726
    test_lon = 88.3639

    print("=" * 65)
    print(" 🚀 TESTING PENMAN-MONTEITH EVAPOTRANSPIRATION ENGINE")
    print("=" * 65)

    # 1. Fetch Live Weather Data
    print("\n[1/2] Fetching Live Daily Meteorological Parameters...")
    weather_res = await WeatherService.fetch_realtime_weather(test_lat, test_lon)
    daily_data = weather_res["daily_weather"]

    # 2. Calculate ETo for each day
    print("\n[2/2] Running FAO-56 Penman-Monteith Engine...")
    print(f"{'Date':<12} | {'Max Temp (°C)':<12} | {'Solar Rad (MJ)':<15} | {'ETo (mm/day)':<12}")
    print("-" * 60)

    for date_str, metrics in daily_data.items():
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=metrics["temp_max_c"],
            temp_min=metrics["temp_min_c"],
            humidity_mean=metrics["humidity_percent"],
            solar_rad_mj=metrics["solar_rad_mj_m2"],
            wind_speed_2m=metrics["wind_speed_m_s"],
            elevation_m=weather_res["elevation"],
            latitude_deg=test_lat
        )
        print(f"{date_str:<12} | {metrics['temp_max_c']:<12.1f} | {metrics['solar_rad_mj_m2']:<15.1f} | {eto:<12.2f}")

    print("\n" + "=" * 65)
    print(" EVAPOTRANSPIRATION ENGINE TEST COMPLETED SUCCESSFULLY!")
    print("=" * 65)

if __name__ == "__main__":
    asyncio.run(main())