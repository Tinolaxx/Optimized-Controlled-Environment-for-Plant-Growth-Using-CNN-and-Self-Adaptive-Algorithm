import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import tensorflow as tf
import cv2 as cv
import keras as kr
import os
import sys
import re
from glob import glob
from tqdm import tqdm
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler, OneHotEncoder
from keras._tf_keras.keras.applications import ResNet50V2,VGG16

print("Status Active: Displaying Version Control")

# Print versions of dependencies
print("Dependency versions:")
print("---------------------")
print(f"TensorFlow: {tf.__version__}")
print(f"NumPy: {np.__version__}")
print(f"Pandas: {pd.__version__}")
print(f"Matplotlib: {mpl.__version__}")
print(f"OpenCV: {cv.__version__}")
print(f"Keras: {kr.__version__}")
print(f"Scikit-learn: {sys.modules['sklearn'].__version__}")
