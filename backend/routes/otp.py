from fastapi import APIRouter
from pydantic import BaseModel
from twilio.rest import Client
from dotenv import load_dotenv
import os

load_dotenv()

router = APIRouter()

ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
VERIFY_SERVICE_SID = os.getenv("TWILIO_VERIFY_SERVICE_SID")

client = Client(ACCOUNT_SID, AUTH_TOKEN)


class PhoneRequest(BaseModel):
    phone: str


class VerifyRequest(BaseModel):
    phone: str
    otp: str


@router.post("/send-otp")
def send_otp(data: PhoneRequest):

    try:
        verification = client.verify.v2.services(
            VERIFY_SERVICE_SID
        ).verifications.create(
            to=data.phone,
            channel="sms"
        )

        return {
            "success": True,
            "status": verification.status
        }

    except Exception as e:
        return {
            "success": False,
            "message": str(e)
        }


@router.post("/verify-otp")
def verify_otp(data: VerifyRequest):

    try:

        check = client.verify.v2.services(
            VERIFY_SERVICE_SID
        ).verification_checks.create(
            to=data.phone,
            code=data.otp
        )

        if check.status == "approved":
            return {
                "verified": True
            }

        return {
            "verified": False
        }

    except Exception as e:
        return {
            "verified": False,
            "message": str(e)
        }