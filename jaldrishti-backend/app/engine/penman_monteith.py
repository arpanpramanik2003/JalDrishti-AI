import math

class PenmanMonteithEngine:
    """
    Implements the FAO-56 Penman-Monteith equation to calculate daily
    Reference Evapotranspiration (ETo) in mm/day.
    """

    @staticmethod
    def calculate_daily_eto(
        temp_max: float,
        temp_min: float,
        humidity_mean: float,
        solar_rad_mj: float,
        wind_speed_2m: float,
        elevation_m: float = 12.0,
        latitude_deg: float = 22.5726
    ) -> float:
        """
        Calculates ETo (mm/day) using FAO-56 formulation.
        
        Parameters:
        - temp_max: Daily maximum temperature (°C)
        - temp_min: Daily minimum temperature (°C)
        - humidity_mean: Mean daily relative humidity (%)
        - solar_rad_mj: Solar radiation (MJ/m²/day)
        - wind_speed_2m: Wind speed measured or converted to 2m height (m/s)
        - elevation_m: Elevation above sea level (m)
        - latitude_deg: Latitude of the farm location (degrees)
        """
        # 1. Mean Temperature
        temp_mean = (temp_max + temp_min) / 2.0

        # 2. Atmospheric Pressure (P) in kPa
        P = 101.3 * ((293.0 - 0.0065 * elevation_m) / 293.0) ** 5.26

        # 3. Psychrometric Constant (gamma) in kPa/°C
        gamma = 0.000665 * P

        # 4. Slope of Saturation Vapor Pressure Curve (delta) in kPa/°C
        delta = (4098.0 * (0.6108 * math.exp((17.27 * temp_mean) / (temp_mean + 237.3)))) / ((temp_mean + 237.3) ** 2)

        # 5. Saturation Vapor Pressure (e_s) in kPa
        e_temp_max = 0.6108 * math.exp((17.27 * temp_max) / (temp_max + 237.3))
        e_temp_min = 0.6108 * math.exp((17.27 * temp_min) / (temp_min + 237.3))
        e_s = (e_temp_max + e_temp_min) / 2.0

        # 6. Actual Vapor Pressure (e_a) in kPa derived from Relative Humidity
        e_a = (humidity_mean / 100.0) * e_s

        # 7. Net Radiation (R_n) Estimation (assumed ~ 77% of solar radiation R_s minus net longwave)
        # Simplified net solar radiation R_ns = 0.77 * R_s
        R_ns = 0.77 * solar_rad_mj
        # R_nl net longwave radiation approximation (simplified for daily operational models)
        R_nl = 0.1 * solar_rad_mj
        R_n = R_ns - R_nl

        # 8. Soil Heat Flux (G) - assumed 0 for daily calculations
        G = 0.0

        # 9. FAO-56 Penman-Monteith Equation
        numerator = 0.408 * delta * (R_n - G) + gamma * (900.0 / (temp_mean + 273.0)) * wind_speed_2m * (e_s - e_a)
        denominator = delta + gamma * (1.0 + 0.34 * wind_speed_2m)

        e_to = numerator / denominator

        # Ensure ETo is non-negative
        return max(0.0, round(e_to, 2))