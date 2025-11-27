# app.py
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image
import io

from model_loader import load_model, predict_image

app = FastAPI(title="Crop Disease Detection API")

# Allow requests from your Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (change later in production)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model on startup
model = load_model()

@app.get("/")
def read_root():
    return {"message": "Crop Disease Detection API is running!"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Receives an image from Flutter, runs inference, and returns prediction + confidence.
    """
    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))
        result = predict_image(model, image)
        return JSONResponse(content=result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")
