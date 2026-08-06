import re
import sys
from pathlib import Path

import pandas as pd

# ==========================================================
# PROJECT PATHS
# ==========================================================

ROOT = Path(__file__).resolve().parent.parent

RAW = ROOT / "raw"
CLEANED = ROOT / "cleaned"

SAFE_FOLDER = RAW / "safe_messages"
SCAM_FOLDER = RAW / "scam_messages"
SMS_FOLDER = RAW / "phishing_sms"
URL_FOLDER = RAW / "phishing_urls"
NON_BANK_FOLDER = RAW / "non_bank_messages"

CLEANED.mkdir(exist_ok=True)

SAFE_FILE = SAFE_FOLDER / "legit_bank_messages.csv"

SMS_FILE = SMS_FOLDER / "sms_phishing.csv"

FINANCIAL_FILE = SCAM_FOLDER / "financial_scam_dataset.csv"
ADDITIONAL_SCAM_FILE = SCAM_FOLDER / "additional_scam_messages.csv"

OPENPHISH_FILE = URL_FOLDER / "openphish.txt"

PHISHTANK_FILE = URL_FOLDER / "phishtank.csv"
ADDITIONAL_URL_FILE = URL_FOLDER / "additional_bank_urls.csv"
NON_BANK_FILE = NON_BANK_FOLDER / "spam.csv"

# ==========================================================
# OUTPUT FILES
# ==========================================================

SAFE_OUT = CLEANED / "safe_messages.csv"

SMS_OUT = CLEANED / "sms_phishing.csv"

FINANCIAL_OUT = CLEANED / "financial_scam_dataset.csv"
ADDITIONAL_SCAM_OUT = CLEANED / "additional_scam_messages.csv"

OPENPHISH_OUT = CLEANED / "openphish.csv"

PHISHTANK_OUT = CLEANED / "phishtank.csv"
ADDITIONAL_URL_OUT = CLEANED / "additional_bank_urls.csv"
NON_BANK_OUT = CLEANED / "non_bank_messages.csv"

# ==========================================================
# LOGGER
# ==========================================================

def info(msg):
    print(f"[INFO] {msg}")

def success(msg):
    print(f"[SUCCESS] {msg}")

def error(msg):
    print(f"[ERROR] {msg}")

# ==========================================================
# CHECK REQUIRED FILES
# ==========================================================

REQUIRED = {

    "legit_bank_messages.csv": SAFE_FILE,

    "sms_phishing.csv": SMS_FILE,

    "financial_scam_dataset.csv": FINANCIAL_FILE,
    "additional_scam_messages.csv": ADDITIONAL_SCAM_FILE,

    "openphish.txt": OPENPHISH_FILE,

    "phishtank.csv": PHISHTANK_FILE,
    "spam.csv": NON_BANK_FILE,
    "additional_bank_urls.csv": ADDITIONAL_URL_FILE
}

def validate_files():

    info("Checking datasets...\n")

    missing = []

    for name, path in REQUIRED.items():

        if not path.exists():

            missing.append(name)

    if missing:

        error("Required datasets missing:\n")

        for m in missing:

            print(f" - {m}")

        sys.exit(1)

    success("All datasets found.\n")

# ==========================================================
# DETECT COLUMN
# ==========================================================

TEXT_COLUMNS = [

    "text",

    "message",

    "TEXT",

    "MESSAGE",

    "sms",

    "body",

    "content",
    "v2"
]

LABEL_COLUMNS = [

    "label",

    "LABEL",

    "class",

    "category",

    "type",
    "v1"
]

URL_COLUMNS = [

    "url",

    "URL"
]

def detect_column(df, candidates):

    for c in candidates:

        if c in df.columns:

            return c

    lower = {x.lower(): x for x in df.columns}

    for c in candidates:

        if c.lower() in lower:

            return lower[c.lower()]

    return None

# ==========================================================
# TEXT CLEANING
# ==========================================================

def clean_text(text):

    text = str(text)

    text = text.replace("\n", " ")

    text = text.replace("\r", " ")

    text = re.sub(r"\s+", " ", text)

    return text.strip()

NON_BANK_FILTER = [

    "bank",
    "account",
    "credit",
    "credited",
    "debit",
    "debited",
    "upi",
    "loan",
    "emi",
    "transaction",
    "balance",
    "card",
    "atm",
    "refund",
    "wallet",
    "kyc",
    "ifsc",
    "neft",
    "rtgs",
    "imps",
    "npci",
    "rbi",
    "sbi",
    "hdfc",
    "icici",
    "axis",
    "kotak",
    "canara",
    "idfc",
    "yes bank",
    "union bank",
    "bank of baroda",
    "indian bank"

]

