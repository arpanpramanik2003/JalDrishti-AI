import os
import json
import logging
from typing import Optional

logger = logging.getLogger("jaldrishti.firebase")

_firebase_initialized = False

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
except ImportError:
    firebase_admin = None
    credentials = None
    messaging = None


class FirebaseService:
    """
    Firebase Admin SDK service for dispatching high-priority push notifications to registered farmer devices.
    """

    @classmethod
    def initialize(cls):
        global _firebase_initialized
        if _firebase_initialized or firebase_admin is None:
            return

        service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "firebase_service_account.json")
        service_account_json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

        try:
            if service_account_json_str:
                cred_dict = json.loads(service_account_json_str)
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
                _firebase_initialized = True
                logger.info("[Firebase] Admin SDK initialized successfully via environment variable.")
            elif os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                _firebase_initialized = True
                logger.info(f"[Firebase] Admin SDK initialized successfully via file '{service_account_path}'.")
            else:
                logger.warning(
                    "[Firebase] Service account JSON not found. "
                    "Push notifications will run in dry-run/simulation mode until service account JSON is added."
                )
        except Exception as e:
            logger.error(f"[Firebase] Failed to initialize Firebase Admin SDK: {e}")

    @classmethod
    def send_push_notification(
        cls,
        fcm_token: str,
        title: str,
        body: str,
        data_payload: Optional[dict] = None
    ) -> bool:
        """
        Sends a native FCM push notification to a targeted device token.
        """
        cls.initialize()

        if not fcm_token:
            logger.warning("[Firebase] Skipping push: FCM token is empty.")
            return False

        if not _firebase_initialized or messaging is None:
            logger.info(f"[Firebase Simulation] PUSH -> Token: {fcm_token[:15]}... | Title: '{title}' | Body: '{body}'")
            return True

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data_payload or {"screen": "pest_advisory"},
                token=fcm_token,
            )
            response = messaging.send(message)
            logger.info(f"[Firebase] Push notification sent successfully! Message ID: {response}")
            return True
        except Exception as e:
            logger.error(f"[Firebase] Error sending push notification to token {fcm_token[:15]}...: {e}")
            return False
