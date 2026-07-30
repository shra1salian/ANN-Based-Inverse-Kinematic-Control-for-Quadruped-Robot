# 3-DOF Robot Leg - ANN-based Inverse Kinematics
## Complete Setup Guide

---

## 📋 Project Overview

This project validates an Artificial Neural Network (ANN) for inverse kinematics control of a 3-DOF quadruped robot leg using:
- **MATLAB**: Leg modeling, dataset generation, and ANN training
- **Raspberry Pi 4**: High-level controller running ANN inference
- **Arduino Uno**: Low-level servo control
- **MG995 Servos**: Physical actuation (3 servos)

---

## 🔧 Hardware Setup

### Components Required
- ✅ Raspberry Pi 4 Model B (with Ubuntu 22.04.5 LTS)
- ✅ Arduino Uno
- ✅ 3× MG995 Servo Motors
- 🔌 5-6V Power Supply (2-3A minimum) for servos
- 🔌 USB Cable (Raspberry Pi ↔ Arduino)
- 📦 Breadboard and jumper wires (optional, for cleaner connections)

### Wiring Diagram

```
SERVO CONNECTIONS TO ARDUINO:
┌─────────────────────────────────────┐
│ Servo 1 (Hip Ab/Ad)                 │
│   Signal → Arduino Pin 9            │
│   VCC    → External 5V Power (+)    │
│   GND    → External Power GND       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Servo 2 (Hip Flex/Ext)              │
│   Signal → Arduino Pin 10           │
│   VCC    → External 5V Power (+)    │
│   GND    → External Power GND       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Servo 3 (Knee)                      │
│   Signal → Arduino Pin 11           │
│   VCC    → External 5V Power (+)    │
│   GND    → External Power GND       │
└─────────────────────────────────────┘

IMPORTANT:
- Connect Arduino GND to External Power GND (common ground)
- DO NOT power servos from Arduino (insufficient current)
- Use separate 5-6V power supply rated for 2-3A minimum
```

### Power Supply Notes
⚠️ **CRITICAL**: MG995 servos draw significant current (up to 1A each under load). Never power them directly from Arduino's 5V pin - this will damage your Arduino!

---

## 💻 Software Setup

### Part 1: MATLAB (On Your PC)

#### Prerequisites
- MATLAB R2020a or later
- Deep Learning Toolbox (for neural networks)

#### Step 1: Run Leg Model & Generate Dataset

```matlab
% In MATLAB:
cd /path/to/project/folder
run('leg_model_and_dataset.m')
```

**What this does:**
- Models the 3-DOF leg kinematics
- Visualizes the leg in 3D
- Generates 50,000 training samples
- Creates files:
  - `leg_ik_dataset.csv` (dataset)
  - `leg_ik_dataset.mat` (MATLAB format)

**Expected output:**
- 3D visualization of leg
- Workspace visualization
- Console output showing dataset statistics

#### Step 2: Train the Neural Network

```matlab
% In MATLAB:
run('train_ann_model.m')
```

**What this does:**
- Loads dataset
- Trains feedforward neural network (3→64→64→3)
- Evaluates performance
- Creates files:
  - `trained_ik_model.mat` (complete model)
  - `model_weights.mat` (weights and biases)

**Expected performance:**
- Mean Absolute Error: < 1-2 degrees
- R² Score: > 0.99
- Training time: 1-3 minutes

#### Step 3: Export Model for Python

```matlab
% In MATLAB:
run('convert_model_to_python.m')
```

**What this does:**
- Exports model to JSON format
- Creates Python inference script
- Creates files:
  - `model_for_python.json` (model weights)
  - `leg_ik_inference.py` (Python inference code)

---

### Part 2: Arduino Setup

#### Step 1: Upload Code to Arduino

1. Open `arduino_servo_controller.ino` in Arduino IDE
2. Connect Arduino Uno via USB
3. Select: Tools → Board → Arduino Uno
4. Select: Tools → Port → (your Arduino port)
5. Click Upload (→ button)