# ==========================================================
# URL VALIDATION
# ==========================================================

def valid_url(url):

    url = str(url).strip().lower()

    return url.startswith("http://") or url.startswith("https://")

# ==========================================================
# DATAFRAME CLEANER
# ==========================================================

def clean_dataframe(df, text_col):

    before = len(df)

    df = df.drop_duplicates(subset=[text_col])

    df = df.dropna(subset=[text_col])

    df[text_col] = df[text_col].astype(str)

    df[text_col] = df[text_col].apply(clean_text)

    df = df[df[text_col].str.len() > 5]

    after = len(df)

    success(f"Removed {before-after} invalid rows")

    return df
# ==========================================================
# CLEAN SAFE DATASET
# ==========================================================

def clean_safe_dataset():

    info("Cleaning Legitimate Bank Messages...")

    df = pd.read_csv(SAFE_FILE)

    text_col = detect_column(df, TEXT_COLUMNS)

    label_col = detect_column(df, LABEL_COLUMNS)

    if text_col is None:

        error("Message column not found in legit_bank_messages.csv")

        sys.exit(1)

    if label_col is None:

        error("Label column not found in legit_bank_messages.csv")

        sys.exit(1)

    df = clean_dataframe(df, text_col)

    # Keep only SAFE labels
    try:
        df[label_col] = pd.to_numeric(df[label_col], errors="coerce")
    except Exception:
        error("SAFE label column contains invalid values.")
        sys.exit(1)

    df = df.dropna(subset=[label_col])

    df[label_col] = df[label_col].astype(int)

    if not set(df[label_col].unique()).issubset({0}):
        error("SAFE dataset must contain only label 0.")
        sys.exit(1)

    df = df[df[label_col] == 0]

    # Keep only required columns
    df = df[[text_col, label_col]]

    df.columns = ["text", "label"]

    df.to_csv(SAFE_OUT, index=False)

    success(f"SAFE Messages : {len(df)}")

    return len(df)


# ==========================================================
# CLEAN SMS PHISHING DATASET
# ==========================================================

def clean_sms_dataset():

    info("Cleaning SMS Phishing Dataset...")

    df = pd.read_csv(SMS_FILE)

    text_col = detect_column(df, TEXT_COLUMNS)

    label_col = detect_column(df, LABEL_COLUMNS)

    if text_col is None:

        error("Message column not found in sms_phishing.csv")

        sys.exit(1)

    if label_col is None:

        error("Label column not found in sms_phishing.csv")

        sys.exit(1)

    df = clean_dataframe(df, text_col)

    # Normalize labels
    df[label_col] = (

        df[label_col]

        .astype(str)

        .str.strip()

        .str.lower()

    )

    # Keep only ham + smishing
    df = df[

        df[label_col].isin(

            [

                "ham",

                "smishing"

            ]

        )

    ]

    # Keep only needed columns
    df = df[[text_col, label_col]]

    df.columns = ["text", "label"]

    df.to_csv(SMS_OUT, index=False)

    ham = (df["label"] == "ham").sum()

    scam = (df["label"] == "smishing").sum()

    success(f"HAM : {ham}")

    success(f"SMISHING : {scam}")

    return ham, scam


# ==========================================================
# CLEAN FINANCIAL DATASET
# ==========================================================
def clean_additional_scams():

    info("Cleaning Additional Scam Messages...")

    df = pd.read_csv(ADDITIONAL_SCAM_FILE)

    df = clean_dataframe(df, "message")

    df = df[["message", "label"]]

    df.columns = ["text", "label"]

    df.to_csv(ADDITIONAL_SCAM_OUT, index=False)

    success(f"Additional Scams : {len(df)}")

    return len(df)

def clean_additional_urls():

    info("Cleaning Additional Bank URLs...")

    df = pd.read_csv(ADDITIONAL_URL_FILE)

    df = df.drop_duplicates()

    df = df[df["url"].apply(valid_url)]

    df.to_csv(ADDITIONAL_URL_OUT, index=False)

    success(f"Additional URLs : {len(df)}")

    return len(df)

