import warnings
warnings.filterwarnings("ignore")

import asyncio
import logging
import datetime
from contextlib import asynccontextmanager
import httpx
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.routers import civilian_auth, police_auth, users, journeys, police, alerts

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s"
)
logger = logging.getLogger("aegispatrol")

# Self-ping keep-alive task reference
_ping_task: asyncio.Task = None

async def _self_ping_worker(target_url: str, interval_seconds: int):
    """
    Background worker that periodically pings the server's /health endpoint
    to prevent Render free tier instances from sleeping due to inactivity.
    """
    # Initial wait before starting pings
    await asyncio.sleep(45)
    ping_endpoint = f"{target_url.rstrip('/')}/health"
    logger.info("Render self-ping keep-alive activated targeting: %s (every %ss)", ping_endpoint, interval_seconds)

    while True:
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(ping_endpoint)
                if response.status_code == 200:
                    logger.debug("Self-ping keep-alive successful: %s", response.status_code)
                else:
                    logger.warning("Self-ping returned status %s", response.status_code)
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.debug("Self-ping pulse note: %s", e)

        await asyncio.sleep(interval_seconds)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global _ping_task
    # Startup: Connect to DB and ensure indexes
    await connect_to_mongo()

    # Determine self-ping target URL for Render or cloud deployments
    target_url = settings.RENDER_EXTERNAL_URL or settings.BACKEND_URL or "http://127.0.0.1:8000"
    if settings.SELF_PING_ENABLED:
        _ping_task = asyncio.create_task(
            _self_ping_worker(target_url, settings.SELF_PING_INTERVAL_SECONDS)
        )

    yield

    # Shutdown: Stop self-ping task and close DB connections
    if _ping_task and not _ping_task.done():
        _ping_task.cancel()
        try:
            await _ping_task
        except asyncio.CancelledError:
            pass
    await close_mongo_connection()

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="AegisPatrol Role-Based Safety Platform Backend API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for Flutter clients (Web, Mobile, Desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom Exception Handlers for consistent API responses: { "success": false, "message": "..." }
@app.exception_handler(StarletteHTTPException)
async def custom_http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "message": exc.detail
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    first_error_msg = "Validation error"
    if errors:
        first_error = errors[0]
        field = " -> ".join(str(loc) for loc in first_error.get("loc", []))
        msg = first_error.get("msg", "Invalid input")
        first_error_msg = f"{msg} ({field})" if field else msg
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "message": first_error_msg
        }
    )

# Routers
app.include_router(civilian_auth.router)
app.include_router(police_auth.router)
app.include_router(users.router)
app.include_router(journeys.router)
app.include_router(police.router)
app.include_router(alerts.router)

@app.get("/")
async def root():
    return {
        "success": True,
        "app": "AegisPatrol Backend API",
        "status": "online",
        "self_ping": "active" if (_ping_task and not _ping_task.done()) else "standby"
    }

@app.get("/health")
@app.get("/ping")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "app": "AegisPatrol"
    }