#### Step 2: Verify Upload

Open Serial Monitor (Tools → Serial Monitor):
- Set baud rate to **115200**
- You should see: "Arduino 3-DOF Leg Controller Ready"

#### Step 3: Calibrate Servos (if needed)

If servos move in wrong direction or wrong range, edit these lines in Arduino code:

```cpp
// Servo 1 calibration
const float SERVO1_OFFSET = 90.0;   // Adjust center position
const float SERVO1_DIRECTION = 1.0; // Change to -1.0 to reverse

// Repeat for SERVO2 and SERVO3
```

Re-upload after changes.

---

### Part 3: Raspberry Pi Setup

#### Step 1: Install Python Dependencies

SSH into your Raspberry Pi:

```bash
ssh your_username@your_pi_ip_address
```

Install required packages:

```bash
# Update system
sudo apt update

# Install Python packages
pip3 install numpy pyserial

# Optional: For faster inference (recommended)
pip3 install tensorflow-lite-runtime
```

#### Step 2: Transfer Files to Raspberry Pi

From your PC, copy the Python files:

```bash
# Method 1: Using scp (from your PC)
scp model_for_python.json your_username@your_pi_ip:/home/your_username/
scp raspberry_pi_controller.py your_username@your_pi_ip:/home/your_username/

# Method 2: Using SFTP or FileZilla
# Use GUI tool to transfer files
```

#### Step 3: Connect Arduino to Raspberry Pi

1. Connect Arduino to Raspberry Pi via USB
2. Check connection:

```bash
ls /dev/tty*
# Look for /dev/ttyACM0 or /dev/ttyUSB0
```

3. Add user to dialout group (for serial access):

```bash
sudo usermod -a -G dialout $USER
# Log out and log back in for changes to take effect
```

#### Step 4: Test the Setup

```bash
# Navigate to project folder
cd ~

# Make script executable
chmod +x raspberry_pi_controller.py

# Run the controller
python3 raspberry_pi_controller.py
```

If Arduino is on different port:
```bash
python3 raspberry_pi_controller.py /dev/ttyUSB0
```

---

## 🎮 Usage

### Test Mode (Recommended for first run)

```bash
python3 raspberry_pi_controller.py
```

When prompted:
- Enter `1` for test sequence
- The leg will move through predefined positions
- Watch for smooth motion and correct angles

### Interactive Mode

```bash
python3 raspberry_pi_controller.py
```

When prompted:
- Enter `2` for interactive mode
- Type positions as: `x y z` (in mm)
- Example: `150 0 -150`

**Recommended test positions:**
```
150 0 -150    (center, medium height)
100 50 -100   (forward-right, high)
100 -50 -100  (forward-left, high)
200 0 -200    (far forward, low)
```

---

## 📊 Understanding the Leg Dimensions

Your leg has these dimensions (from your specs):

```
Hip Mount Offset (d₁) = 25.3 mm
Upper Leg Length (L₁) = 150 mm
Knee Joint Offset (d₂) = 35.5 mm
Lower Leg Length (L₂) = 150 mm
```

### Coordinate System

```
     Z (up)
     |
     |
     +---- X (forward)
    /
   Y (lateral/sideways)

Origin: Body attachment point
Foot position: (x, y, z) where z is negative (below origin)
```

### Approximate Workspace
- **X (forward/back)**: 0 to ~280 mm
- **Y (lateral)**: -100 to +100 mm  
- **Z (vertical)**: -50 to -300 mm (negative = below origin)

---

## 🐛 Troubleshooting

### Problem: "Permission denied" on serial port

**Solution:**
```bash
sudo usermod -a -G dialout $USER
# Then log out and back in
```

### Problem: Servos not moving

