import os
import random
import warnings

from pathlib import Path

import numpy as np
import pandas as pd
import torch

from sklearn.model_selection import train_test_split

from transformers import (

    AutoTokenizer,

    AutoModelForSequenceClassification,

    TrainingArguments,

    Trainer,

    EarlyStoppingCallback

)

from datasets import Dataset

from sklearn.metrics import (

    accuracy_score,

    precision_recall_fscore_support,

    confusion_matrix,

    classification_report

)

warnings.filterwarnings("ignore")

# ==========================================================
# PROJECT PATHS
# ==========================================================

ROOT = Path(__file__).resolve().parent.parent

FINAL = ROOT / "final"

MODEL = ROOT / "model"

MODEL.mkdir(exist_ok=True)

DATASET_FILE = FINAL / "final_dataset.csv"

REPORT_FILE = MODEL / "classification_report.txt"

CONFUSION_FILE = MODEL / "confusion_matrix.csv"

MODEL_NAME = "distilbert-base-uncased"

# ==========================================================
# TRAINING CONFIGURATION
# ==========================================================

MAX_LENGTH = 128

BATCH_SIZE = 32

EPOCHS = 3

LEARNING_RATE = 2e-5

WEIGHT_DECAY = 0.01

SEED = 42

# ==========================================================
# CPU OPTIMIZATION
# ==========================================================

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

torch.set_num_threads(os.cpu_count())

print()

print("="*60)

print(" CPU TRAINING ")

print("="*60)

print()

print(f"CPU Threads : {torch.get_num_threads()}")

print(f"Device : {DEVICE}")

# ==========================================================
# RANDOM SEED
# ==========================================================

random.seed(SEED)

np.random.seed(SEED)

torch.manual_seed(SEED)

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
# DATA CONTAINERS
# ==========================================================

train_dataset = None

test_dataset = None

tokenizer = None

model = None
trainer = None

# ==========================================================
# LOAD DATASET
# ==========================================================

def load_dataset():

    info("Loading final dataset...")

    if not DATASET_FILE.exists():

        error("final_dataset.csv not found.")

        raise FileNotFoundError(DATASET_FILE)

    df = pd.read_csv(DATASET_FILE)

    required_columns = {"text", "label"}

    if not required_columns.issubset(df.columns):

        error("Dataset must contain text and label columns.")

        raise ValueError("Invalid dataset")

    df = df.dropna(subset=["text", "label"])

    df["text"] = df["text"].astype(str).str.strip()

    df["label"] = df["label"].astype(int)

    df = df[df["text"].str.len() > 5]

    df = df.drop_duplicates(subset=["text"])

    if not set(df["label"].unique()).issubset({0, 1, 2}):

        error("Labels must contain only 0 and 1 and 2.")

        raise ValueError("Invalid labels")

    success(f"Loaded {len(df)} samples")

    print()

    print(df["label"].value_counts().sort_index())

    print()

    return df


# ==========================================================
# TRAIN / VALIDATION SPLIT
# ==========================================================

def split_dataset(df):

    info("Creating train / validation split...")

    train_df, valid_df = train_test_split(

        df,

        test_size=0.10,

        random_state=SEED,

        shuffle=True,

        stratify=df["label"]

    )

    success(f"Training Samples   : {len(train_df)}")

    success(f"Validation Samples : {len(valid_df)}")

    return train_df.reset_index(drop=True), valid_df.reset_index(drop=True)


# ==========================================================
# CONVERT TO HF DATASET
# ==========================================================

def build_hf_dataset(train_df, valid_df):

    global train_dataset

    global test_dataset

    train_dataset = Dataset.from_pandas(train_df)

    test_dataset = Dataset.from_pandas(valid_df)

    success("Hugging Face datasets created.")

# ==========================================================
# LOAD TOKENIZER
# ==========================================================

def load_tokenizer():

    global tokenizer

    info("Loading tokenizer...")

    tokenizer = AutoTokenizer.from_pretrained(

        MODEL_NAME,

        use_fast=True

    )

    success("Tokenizer loaded.")


# ==========================================================
# TOKENIZATION FUNCTION
# ==========================================================

def tokenize(batch):

    return tokenizer(

        batch["text"],

        padding="max_length",

        truncation=True,

        max_length=MAX_LENGTH

    )


# ==========================================================
# TOKENIZE DATASETS
# ==========================================================

