# Quick Reference Card - 3-DOF Robot Leg Control

## 🚀 Quick Start (After Initial Setup)

### 1. Power On
```bash
# 1. Connect external power to servos (5-6V, 2-3A)
# 2. Connect Arduino to Raspberry Pi via USB
# 3. SSH into Raspberry Pi
ssh your_username@your_pi_ip
```

### 2. Run Controller
```bash
cd ~
python3 raspberry_pi_controller.py

# If different port:
python3 raspberry_pi_controller.py /dev/ttyUSB0
```

### 3. Choose Mode
- Press `1` for **Test Sequence** (automatic demo)
- Press `2` for **Interactive Mode** (manual control)

---

## 📍 Coordinate System

```
     Z (↑ up)
     |
     |
     +---- X (→ forward)
    /
   Y (← lateral)
```

- **Origin**: Body attachment point  
- **Units**: millimeters (mm)
- **Z**: Negative values (foot is below origin)

---

## 🎯 Safe Test Positions

Copy-paste these into interactive mode:

```
150 0 -150     # Center, medium height (SAFE START)
100 50 -100    # Forward-right, high
100 -50 -100   # Forward-left, high  
200 0 -200     # Far forward, low
120 0 -180     # Slightly forward, medium-low
```

---

## 🔧 Common Commands

### Check Arduino Connection
```bash
ls /dev/tty*
# Look for /dev/ttyACM0 or /dev/ttyUSB0
```

### Test Serial Communication
```bash
# Open screen to Arduino
screen /dev/ttyACM0 115200
# Type: 0,0,0
# Should see: OK: 0.00,0.00,0.00

# Exit screen: Ctrl+A, then K, then Y
```

### Check Python Installation
```bash
python3 --version
pip3 list | grep numpy
pip3 list | grep pyserial
```

---

## ⚡ Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Permission denied | `sudo chmod 666 /dev/ttyACM0` |
| No servo movement | Check external power supply |
| Wrong direction | Edit Arduino code: change `DIRECTION` sign |
| Jerky motion | Reduce power supply load / add capacitor |
| Model not found | `ls model_for_python.json` to verify |
| Pi can't connect | Check USB cable / try different port |

---

## 🔄 Typical Workflow

```
1. Power on hardware
2. SSH into Pi
3. Run: python3 raspberry_pi_controller.py
4. Test mode 1 (verify system works)
5. Switch to mode 2 (manual testing)
6. Enter positions
7. Ctrl+C to exit
8. Power off
```

---

## 📏 Leg Specifications

```
Hip Offset (d₁):    25.3 mm
Upper Leg (L₁):     150 mm
Knee Offset (d₂):   35.5 mm
Lower Leg (L₂):     150 mm

Joint Limits:
  θ₁: -45° to +45°   (Hip lateral)
  θ₂: -90° to +90°   (Hip front/back)
  θ₃: -135° to 0°    (Knee)
```

---

## 🎨 MATLAB Workflow (On PC)

### One-time Setup:
```matlab
% Step 1: Generate dataset
run('leg_model_and_dataset.m')

% Step 2: Train model
run('train_ann_model.m')

% Step 3: Export to Python
run('convert_model_to_python.m')

% Step 4: Transfer to Pi
% Copy model_for_python.json to Raspberry Pi
```

### Re-training (if needed):
```matlab
% Just run steps 2-4 again
run('train_ann_model.m')
run('convert_model_to_python.m')
% Re-copy model_for_python.json to Pi
```

---

## 🔌 Pin Connections

```
Arduino Pin 9  → Servo 1 Signal (Hip Ab/Ad)
Arduino Pin 10 → Servo 2 Signal (Hip Flex/Ext)
Arduino Pin 11 → Servo 3 Signal (Knee)

All Servos:
  VCC → External 5V Power (+)
  GND → External Power GND + Arduino GND
```

---

## 🛡️ Safety Checklist

Before each run:
- [ ] External power supply connected (5-6V, 2A+)
- [ ] Common ground established
- [ ] USB cable secure (Pi ↔ Arduino)
- [ ] Leg has clearance to move
- [ ] Emergency stop ready (power switch)
- [ ] Start with conservative positions

---

## 📊 Expected Performance

- **ANN Inference Time**: < 1 ms
- **Serial Latency**: ~10 ms  
- **Servo Response**: 20-60 ms
- **Total Latency**: 50-100 ms
- **Position Accuracy**: ±1-2 degrees
- **Spatial Error**: < 5-10 mm

---

## 💾 Important Files

**On Raspberry Pi:**
- `raspberry_pi_controller.py` - Main controller
- `model_for_python.json` - ANN model weights

**On Arduino:**
- `arduino_servo_controller.ino` - Servo control

**On PC (MATLAB):**
- `leg_model_and_dataset.m` - Modeling
- `train_ann_model.m` - Training
- `convert_model_to_python.m` - Export

---

## 📝 Quick Notes Space

```
My Arduino port: _______________
My Pi IP address: _______________
Servo calibration notes:
  Servo 1 direction: _____
  Servo 2 direction: _____
  Servo 3 direction: _____

Working positions I've tested:
1. _________________________
2. _________________________
3. _________________________

Issues encountered:
_________________________________
_________________________________
```

---

## 🎓 Understanding the System

**How it works:**
```
Target Position (x,y,z)
    ↓
Neural Network (3→64→64→3)
    ↓
Joint Angles (θ₁,θ₂,θ₃)
    ↓
Serial Communication
    ↓
Arduino → Servos → Leg Movement
```

**Why this approach:**
- ✅ Fast inference (< 1ms)
- ✅ No analytical IK needed
- ✅ Handles complex geometries
- ✅ Generalizes across workspace
- ✅ Easy to deploy

---

**Keep this card handy for daily use!** 📌