**Checklist:**
1. ✅ External power supply connected?
2. ✅ Common ground between Arduino and power supply?
3. ✅ Servo signal wires on correct pins (9, 10, 11)?
4. ✅ Arduino code uploaded successfully?
5. ✅ Serial communication working? (check Serial Monitor)

### Problem: Servo moves in wrong direction

**Solution:**
Edit Arduino code, change `DIRECTION` from `1.0` to `-1.0` (or vice versa)

### Problem: ANN predictions seem wrong

**Solution:**
1. Check if model file exists: `ls -l model_for_python.json`
2. Verify you're sending positions in mm, not meters
3. Ensure positions are within workspace limits
4. Re-train model if dataset was corrupted

### Problem: Jerky or slow servo movement

**Solution:**
1. Check power supply current rating (need 2-3A)
2. Add small delays between commands
3. Check for voltage drops under load

---

## 📈 Performance Metrics

### Expected ANN Performance
- **Training samples**: 50,000
- **Mean Absolute Error**: < 1-2 degrees
- **R² Score**: > 0.99
- **Inference time**: < 1 ms (on Raspberry Pi)

### System Latency
- **Total latency** (position → servo motion): ~50-100 ms
  - ANN inference: < 1 ms
  - Serial communication: ~10 ms
  - Servo response: 20-60 ms (depends on distance)

---

## 🔬 Validation Tests

### Test 1: Accuracy Test
Compare predicted vs actual foot positions:

1. Send known position to leg
2. Measure actual foot position (ruler/calipers)
3. Calculate error
4. Repeat for 10-20 positions

**Acceptable error**: < 5-10 mm for validation

### Test 2: Repeatability Test
1. Move to position A
2. Move to position B
3. Return to position A
4. Measure if foot returns to same position

**Acceptable variation**: < 2-3 mm

### Test 3: Workspace Coverage
Test positions across the entire workspace:
- Near limits (max reach)
- Center region
- Different height levels

---

## 📁 File Structure

```
project/
├── MATLAB Files (run on PC):
│   ├── leg_model_and_dataset.m      # Step 1: Model + dataset
│   ├── train_ann_model.m            # Step 2: Train network
│   └── convert_model_to_python.m    # Step 3: Export model
│
├── Generated Files:
│   ├── leg_ik_dataset.csv           # Training data
│   ├── trained_ik_model.mat         # MATLAB model
│   ├── model_for_python.json        # Python model (→ copy to Pi)
│   └── leg_ik_inference.py          # Inference script
│
├── Raspberry Pi Files:
│   ├── raspberry_pi_controller.py   # Main controller (→ copy to Pi)
│   └── model_for_python.json        # Model weights (→ copy to Pi)
│
└── Arduino Files:
    └── arduino_servo_controller.ino # Upload to Arduino
```

---

## 🎯 Next Steps

After successful validation:

1. **Tune performance:**
   - Adjust servo calibration for better accuracy
   - Optimize ANN architecture if needed
   - Add velocity/acceleration limits for smoother motion

2. **Expand to full quadruped:**
   - Replicate for 4 legs
   - Implement gait patterns
   - Add trajectory planning

3. **Advanced features:**
   - Real-time feedback (force sensors, IMU)
   - Closed-loop control
   - Terrain adaptation

---

## 📞 Support

If you encounter issues:

1. Check troubleshooting section above
2. Verify all connections (power, USB, servos)
3. Test each component separately:
   - Arduino: Use Serial Monitor
   - Raspberry Pi: Test Python script standalone
   - ANN: Verify predictions in MATLAB first

---

## 📝 Notes

- Always start with small movements to test calibration
- Keep an emergency stop ready (unplug power)
- MG995 servos have ~180° range; respect physical limits
- Model accuracy depends on quality of training data
- For best results, retrain model if you modify leg dimensions

---

**Good luck with your validation!** 🚀

If the system works well, you've successfully validated:
✅ ANN can learn inverse kinematics
✅ Real-time inference is fast enough
✅ Integration with hardware works
✅ Control architecture is sound
