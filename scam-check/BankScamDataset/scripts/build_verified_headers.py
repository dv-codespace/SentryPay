import json
import pandas as pd
from pathlib import Path

# ==========================================================
# PATHS
# ==========================================================

BASE = Path(__file__).resolve().parent.parent

INPUT_FILE = BASE / "data" / "trai_headers.xlsx"

OUTPUT_FILE = (
    BASE
    / "assets"
    / "sender_validation"
    / "verified_bank_headers.json"
)

# ==========================================================
# LOAD EXCEL
# ==========================================================

print("=" * 60)
print(" BUILDING VERIFIED BANK HEADERS ")
print("=" * 60)

df = pd.read_excel(INPUT_FILE)

df.columns = [c.strip() for c in df.columns]

# ==========================================================
# KEYWORDS
# ==========================================================

BANK_KEYWORDS = [

    "BANK",

    "BANK LIMITED",

    "BANK LTD",

    "BANKING",

    "PAYMENTS BANK",

    "SMALL FINANCE",

    "CO-OPERATIVE BANK",

    "COOPERATIVE BANK",

    "RURAL BANK",

]

# ==========================================================
# FILTER
# ==========================================================

filtered = df[
    df["Principal Entity Name"]
    .astype(str)
    .str.upper()
    .apply(
        lambda x: any(k in x for k in BANK_KEYWORDS)
    )
]

print(f"Total Bank Rows : {len(filtered)}")

# ==========================================================
# BUILD JSON
# ==========================================================

verified = {}

for _, row in filtered.iterrows():

    header = str(row["Header"]).strip().upper()

    entity = str(row["Principal Entity Name"]).strip()

    if not header:
        continue

    verified[header] = entity

# ==========================================================
# SAVE
# ==========================================================

OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:

    json.dump(
        verified,
        f,
        indent=4,
        ensure_ascii=False
    )

print()

print(f"Verified Headers : {len(verified)}")

print()

print("Saved to")

print(OUTPUT_FILE)

print("=" * 60)