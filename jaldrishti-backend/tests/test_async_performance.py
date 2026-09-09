import sys
import os
import asyncio
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.cache_service import CacheService
from app.services.automated_advisory_cron import run_daily_weather_and_pest_batch_job
from app.models.farm_plot import FarmPlot
from app.models.user import User

@pytest.mark.anyio
async def test_async_cache_service_contract():
    """Validates [F-15]: CacheService methods are true coroutines supporting async/await."""
    test_key = "test:async_perf_key"
    test_val = {"status": "ok", "latency_ms": 12.5}

    # 1. Set async
    set_res = await CacheService.set(test_key, test_val, expire_seconds=60)
    assert set_res is True

    # 2. Get async
    retrieved = await CacheService.get(test_key)
    assert retrieved == test_val

    # 3. Delete async
    del_res = await CacheService.delete(test_key)
    assert del_res is True

    # 4. Confirm deleted
    retrieved_after_del = await CacheService.get(test_key)
    assert retrieved_after_del is None

@pytest.mark.anyio
async def test_automated_advisory_batch_bounded_concurrency():
    """Validates [5.3]: Automated advisory cron uses bounded concurrency with Semaphore(20)."""
    # Create mock user and mock farm plots
    mock_user = MagicMock(spec=User)
    mock_user.fcm_token = "fake_fcm_token_123"

    mock_plots = []
    for i in range(25):
        p = MagicMock(spec=FarmPlot)
        p.id = i + 1
        p.name = f"Plot {i + 1}"
        p.latitude = 23.23
        p.longitude = 87.86
        p.crop_id = "paddy_rice"
        p.user = mock_user
        mock_plots.append(p)

    mock_db = MagicMock()
    mock_db.query.return_value.join.return_value.all.return_value = mock_plots

    import time
    import threading
    concurrent_calls = 0
    max_concurrent_calls = 0
    lock = threading.Lock()

    def mock_send_push(*args, **kwargs):
        nonlocal concurrent_calls, max_concurrent_calls
        with lock:
            concurrent_calls += 1
            if concurrent_calls > max_concurrent_calls:
                max_concurrent_calls = concurrent_calls
        time.sleep(0.01) # Simulate network latency
        with lock:
            concurrent_calls -= 1
        return True

    with patch("app.services.weather_service.WeatherService.fetch_realtime_weather", new_callable=AsyncMock) as mock_weather, \
         patch("app.engine.pest_disease_engine.PestDiseaseEngine.evaluate_pest_risk") as mock_pest, \
         patch("app.services.firebase_service.FirebaseService.send_push_notification", side_effect=mock_send_push):

        mock_weather.return_value = {
            "daily_weather": {
                "2026-09-09": {
                    "temp_max_c": 33.0,
                    "temp_min_c": 25.0,
                    "humidity_percent": 90.0,
                    "precipitation_mm": 5.0
                }
            }
        }
        mock_pest.return_value = [
            {
                "disease_name": "Bacterial Blight",
                "risk_level": "CRITICAL",
                "chemical_treatment": "Copper Hydroxide spray"
            }
        ]

        result = await run_daily_weather_and_pest_batch_job(db=mock_db)

        assert result["status"] == "success"
        assert result["plots_scanned"] == 25
        assert result["notifications_dispatched"] == 25
        # Verify concurrency was capped at <= 20
        assert max_concurrent_calls <= 20
        assert max_concurrent_calls > 1  # Verified concurrent execution
