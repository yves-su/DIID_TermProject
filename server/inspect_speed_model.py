import tensorflow as tf
from tensorflow.keras.models import load_model
import os

try:
    model = load_model("speed_estimation_model.h5")
    print(f"Input Shape: {model.input_shape}")
    print(f"Output Shape: {model.output_shape}")
except Exception as e:
    print(f"Error: {e}")
