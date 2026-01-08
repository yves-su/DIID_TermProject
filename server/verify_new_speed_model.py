import logging
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from typing import List, Optional
import os
import sys

# Ensure we can import regression_helpers
# If running not from server dir, add it
if os.path.exists("server"):
    sys.path.append("server")
    from regression_helpers import sum_over_time, physics_transform
else:
    from regression_helpers import sum_over_time, physics_transform

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Test")

class IMUFrame:
    def __init__(self, ts, acc, gyro):
        self.ts = ts
        self.acc = acc
        self.gyro = gyro

class SpeedRegressor:
    """
    球速預測模型 (Regressor) - using model_speed_cnn_att.keras
    Features: Uses raw IMU data (40x6) and internal physics_transform layer.
    """
    def __init__(self):
        try:
            # Load with custom objects required for the new .keras model
            # Assuming files are in current dir or server/
            model_path = "model_speed_cnn_att.keras"
            if not os.path.exists(model_path) and os.path.exists(f"server/{model_path}"):
                model_path = f"server/{model_path}"
                
            self.model = load_model(
                model_path, 
                custom_objects={
                    "sum_over_time": sum_over_time, 
                    "physics_transform": physics_transform
                },
                compile=False
            )
            logger.info(f"Loaded Speed Model: {model_path}")
            
            # Log input shape to help debug
            self.input_shape = self.model.input_shape
            logger.info(f"Speed Model Input Shape: {self.input_shape}")
        except Exception as e:
            logger.error(f"Failed to load Speed model: {e}")
            self.model = None

    def predict(self, frames: List[IMUFrame], client_id: Optional[str] = "unknown"):
        if self.model is None:
            return 0.0

        data = []
        for f in frames:
            row = [f.acc[0], f.acc[1], f.acc[2], f.gyro[0], f.gyro[1], f.gyro[2]]
            data.append(row)
        
        data_np = np.array(data)
        
        target_len = 40
        if len(data_np) < target_len:
            pad = np.zeros((target_len - len(data_np), 6))
            if len(data_np) > 0:
                data_np = np.vstack([data_np, pad])
            else:
                data_np = pad
        elif len(data_np) > target_len:
            start = (len(data_np) - target_len) // 2
            data_np = data_np[start:start+target_len]

        input_data = data_np.reshape(1, 40, 6)
        
        try:
            logger.info(f"SpeedModel Input Shape: {input_data.shape}")
            prediction = self.model.predict(input_data, verbose=0)
            logger.info(f"SpeedModel Raw Output: {prediction}")

            speed = float(prediction[0][0])
            
            # speed = speed * 5.0 
            
            if speed < 0: speed = 0
            
            return round(speed, 1)
            
        except Exception as e:
            logger.error(f"Speed prediction failed: {e}")
            return 0.0

def test_model():
    print("Initializing SpeedRegressor...")
    speed_model = SpeedRegressor()

    if speed_model.model is None:
        print("Error: Speed model is None.")
        return

    print("Speed model loaded successfully.")
    
    # Create dummy data
    frames = []
    for i in range(45): 
        acc = [np.random.rand(), np.random.rand(), np.random.rand()]
        gyro = [np.random.rand()*100, np.random.rand()*100, np.random.rand()*100]
        frames.append(IMUFrame(0, acc, gyro))
    
    print("Running prediction...")
    result = speed_model.predict(frames)
    print(f"Prediction Result: {result} km/h")

if __name__ == "__main__":
    test_model()
