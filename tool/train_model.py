"""
Mango Ripeness Classification Training Script (Fixed Clean Model Version)
--------------------------------------------------------------------------
Features:
- Pure MobileNetV2 architecture without standalone BatchNormalization on the head
  (prevents single-sample variance collapse during mobile TFLite inference).
- Anti-bias data augmentation with background equalization.
- Clean inference graph export and verification.
"""

import os
import sys
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, callbacks

# -------------------------------------------------------------
# Configuration
# -------------------------------------------------------------
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS_WARMUP = 8
EPOCHS_FINETUNE = 10
CLASS_NAMES = ['Unripe', 'Partially Ripe', 'Fully Ripe', 'Overripe']

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TRAIN_DIR = os.path.join(PROJECT_DIR, "Dataset", "Train")
TEST_DIR = os.path.join(PROJECT_DIR, "Dataset", "Test")
OUTPUT_MODEL_PATH = os.path.join(PROJECT_DIR, "assets", "models", "mango_classifier.tflite")
LABELS_PATH = os.path.join(PROJECT_DIR, "assets", "models", "labels.txt")


def check_directories():
    if not os.path.exists(TRAIN_DIR):
        print(f"Error: Train directory not found at: {TRAIN_DIR}")
        sys.exit(1)
    if not os.path.exists(TEST_DIR):
        print(f"Error: Test directory not found at: {TEST_DIR}")
        sys.exit(1)


def load_datasets():
    print("\nLoading datasets...")
    train_ds = tf.keras.utils.image_dataset_from_directory(
        TRAIN_DIR,
        labels='inferred',
        class_names=CLASS_NAMES,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        shuffle=True,
        seed=42,
    )

    test_ds = tf.keras.utils.image_dataset_from_directory(
        TEST_DIR,
        labels='inferred',
        class_names=CLASS_NAMES,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        shuffle=False,
    )

    val_size = max(1, int(0.15 * len(train_ds)))
    val_ds = train_ds.take(val_size)
    train_ds = train_ds.skip(val_size)

    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)
    test_ds = test_ds.prefetch(buffer_size=AUTOTUNE)

    return train_ds, val_ds, test_ds


class BackgroundEqualizer(layers.Layer):
    """
    Equalizes white background distribution so no single class claims white backgrounds.
    """
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def call(self, images, training=True):
        if not training:
            return images

        batch_size = tf.shape(images)[0]
        # Detect white pixels
        is_white = tf.reduce_all(images > 0.88, axis=-1, keepdims=True)

        # Replace white background with random warm/neutral table colors
        rand_r = tf.random.uniform([batch_size, 1, 1, 1], 0.3, 0.6)
        rand_g = tf.random.uniform([batch_size, 1, 1, 1], 0.25, 0.5)
        rand_b = tf.random.uniform([batch_size, 1, 1, 1], 0.15, 0.4)
        rand_bg = tf.concat([rand_r, rand_g, rand_b], axis=-1)

        replace_prob = tf.random.uniform([batch_size, 1, 1, 1], 0.0, 1.0)
        should_replace = tf.cast(replace_prob > 0.4, tf.float32) * tf.cast(is_white, tf.float32)
        images = images * (1.0 - should_replace) + rand_bg * should_replace

        # Randomly paint borders white for any class
        paint_prob = tf.random.uniform([batch_size, 1, 1, 1], 0.0, 1.0)
        should_paint = tf.cast(paint_prob > 0.7, tf.float32)

        h, w = IMAGE_SIZE
        y = tf.range(h, dtype=tf.float32)
        x = tf.range(w, dtype=tf.float32)
        Y, X = tf.meshgrid(y, x, indexing='ij')
        is_border = (Y < 20.0) | (Y > float(h - 21)) | (X < 20.0) | (X > float(w - 21))
        border_mask = tf.expand_dims(tf.expand_dims(tf.cast(is_border, tf.float32), 0), -1)

        images = images * (1.0 - should_paint * border_mask) + (1.0 * should_paint * border_mask)
        return images


