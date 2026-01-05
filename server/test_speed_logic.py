
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

def create_gyro_y_frames(gyro_y_val):
    frames = []
    for i in range(40):
        # Create frames where Gyro Y reaches the target value
        # We put the max value in the middle
        if i == 20:
             gy = gyro_y_val
        else:
             gy = gyro_y_val * 0.5 # Some lower value
             
        frame = IMUFrame(
            ts=i * 0.01,
            acc=[0.0, 0.0, 9.8],
            gyro=[0.0, gy, 0.0]
        )
        frames.append(frame)
    return frames

def test_speed_model():
    print("Initializing SpeedRegressor...")
    try:
        speed_model = SpeedRegressor()
    except Exception as e:
        print(f"Failed to init model: {e}")
        return

    # Test Cases for Mapping: 500-2000 dps -> 95-170 km/h
    # Formula: speed = 0.05 * gyro_y + 70
    
    test_cases = [
        (500, 95.0),
        (2000, 170.0),
        (1000, 120.0), # 0.05 * 1000 + 70 = 50 + 70 = 120
        (0, 70.0),      # Should be handled gracefully, though physically unlikely for a smash
        (-2000, 170.0)  # Absolute value check
    ]

    print("\n--- Testing Gyro Y Mapping Logic ---")
    
    for gyro_y, expected_speed in test_cases:
        print(f"\nTesting Gyro Y = {gyro_y}...")
        frames = create_gyro_y_frames(gyro_y)
        
        try:
            speed = speed_model.predict(frames)
            print(f"  Input Max Gyro Y: {abs(gyro_y)}")
            print(f"  Predicted Speed : {speed}")
            print(f"  Expected Speed  : {expected_speed}")
            
            # Allow small float error
            if abs(speed - expected_speed) < 1.0:
                 print("  [PASS]")
            else:
                 print("  [FAIL]")
                 
        except Exception as e:
            print(f"  [ERROR] Prediction failed: {e}")

if __name__ == "__main__":
    test_speed_model()
