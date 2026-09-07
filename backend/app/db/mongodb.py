import logging
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.core.config import settings

logger = logging.getLogger("aegispatrol.db")

class MongoDB:
    client: AsyncIOMotorClient = None
    db: AsyncIOMotorDatabase = None

db_instance = MongoDB()

async def get_database() -> AsyncIOMotorDatabase:
    """Returns active MongoDB database instance."""
    return db_instance.db

async def connect_to_mongo():
    """Establishes connection to MongoDB and creates necessary indexes."""
    logger.info("Connecting to MongoDB at: %s", settings.MONGO_URI.split("@")[-1] if "@" in settings.MONGO_URI else settings.MONGO_URI)
    db_instance.client = AsyncIOMotorClient(settings.MONGO_URI)
    db_instance.db = db_instance.client[settings.DATABASE_NAME]
    
    # Initialize indexes
    try:
        users_collection = db_instance.db["users"]
        await users_collection.create_index(
            [("phone", 1), ("role", 1)],
            unique=True,
            name="unique_phone_role_idx"
        )

        journeys_collection = db_instance.db["journeys"]
        await journeys_collection.create_index([("user_id", 1)], name="journey_user_id_idx")
        await journeys_collection.create_index([("created_at", -1)], name="journey_created_at_idx")

        alerts_collection = db_instance.db["alerts"]
        await alerts_collection.create_index([("user_id", 1)], name="alert_user_id_idx")
        await alerts_collection.create_index([("journey_id", 1)], name="alert_journey_id_idx")

        police_collection = db_instance.db["police_stations"]
        await police_collection.create_index([("location", "2dsphere")], name="police_location_2dsphere_idx")

        # Preload verified police stations if empty
        from app.services.police_service import police_service
        await police_service.seed_police_stations_if_empty(db_instance.db)

        logger.info("MongoDB connected successfully and indexes ensured (users, journeys, alerts, police 2dsphere).")
    except Exception as e:
        logger.error("Error creating MongoDB indexes: %s", e)

async def close_mongo_connection():
    """Closes MongoDB connection."""
    if db_instance.client:
        db_instance.client.close()
        logger.info("MongoDB connection closed.")
