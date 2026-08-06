from fastapi import FastAPI
from routes.otp import router as otp_router
from routes.audio import router as audio_router
from routes.face import router as face_router

app = FastAPI(title="SentryPay Backend")

app.include_router(
    otp_router,
    prefix="/api"
)

app.include_router(
    audio_router,
    prefix="/api/audio"
)

app.include_router(
    face_router,
    prefix="/api"
)

@app.api_route("/", methods=["GET", "HEAD"])
def home():
    return {
        "message": "SentryPay Backend Running"
    }