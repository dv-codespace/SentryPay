import random
import re
import sys

from pathlib import Path

import pandas as pd

# ==========================================================
# PROJECT PATHS
# ==========================================================

ROOT = Path(__file__).resolve().parent.parent

CLEANED = ROOT / "cleaned"

FINAL = ROOT / "final"

FINAL.mkdir(exist_ok=True)

SAFE_FILE = CLEANED / "safe_messages.csv"

SMS_FILE = CLEANED / "sms_phishing.csv"

FINANCIAL_FILE = CLEANED / "financial_scam_dataset.csv"

OPENPHISH_FILE = CLEANED / "openphish.csv"

PHISHTANK_FILE = CLEANED / "phishtank.csv"

FINAL_DATASET = FINAL / "final_dataset.csv"
ADDITIONAL_SCAM_FILE = CLEANED / "additional_scam_messages.csv"

ADDITIONAL_URL_FILE = CLEANED / "additional_bank_urls.csv"

NON_BANK_FILE = CLEANED / "non_bank_messages.csv"

REPORT = FINAL / "dataset_report.txt"

# ==========================================================
# REQUIRED FILES
# ==========================================================

FILES = {

    "safe_messages.csv": SAFE_FILE,
    "additional_scam_messages.csv": ADDITIONAL_SCAM_FILE,

"additional_bank_urls.csv": ADDITIONAL_URL_FILE,

    "sms_phishing.csv": SMS_FILE,

    "financial_scam_dataset.csv": FINANCIAL_FILE,

    "openphish.csv": OPENPHISH_FILE,

    "phishtank.csv": PHISHTANK_FILE,
    "non_bank_messages.csv": NON_BANK_FILE

}

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
# VALIDATE FILES
# ==========================================================

def validate():

    info("Checking cleaned datasets...\n")

    missing = []

    for name, path in FILES.items():

        if not path.exists():

            missing.append(name)

    if missing:

        error("Missing cleaned datasets\n")

        for m in missing:

            print("-", m)

        sys.exit(1)

    success("All cleaned datasets found.\n")

# ==========================================================
# BANKING VOCABULARY
# ==========================================================

BANK_TERMS = {

    "bank",

    "account",

    "transaction",

    "credit",

    "credited",

    "debit",

    "debited",

    "balance",

    "statement",

    "beneficiary",

    "ifsc",

    "imps",

    "neft",

    "rtgs",

    "upi",

    "otp",

    "kyc",

    "atm",

    "card",

    "pin",

    "loan",

    "refund",

    "payment",

    "customer id",

    "net banking",

    "rbi",

    "npci",

    "sbi",

    "hdfc",

    "icici",

    "axis",

    "kotak",

    "canara",

    "idfc",

    "union bank",

    "bank of baroda",

    "indian bank",

    "yes bank",

    "indusind",

    "bandhan"

}

# ==========================================================
# URL FILTER WORDS
# ==========================================================

BANK_URL_TERMS = {

    "bank",

    "upi",

    "npci",

    "rbi",

    "sbi",

    "hdfc",

    "icici",

    "axis",

    "kotak",

    "yono",

    "idfc",

    "pnb",

    "unionbank",

    "bankofbaroda",

    "indianbank"

}

# ==========================================================
# URL → MESSAGE
# ==========================================================

URL_TEMPLATES = [

    "Your bank account requires verification: {}",

    "Security Alert! Verify your account: {}",

    "Complete your KYC immediately: {}",

    "Account suspended. Login here: {}",

    "Verify your debit card here: {}",

    "Transaction failed. Verify now: {}",

    "Your UPI account needs verification: {}",

    "Bank verification pending: {}",

    "Update your account immediately: {}",

    "Your account will be blocked. Verify: {}"

]

# ==========================================================
# HELPERS
# ==========================================================

def is_bank_related(text):

    text = str(text).lower()

    return any(term in text for term in BANK_TERMS)

def make_url_message(url):

    return random.choice(URL_TEMPLATES).format(url)

def clean_text(text):

    text = str(text)

    text = re.sub(r"\s+", " ", text)

    return text.strip()
SAFE = []

SCAM = []

NON_BANK = []
# ==========================================================
# LOAD SAFE DATASET
# ==========================================================

def load_safe_dataset():

    info("Loading SAFE dataset...")

    df = pd.read_csv(SAFE_FILE)

    if "text" not in df.columns or "label" not in df.columns:

        error("safe_messages.csv must contain text,label")

        sys.exit(1)

    count = 0

    for _, row in df.iterrows():

        text = clean_text(row["text"])

        if len(text) < 5:

            continue

        SAFE.append({

            "text": text,

            "label": 0

        })

        count += 1

    success(f"SAFE Loaded : {count}")

    return count


