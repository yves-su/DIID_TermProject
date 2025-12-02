import serial
import time
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.animation as animation
import re
import numpy as np

# --- Configuration ---
SERIAL_PORT = 'COM16'  # CHANGE THIS to your actual COM port
BAUD_RATE = 9600
MAX_POINTS = 100      # Number of points to keep for the graph

# --- Global Variables ---
data_buffer = {
    'timestamp': [],
    'acc_x': [], 'acc_y': [], 'acc_z': [],
    'gyro_x': [], 'gyro_y': [], 'gyro_z': []
}

# Regex to parse the line
pattern = re.compile(r"Timestamp:(\d+), AccX:([-\d.]+), AccY:([-\d.]+), AccZ:([-\d.]+), GyroX:([-\d.]+), GyroY:([-\d.]+), GyroZ:([-\d.]+)")

# Initialize Serial
try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
    print(f"Connected to {SERIAL_PORT}")
except Exception as e:
    print(f"Error opening serial port {SERIAL_PORT}: {e}")
    print("Please check your COM port and set it in the script.")
    exit()

# Setup Plot
fig = plt.figure(figsize=(10, 8))

# 3D Subplot for Attitude
ax3d = fig.add_subplot(2, 1, 1, projection='3d')
ax3d.set_title("MCU Attitude (Body Axes)")
ax3d.set_xlim([-1.5, 1.5])
ax3d.set_ylim([-1.5, 1.5])
ax3d.set_zlim([-1.5, 1.5])
ax3d.set_xlabel('X (World)')
ax3d.set_ylabel('Y (World)')
ax3d.set_zlabel('Z (World)')

# Draw World Axes (Thin, Dashed)
ax3d.plot([-1.5, 1.5], [0, 0], [0, 0], 'k--', linewidth=0.5, alpha=0.5)
ax3d.plot([0, 0], [-1.5, 1.5], [0, 0], 'k--', linewidth=0.5, alpha=0.5)
ax3d.plot([0, 0], [0, 0], [-1.5, 1.5], 'k--', linewidth=0.5, alpha=0.5)

# Initialize Body Axes Lines (Red=X, Green=Y, Blue=Z)
axis_x_line, = ax3d.plot([0, 1], [0, 0], [0, 0], color='r', linewidth=3, label='Body X')
axis_y_line, = ax3d.plot([0, 0], [0, 1], [0, 0], color='g', linewidth=3, label='Body Y')
axis_z_line, = ax3d.plot([0, 0], [0, 0], [0, 1], color='b', linewidth=3, label='Body Z')
ax3d.legend()

# 2D Subplot for Acceleration
ax2d = fig.add_subplot(2, 1, 2)
ax2d.set_title("Acceleration (g)")
ax2d.set_xlabel("Time (samples)")
ax2d.set_ylabel("Accel (g)")
line_x, = ax2d.plot([], [], label='Acc X', color='r')
line_y, = ax2d.plot([], [], label='Acc Y', color='g')
line_z, = ax2d.plot([], [], label='Acc Z', color='b')
ax2d.legend()
ax2d.grid(True)

def get_rotation_matrix(ax, ay, az):
    # Calculate Roll and Pitch from Accelerometer
    # Roll: Rotation around X-axis
    # Pitch: Rotation around Y-axis
    
    # Normalize acceleration vector
    norm = np.sqrt(ax**2 + ay**2 + az**2)
    if norm == 0: return np.eye(3)
    
    # Note: Accelerometer measures reaction force. 
    # When flat: (0, 0, 1). 
    # We want to find the rotation that aligns World Z (0,0,1) to Body Z (ax, ay, az).
    # Or rather, we want to visualize the Body Frame in the World Frame.
    
    # Standard formulas for Pitch/Roll from Accel (assuming Z-up world sequence Yaw-Pitch-Roll)
    # roll = atan2(ay, az)
    # pitch = atan2(-ax, sqrt(ay^2 + az^2))
    
    roll = np.arctan2(ay, az)
    pitch = np.arctan2(-ax, np.sqrt(ay**2 + az**2))
    
    # Rotation Matrices
    # Rx (Roll)
    Rx = np.array([
        [1, 0, 0],
        [0, np.cos(roll), -np.sin(roll)],
        [0, np.sin(roll), np.cos(roll)]
    ])
    
    # Ry (Pitch)
    Ry = np.array([
        [np.cos(pitch), 0, np.sin(pitch)],
        [0, 1, 0],
        [-np.sin(pitch), 0, np.cos(pitch)]
    ])
    
    # Combined Rotation R = Ry * Rx (assuming Yaw=0)
    # This transforms vectors from World to Body? Or Body to World?
    # Let's check: 
    # If we have a vector in Body frame, say Xb = [1, 0, 0].
    # We want to know its coordinates in World frame.
    # R_body_to_world = (Ry * Rx)^T ? Or just Ry * Rx?
    # Usually, if we rotate the object by (Roll, Pitch), the Rotation Matrix R represents that orientation.
    # So V_world = R * V_body.
    
    R = np.dot(Ry, Rx)
    return R

