from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import urllib.parse
import tldextract
import re

app = FastAPI(
    title="SentryPay Intent Verification AI API",
    description="Cognitive Intent Verification Layer for SentryPay QR Payments",
    version="1.0"
)

# =====================================
# Request & Response Schemas
# =====================================

class RiskEngineResult(BaseModel):
    url: str
    ml_score: int
    rule_score: int
    risk_score: int
    risk_level: str
    reasons: List[str]

class QuestionGenerationResponse(BaseModel):
    questions: List[str]

class VerifyIntentRequest(BaseModel):
    risk_result: RiskEngineResult
    questions: List[str]
    answers: List[str]

class VerifyIntentResponse(BaseModel):
    intent_score: int
    decision: str
    confidence: float
    reason: List[str]


# =====================================
# Helper Utilities
# =====================================

def parse_url_context(url: str) -> Dict[str, Any]:
    """
    Parses a URL (UPI or Web address) and extracts:
    - qr_type: 'UPI' or 'Web'
    - merchant_name: Name of payee/domain
    - payment_context: Description/purpose of payment
    - category: 'banking', 'marketplace', 'prize_scam', or 'general'
    """
    parsed = urllib.parse.urlparse(url)
    scheme = parsed.scheme.lower()
    
    qr_type = "Web Link"
    merchant_name = "Scanned Merchant"
    payment_context = "Purchase / Transfer"
    category = "general"
    bank_name = "your bank"
    
    # 1. Parse UPI deep-links
    if scheme == "upi":
        qr_type = "UPI Payment Deep-link"
        query_params = urllib.parse.parse_qs(parsed.query)
        
        # Payee Name (pn)
        if "pn" in query_params and query_params["pn"]:
            merchant_name = query_params["pn"][0]
        # Fallback to Payee Address (pa)
        elif "pa" in query_params and query_params["pa"]:
            pa = query_params["pa"][0]
            merchant_name = pa.split("@")[0].replace(".", " ").title()
            
        # Transaction Note (tn)
        if "tn" in query_params and query_params["tn"]:
            payment_context = query_params["tn"][0]
            
        # Category classification based on UPI MCC code (mc)
        if "mc" in query_params and query_params["mc"]:
            mcc = query_params["mc"][0]
            if mcc in ["6011", "6012"]:
                category = "banking"
            elif mcc in ["5411", "5311", "5977"]:
                category = "marketplace"
            elif mcc in ["7995", "7996"]:
                category = "prize_scam"
                
    # 2. Parse standard HTTP/HTTPS URLs
    elif scheme in ["http", "https"]:
        qr_type = "Web Link"
        ext = tldextract.extract(url)
        domain = ext.domain
        suffix = ext.suffix
        
        merchant_name = domain.title()
        
        # Look for payment intent or note in URL path/query
        path = parsed.path.lower()
        query = parsed.query.lower()
        if "pay" in path or "pay" in query:
            payment_context = "Web Payment"
        elif "login" in path or "verify" in path:
            payment_context = "Account Action"
            
    # 3. Categorize based on keywords in URL
    url_lower = url.lower()
    
    # Check for banking keywords
    bank_keywords = ["sbi", "hdfc", "icici", "axis", "kotak", "yono", "bank", "verify", "login", "kyc", "secure", "auth"]
    if any(kw in url_lower for kw in bank_keywords):
        category = "banking"
        # Guess specific bank
        for bank in ["sbi", "hdfc", "icici", "axis", "kotak"]:
            if bank in url_lower:
                bank_name = bank.upper()
                break
                
    # Check for marketplace keywords
    market_keywords = ["paytm", "phonepe", "amazon", "flipkart", "store", "shop", "retail", "delivery", "marketplace", "seller"]
    if any(kw in url_lower for kw in market_keywords):
        category = "marketplace"
        
    # Check for prize scam keywords
    prize_keywords = ["prize", "reward", "gift", "bonus", "claim", "win", "lottery", "free", "cashback"]
    if any(kw in url_lower for kw in prize_keywords):
        category = "prize_scam"

    return {
        "qr_type": qr_type,
        "merchant_name": merchant_name,
        "payment_context": payment_context,
        "category": category,
        "bank_name": bank_name
    }


