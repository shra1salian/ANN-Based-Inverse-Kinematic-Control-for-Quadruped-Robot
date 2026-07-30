#!/usr/bin/env python3
"""
Raspberry Pi Controller for 3-DOF Robot Leg with ANN Inverse Kinematics
Receives target foot positions, predicts joint angles using ANN, sends to Arduino
"""

import numpy as np
import json
import serial
import time
import sys

class LegIKModel:
    """Simple feedforward neural network for inverse kinematics"""
    
    def __init__(self, model_path="model_for_python.json"):
        """Load model from JSON file"""
        print("Loading neural network model...")
        
        with open(model_path, 'r') as f:
            model_data = json.load(f)
        
        # Load weights
        self.W1 = np.array(model_data['weights']['W1'])
        self.b1 = np.array(model_data['weights']['b1']).reshape(-1, 1)
        self.W2 = np.array(model_data['weights']['W2'])
        self.b2 = np.array(model_data['weights']['b2']).reshape(-1, 1)
        self.W3 = np.array(model_data['weights']['W3'])
        self.b3 = np.array(model_data['weights']['b3']).reshape(-1, 1)
        
        # Load normalization parameters
        self.input_min = np.array(model_data['normalization']['input_min']).reshape(-1, 1)
        self.input_max = np.array(model_data['normalization']['input_max']).reshape(-1, 1)
        self.output_min = np.array(model_data['normalization']['output_min']).reshape(-1, 1)
        self.output_max = np.array(model_data['normalization']['output_max']).reshape(-1, 1)
        
        print("✓ Model loaded successfully")
        print(f"  Architecture: {self.W1.shape[1]} → {self.W1.shape[0]} → {self.W2.shape[0]} → {self.W3.shape[0]}")
    
    def normalize_input(self, x):
        """Normalize input to [-1, 1] range"""
        return 2 * (x - self.input_min) / (self.input_max - self.input_min) - 1
    
    def denormalize_output(self, y):
        """Denormalize output from [-1, 1] range"""
        return (y + 1) / 2 * (self.output_max - self.output_min) + self.output_min
    
    def tanh(self, x):
        """Hyperbolic tangent activation"""
        return np.tanh(x)
    
    def predict(self, x, y, z):
        """
        Predict joint angles from foot position
        
        Args:
            x, y, z: Foot position in mm
        
        Returns:
            theta1, theta2, theta3: Joint angles in degrees
        """
        # Prepare input
        input_vec = np.array([[x], [y], [z]])
        
        # Normalize
        input_norm = self.normalize_input(input_vec)
        
        # Forward pass
        hidden1 = self.tanh(np.dot(self.W1, input_norm) + self.b1)
        hidden2 = self.tanh(np.dot(self.W2, hidden1) + self.b2)
        output_norm = np.dot(self.W3, hidden2) + self.b3
        
        # Denormalize
        output = self.denormalize_output(output_norm)
        
        theta1, theta2, theta3 = output.flatten()
        return theta1, theta2, theta3


class ArduinoController:
    """Interface to Arduino for servo control"""
    
    def __init__(self, port='/dev/ttyACM0', baudrate=115200):
        """
        Initialize serial connection to Arduino
        
        Args:
            port: Serial port (usually /dev/ttyACM0 or /dev/ttyUSB0)
            baudrate: Communication speed
        """
        print(f"Connecting to Arduino on {port}...")
        
        try:
            self.serial = serial.Serial(port, baudrate, timeout=1)
            time.sleep(2)  # Wait for Arduino to reset
            print("✓ Connected to Arduino")
        except serial.SerialException as e:
            print(f"✗ Error connecting to Arduino: {e}")
            print("  Check:")
            print("  1. Arduino is connected via USB")
            print("  2. Correct port (try: ls /dev/tty*)")
            print("  3. User has permission (add to dialout group)")
            sys.exit(1)
    
    def send_angles(self, theta1, theta2, theta3):
        """
        Send joint angles to Arduino
        
        Protocol: "A1,A2,A3\n" where A1, A2, A3 are angles in degrees
        
        Args:
            theta1, theta2, theta3: Joint angles in degrees
        """
        # Format command
        command = f"{theta1:.2f},{theta2:.2f},{theta3:.2f}\n"
        
        # Send to Arduino
        self.serial.write(command.encode())
        
        # Wait for acknowledgment
        response = self.serial.readline().decode().strip()
        
        return response
    
    def close(self):
        """Close serial connection"""
        if self.serial.is_open:
            self.serial.close()
            print("✓ Serial connection closed")


