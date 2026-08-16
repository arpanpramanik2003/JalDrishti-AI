import asyncio
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.services.automated_advisory_cron import run_daily_weather_and_pest_batch_job

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("jaldrishti.worker")

def start_worker():
    logger.info("Initializing JalDrishti Standalone Background Worker...")
    scheduler = AsyncIOScheduler()
    
    # Schedule automated daily weather & pest evaluation every 12 hours
    scheduler.add_job(
        run_daily_weather_and_pest_batch_job,
        'interval',
        hours=12,
        id="daily_weather_pest_batch_job"
    )
    scheduler.start()
    logger.info("[Worker] Standalone scheduler started! Running job every 12 hours.")

    try:
        asyncio.get_event_loop().run_forever()
    except (KeyboardInterrupt, SystemExit):
        logger.info("[Worker] Shutting down worker process...")
        scheduler.shutdown()

if __name__ == "__main__":
    start_worker()
