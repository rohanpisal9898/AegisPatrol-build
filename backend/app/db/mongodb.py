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
        # Compound unique index on phone + role
        # Allows same phone to exist in separate roles if needed, while preventing duplicates in same role
        await users_collection.create_index(
            [("phone", 1), ("role", 1)],
            unique=True,
            name="unique_phone_role_idx"
        )
        logger.info("MongoDB connected successfully and unique index (phone + role) ensured.")
    except Exception as e:
        logger.error("Error creating MongoDB indexes: %s", e)

async def close_mongo_connection():
    """Closes MongoDB connection."""
    if db_instance.client:
        db_instance.client.close()
        logger.info("MongoDB connection closed.")