def build_model():
    print("\nBuilding MobileNetV2 architecture...")
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.2),
        layers.RandomZoom(0.2),
        layers.RandomContrast(0.2),
        layers.RandomBrightness(0.2),
    ], name="data_augmentation")

    rescaling = layers.Rescaling(1.0 / 255.0, name="rescaling")
    bg_layer = BackgroundEqualizer(name="bg_equalizer")

    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(*IMAGE_SIZE, 3),
        include_top=False,
        weights='imagenet',
    )
    base_model.trainable = False

    inputs = layers.Input(shape=(*IMAGE_SIZE, 3), name="input_image")
    x = data_augmentation(inputs)
    x = rescaling(x)
    x = bg_layer(x)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D(name="global_avg_pool")(x)
    x = layers.Dropout(0.3, name="drop1")(x)
    x = layers.Dense(128, activation='relu', name="dense128")(x)
    x = layers.Dropout(0.2, name="drop2")(x)
    outputs = layers.Dense(len(CLASS_NAMES), activation='softmax', name="probabilities")(x)

    model = models.Model(inputs, outputs, name="mango_ripeness_detector")
    return model, base_model


def train():
    check_directories()
    train_ds, val_ds, test_ds = load_datasets()
    model, base_model = build_model()

    print("\n[Phase 1] Training classification head...")
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    callbacks_list = [
        callbacks.EarlyStopping(monitor='val_loss', patience=4, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=2),
    ]

    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_WARMUP,
        callbacks=callbacks_list,
    )

    print("\n[Phase 2] Fine-tuning MobileNetV2 base layers...")
    base_model.trainable = True
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_FINETUNE,
        callbacks=callbacks_list,
    )

    print("\nEvaluating on Test dataset...")
    test_loss, test_acc = model.evaluate(test_ds)
    print(f">> Final Test Accuracy: {test_acc * 100:.2f}% (Loss: {test_loss:.4f})")

    # Clean inference model for export (rescaling -> base_model -> pooling -> dense -> softmax)
    print(f"\nBuilding clean inference graph for TFLite export...")
    inf_in = layers.Input(shape=(*IMAGE_SIZE, 3), name="input_image")
    inf_x = layers.Rescaling(1.0 / 255.0)(inf_in)
    inf_x = base_model(inf_x, training=False)
    inf_x = model.get_layer("global_avg_pool")(inf_x)
    inf_x = model.get_layer("dense128")(inf_x)
    inf_out = model.get_layer("probabilities")(inf_x)

    inference_model = models.Model(inf_in, inf_out, name="mango_clean_inference")

    converter = tf.lite.TFLiteConverter.from_keras_model(inference_model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    os.makedirs(os.path.dirname(OUTPUT_MODEL_PATH), exist_ok=True)
    with open(OUTPUT_MODEL_PATH, "wb") as f:
        f.write(tflite_model)
    print(f"Exported TFLite model to: {OUTPUT_MODEL_PATH} ({len(tflite_model) / 1024:.1f} KB)")

    with open(LABELS_PATH, "w") as f:
        f.write("\n".join(CLASS_NAMES) + "\n")
    print(f"Updated labels file: {LABELS_PATH}")

    # Verify TFLite model with sample images
    interp = tf.lite.Interpreter(model_content=tflite_model)
    interp.allocate_tensors()
    inp_d = interp.get_input_details()
    out_d = interp.get_output_details()

    print("\nTFLite Verification on Class Samples:")
    from PIL import Image
    for c in CLASS_NAMES:
        d = os.path.join(TEST_DIR, c)
        if os.path.exists(d) and os.listdir(d):
            sample_f = os.listdir(d)[0]
            im = Image.open(os.path.join(d, sample_f)).resize(IMAGE_SIZE)
            arr = np.expand_dims(np.array(im, dtype=np.float32), 0)
            interp.set_tensor(inp_d[0]['index'], arr)
            interp.invoke()
            preds = interp.get_tensor(out_d[0]['index'])[0]
            best = CLASS_NAMES[np.argmax(preds)]
            print(f"  Sample {c:<14} -> Predicted: {best:<14} (probs: {preds.round(3)})")

    print("\nTraining complete and verified!")


if __name__ == "__main__":
    train()