def is_affirmative(ans: str) -> bool:
    """Detects yes/affirmative answers."""
    ans = ans.lower().strip()
    affirmative_patterns = [
        r"\byes\b", r"\byep\b", r"\byeah\b", r"\bsure\b", r"\bcorrect\b",
        r"\bi do\b", r"\bi am\b", r"\bindeed\b", r"\btrue\b", r"\bof course\b",
        r"\bsomeone did\b", r"\bthey did\b", r"\by\b"
    ]
    return any(re.search(pat, ans) for pat in affirmative_patterns)


def is_negative(ans: str) -> bool:
    """Detects no/negative answers."""
    ans = ans.lower().strip()
    negative_patterns = [
        r"\bno\b", r"\bnope\b", r"\bnah\b", r"\bnever\b", r"\bnot\b",
        r"\bdont\b", r"\bdon't\b", r"\bdo not\b", r"\bfalse\b", r"\bnot at all\b",
        r"\bincorrect\b", r"\bno one\b", r"\bnobody\b", r"\bn\b"
    ]
    return any(re.search(pat, ans) for pat in negative_patterns)


# =====================================
# Endpoints
# =====================================

@app.get("/")
def root():
    return {
        "status": "running",
        "service": "SentryPay Intent Verification AI Engine"
    }


# =====================================
# Question Database (Pool)
# =====================================

QUESTION_POOL = [
    # --- RISK-SPECIFIC QUESTIONS ---
    {
        "id": "risk_shortener",
        "tag": "shortener_use",
        "template": "Did you know that this QR code uses a shortened URL link ({url_domain}) which hides the real destination?",
        "categories": ["general", "banking", "marketplace", "prize_scam", "p2p"],
        "trigger_words": ["shortener"]
    },
    {
        "id": "risk_ip",
        "tag": "ip_use",
        "template": "This QR code points directly to a numeric IP address ({url_domain}) instead of a secure company website. Do you know why?",
        "categories": ["general", "banking", "marketplace", "prize_scam", "p2p"],
        "trigger_words": ["ip address"]
    },
    {
        "id": "risk_obfuscation",
        "tag": "obfuscation_use",
        "template": "This URL contains special characters or percent-encoding that obfuscates the destination. Are you sure you trust it?",
        "categories": ["general", "banking", "marketplace", "prize_scam", "p2p"],
        "trigger_words": ["obfuscation"]
    },
    # --- BANKING TOPIC QUESTIONS ---
    {
        "id": "bank_rep",
        "tag": "bank_impersonation",
        "template": "Did someone claiming to be a customer care agent, support staff, or {bank} representative ask you to scan this?",
        "categories": ["banking"]
    },
    {
        "id": "bank_verify",
        "tag": "account_verification",
        "template": "Are you paying or verifying your account to prevent a bank block, service suspension, or KYC issue?",
        "categories": ["banking"]
    },
    {
        "id": "bank_auth",
        "tag": "third_party_instruction",
        "template": "Are you executing this action because someone on a phone call or chat instructed you to follow their steps?",
        "categories": ["banking"]
    },
    # --- MARKETPLACE QUESTIONS ---
    {
        "id": "market_familiarity",
        "tag": "merchant_familiarity",
        "template": "Do you personally trust the merchant '{merchant}' or have you successfully bought from them before?",
        "categories": ["marketplace"]
    },
    {
        "id": "market_delivery",
        "tag": "delivery_receipt",
        "template": "Have you already received or verified the goods/services for '{context}' before making this payment?",
        "categories": ["marketplace"]
    },
    {
        "id": "market_match",
        "tag": "merchant_match",
        "template": "Does the name of the payee '{merchant}' exactly match the business or shop you are physically transacting with?",
        "categories": ["marketplace"]
    },
    # --- PRIZE / SCAM QUESTIONS ---
    {
        "id": "prize_promise",
        "tag": "prepayment_prize",
        "template": "Were you promised a prize, cash refund, lottery win, or lottery reward in exchange for scanning this QR?",
        "categories": ["prize_scam"]
    },
    {
        "id": "prize_prepay",
        "tag": "prepayment_fee",
        "template": "Did someone tell you that you must pay this fee/transfer to '{merchant}' before you can claim your reward?",
        "categories": ["prize_scam"]
    },
    {
        "id": "prize_trust",
        "tag": "prize_organization",
        "template": "Do you personally verify that '{merchant}' is a legitimate, well-known organization giving prizes?",
        "categories": ["prize_scam"]
    },
    # --- P2P (PEER-TO-PEER) INDIVIDUAL QUESTIONS ---
    {
        "id": "p2p_trust",
        "tag": "individual_trust",
        "template": "Are you sending money to an individual person ('{merchant}') rather than a registered commercial shop?",
        "categories": ["p2p"]
    },
    {
        "id": "p2p_relation",
        "tag": "relationship_verification",
        "template": "Do you personally know this receiver ('{merchant}') in real life, or is this an unknown person?",
        "categories": ["p2p"]
    },
    {
        "id": "p2p_reason",
        "tag": "purpose_verification",
        "template": "Are you paying this person ('{merchant}') under a threat, urgent request, or emergency call?",
        "categories": ["p2p"]
    },
    # --- GENERAL / FALLBACK SAFETY QUESTIONS ---
    {
        "id": "gen_freewill",
        "tag": "free_will",
        "template": "Are you scanning this QR code to pay '{merchant}' entirely out of your own free will?",
        "categories": ["general"]
    },
    {
        "id": "gen_coercion",
        "tag": "phone_coercion",
        "template": "Did you receive a phone call, SMS, or screen-share request telling you to scan this specific QR?",
        "categories": ["general"]
    },
    {
        "id": "gen_legitimacy",
        "tag": "legitimacy_check",
        "template": "Do you confirm that the recipient '{merchant}' is correct and you understand that UPI payments are non-refundable?",
        "categories": ["general"]
    }
]

