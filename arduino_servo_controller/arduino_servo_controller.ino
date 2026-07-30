/*
 * Arduino Uno - 3-DOF Robot Leg Servo Controller
 * 
 * Receives joint angles from Raspberry Pi via Serial
 * Controls 3 MG995 servos
 * 
 * Protocol: "theta1,theta2,theta3\n" (angles in degrees)
 * Example: "45.00,30.50,-90.25\n"
 */

#include <Servo.h>

// ===== SERVO OBJECTS =====
Servo servo1;  // Hip abduction/adduction (Joint 1)
Servo servo2;  // Hip flexion/extension (Joint 2)
Servo servo3;  // Knee flexion (Joint 3)

// ===== SERVO PIN ASSIGNMENTS =====
const int SERVO1_PIN = 9;   // PWM pin for servo 1
const int SERVO2_PIN = 10;  // PWM pin for servo 2
const int SERVO3_PIN = 11;  // PWM pin for servo 3

// ===== SERVO CALIBRATION =====
// Adjust these values to match your physical servo orientations
// Format: servo_angle = OFFSET + DIRECTION * joint_angle

// Servo 1 (Hip Ab/Ad) calibration
const float SERVO1_OFFSET = 90.0;   // Center position (degrees)
const float SERVO1_DIRECTION = -1.0; // 1.0 or -1.0 to reverse direction

// Servo 2 (Hip Flex/Ext) calibration
const float SERVO2_OFFSET = 90.0;
const float SERVO2_DIRECTION = -1.0;

// Servo 3 (Knee) calibration
const float SERVO3_OFFSET = 0.0;
const float SERVO3_DIRECTION = -1.0;  // Often reversed

// ===== JOINT ANGLE LIMITS (safety) =====
const float THETA1_MIN = -90.0; 
const float THETA1_MAX = 90.0;
const float THETA2_MIN = -90.0;
const float THETA2_MAX = 90.0;
const float THETA3_MIN = -175.0;
const float THETA3_MAX = 0.0;

// ===== SERVO ANGLE LIMITS (hardware limits) =====
const int SERVO_MIN = 0;
const int SERVO_MAX = 180;

// ===== COMMUNICATION SETTINGS =====
const long BAUD_RATE = 115200;
const int SERIAL_TIMEOUT = 1000;  // ms

// ===== GLOBAL VARIABLES =====
float current_theta1 = 0.0;
float current_theta2 = 0.0;
float current_theta3 = 0.0;

String inputString = "";
boolean stringComplete = false;

// ===== SETUP =====
void setup() {
  // Initialize serial communication
  Serial.begin(BAUD_RATE);
  Serial.setTimeout(SERIAL_TIMEOUT);
  
  // Attach servos to pins
  servo1.attach(SERVO1_PIN);
  servo2.attach(SERVO2_PIN);
  servo3.attach(SERVO3_PIN);
  
  // Move to neutral position
  moveToNeutral();
  
  // Reserve buffer for input string
  inputString.reserve(50);
  
  // Startup message
  Serial.println("Arduino 3-DOF Leg Controller Ready");
  Serial.println("Waiting for commands...");
}

// ===== MAIN LOOP =====
void loop() {
  // Check for incoming serial data
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command.length() > 0) {
      processCommand(command);
    }
  }
}

// ===== PROCESS INCOMING COMMAND =====
void processCommand(String command) {
  // Parse command: "theta1,theta2,theta3"
  float theta1, theta2, theta3;
  
  if (parseAngles(command, theta1, theta2, theta3)) {
    // Check if angles are within safe limits
    if (validateAngles(theta1, theta2, theta3)) {
      // Move servos
      moveServos(theta1, theta2, theta3);
      
      // Send acknowledgment
      Serial.print("OK: ");
      Serial.print(theta1, 2);
      Serial.print(",");
      Serial.print(theta2, 2);
      Serial.print(",");
      Serial.println(theta3, 2);
    } else {
      Serial.println("ERROR: Angles out of range");
    }
  } else {
    Serial.println("ERROR: Invalid command format");
  }
}

// ===== PARSE ANGLE VALUES FROM STRING =====
boolean parseAngles(String command, float &theta1, float &theta2, float &theta3) {
  int comma1 = command.indexOf(',');
  int comma2 = command.indexOf(',', comma1 + 1);
  
  if (comma1 == -1 || comma2 == -1) {
    return false;
  }
  
  String str1 = command.substring(0, comma1);
  String str2 = command.substring(comma1 + 1, comma2);
  String str3 = command.substring(comma2 + 1);
  
  theta1 = str1.toFloat();
  theta2 = str2.toFloat();
  theta3 = str3.toFloat();
  
  return true;
}

// ===== VALIDATE ANGLES AGAINST LIMITS =====
boolean validateAngles(float theta1, float theta2, float theta3) {
  if (theta1 < THETA1_MIN || theta1 > THETA1_MAX) return false;
  if (theta2 < THETA2_MIN || theta2 > THETA2_MAX) return false;
  if (theta3 < THETA3_MIN || theta3 > THETA3_MAX) return false;
  return true;
}

// ===== MOVE SERVOS TO JOINT ANGLES =====
void moveServos(float theta1, float theta2, float theta3) {
  // Convert joint angles to servo angles using calibration
  int servo1_angle = jointToServoAngle(theta1, SERVO1_OFFSET, SERVO1_DIRECTION);
  int servo2_angle = jointToServoAngle(theta2, SERVO2_OFFSET, SERVO2_DIRECTION);
  int servo3_angle = jointToServoAngle(theta3, SERVO3_OFFSET, SERVO3_DIRECTION);
  
  // Constrain to servo limits
  servo1_angle = constrain(servo1_angle, SERVO_MIN, SERVO_MAX);
  servo2_angle = constrain(servo2_angle, SERVO_MIN, SERVO_MAX);
  servo3_angle = constrain(servo3_angle, SERVO_MIN, SERVO_MAX);
  
  // Write to servos
  servo1.write(servo1_angle);
  servo2.write(servo2_angle);
  servo3.write(servo3_angle);
  
  // Update current angles
  current_theta1 = theta1;
  current_theta2 = theta2;
  current_theta3 = theta3;
  
  // Small delay for servo movement
  delay(200);
}

// ===== CONVERT JOINT ANGLE TO SERVO ANGLE =====
int jointToServoAngle(float joint_angle, float offset, float direction) {
  return (int)(offset + direction * joint_angle);
}

// ===== MOVE TO NEUTRAL POSITION =====
void moveToNeutral() {
  Serial.println("Moving to neutral position...");
  
  // Neutral position (all joints at 0 degrees)
  moveServos(0.0, 0.0, 0.0);
  
  delay(500);
  Serial.println("Neutral position reached");
}

// ===== UTILITY: PRINT CURRENT STATE =====
void printCurrentState() {
  Serial.print("Current angles: θ1=");
  Serial.print(current_theta1, 2);
  Serial.print("°, θ2=");
  Serial.print(current_theta2, 2);
  Serial.print("°, θ3=");
  Serial.print(current_theta3, 2);
  Serial.println("°");
}
