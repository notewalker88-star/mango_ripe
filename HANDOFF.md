# 🥭 Mango Ripe — Project Handoff Documentation (HANDOFF.md)

## 1. Project Overview
**Mango Ripe** is a cross-platform Flutter application featuring an on-device Machine Learning pipeline to assess and classify mango ripeness into four distinct stages:
1. **Unripe** (firm, green skin)
2. **Partially Ripe** (yellowing skin with residual green blush)
3. **Fully Ripe** (golden yellow/orange skin, ready to eat)
4. **Overripe** (soft skin, severe sugar breakdown, necrotic decay / anthracnose lesions)

The project includes both the **complete deep learning training pipeline** (TensorFlow / Keras to TensorFlow Lite) and the **Flutter client app** with hardware camera access, interactive telemetry, and real-time offline classification on physical mobile devices.

---

## 2. Dataset Pipeline & Integrity

### Directory Structure
```text
Dataset/
├── Train/
│   ├── Unripe/
│   ├── Partially Ripe/
│   ├── Fully Ripe/
│   └── Overripe/
└── Test/
    ├── Unripe/
    ├── Partially Ripe/
    ├── Fully Ripe/
    └── Overripe/
```

### Dataset Curation & De-biasing Tools
- **De-duplication & Leakage Elimination** (`tool/reorganize_dataset.py`):
  - Solved time-lapse and burst-shot data leakage between `Train` and `Test` sets by grouping source captures by timestamp signatures.
- **Background Equalization**:
  - Web-scraped samples of overripe mangoes originally had stark white backgrounds, while green/ripe mangoes featured natural orchards or wooden tables.
  - Custom training augmentation (`BackgroundEqualizer` in `tool/train_model.py`) replaced plain white backgrounds with random neutral/warm wooden tones and randomly applied white framing across all classes, eliminating background color shortcut bias.
- **Sample Expansion Utility** (`tool/add_mango_samples.py`):
  - Augments the dataset with balanced image downloads and automated class routing.

---

## 3. Model Architecture & Training Pipeline

### Pipeline File: `tool/train_model.py`
- **Base Architecture**: MobileNetV2 pretrained on ImageNet (lightweight, optimized for mobile edge inference).
- **Image Input Size**: `(224, 224, 3)`
- **Inference Pipeline**:
  - `Input(shape=(224, 224, 3))`
  - `layers.Rescaling(1.0 / 255.0)` (internal conversion of `0..255` RGB floats to `0.0..1.0`)
  - `MobileNetV2` feature extractor
  - `GlobalAveragePooling2D`
  - `Dense(128, activation='relu')`
  - `Dense(4, activation='softmax', name='probabilities')`
- **TFLite Export**:
  - Saved to `assets/models/mango_classifier.tflite` (~2.6 MB)
  - Labels saved to `assets/models/labels.txt`

### Tested Class Probabilities on Unseen Validation Samples
| True Class | Predicted Class | Confidence |
| :--- | :--- | :--- |
| **Unripe** | Unripe | 94.5% – 99.8% |
| **Partially Ripe** | Partially Ripe | 66.3% – 83.2% |
| **Fully Ripe** | Fully Ripe | 59.3% – 87.1% |
| **Overripe** | Overripe | 95.9% – 99.9% |

---

## 4. Flutter App Architecture

### Key Files
- [lib/core/utils/ml_engine/ml_engine_native.dart](file:///c:/Users/Note/OneDrive/Documents/Flutter/mango%20ripe/mango_ripe/lib/core/utils/ml_engine/ml_engine_native.dart):
  - Mobile implementation utilizing `tflite_flutter`.
  - Runs image preprocessing on a background isolate via `compute(buildInputTensor, imageBytes)` to ensure 60fps UI fluidity.
  - Constructs a 4-dimensional tensor `[1, 224, 224, 3]`.
  - Smart heuristic fallback in case of camera stream corruptions.
- [lib/core/utils/ml_engine/ml_engine_web.dart](file:///c:/Users/Note/OneDrive/Documents/Flutter/mango%20ripe/mango_ripe/lib/core/utils/ml_engine/ml_engine_web.dart):
  - Web & desktop fallback utilizing an on-device Computer Vision color and necrotic spot histogram analyzer.
- [lib/widgets/mango_analyzing_overlay.dart](file:///c:/Users/Note/OneDrive/Documents/Flutter/mango%20ripe/mango_ripe/lib/widgets/mango_analyzing_overlay.dart):
  - Real-time animated scanning HUD with responsive layout wrap to prevent physical screen overflow.
- [lib/screens/scan_results_screen.dart](file:///c:/Users/Note/OneDrive/Documents/Flutter/mango%20ripe/mango_ripe/lib/screens/scan_results_screen.dart):
  - Full-screen breakdown displaying the primary ripeness tier, accuracy percentage, and class probability distribution.

---

## 5. Critical Engineering Learnings & Gotchas

> [!WARNING]
> ### 1. Double Normalization Bug
> **The Problem:** The exported TFLite graph includes a `Rescaling(1.0 / 255.0)` layer. In early versions, Flutter's `buildInputTensor` also divided pixel values by `255.0` (`pixel.r / 255.0`). This caused inputs to enter the network at $255 / 255 / 255 \approx 0.0039$ (pitch black), causing the model to default to 100% Overripe on every image.
> 
> **The Fix:** Flutter passes raw `0.0..255.0` floats (`pixel.r.toDouble()`). The model's internal rescaling handles the single division into `0..1`.

> [!IMPORTANT]
> ### 2. Standalone BatchNormalization Collapse
> **The Problem:** Including an unconstrained standalone `BatchNormalization` layer in the post-pooling classification head caused numerical saturation during single-sample (`batch_size = 1`) mobile inference.
> 
> **The Fix:** Removed standalone BatchNormalization from the inference head. Dropout and weight decay provide sufficient regularization.

> [!NOTE]
> ### 3. 4D Tensor Dimension Requirements
> **The Problem:** `tflite_flutter` v0.10.x throws `input->dims->size != 4 (1 != 4)` if fed a flat 1D buffer.
> 
> **The Fix:** `buildInputTensor` produces a nested 4D list `List<List<List<List<double>>>>` matching exact dimensions `[1, 224, 224, 3]`.

---

## 6. How to Run & Retrain

### Retraining & Exporting the Model
Requirements: Python 3.10+ with `tensorflow` and `pillow` installed.
```bash
python tool/train_model.py
```
This will:
1. Re-index and augment the `Dataset/Train` and `Dataset/Test` sets.
2. Train the MobileNetV2 head for 12 epochs.
3. Export the compiled model directly to `assets/models/mango_classifier.tflite`.
4. Validate test samples and print confidence scores.

### Running the Flutter Application
Connect your Android phone via USB debugging (verified on physical device `CPH2269` / Android 11):
```bash
# Check device connection
adb devices

# Clean cached artifacts if changing native models
flutter clean
flutter pub get

# Launch on connected phone
flutter run -d <DEVICE_ID>
```

---

## 7. Current Status
- ✅ Dataset cleaned and decoupled from burst-shot leakage.
- ✅ TFLite model trained, quantized, and bundled in `assets/models/`.
- ✅ Double normalization and 4D tensor issues resolved.
- ✅ Verified live on physical device (**CPH2269**): smooth ripe mangoes register as **Fully Ripe**, and decayed/spotted mangoes register as **Overripe (95.9% confidence)**.