def get_tag_for_question(question_text: str) -> str:
    """Matches a dynamically formatted question back to its tag using regex."""
    for q in QUESTION_POOL:
        template = q["template"]
        pattern = re.escape(template)
        # Replace escaped placeholders with wildcard patterns
        pattern = pattern.replace(r"\{merchant\}", r".*")
        pattern = pattern.replace(r"\{bank\}", r".*")
        pattern = pattern.replace(r"\{context\}", r".*")
        pattern = pattern.replace(r"\{url_domain\}", r".*")
        pattern = "^" + pattern + "$"
        if re.match(pattern, question_text):
            return q["tag"]
    return "general"

# =====================================
# Endpoints
# =====================================

@app.get("/")
def root():
    return {
        "status": "running",
        "service": "SentryPay Intent Verification AI Engine"
    }


@app.post("/generate-intent-questions", response_model=QuestionGenerationResponse)
def generate_intent_questions(risk_engine_output: RiskEngineResult):
    """
    Dynamically generates exactly three verification questions based on the
    context extracted from the QR URL, risk score, and risk reasons.
    """
    url = risk_engine_output.url
    ctx = parse_url_context(url)
    
    # Check if this is a P2P transfer (no merchant code/mcc parameter in UPI)
    parsed_url = urllib.parse.urlparse(url)
    if parsed_url.scheme.lower() == "upi":
        query_params = urllib.parse.parse_qs(parsed_url.query)
        if "mc" not in query_params or not query_params["mc"]:
            ctx["category"] = "p2p"
            
    category = ctx["category"]
    merchant = ctx["merchant_name"]
    context = ctx["payment_context"]
    bank = ctx["bank_name"]
    url_domain = parsed_url.netloc if parsed_url.netloc else merchant

    # 1. Classify risk factors from risk engine reasons
    reasons_str = " ".join(risk_engine_output.reasons).lower()
    
    selected_questions = []
    
    # Priority A: Risk-specific questions
    for q in QUESTION_POOL:
        if "trigger_words" in q:
            if any(tw in reasons_str for tw in q["trigger_words"]):
                formatted = q["template"].format(
                    merchant=merchant,
                    bank=bank,
                    context=context,
                    url_domain=url_domain
                )
                selected_questions.append(formatted)

    # Priority B: Category-specific questions
    cat_questions = [q for q in QUESTION_POOL if category in q["categories"] and "trigger_words" not in q]
    for q in cat_questions:
        formatted = q["template"].format(
            merchant=merchant,
            bank=bank,
            context=context,
            url_domain=url_domain
        )
        if formatted not in selected_questions:
            selected_questions.append(formatted)

    # Priority C: General fallback questions
    gen_questions = [q for q in QUESTION_POOL if "general" in q["categories"] and "trigger_words" not in q]
    for q in gen_questions:
        formatted = q["template"].format(
            merchant=merchant,
            bank=bank,
            context=context,
            url_domain=url_domain
        )
        if formatted not in selected_questions:
            selected_questions.append(formatted)

    # Keep exactly 3 questions
    selected_questions = selected_questions[:3]
    while len(selected_questions) < 3:
        selected_questions.append("Do you verify that this payment is legitimate and correct?")
        
    return QuestionGenerationResponse(questions=selected_questions)


