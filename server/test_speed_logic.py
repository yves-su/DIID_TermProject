
import sys
import numpy as np
import logging

# Configure logging to stdout
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("TestSpeed")

try:
    from main import SpeedRegressor, IMUFrame
except ImportError:
    print("Could not import from main.py. Make sure you are in the server directory.")
    sys.exit(1)

def test_speed_model():
    print("Initializing SpeedRegressor...")
    try:
        speed_model = SpeedRegressor()
    except Exception as e:
        print(f"Failed to init model: {e}")
        return

    if speed_model.model is None:
        print("Model file not found or failed to load. Skipping test.")
        return

    print("Creating dummy frames...")
    # Create 40 frames of dummy data
    frames = []
    for i in range(40):
        # Simulate some movement
        frame = IMUFrame(
            ts=i * 0.01,
            acc=[0.5 + np.random.rand(), 0.5, 9.8],
            gyro=[100.0, 200.0, 50.0]
        )
        frames.append(frame)

    print("Predicting speed...")
    try:
        speed = speed_model.predict(frames)
        print(f"Predicted Speed: {speed}")
        
        if isinstance(speed, (int, float)) and speed >= 0:
            print("SUCCESS: Speed model returned a valid non-negative number.")
        else:
            print(f"FAILURE: Speed model returned invalid type or value: {type(speed)}")
            
    except Exception as e:
        print(f"FAILURE: Prediction raised exception: {e}")

if __name__ == "__main__":
    test_speed_model()
