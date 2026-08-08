import logging
import asyncio
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.models.farm_plot import FarmPlot
from app.models.user import User
from app.engine.pest_disease_engine import PestDiseaseEngine
from app.services.weather_service import WeatherService
from app.services.firebase_service import FirebaseService

logger = logging.getLogger("jaldrishti.cron")


async def run_daily_weather_and_pest_batch_job(db: Session = None) -> dict:
    """
    Automated Background Cron Task:
    1. Scans all active farm plots across all users in the system.
    2. Clusters and fetches live daily satellite weather parameters.
    3. Evaluates FAO-56 and ICAR pest/disease risk models.
    4. Dispatches high-priority FCM push notifications to registered farmer devices.
    """
    close_session_at_end = False
    if db is None:
        db = SessionLocal()
        close_session_at_end = True

    try:
        plots = db.query(FarmPlot).join(User).all()
        logger.info(f"[Cron Scheduler] Starting daily automated weather & pest batch check for {len(plots)} farm plots...")

        total_scanned = len(plots)
        notifications_sent = 0

        # Cluster by geo-location grid to prevent duplicate external weather calls
        geo_clusters = {}
        for p in plots:
            key = (round(p.latitude, 2), round(p.longitude, 2))
            if key not in geo_clusters:
                geo_clusters[key] = []
            geo_clusters[key].append(p)

        for (lat, lon), cluster_plots in geo_clusters.items():
            try:
                weather_res = await WeatherService.fetch_realtime_weather(lat, lon)
                daily_weather = weather_res.get("daily_weather", {})

                if daily_weather:
                    today_key = list(daily_weather.keys())[0]
                    w = daily_weather[today_key]
                    max_t = w.get("temp_max_c", 32.0)
                    min_t = w.get("temp_min_c", 24.0)
                    hum = w.get("humidity_percent", 85.0)
                    rain = w.get("precipitation_mm", 0.0)
                else:
                    max_t, min_t, hum, rain = 32.0, 24.0, 85.0, 0.0

                for plot in cluster_plots:
                    user = plot.user
                    if not user or not user.fcm_token:
                        continue

                    advisories = PestDiseaseEngine.evaluate_pest_risk(
                        crop_id=plot.crop_id,
                        max_temp_c=max_t,
                        min_temp_c=min_t,
                        humidity_percent=hum,
                        precipitation_mm=rain
                    )

                    for adv in advisories:
                        risk = adv.get("risk_level", "").upper()
                        if risk in ["CRITICAL", "HIGH"]:
                            disease_name = adv.get("disease_name", "Pest Warning")
                            crop_name = plot.crop_id.replaceAll("_", " ").title() if hasattr(plot.crop_id, "replaceAll") else plot.crop_id.replace("_", " ").title()
                            treatment = adv.get("chemical_treatment", "Apply recommended treatment.")

                            title = f"⚠️ {disease_name} ({risk})"
                            body = f"High risk in {plot.name} ({crop_name}). {treatment}"

                            sent = FirebaseService.send_push_notification(
                                fcm_token=user.fcm_token,
                                title=title,
                                body=body,
                                data_payload={
                                    "screen": "pest_advisory",
                                    "plot_id": str(plot.id),
                                    "crop_id": plot.crop_id
                                }
                            )
                            if sent:
                                notifications_sent += 1

            except Exception as e:
                logger.error(f"[Cron Scheduler] Error processing weather cluster at ({lat}, {lon}): {e}")

        logger.info(f"[Cron Scheduler] Batch completed! Scanned {total_scanned} plots. Dispatched {notifications_sent} notifications.")
        return {
            "status": "success",
            "plots_scanned": total_scanned,
            "notifications_dispatched": notifications_sent
        }
    finally:
        if close_session_at_end:
            db.close()
