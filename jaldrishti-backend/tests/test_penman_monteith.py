import pytest
from app.engine.penman_monteith import PenmanMonteithEngine


class TestPenmanMonteithEngine:
    """
    FAO-56 Penman-Monteith Evapotranspiration Unit & Edge Tests.
    """

    def test_hot_summer_day_reference_baseline(self):
        """
        Reference Case 1: Hot Summer Day Baseline
        Inputs: Temp 40°C/28°C, RH 45%, Solar 25 MJ/m²/day, Wind 3.5 m/s, Lat 23.23°
        Expected ETo Baseline: 9.34 mm/day (± 0.05 mm/day tolerance)
        """
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=40.0,
            temp_min=28.0,
            humidity_mean=45.0,
            solar_rad_mj=25.0,
            wind_speed_2m=3.5,
            elevation_m=12.0,
            latitude_deg=23.23
        )
        assert eto == pytest.approx(9.34, abs=0.05)

    def test_cool_winter_day_reference_baseline(self):
        """
        Reference Case 2: Cool Winter Day Baseline
        Inputs: Temp 20°C/10°C, RH 70%, Solar 12 MJ/m²/day, Wind 1.2 m/s, Lat 23.23°
        Expected ETo Baseline: 2.42 mm/day (± 0.05 mm/day tolerance)
        """
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=20.0,
            temp_min=10.0,
            humidity_mean=70.0,
            solar_rad_mj=12.0,
            wind_speed_2m=1.2,
            elevation_m=12.0,
            latitude_deg=23.23
        )
        assert eto == pytest.approx(2.42, abs=0.05)

    def test_zero_wind_speed_aerodynamic_stability(self):
        """
        Edge Case: Zero wind speed (u2 = 0 m/s).
        Engine must not throw DivideByZeroError or return NaN.
        """
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=30.0,
            temp_min=20.0,
            humidity_mean=60.0,
            solar_rad_mj=18.0,
            wind_speed_2m=0.0,
            elevation_m=12.0,
            latitude_deg=23.23
        )
        assert eto >= 0.0
        assert not pytest.approx(eto) == float('nan')

    def test_100_percent_humidity_vpd_zero(self):
        """
        Edge Case: 100% relative humidity -> Vapor Pressure Deficit (VPD) = 0.
        ETo should be non-negative and driven strictly by solar radiation.
        """
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=25.0,
            temp_min=25.0,
            humidity_mean=100.0,
            solar_rad_mj=15.0,
            wind_speed_2m=2.0,
            elevation_m=12.0,
            latitude_deg=23.23
        )
        assert eto >= 0.0

    def test_extreme_high_temperature(self):
        """
        Edge Case: Extreme Heatwave conditions (55°C).
        Verify numeric stability without float overflow.
        """
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=55.0,
            temp_min=38.0,
            humidity_mean=20.0,
            solar_rad_mj=30.0,
            wind_speed_2m=4.5,
            elevation_m=12.0,
            latitude_deg=23.23
        )
        assert eto > 10.0
