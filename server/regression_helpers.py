import tensorflow as tf # type: ignore
from tensorflow.keras.saving import register_keras_serializable # type: ignore


@register_keras_serializable()
def sum_over_time(x):
    import tensorflow as tf
    # Sum over the time dimension (axis 1)
    return tf.reduce_sum(x, axis=1)

@register_keras_serializable()
def physics_transform(inputs):
    # Hardcoded constants for feature engineering
    R_SENSOR = 0.10
    GRAVITY = 9.80665
    MAX_ACCEL_2D = 23.0     # Approximate max magnitude for two axes
    MAX_ACCEL_3D = 28.0     # Approximate max magnitude for three axes
    MAX_GYRO_1D = 2000.0    # Approximate max magnitude for one axis
    MAX_GYRO_2D = 2830.0    # Approximate max magnitude for two axes
    MAX_JERK = 10.0
    MAX_RAD_S = 60.0

    # 1. Unpack Axes (Slicing)
    ax = inputs[..., 0]
    ay = inputs[..., 1]
    az = inputs[..., 2]
    gx = inputs[..., 3]
    gy = inputs[..., 4]
    gz = inputs[..., 5]

    # 2. Channel Engineering
    # C1: Total Accel Magnitude
    acc_mag = tf.sqrt(tf.square(ax) + tf.square(ay) + tf.square(az) + 1e-6)

    # C2: Jerk (Derivative)
    # diff = current - previous
    diff = acc_mag[:, 1:] - acc_mag[:, :-1]
    # Pad to restore length to 40
    jerk = tf.pad(diff, [[0, 0], [1, 0]], "CONSTANT")
    jerk = tf.abs(jerk)

    # C3: Snap Gyro (Spin)
    snap_gyro = tf.abs(gx)

    # C4: Flow Gyro (Arm Swing)
    flow_gyro = tf.sqrt(tf.square(gy) + tf.square(gz) + 1e-6)

    # C5: Push Accel (Tangential)
    push_acc = tf.sqrt(tf.square(ay) + tf.square(az) + 1e-6)

    # C6: Centripetal Speed Proxy
    # w = sqrt(|ax| * 9.8 / r)
    ax_mps2 = tf.abs(ax) * GRAVITY
    est_speed = tf.sqrt((ax_mps2 / R_SENSOR) + 1e-6)

    # 3. Stack and Scale
    return tf.stack([
        acc_mag   / MAX_ACCEL_3D,
        jerk      / MAX_JERK,
        snap_gyro / MAX_GYRO_1D,
        flow_gyro / MAX_GYRO_2D,
        push_acc  / MAX_ACCEL_2D,
        est_speed / MAX_RAD_S
    ], axis=-1)
