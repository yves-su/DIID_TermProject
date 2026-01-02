
import pandas as pd
import ast
import numpy as np
import sys

try:
    from main import SwingClassifier, IMUFrame
except ImportError as e:
    print("Error importing modules. Please ensure you have installed the requirements.")
    print("Run: pip install -r requirements.txt")
    print(f"Details: {e}")
    sys.exit(1)

def verify_model():
    print("Loading data...")
    try:
        df = pd.read_csv("20260101_171025.csv")
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return

    print(f"Loaded {len(df)} rows.")
    
    print("Initializing Classifier...")
    try:
        classifier = SwingClassifier()
    except Exception as e:
        print(f"Error initializing classifier: {e}")
        return

    if classifier.model is None:
        print("Model failed to load. Aborting verification.")
        return

    # User defined mapping: 1: Smash, 2: Drive, 3: Toss, 4: Drop
    # Model (assumed 0-indexed): 0: Smash, 1: Drive, 2: Toss, 3: Drop
    # CSV label_id matches the 1-based index presumably?
    # Let's check a few samples.
    
    correct_count = 0
    total_count = 0
    
    # Mapping CSV label (string) to model Output ?
    # Actually let's just check if it predicts what the CSV label column says.
    
    for i, row in df.iterrows():
        try:
            # Parse data
            raw_data = ast.literal_eval(row['data'])
            
            # Convert to IMUFrame list
            frames = []
            for item in raw_data:
                # item is [ax, ay, az, gx, gy, gz]
                # IMUFrame needs ts as well, but classifier implementation re-extracts acc/gyro from object
                # checking main.py:
                # row = [f.acc[0], f.acc[1], f.acc[2], f.gyro[0], f.gyro[1], f.gyro[2]]
                # So we just need to populate acc and gyro in the object.
                frame = IMUFrame(
                    ts=0.0, 
                    acc=[item[0], item[1], item[2]], 
                    gyro=[item[3], item[4], item[5]]
                )
                frames.append(frame)
            
            # Predict
            pred_type, confidence = classifier.predict(frames)
            
            ground_truth = row['label']
            
            logging_msg = f"Row {i}: True={ground_truth}, Pred={pred_type}, Conf={confidence:.2f}"
            
            match = False
            # Check for match (case insensitive mostly, but here rigorous)
            if pred_type == ground_truth:
                match = True
            elif pred_type == "Other" and confidence < 0.8:
                # This is valid behavior if model is uncertain
                logging_msg += " (Low Conf -> Other)"
            
            if match:
                correct_count += 1
                print(f"[OK] {logging_msg}")
            else:
                print(f"[FAIL] {logging_msg}")
            
            total_count += 1
            
            # Verify Threshold Logic explicitly
            if confidence < 0.8 and pred_type != "Other":
                 print(f"CRITICAL ERROR: Confidence {confidence} < 0.8 but predicted {pred_type}")

        except Exception as e:
            print(f"Error processing row {i}: {e}")
            continue
            
    if total_count > 0:
        print(f"\nVerification Complete. Accuracy (Strict Match): {correct_count}/{total_count} ({correct_count/total_count:.2%})")
    
if __name__ == "__main__":
    verify_model()
