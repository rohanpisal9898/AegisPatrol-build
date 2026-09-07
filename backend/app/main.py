import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.routers import civilian_auth, police_auth, users, journeys, police, alerts
from app.services.gemini_service import gemini_service

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s"
)
logger = logging.getLogger("aegispatrol")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Connect to DB and ensure indexes
    await connect_to_mongo()
    yield
    # Shutdown: Close DB connections
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
        "gemini_ready": gemini_service.is_configured
    }
