import math
from datetime import date
from typing import Optional


class PenmanMonteithEngine:
    """
    Implements the full FAO-56 Penman-Monteith equation (FAO Paper 56, Chapter 4)
    to calculate daily Reference Evapotranspiration (ETo) in mm/day.
    """

    @staticmethod
    def calculate_daily_eto(
        temp_max: float,
        temp_min: float,
        humidity_mean: float,
        solar_rad_mj: float,
        wind_speed_2m: float,
        elevation_m: float = 12.0,
        latitude_deg: float = 22.5726,
        day_of_year: Optional[int] = None
    ) -> float:
        """
        Calculates ETo (mm/day) using full FAO-56 formulation including
        Stefan-Boltzmann Net Longwave Radiation (R_nl) and clear-sky radiation (R_so).

        Parameters:
        - temp_max: Daily maximum temperature (°C)
        - temp_min: Daily minimum temperature (°C)
        - humidity_mean: Mean daily relative humidity (%)
        - solar_rad_mj: Solar radiation (MJ/m²/day)
        - wind_speed_2m: Wind speed measured or converted to 2m height (m/s)
        - elevation_m: Elevation above sea level (m)
        - latitude_deg: Latitude of the farm location (degrees)
        - day_of_year: Day of the year (1-365). Defaults to current date if None.
        """
        if day_of_year is None:
            day_of_year = date.today().timetuple().tm_yday

        # 1. Mean Temperature (°C)
        temp_mean = (temp_max + temp_min) / 2.0

        # 2. Atmospheric Pressure (P) in kPa (FAO-56 Eq. 7)
        P = 101.3 * ((293.0 - 0.0065 * elevation_m) / 293.0) ** 5.26

        # 3. Psychrometric Constant (gamma) in kPa/°C (FAO-56 Eq. 8)
        gamma = 0.000665 * P

        # 4. Slope of Saturation Vapor Pressure Curve (delta) in kPa/°C (FAO-56 Eq. 13)
        delta = (4098.0 * (0.6108 * math.exp((17.27 * temp_mean) / (temp_mean + 237.3)))) / ((temp_mean + 237.3) ** 2)

        # 5. Saturation Vapor Pressure (e_s) in kPa (FAO-56 Eq. 12)
        e_temp_max = 0.6108 * math.exp((17.27 * temp_max) / (temp_max + 237.3))
        e_temp_min = 0.6108 * math.exp((17.27 * temp_min) / (temp_min + 237.3))
        e_s = (e_temp_max + e_temp_min) / 2.0

        # 6. Actual Vapor Pressure (e_a) in kPa derived from Relative Humidity (FAO-56 Eq. 17)
        e_a = (humidity_mean / 100.0) * e_s

        # 7. Net Shortwave Radiation R_ns (FAO-56 Eq. 38, Albedo alpha = 0.23 for reference grass)
        R_ns = 0.77 * solar_rad_mj

        # 8. Extraterrestrial Radiation R_a (FAO-56 Eq. 21) & Clear-Sky Radiation R_so (FAO-56 Eq. 37)
        phi = math.radians(latitude_deg)
        dr = 1.0 + 0.033 * math.cos(2.0 * math.pi * day_of_year / 365.0)
        solar_dec = 0.409 * math.sin((2.0 * math.pi * day_of_year / 365.0) - 1.39)
        ws = math.acos(max(-1.0, min(1.0, -math.tan(phi) * math.tan(solar_dec))))
        R_a = (24.0 * 60.0 / math.pi) * 0.0820 * dr * (
            ws * math.sin(phi) * math.sin(solar_dec) + math.cos(phi) * math.cos(solar_dec) * math.sin(ws)
        )
        R_so = (0.75 + 2e-5 * elevation_m) * R_a

        # Relative Solar Radiation R_s / R_so
        rs_rso = max(0.3, min(1.0, solar_rad_mj / R_so)) if R_so > 0 else 0.7

        # 9. Net Longwave Radiation R_nl (FAO-56 Eq. 39)
        sigma = 4.903e-9 # Stefan-Boltzmann constant MJ K^-4 m^-2 day^-1
        t_max_k4 = (temp_max + 273.16) ** 4
        t_min_k4 = (temp_min + 273.16) ** 4
        R_nl = sigma * ((t_max_k4 + t_min_k4) / 2.0) * (0.34 - 0.14 * math.sqrt(e_a)) * (1.35 * rs_rso - 0.35)

        # Net Radiation R_n
        R_n = R_ns - R_nl

        # 10. Soil Heat Flux (G) - assumed 0 for daily operational timestep
        G = 0.0

        # 11. FAO-56 Penman-Monteith Equation (FAO-56 Eq. 6)
        numerator = 0.408 * delta * (R_n - G) + gamma * (900.0 / (temp_mean + 273.0)) * wind_speed_2m * (e_s - e_a)
        denominator = delta + gamma * (1.0 + 0.34 * wind_speed_2m)

        e_to = numerator / denominator

        # Ensure ETo is non-negative
        return max(0.0, round(e_to, 2))