def update(frame):
    # Read all available lines
    latest_ax, latest_ay, latest_az = None, None, None
    
    while ser.in_waiting:
        try:
            line = ser.readline().decode('utf-8').strip()
            match = pattern.search(line)
            if match:
                ts = int(match.group(1))
                ax = float(match.group(2))
                ay = float(match.group(3))
                az = float(match.group(4))
                gx = float(match.group(5))
                gy = float(match.group(6))
                gz = float(match.group(7))

                # Append to buffer
                data_buffer['timestamp'].append(ts)
                data_buffer['acc_x'].append(ax)
                data_buffer['acc_y'].append(ay)
                data_buffer['acc_z'].append(az)
                data_buffer['gyro_x'].append(gx)
                data_buffer['gyro_y'].append(gy)
                data_buffer['gyro_z'].append(gz)
                
                # Keep buffer size limited
                if len(data_buffer['timestamp']) > MAX_POINTS:
                    for key in data_buffer:
                        if len(data_buffer[key]) > 0:
                            data_buffer[key].pop(0)
                
                # Store latest values for 3D update
                latest_ax, latest_ay, latest_az = ax, ay, az
                
        except Exception as e:
            print(f"Error parsing line: {e}")

    # Only update plots if we got new data
    if latest_ax is not None:
        # Calculate Rotation Matrix
        R = get_rotation_matrix(latest_ax, latest_ay, latest_az)
        
        # Body Axes in Body Frame
        body_x = np.array([1, 0, 0])
        body_y = np.array([0, 1, 0])
        body_z = np.array([0, 0, 1])
        
        # Transform to World Frame
        # We want to visualize how the Body axes look in the World.
        # If the board is pitched up, Body X should point up in World Z.
        # Let's apply the rotation.
        
        # We need to be careful with the inverse.
        # If we calculated Roll/Pitch FROM the accelerometer, we found the rotation that explains the gravity vector.
        # Gravity is [0, 0, 1] in World (assuming 1g up reaction).
        # Accel reading is R_world_to_body * [0, 0, 1].
        # So Accel = R^T * [0, 0, 1].
        # Our constructed R (Ry * Rx) is the rotation of the BODY relative to WORLD.
        # So V_world = R * V_body.
        
        world_x = np.dot(R, body_x)
        world_y = np.dot(R, body_y)
        world_z = np.dot(R, body_z)
        
        # Update Lines (Origin -> Transformed Axis)
        axis_x_line.set_data([0, world_x[0]], [0, world_x[1]])
        axis_x_line.set_3d_properties([0, world_x[2]])
        
        axis_y_line.set_data([0, world_y[0]], [0, world_y[1]])
        axis_y_line.set_3d_properties([0, world_y[2]])
        
        axis_z_line.set_data([0, world_z[0]], [0, world_z[1]])
        axis_z_line.set_3d_properties([0, world_z[2]])

        # Update 2D lines
        x_data = range(len(data_buffer['timestamp']))
        line_x.set_data(x_data, data_buffer['acc_x'])
        line_y.set_data(x_data, data_buffer['acc_y'])
        line_z.set_data(x_data, data_buffer['acc_z'])
        
        ax2d.relim()
        ax2d.autoscale_view()

    return axis_x_line, axis_y_line, axis_z_line, line_x, line_y, line_z

# Animate
ani = animation.FuncAnimation(fig, update, interval=50)

plt.tight_layout()
plt.show()
