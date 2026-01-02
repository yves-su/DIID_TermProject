
import pandas as pd
import ast
import numpy as np
import sys
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Verifier")

try:
    import tensorflow as tf
    from tensorflow.keras.models import load_model
except ImportError as e:
    print(f"Error importing TensorFlow: {e}")
    sys.exit(1)

# --- Define Data Structure Mock ---
class IMUFrame:
    def __init__(self, ts, acc, gyro):
        self.ts = ts
        self.acc = acc
        self.gyro = gyro

# --- Standalone Classifier Class ---
class SwingClassifier:
    """
    Standalone version of SwingClassifier for verification.
    """
    def __init__(self):
        try:
            self.model = load_model("badminton_model_v3.h5")
            logger.info("Loaded Classifier Model: badminton_model_v3.h5")
        except Exception as e:
            logger.error(f"Failed to load H5 model: {e}")
            self.model = None

        # User defined: 1: Smash, 2: Drive, 3: Toss, 4: Drop
        # Suspecting Keras alphabetical order: Drive, Drop, Smash, Toss
        self.classes = ["Drive", "Drop", "Smash", "Toss"]

    def predict(self, frames):
        if self.model is None:
            return "Other", 0.0

        # Preprocessing
        data = []
        for f in frames:
            row = [f.acc[0], f.acc[1], f.acc[2], f.gyro[0], f.gyro[1], f.gyro[2]]
            data.append(row)
        
        target_len = 40
        data_np = np.array(data)
        
        if len(data_np) < target_len:
            pad = np.zeros((target_len - len(data_np), 6))
            data_np = np.vstack([data_np, pad])
        elif len(data_np) > target_len:
            start = (len(data_np) - target_len) // 2
            data_np = data_np[start:start+target_len]
            
        input_data = data_np.reshape(1, 40, 6, 1)

        # Predict
        prediction = self.model.predict(input_data, verbose=0)
        
        predicted_idx = np.argmax(prediction)
        confidence = float(np.max(prediction))
        
        # Confidence threshold
        if confidence < 0.8:
            return "Other", confidence
        
        predicted_class = self.classes[predicted_idx]
        return predicted_class, confidence

def verify_model():
    print("Loading csv data...")
    try:
        df = pd.read_csv("20260101_171025.csv")
    except Exception as e:
        print(f"Error reading CSV: {e}")
        # If pandas fails, we can't proceed easily
        return

    print(f"Loaded {len(df)} rows. Initializing Classifier...")
    classifier = SwingClassifier()

    if classifier.model is None:
        print("Model failed to load.")
        return

    correct_count = 0
    total_count = 0
    
    classification_report = {
        "Smash": {"TP": 0, "Count": 0},
        "Drive": {"TP": 0, "Count": 0},
        "Toss": {"TP": 0, "Count": 0},
        "Drop": {"TP": 0, "Count": 0},
        "Other": {"TP": 0, "Count": 0} # Should technically be 0 count in labelled data usually
    }

    print("\nStarting Verification...")
    
    for i, row in df.iterrows():
        try:
            raw_data = ast.literal_eval(row['data'])
            frames = []
            for item in raw_data:
                # [ax, ay, az, gx, gy, gz]
                frame = IMUFrame(
                    ts=0.0, 
                    acc=[item[0], item[1], item[2]], 
                    gyro=[item[3], item[4], item[5]]
                )
                frames.append(frame)
            
            ground_truth = row['label']
            pred_type, confidence = classifier.predict(frames)
            
            # Count ground truth
            if ground_truth not in classification_report:
                classification_report[ground_truth] = {"TP": 0, "Count": 0}
            classification_report[ground_truth]["Count"] += 1
            
            is_correct = (pred_type == ground_truth)
            
            # Handling "Other" logic: If GT is "Drive" but Pred is "Other" (low conf), it's a miss for Drive.
            
            if is_correct:
                correct_count += 1
                classification_report[ground_truth]["TP"] += 1
            
            total_count += 1
            
            if i < 5: # Print first 5 for sanity check
                print(f"Row {i}: GT={ground_truth}, Pred={pred_type}, Conf={confidence:.2f} [{'OK' if is_correct else 'FAIL'}]")

        except Exception as e:
            print(f"Error row {i}: {e}")
            continue
            
    print(f"\nOptimization Summary:")
    print(f"Total Accuracy: {correct_count}/{total_count} ({correct_count/total_count:.2%})")
    
    print("\nPer Class Accuracy:")
    for cls, stats in classification_report.items():
        if stats["Count"] > 0:
            acc = stats["TP"] / stats["Count"]
            print(f"  {cls}: {stats['TP']}/{stats['Count']} ({acc:.2%})")
        else:
            print(f"  {cls}: No samples")

if __name__ == "__main__":
    verify_model()
