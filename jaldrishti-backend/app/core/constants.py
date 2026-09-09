"""
JalDrishti Core Engineering & Agronomic Constants.

This module centralizes all physical, meteorological, economic, and agronomic
constants used across the FAO-56 Penman-Monteith hydrology engine, soil water
balance bucket model, and regional economic ROI tracker.

References:
- FAO Irrigation and Drainage Paper No. 56 (Allen, Pereira, Raes, Smith, 1998)
- Central Electricity Authority (CEA) India CO2 Baseline Database v19 (2024)
- Indian Council of Agricultural Research (ICAR) Water Management Guidelines
"""

from typing import Final

# ==============================================================================
# FAO-56 PENMAN-MONTEITH PHYSICAL & METEOROLOGICAL CONSTANTS
# ==============================================================================

# FAO-56 Section 3 / Chapter 4: Stefan-Boltzmann constant (MJ K^-4 m^-2 day^-1)
STEFAN_BOLTZMANN_CONSTANT: Final[float] = 4.903e-9

# FAO-56 Eq. 38: Canopy reflection coefficient (albedo) for hypothetical reference grass
ALBEDO_REFERENCE_GRASS: Final[float] = 0.23

# FAO-56 Eq. 38: Net shortwave radiation coefficient (1 - alpha)
NET_SHORTWAVE_RADIATION_COEFFICIENT: Final[float] = 1.0 - ALBEDO_REFERENCE_GRASS  # 0.77

# FAO-56 Eq. 8: Coefficient for psychrometric constant gamma = 0.000665 * P (kPa/°C)
PSYCHROMETRIC_COEFFICIENT: Final[float] = 0.000665

# FAO-56 Chapter 3: Soil heat flux (G) for daily operational timestep is negligible (MJ/m²/day)
SOIL_HEAT_FLUX_DAILY_G: Final[float] = 0.0

# FAO-56 Eq. 47: Wind speed logarithmic profile reduction constants from height z to 2m
# Formula: u2 = uz * (4.87 / ln(67.8 * z - 5.42))
WIND_HEIGHT_NUMERATOR: Final[float] = 4.87
WIND_HEIGHT_ROUGHNESS_FACTOR: Final[float] = 67.8
WIND_HEIGHT_ZERO_PLANE_OFFSET: Final[float] = 5.42
DEFAULT_WIND_MEASUREMENT_HEIGHT_M: Final[float] = 10.0

# Fallback extraterrestrial relative solar radiation ratio (Rs / Rso) when Rso is invalid
FALLBACK_RS_RSO_RATIO: Final[float] = 0.70

# Default solar radiation fallback for coastal/monsoon regions when API is missing shortwave (MJ/m²/day)
FALLBACK_SOLAR_RADIATION_MJ_M2: Final[float] = 21.0


# ==============================================================================
# SOIL HYDROLOGY & WATER BALANCE CONSTANTS
# ==============================================================================

# FAO-56 Chapter 8: Effective rainfall coefficient (P_eff = P * 0.80)
# Accounts for surface runoff, canopy interception, and deep percolation losses
EFFECTIVE_RAINFALL_COEFFICIENT: Final[float] = 0.80

# Default pedotransfer characteristics (Gangetic Alluvium - clay loam profile)
DEFAULT_SOIL_CLAY_PERCENT: Final[float] = 30.0
DEFAULT_SOIL_SAND_PERCENT: Final[float] = 25.0
DEFAULT_SOIL_BULK_DENSITY_KG_DM3: Final[float] = 1.35
DEFAULT_SOIL_SOC_G_KG: Final[float] = 10.0

# Volumetric conversion: 1 mm water depth across 1 m² area equals exactly 1.0 Liter
WATER_DEPTH_MM_TO_L_PER_M2: Final[float] = 1.0

# Area conversion: 1 international acre equals exactly 4046.8564224 square meters
ACRE_TO_SQUARE_METERS: Final[float] = 4046.86


# ==============================================================================
# CROP PHENOLOGY & LIFECYCLE BOUNDARY CONSTANTS
# ==============================================================================

# Maximum days allowed past cumulative lifecycle (init + dev + mid + late) before
# the crop state transitions to HARVEST_OVERDUE and pump recommendations halt.
POST_HARVEST_MAX_OVERDUE_DAYS: Final[int] = 15

# Default initial root depth fraction relative to maximum crop root depth
INITIAL_ROOT_DEPTH_FRACTION: Final[float] = 0.30
MINIMUM_EFFECTIVE_ROOT_DEPTH_M: Final[float] = 0.15


# ==============================================================================
# SMART RAIN HOLD THRESHOLDS & OVERRIDES
# ==============================================================================

# 24-hour upcoming forecast precipitation threshold to trigger Smart Rain Hold (mm)
RAIN_HOLD_24H_THRESHOLD_MM: Final[float] = 3.0

# 48-hour cumulative forecast precipitation threshold to trigger Smart Rain Hold (mm)
RAIN_HOLD_48H_THRESHOLD_MM: Final[float] = 5.0

# Current-day active rainfall threshold to trigger Smart Rain Hold (mm)
RAIN_HOLD_TODAY_PRECIP_THRESHOLD_MM: Final[float] = 4.0

# Minimum pump hours credited as avoided pumping during a Rain Hold event (hours)
MINIMUM_HOURS_SAVED_RAIN_HOLD: Final[float] = 1.5


# ==============================================================================
# REGIONAL ECONOMIC TARIFF & EMISSIONS BENCHMARKS
# ==============================================================================

# Default agricultural electricity tariff benchmark in India (INR per pump operating hour)
DEFAULT_ELECTRIC_TARIFF_INR_HR: Final[float] = 80.0

# Default agricultural diesel operating cost benchmark (INR per operating hour)
DEFAULT_DIESEL_TARIFF_INR_HR: Final[float] = 145.0

# National grid emission factor for agricultural pumping (kg CO2 per electric pump hour)
DEFAULT_ELECTRIC_CO2_KG_HR: Final[float] = 2.68

# Carbon emission factor for agricultural diesel pumpsets (kg CO2 per diesel pump hour)
DEFAULT_DIESEL_CO2_KG_HR: Final[float] = 3.42

# Fraction of water wasted by conventional un-metered flood irrigation vs precision application
TRADITIONAL_FLOOD_WASTE_FRACTION: Final[float] = 0.45

# Minimum water depth savings credited per skipped or optimized session (mm)
MINIMUM_WATER_SAVED_PER_SESSION_MM: Final[float] = 4.0

# Default water depth savings credited per skipped session when gross water is 0 (mm)
FALLBACK_WATER_SAVED_PER_SESSION_MM: Final[float] = 12.0

# Default pump hardware parameters
DEFAULT_PUMP_FLOW_LPS: Final[float] = 5.0
DEFAULT_PUMP_HP: Final[float] = 5.0
DEFAULT_PLOT_AREA_ACRES: Final[float] = 2.5
