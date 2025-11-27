# model_loader.py
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms
from PIL import Image

# ================================
# CONFIGURATION
# ================================

MODEL_PATH = "mobilenet_finetuned.pth"

CLASS_NAMES = [
    "Cashew__anthracnose",
    "Cashew__gumosis",
    "Cashew__healthy",
    "Cashew__leaf_miner",
    "Cashew__red_rust",
    "Cassava__bacterial_blight",
    "Cassava__brown_spot",
    "Cassava__green_mite",
    "Cassava__healthy",
    "Cassava__mosaic",
    "Corn_(maize)__fall_armyworm",
    "Corn_(maize)__grasshoper",
    "Corn_(maize)__healthy",
    "Corn_(maize)__leaf_beetle",
    "Corn_(maize)__leaf_blight",
    "Corn_(maize)__leaf_spot",
    "Corn_(maize)__streak_virus",
    "Tomato__healthy",
    "Tomato__leaf_blight",
    "Tomato__leaf_curl",
    "Tomato__septoria_leaf_spot",
    "Tomato__verticulium_wilt"
]

# ================================
# IMAGE PREPROCESSING
# ================================

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406],
                         [0.229, 0.224, 0.225]),
])

# ================================
# MODEL LOADING
# ================================

def load_model():
    print("🔄 Loading MobileNetV3-Large model architecture...")
    model = models.mobilenet_v3_large(weights=None)

    # Adjust classifier to match training setup (index [3] replaced in training)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, len(CLASS_NAMES))

    print("📦 Loading model weights from:", MODEL_PATH)
    state_dict = torch.load(MODEL_PATH, map_location=torch.device("cpu"))

    # Load trained weights
    model.load_state_dict(state_dict, strict=True)
    model.eval()
    print("✅ Model loaded successfully and ready for inference.")
    return model

# ================================
# INFERENCE FUNCTION
# ================================

def predict_image(model, image):
    """
    Takes a PIL image and returns the predicted class and confidence.
    """
    image = image.convert("RGB")
    img_t = transform(image).unsqueeze(0)
    with torch.no_grad():
        outputs = model(img_t)
        probs = F.softmax(outputs, dim=1)
        conf, pred = torch.max(probs, dim=1)
        predicted_class = CLASS_NAMES[pred.item()]
        confidence = conf.item() * 100
    return {"prediction": predicted_class, "confidence": round(confidence, 2)}