class RobotLegController:
    """High-level controller combining IK model and Arduino interface"""
    
    def __init__(self, model_path="model_for_python.json", arduino_port='/dev/ttyACM0'):
        """Initialize controller"""
        print("=" * 60)
        print("3-DOF Robot Leg Controller - ANN-based Inverse Kinematics")
        print("=" * 60)
        print()
        
        # Load IK model
        self.model = LegIKModel(model_path)
        print()
        
        # Connect to Arduino
        self.arduino = ArduinoController(arduino_port)
        print()
        
        print("✓ System ready!")
        print()
    
    def move_to_position(self, x, y, z, verbose=True):
        """
        Move foot to target position
        
        Args:
            x, y, z: Target position in mm
            verbose: Print details
        
        Returns:
            success: True if successful
        """
        if verbose:
            print(f"Target position: ({x:.1f}, {y:.1f}, {z:.1f}) mm")
        
        # Predict joint angles using ANN
        theta1, theta2, theta3 = self.model.predict(x, y, z)
        
        if verbose:
            print(f"Predicted angles: θ1={theta1:.2f}°, θ2={theta2:.2f}°, θ3={theta3:.2f}°")
        
        # Send to Arduino
        response = self.arduino.send_angles(theta1, theta2, theta3)
        
        if verbose:
            print(f"Arduino response: {response}")
            print()
        
        return True
    
    def run_test_sequence(self):
        """Run a test sequence of positions"""
        print("=" * 60)
        print("Running Test Sequence")
        print("=" * 60)
        print()
        
        # Define test positions (x, y, z) in mm
        test_positions = [
            (150, 0, -150, "Center, medium height"),
            (100, 50, -100, "Forward-right, high"),
            (100, -50, -100, "Forward-left, high"),
            (200, 0, -200, "Far forward, low"),
            (150, 0, -150, "Return to center"),
        ]
        
        for i, (x, y, z, description) in enumerate(test_positions, 1):
            print(f"Position {i}/{len(test_positions)}: {description}")
            self.move_to_position(x, y, z)
            time.sleep(2)  # Wait 2 seconds between positions
        
        print("✓ Test sequence complete!")
        print()
    
    def interactive_mode(self):
        """Interactive mode - user enters positions manually"""
        print("=" * 60)
        print("Interactive Mode")
        print("=" * 60)
        print("Enter target positions as: x y z (in mm)")
        print("Example: 150 0 -150")
        print("Type 'test' to run test sequence")
        print("Type 'quit' to exit")
        print("=" * 60)
        print()
        
        while True:
            try:
                user_input = input("Enter position (x y z): ").strip().lower()
                
                if user_input == 'quit':
                    break
                elif user_input == 'test':
                    self.run_test_sequence()
                    continue
                
                # Parse input
                parts = user_input.split()
                if len(parts) != 3:
                    print("✗ Invalid input. Use format: x y z")
                    continue
                
                x, y, z = map(float, parts)
                self.move_to_position(x, y, z)
                
            except ValueError:
                print("✗ Invalid numbers. Try again.")
            except KeyboardInterrupt:
                print("\n\nInterrupted by user")
                break
            except Exception as e:
                print(f"✗ Error: {e}")
    
    def close(self):
        """Cleanup"""
        self.arduino.close()


def main():
    """Main entry point"""
    
    # Default parameters
    MODEL_PATH = "model_for_python.json"
    ARDUINO_PORT = "/dev/ttyACM0"  # Change if needed (try /dev/ttyUSB0)
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        ARDUINO_PORT = sys.argv[1]
    
    try:
        # Initialize controller
        controller = RobotLegController(MODEL_PATH, ARDUINO_PORT)
        
        # Choose mode
        print("Select mode:")
        print("  1. Test sequence (predefined positions)")
        print("  2. Interactive mode (manual input)")
        print()
        
        choice = input("Enter choice (1 or 2): ").strip()
        
        if choice == '1':
            controller.run_test_sequence()
        else:
            controller.interactive_mode()
        
    except KeyboardInterrupt:
        print("\n\nShutdown requested")
    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
    finally:
        # Cleanup
        try:
            controller.close()
        except:
            pass
        
        print("\nGoodbye!")


if __name__ == "__main__":
    main()
