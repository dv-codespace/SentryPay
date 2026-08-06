import torch

from pathlib import Path

from transformers import (

    AutoTokenizer,

    AutoModelForSequenceClassification

)

# ==========================================================
# MODEL PATH
# ==========================================================

ROOT = Path(__file__).resolve().parent.parent

MODEL_PATH = ROOT / "model"

# ==========================================================
# LOAD MODEL
# ==========================================================

print()

print("=" * 60)

print(" LOADING MODEL ")

print("=" * 60)

print()

tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)

model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH)

model.eval()

print("[SUCCESS] Model Loaded.")

print()

# ==========================================================
# PREDICTION
# ==========================================================

labels = {

    0: "SAFE",

    1: "SCAM",

     2: "NON_BANK"

}

while True:

    print("-" * 60)

    text = input("Enter Message (type exit to quit):\n\n")

    if text.lower() == "exit":

        break

    inputs = tokenizer(

        text,

        return_tensors="pt",

        truncation=True,

        padding=True,

        max_length=96

    )

    with torch.no_grad():

        outputs = model(**inputs)

    probabilities = torch.softmax(

        outputs.logits,

        dim=1

    )

    confidence, prediction = torch.max(

        probabilities,

        dim=1

    )

    print()

    print("=" * 60)

    print(" RESULT ")

    print("=" * 60)

    print()

    print(f"Prediction : {labels[prediction.item()]}")

    print(f"Confidence : {confidence.item()*100:.2f}%")

    print()

    print("SAFE Probability :", f"{probabilities[0][0].item()*100:.2f}%")

    print("SCAM Probability :", f"{probabilities[0][1].item()*100:.2f}%")

    print("NON_BANK Probability  :", f"{probabilities[0][2].item()*100:.2f}%")

    print()