# ==========================================================
# LOAD SMS PHISHING DATASET
# ==========================================================

def load_additional_scams():

    info("Loading Additional Scam Messages...")

    df = pd.read_csv(ADDITIONAL_SCAM_FILE)

    for _, row in df.iterrows():

        SCAM.append({

            "text": clean_text(row["text"]),

            "label": 1

        })

    success(f"Additional Scams : {len(df)}")

def load_additional_urls():

    info("Loading Additional Bank URLs...")

    df = pd.read_csv(ADDITIONAL_URL_FILE)

    safe = 0
    scam = 0

    for _, row in df.iterrows():

        url = clean_text(row["url"])

        label = int(row["label"])

        if label == 0:

            SAFE.append({

                "text": f"Visit the official bank website: {url}",

                "label": 0

            })

            safe += 1

        else:

            SCAM.append({

                "text": make_url_message(url),

                "label": 1

            })

            scam += 1

    success(f"Additional SAFE URLs : {safe}")

    success(f"Additional SCAM URLs : {scam}")



def load_non_bank():

    info("Loading NON-BANK dataset...")

    df = pd.read_csv(NON_BANK_FILE)

    count = 0

    for _, row in df.iterrows():

        NON_BANK.append({

            "text": clean_text(row["text"]),

            "label": 2

        })

        count += 1

    success(f"NON-BANK Messages : {count}")

    return count

def load_sms_scams():

    info("Extracting Banking Smishing Messages...")

    df = pd.read_csv(SMS_FILE)

    if "text" not in df.columns or "label" not in df.columns:

        error("sms_phishing.csv must contain text,label")

        sys.exit(1)

    count = 0

    ignored = 0

    for _, row in df.iterrows():

        label = str(row["label"]).strip().lower()

        if label != "smishing":

            continue

        text = clean_text(row["text"])

        if len(text) < 5:

            continue

        # if not is_bank_related(text):

        #     ignored += 1

        #     continue

        SCAM.append({

            "text": text,

            "label": 1

        })

        count += 1

    success(f"Bank Smishing : {count}")

    info(f"Ignored Non-Banking Smishing : {ignored}")

    return count


# ==========================================================
# LOAD FINANCIAL SCAM DATASET
# ==========================================================

def load_financial_scams():

    info("Extracting Financial Scam Messages...")

    df = pd.read_csv(FINANCIAL_FILE)

    if "text" not in df.columns or "label" not in df.columns:

        error("financial_scam_dataset.csv must contain text,label")

        sys.exit(1)

    count = 0

    ignored = 0

    for _, row in df.iterrows():

        label = str(row["label"]).strip().lower()

        if label != "scam":

            continue

        text = clean_text(row["text"])

        if len(text) < 5:

            continue

        #if not is_bank_related(text):

            #ignored += 1

            #continue

        SCAM.append({

            "text": text,

            "label": 1

        })

        count += 1

    success(f"Financial Scams : {count}")

    info(f"Ignored Non-Banking Financial Scams : {ignored}")

    return count


# ==========================================================
# DATASET SUMMARY
# ==========================================================

def show_partial_summary():

    print()

    print("=" * 60)

    print(" CURRENT DATASET STATUS ")

    print("=" * 60)

    print()

    print(f"SAFE Messages : {len(SAFE)}")

    print(f"SCAM Messages : {len(SCAM)}")

    print()

# ==========================================================
# LOAD OPENPHISH
# ==========================================================

def load_openphish():

    info("Processing OpenPhish...")

    df = pd.read_csv(OPENPHISH_FILE)

    if "url" not in df.columns:

        error("openphish.csv must contain url column")

        sys.exit(1)

    count = 0

    ignored = 0

    for _, row in df.iterrows():

        url = clean_text(row["url"]).lower()

        #if not any(term in url for term in BANK_URL_TERMS):

            #ignored += 1
           # continue

        SCAM.append({

            "text": make_url_message(url),

            "label": 1

        })

        count += 1

    success(f"Bank OpenPhish URLs : {count}")

    info(f"Ignored URLs : {ignored}")

    return count


# ==========================================================
# LOAD PHISHTANK
# ==========================================================