def clean_non_bank_dataset():

    info("Cleaning NON-BANK Dataset...")

    df = pd.read_csv(NON_BANK_FILE, encoding="latin-1")

    text_col = detect_column(df, TEXT_COLUMNS)
    label_col = detect_column(df, LABEL_COLUMNS)

    if text_col is None or label_col is None:

        error("SMS Spam dataset must contain text and label columns")

        sys.exit(1)

    df = clean_dataframe(df, text_col)

    df[label_col] = (

        df[label_col]

        .astype(str)

        .str.strip()

        .str.lower()

    )

    # Keep only HAM

    df = df[df[label_col] == "ham"]

    # Remove banking messages

    df = df[
        ~df[text_col]
        .str.lower()
        .str.contains("|".join(NON_BANK_FILTER), regex=True)
    ]

    df["label"] = 2

    df = df[[text_col, "label"]]

    df.columns = ["text", "label"]

    df.to_csv(NON_BANK_OUT, index=False)

    success(f"NON-BANK Messages : {len(df)}")

    return len(df)


def clean_financial_dataset():

    info("Cleaning Financial Scam Dataset...")

    df = pd.read_csv(FINANCIAL_FILE)

    text_col = detect_column(df, TEXT_COLUMNS)

    label_col = detect_column(df, LABEL_COLUMNS)

    if text_col is None:

        error("Message column not found in financial_scam_dataset.csv")

        sys.exit(1)

    if label_col is None:

        error("Label column not found in financial_scam_dataset.csv")

        sys.exit(1)

    df = clean_dataframe(df, text_col)

    df[label_col] = (

        df[label_col]

        .astype(str)

        .str.strip()

        .str.lower()

    )

    # Keep only ham + scam
    df = df[

        df[label_col].isin(

            [

                "ham",

                "scam"

            ]

        )

    ]

    df = df[[text_col, label_col]]

    df.columns = ["text", "label"]

    df.to_csv(FINANCIAL_OUT, index=False)

    ham = (df["label"] == "ham").sum()

    scam = (df["label"] == "scam").sum()

    success(f"HAM : {ham}")

    success(f"SCAM : {scam}")

    return ham, scam
# ==========================================================
# CLEAN OPENPHISH
# ==========================================================

def clean_openphish():

    info("Cleaning OpenPhish...")

    urls = []

    with open(OPENPHISH_FILE, "r", encoding="utf-8") as f:

        for line in f:

            url = line.strip()

            if valid_url(url):

                urls.append(url)

    df = pd.DataFrame({

        "url": urls

    })

    before = len(df)

    df.drop_duplicates(inplace=True)

    after = len(df)

    success(f"Removed {before-after} duplicate URLs")

    df.to_csv(

        OPENPHISH_OUT,

        index=False
    )

    success(f"OpenPhish URLs : {len(df)}")

    return len(df)


# ==========================================================
# CLEAN PHISHTANK
# ==========================================================

def clean_phishtank():

    info("Cleaning PhishTank...")

    df = pd.read_csv(PHISHTANK_FILE)

    url_col = detect_column(

        df,

        URL_COLUMNS
    )

    if url_col is None:

        error("URL column not found in phishtank.csv")

        sys.exit(1)

    target_col = None

    for c in df.columns:

        if c.lower() == "target":

            target_col = c

            break

    if target_col is None:

        df["target"] = ""

        target_col = "target"

    df = df[[

        url_col,

        target_col

    ]]

    df.columns = [

        "url",

        "target"

    ]

    df = df.drop_duplicates()

    df = df.dropna()

    df = df[

        df["url"].apply(valid_url)

    ]

    df.to_csv(

        PHISHTANK_OUT,

        index=False
    )

    success(f"PhishTank URLs : {len(df)}")

    return len(df)


# ==========================================================
# MAIN
# ==========================================================

def main():

    print()

    print("=" * 60)

    print(" CLEANING DATASETS ")

    print("=" * 60)

    print()

    validate_files()

    safe_count = clean_safe_dataset()

    sms_ham, sms_scam = clean_sms_dataset()

    fin_ham, fin_scam = clean_financial_dataset()
    clean_additional_scams()

    open_count = clean_openphish()

    tank_count = clean_phishtank()
    clean_additional_urls()
    non_bank = clean_non_bank_dataset()

    print()

    print("=" * 60)

    print(" CLEANING SUMMARY ")

    print("=" * 60)

    print()

    print(f"SAFE DATASET             : {safe_count}")

    print(f"SMS HAM                 : {sms_ham}")

    print(f"SMS SMISHING            : {sms_scam}")

    print(f"FINANCIAL HAM           : {fin_ham}")

    print(f"FINANCIAL SCAM          : {fin_scam}")

    print(f"OPENPHISH URLS          : {open_count}")

    print(f"PHISHTANK URLS          : {tank_count}")
    print(f"NON-BANK DATASET        : {non_bank}")

    print()

    success("All cleaned datasets saved successfully.")

    print()

    print("Saved inside:")

    print(CLEANED)

    print()


if __name__ == "__main__":

    main()