def tokenize_datasets():

    global train_dataset

    global test_dataset

    info("Tokenizing training dataset...")

    train_dataset = train_dataset.map(

        tokenize,

        batched=True,

        batch_size=1000

    )

    info("Tokenizing validation dataset...")

    test_dataset = test_dataset.map(

        tokenize,

        batched=True,

        batch_size=1000

    )

    columns = [

        "input_ids",

        "attention_mask",

        "label"

    ]

    train_dataset.set_format(

        type="torch",

        columns=columns

    )

    test_dataset.set_format(

        type="torch",

        columns=columns

    )

    success("Datasets tokenized successfully.")

# ==========================================================
# LOAD MODEL
# ==========================================================

def load_model():

    global model

    info(f"Loading {MODEL_NAME}...")

    model = AutoModelForSequenceClassification.from_pretrained(

        MODEL_NAME,

        num_labels=3

    )
  

    success("Model loaded.")


# ==========================================================
# METRICS
# ==========================================================
def compute_metrics(eval_pred):

    logits, labels = eval_pred

    predictions = np.argmax(logits, axis=1)

    precision, recall, f1, _ = precision_recall_fscore_support(
        labels,
        predictions,
        average="weighted",
        zero_division=0
    )

    accuracy = accuracy_score(labels, predictions)

    return {

        "accuracy": accuracy,

        "precision": precision,

        "recall": recall,

        "f1": f1

    }

# ==========================================================
# TRAINING ARGUMENTS
# ==========================================================

training_args = TrainingArguments(

    output_dir=str(MODEL),

    

    num_train_epochs=EPOCHS,

    learning_rate=LEARNING_RATE,

    weight_decay=WEIGHT_DECAY,

    per_device_train_batch_size=BATCH_SIZE,

    per_device_eval_batch_size=BATCH_SIZE,

    gradient_accumulation_steps=1,

    warmup_steps=200,

    lr_scheduler_type="linear",

    eval_strategy="epoch",

    save_strategy="epoch",

    logging_strategy="epoch",

    load_best_model_at_end=True,

    metric_for_best_model="f1",

    greater_is_better=True,

    save_total_limit=1,

    seed=SEED,

    report_to="none",

    dataloader_num_workers=0,

    fp16=True,

    bf16=False

)


# ==========================================================
# TRAINER
# ==========================================================


def train():

    global trainer

    trainer = Trainer(

        model=model,

        args=training_args,

        train_dataset=train_dataset,

        eval_dataset=test_dataset,

        processing_class=tokenizer,

        compute_metrics=compute_metrics,

        callbacks=[

            EarlyStoppingCallback(

                early_stopping_patience=2

            )

        ]

    )

    info("Starting training...\n")

    trainer.train()

    success("Training completed.")

# ==========================================================
# EVALUATE MODEL
# ==========================================================

def evaluate():

    info("Evaluating model...\n")

    metrics = trainer.evaluate()

    predictions = trainer.predict(test_dataset)

    preds = np.argmax(predictions.predictions, axis=1)

    labels = predictions.label_ids

    report = classification_report(

        labels,

        preds,

        target_names=["SAFE", "SCAM","NON_BANK"],

        digits=4

    )

    with open(REPORT_FILE, "w", encoding="utf-8") as f:

        f.write(report)

    cm = confusion_matrix(labels, preds)

    pd.DataFrame(

        cm,

        index=["SAFE", "SCAM","NON_BANK"],

        columns=["SAFE", "SCAM","NON_BANK"]

    ).to_csv(CONFUSION_FILE)

    print()

    print("=" * 60)

    print(" FINAL METRICS ")

    print("=" * 60)

    print()

    print(f"Accuracy  : {metrics['eval_accuracy']:.4f}")

    print(f"Precision : {metrics['eval_precision']:.4f}")

    print(f"Recall    : {metrics['eval_recall']:.4f}")

    print(f"F1 Score  : {metrics['eval_f1']:.4f}")

    print()

    success("Classification report saved.")

    success("Confusion matrix saved.")


# ==========================================================
# SAVE MODEL
# ==========================================================

def save_model():

    info("Saving model...")

    trainer.save_model(MODEL)

    tokenizer.save_pretrained(MODEL)

    success("Model saved successfully.")

    print()

    print("Saved to:")

    print(MODEL)


# ==========================================================
# MAIN
# ==========================================================

def main():

    print()

    print("=" * 60)

    print(" BANK SCAM MODEL TRAINING ")

    print("=" * 60)

    print()

    df = load_dataset()

    train_df, valid_df = split_dataset(df)

    build_hf_dataset(train_df, valid_df)

    load_tokenizer()

    tokenize_datasets()

    load_model()

    train()

    evaluate()

    save_model()

    print()

    print("=" * 60)

    print(" TRAINING COMPLETE ")

    print("=" * 60)

    print()


if __name__ == "__main__":

    main()