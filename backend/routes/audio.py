from fastapi import APIRouter, File, UploadFile, HTTPException
import speech_recognition as sr
import os
import tempfile
from pydub import AudioSegment

router = APIRouter()

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    temp_dir = tempfile.mkdtemp()
    file_path = os.path.join(temp_dir, file.filename)
    
    # Save the uploaded file
    with open(file_path, "wb") as f:
        f.write(await file.read())
        
    try:
        # Convert to wav if not wav (SpeechRecognition requires wav/aiff/flac)
        wav_path = os.path.join(temp_dir, "converted.wav")
        audio = AudioSegment.from_file(file_path)
        audio.export(wav_path, format="wav")
        
        # Transcribe using SpeechRecognition
        recognizer = sr.Recognizer()
        with sr.AudioFile(wav_path) as source:
            audio_data = recognizer.record(source)
            text = recognizer.recognize_google(audio_data)
            return {"text": text}
    except Exception as e:
        return {"error": str(e), "text": ""}
    finally:
        # Cleanup
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
            if 'wav_path' in locals() and os.path.exists(wav_path):
                os.remove(wav_path)
        except:
            pass