def load_phishtank():

    info("Processing PhishTank...")

    df = pd.read_csv(PHISHTANK_FILE)

    if "url" not in df.columns:

        error("phishtank.csv must contain url column")

        sys.exit(1)

    if "target" not in df.columns:

        df["target"] = ""

    count = 0

    ignored = 0

    for _, row in df.iterrows():

        url = clean_text(row["url"]).lower()

        target = clean_text(row["target"]).lower()

        bank_match = any(term in url for term in BANK_URL_TERMS)

        target_match = any(term in target for term in BANK_URL_TERMS)

        if not (bank_match or target_match):

            ignored += 1
            continue

        SCAM.append({

            "text": make_url_message(url),

            "label": 1

        })

        count += 1

    success(f"Bank PhishTank URLs : {count}")

    info(f"Ignored URLs : {ignored}")

    return count


# ==========================================================
# SUMMARY
# ==========================================================

def show_summary():

    print()

    print("=" * 60)

    print(" DATASET STATUS ")

    print("=" * 60)

    print()

    print(f"SAFE : {len(SAFE)}")

    print(f"SCAM : {len(SCAM)}")
    print(f"NON-BANK : {len(NON_BANK)}")
   

    print()
# ==========================================================
# BUILD FINAL DATASET
# ==========================================================

def build_dataset():

    info("Building final dataset...")

    safe_df = pd.DataFrame(SAFE)
  
    scam_df = pd.DataFrame(SCAM)

    non_bank_df = pd.DataFrame(NON_BANK)

    before_safe = len(safe_df)
    before_scam = len(scam_df)

    safe_df.drop_duplicates(subset=["text"], inplace=True)
    scam_df.drop_duplicates(subset=["text"], inplace=True)

    safe_df["text"] = safe_df["text"].apply(clean_text)
    scam_df["text"] = scam_df["text"].apply(clean_text)

    safe_df = safe_df[safe_df["text"].str.len() > 5]
    scam_df = scam_df[scam_df["text"].str.len() > 5]

    after_safe = len(safe_df)
    after_scam = len(scam_df)

    info(f"SAFE duplicates removed : {before_safe-after_safe}")
    info(f"SCAM duplicates removed : {before_scam-after_scam}")

    final_df = pd.concat(
        [safe_df, scam_df,non_bank_df],
        ignore_index=True
    )

    final_df = final_df.sample(
        frac=1,
        random_state=42
    ).reset_index(drop=True)

    return final_df


# ==========================================================
# BIAS AUDIT
# ==========================================================

AUDIT_TERMS = [

    "otp",

    "kyc",

    "account",

    "transaction",

    "bank",

    "upi",

    "card",

    "credit",

    "debit",

    "balance"

]

def bias_audit(df):

    info("Running bias audit...")

    report = []

    for term in AUDIT_TERMS:

        safe = df[
            (df.label == 0) &
            (df.text.str.lower().str.contains(term))
        ]

        scam = df[
            (df.label == 1) &
            (df.text.str.lower().str.contains(term))
        ]

        report.append(

            (

                term,

                len(safe),

                len(scam)

            )

        )

    return report


# ==========================================================
# DATASET REPORT
# ==========================================================

def generate_report(df, audit):

    safe = (df.label == 0).sum()
    scam = (df.label == 1).sum()

    with open(REPORT, "w", encoding="utf-8") as f:

        f.write("="*60+"\n")
        f.write("BANK SCAM DATASET REPORT\n")
        f.write("="*60+"\n\n")

        f.write(f"SAFE Messages : {safe}\n")
        f.write(f"SCAM Messages : {scam}\n")
        f.write(f"TOTAL : {len(df)}\n\n")

        f.write("="*60+"\n")
        f.write("BIAS AUDIT\n")
        f.write("="*60+"\n\n")

        for term, s, c in audit:

            f.write(f"{term:<15} SAFE={s:<5} SCAM={c}\n")

    success("dataset_report.txt generated")


# ==========================================================
# SAVE DATASET
# ==========================================================

def save_dataset(df):

    df.to_csv(

        FINAL_DATASET,

        index=False

    )

    success(f"Dataset saved : {FINAL_DATASET}")

    success(f"Total Samples : {len(df)}")


# ==========================================================
# MAIN
# ==========================================================

def main():

    print("\n"+"="*60)
    print(" BUILDING FINAL DATASET ")
    print("="*60+"\n")

    validate()

    load_safe_dataset()

    load_sms_scams()

    load_financial_scams()
    load_additional_scams()

    load_openphish()
    load_additional_urls()

    load_phishtank()
    load_non_bank()

    show_summary()

    df = build_dataset()

    audit = bias_audit(df)

    generate_report(df, audit)

    save_dataset(df)

    print("\n"+"="*60)
    print(" DATASET BUILD COMPLETE ")
    print("="*60+"\n")


if __name__ == "__main__":

    main()