@app.post("/verify-intent", response_model=VerifyIntentResponse)
def verify_intent(payload: VerifyIntentRequest):
    """
    Analyzes the 3 answers together with risk engine parameters and generates
    the Intent Score, Decision, Confidence, and Reasons.
    """
    risk_result = payload.risk_result
    questions = payload.questions
    answers = payload.answers
    
    if len(questions) != len(answers) or len(questions) != 3:
        raise HTTPException(status_code=400, detail="Exactly 3 questions and 3 answers must be provided.")
        
    intent_score = 100
    flagged_reasons = []
    
    for q, a in zip(questions, answers):
        tag = get_tag_for_question(q)
        a_lower = a.lower().strip()
        
        # 1. URL Shortener
        if tag == "shortener_use":
            if is_affirmative(a):
                intent_score -= 20
                flagged_reasons.append("User is proceeding despite knowing the URL is shortened.")
            else:
                intent_score -= 35
                flagged_reasons.append("User is unaware that this QR uses a hidden shortened URL link.")
                
        # 2. IP Address
        elif tag == "ip_use":
            if is_affirmative(a):
                intent_score -= 20
                flagged_reasons.append("User is proceeding despite knowing they are connecting to a raw numeric IP address.")
            else:
                intent_score -= 35
                flagged_reasons.append("User is unaware that this QR connects directly to a numeric IP address.")

        # 3. Obfuscation
        elif tag == "obfuscation_use":
            if is_affirmative(a):
                intent_score -= 20
                flagged_reasons.append("User is proceeding despite URL destination obfuscation.")
            else:
                intent_score -= 35
                flagged_reasons.append("User is unaware of destination obfuscation in the scanned QR.")
                
        # 4. Bank Impersonation
        elif tag == "bank_impersonation":
            if is_affirmative(a):
                intent_score -= 45
                flagged_reasons.append("User believes a bank representative requested the payment.")
            elif not is_negative(a):
                intent_score -= 15
                flagged_reasons.append("User gave an ambiguous response regarding bank authorization.")
                
        # 5. Account Verification
        elif tag == "account_verification":
            if is_affirmative(a):
                intent_score -= 35
                flagged_reasons.append("User believes they are paying to verify, unblock, or activate an account.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("User's purpose for account verification remains unverified.")

        # 6. Third Party Instruction
        elif tag == "third_party_instruction":
            if is_affirmative(a):
                intent_score -= 30
                flagged_reasons.append("User was instructed by a caller/third-party to perform this scan.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("Ambiguous answer about third-party coaching.")
                
        # 7. Merchant Familiarity
        elif tag == "merchant_familiarity":
            if is_negative(a):
                intent_score -= 25
                flagged_reasons.append("User does not know or trust the merchant.")
            elif not is_affirmative(a):
                intent_score -= 10
                flagged_reasons.append("User's familiarity with the merchant is unconfirmed.")
                
        # 8. Delivery Receipt
        elif tag == "delivery_receipt":
            if is_negative(a):
                intent_score -= 15
                flagged_reasons.append("Payment is being made before receiving the product or service.")
                
        # 9. Merchant Match
        elif tag == "merchant_match":
            if is_negative(a):
                intent_score -= 20
                flagged_reasons.append("Payee name does not match the actual business name.")
                
        # 10. Prepayment Prize
        elif tag == "prepayment_prize":
            if is_affirmative(a):
                intent_score -= 35
                flagged_reasons.append("User is scanning QR under the promise of a reward, lottery, or cashback.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("User was vague about reward or cashback promises.")
                
        # 11. Prepayment Fee
        elif tag == "prepayment_fee":
            if is_affirmative(a):
                intent_score -= 40
                flagged_reasons.append("User is paying upfront fees to obtain a prize or reward.")
                
        # 12. Prize Organization
        elif tag == "prize_organization":
            if is_negative(a):
                intent_score -= 25
                flagged_reasons.append("User does not know the organization offering the prize.")
                
        # 13. Individual Trust
        elif tag == "individual_trust":
            if is_affirmative(a):
                intent_score -= 15
                flagged_reasons.append("User is sending money to an individual instead of a registered merchant.")
                
        # 14. Relationship Verification
        elif tag == "relationship_verification":
            if is_negative(a):
                intent_score -= 30
                flagged_reasons.append("User is transferring money to an unknown individual.")
                
        # 15. Purpose Verification
        elif tag == "purpose_verification":
            if is_affirmative(a):
                intent_score -= 40
                flagged_reasons.append("User is paying this person under pressure, threat, or emergency call.")
                
        # 16. Free Will
        elif tag == "free_will":
            if is_negative(a):
                intent_score -= 55
                flagged_reasons.append("User is not making this payment out of their own free will.")
            elif not is_affirmative(a):
                intent_score -= 20
                flagged_reasons.append("User's free will authorization is ambiguous.")
                
        # 17. Phone Coercion
        elif tag == "phone_coercion":
            if is_affirmative(a):
                intent_score -= 30
                flagged_reasons.append("User was instructed over a phone call, message, or chat to scan this QR.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("Uncertain if user scanned QR due to third-party instruction.")
                
        # 18. Legitimacy Check
        elif tag == "legitimacy_check":
            if is_negative(a):
                intent_score -= 40
                flagged_reasons.append("User is unsure if the payment is legitimate or correct.")

    # Apply boundary limits
    intent_score = max(0, min(intent_score, 100))
    
    # Determine Decision
    if intent_score >= 70:
        decision = "SAFE"
        confidence = 0.90 + (intent_score - 70) / 300.0
        reason = [
            "User understands the payment purpose.",
            "Merchant information matches the payment context.",
            "No signs of social engineering detected."
        ]
    elif intent_score >= 40:
        decision = "SUSPICIOUS"
        confidence = 0.80 + (70 - intent_score) / 300.0
        reason = flagged_reasons if flagged_reasons else [
            "User's payment intent is inconsistent.",
            "Potential social engineering risk detected."
        ]
    else:
        decision = "BLOCK"
        confidence = 0.90 + (40 - intent_score) / 600.0
        reason = flagged_reasons if flagged_reasons else [
            "User does not understand the payment context.",
            "High risk of social engineering or scam detected."
        ]
        
    return VerifyIntentResponse(
        intent_score=intent_score,
        decision=decision,
        confidence=round(confidence, 2),
        reason=reason
    )

