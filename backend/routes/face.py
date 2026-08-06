from fastapi import APIRouter, UploadFile, File, HTTPException
import face_recognition
import numpy as np
import cv2

router = APIRouter()

@router.post("/verify-face")
async def verify_face(image1: UploadFile = File(...), image2: UploadFile = File(...)):
    try:
        # Read uploaded files into memory
        contents1 = await image1.read()
        contents2 = await image2.read()
        
        # Convert bytes to numpy arrays
        nparr1 = np.frombuffer(contents1, np.uint8)
        nparr2 = np.frombuffer(contents2, np.uint8)
        
        # Decode images
        img1 = cv2.imdecode(nparr1, cv2.IMREAD_COLOR)
        img2 = cv2.imdecode(nparr2, cv2.IMREAD_COLOR)
        
        if img1 is None or img2 is None:
            raise HTTPException(status_code=400, detail="Could not read one or both images")
            
        # Convert to RGB (face_recognition requires RGB)
        img1_rgb = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)
        img2_rgb = cv2.cvtColor(img2, cv2.COLOR_BGR2RGB)
        
        # Get face encodings
        encodings1 = face_recognition.face_encodings(img1_rgb)
        encodings2 = face_recognition.face_encodings(img2_rgb)
        
        if len(encodings1) == 0 or len(encodings2) == 0:
            return {"match": False, "message": "Face not detected in one or both images"}
            
        # We assume the first detected face is the target
        encoding1 = encodings1[0]
        encoding2 = encodings2[0]
        
        # Compare faces (tolerance 0.6 is default)
        results = face_recognition.compare_faces([encoding1], encoding2, tolerance=0.6)
        
        return {"match": bool(results[0])}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
