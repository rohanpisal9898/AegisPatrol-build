import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
from app.core.security import get_password_hash
from app.services.police_service import VERIFIED_MUMBAI_POLICE_STATIONS
import google.generativeai as genai

async def main():
    print(f"Connecting to MongoDB: {settings.MONGO_URI.split('@')[-1]}")
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.DATABASE_NAME]

    # 1. List collections
    collections = await db.list_collection_names()
    print(f"Existing Collections in '{settings.DATABASE_NAME}': {collections}")

    # 2. Seed verified police stations if empty
    stations_col = db["police_stations"]
    station_count = await stations_col.count_documents({})
    print(f"Police Stations count: {station_count}")
    if station_count == 0:
        await stations_col.insert_many(VERIFIED_MUMBAI_POLICE_STATIONS)
        print(f"Seeded {len(VERIFIED_MUMBAI_POLICE_STATIONS)} verified Mumbai police stations.")

    # 3. Check and seed demo users
    users_col = db["users"]
    user_count = await users_col.count_documents({})
    print(f"Users count: {user_count}")

    demo_users = [
        {
            "name": "Ananya Sharma",
            "phone": "9876543210",
            "password_hash": get_password_hash("password123"),
            "role": "civilian",
            "district": "Mumbai Suburban",
        },
        {
            "name": "Rajesh Patil",
            "phone": "9876543211",
            "password_hash": get_password_hash("password123"),
            "role": "police",
            "district": "Mumbai Suburban",
        },
        # Also alias for 9876543210 for police if requested
        {
            "name": "Inspector Rajesh Patil",
            "phone": "9876543210",
            "password_hash": get_password_hash("password123"),
            "role": "police",
            "district": "Mumbai Suburban",
        }
    ]

    for u in demo_users:
        existing = await users_col.find_one({"phone": u["phone"], "role": u["role"]})
        if not existing:
            await users_col.insert_one(u)
            print(f"Seeded user: {u['name']} ({u['role']}, phone: {u['phone']}, password: password123)")
        else:
            print(f"User already exists: {u['name']} ({u['role']}, phone: {u['phone']})")

    # 4. Check Gemini AI
    print(f"Testing Gemini API Key: {settings.GEMINI_API_KEY[:8]}...{settings.GEMINI_API_KEY[-4:]}")
    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = await asyncio.to_thread(model.generate_content, "Say 'Gemini is online and ready for D.H.A.A.L' in 1 sentence.")
        print(f"Gemini API Response: {response.text.strip()}")
    except Exception as e:
        print(f"Gemini test note: {e}")

    client.close()
    print("MongoDB inspection and seeding complete!")

if __name__ == "__main__":
    asyncio.run(main())
