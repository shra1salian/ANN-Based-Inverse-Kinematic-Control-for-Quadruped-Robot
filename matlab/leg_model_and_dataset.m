%% 3-DOF Quadruped Leg - Forward Kinematics, Visualization & Dataset Generation
% Author: Generated for ANN-based Inverse Kinematics Project
% Description: Models a 3-DOF leg, visualizes it, and generates training dataset

clear all; close all; clc;

%% ===== LEG DIMENSIONS (in mm) =====
d1 = 25.3;   % Hip mount offset (lateral)
L1 = 150;    % Upper leg length (Hip to Knee)
d2 = 35.5;   % Knee joint offset
L2 = 150;    % Lower leg length (Knee to Foot)

%% ===== JOINT ANGLE LIMITS (in degrees) =====
% Define realistic servo limits for MG995
theta1_min = -45;  theta1_max = 45;   % Hip abduction/adduction
theta2_min = -90;  theta2_max = 90;   % Hip flexion/extension
theta3_min = -135; theta3_max = 0;    % Knee flexion (negative = bent)

%% ===== FORWARD KINEMATICS FUNCTION =====
function [x, y, z] = forward_kinematics(theta1, theta2, theta3, d1, L1, d2, L2)
    % Convert degrees to radians
    th1 = deg2rad(theta1);
    th2 = deg2rad(theta2);
    th3 = deg2rad(theta3);
    
    % --- Corrected Kinematics ---
    % We calculate the reach in the leg's local 2D plane first:
    local_x = L1*sin(th2) + L2*sin(th2 + th3);
    local_z = -(L1*cos(th2) + L2*cos(th2 + th3));
    
    % Now we project that into 3D space and apply the offsets:
    % d1 is the hip offset, d2 is the knee/shank lateral offset.
    x = local_x * cos(th1);
    y = local_x * sin(th1) + (d1 + d2*cos(th1)); % Offset d2 follows the hip rotation
    z = local_z;
end

%% ===== VISUALIZE SAMPLE LEG POSE =====
fprintf('===== Visualizing Sample Leg Configuration =====\n');

% Sample angles (in degrees)
sample_theta1 = 0;
sample_theta2 = 45;
sample_theta3 = -90;

% Calculate joint positions for visualization
th1 = deg2rad(sample_theta1);
th2 = deg2rad(sample_theta2);
th3 = deg2rad(sample_theta3);

% Joint positions for plotting
hip_pos = [0, d1, 0];

% Knee (End of L1)
knee_x = L1*sin(th2) * cos(th1);
knee_y = L1*sin(th2) * sin(th1) + d1;
knee_z = -L1*cos(th2);
knee_pos = [knee_x, knee_y, knee_z];

% Ankle (Adding the lateral offset d2)
ankle_x = knee_x; 
ankle_y = knee_y + d2*cos(th1); 
ankle_z = knee_z;
ankle_pos = [ankle_x, ankle_y, ankle_z];

% Foot (End of L2)
[foot_x, foot_y, foot_z] = forward_kinematics(sample_theta1, sample_theta2, sample_theta3, d1, L1, d2, L2);
foot_pos = [foot_x, foot_y, foot_z];

% Plot the leg
figure('Name', '3-DOF Leg Visualization', 'Position', [100 100 800 600]);
hold on; grid on; axis equal;

% Plot links
plot3([0, hip_pos(1)], [0, hip_pos(2)], [0, hip_pos(3)], 'k-', 'LineWidth', 3); % Body to hip
plot3([hip_pos(1), knee_pos(1)], [hip_pos(2), knee_pos(2)], [hip_pos(3), knee_pos(3)], 'b-', 'LineWidth', 4);
plot3([knee_pos(1), ankle_pos(1)], [knee_pos(2), ankle_pos(2)], [knee_pos(3), ankle_pos(3)], 'c-', 'LineWidth', 2);
plot3([ankle_pos(1), foot_pos(1)], [ankle_pos(2), foot_pos(2)], [ankle_pos(3), foot_pos(3)], 'r-', 'LineWidth', 4);

% Plot joints
plot3(0, 0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); % Body origin
plot3(hip_pos(1), hip_pos(2), hip_pos(3), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r'); % Hip
plot3(knee_pos(1), knee_pos(2), knee_pos(3), 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g'); % Knee
plot3(ankle_pos(1), ankle_pos(2), ankle_pos(3), 'co', 'MarkerSize', 10, 'MarkerFaceColor', 'c'); % Ankle
plot3(foot_pos(1), foot_pos(2), foot_pos(3), 'mo', 'MarkerSize', 14, 'MarkerFaceColor', 'm'); % Foot

% Labels and formatting
xlabel('X (mm) - Forward/Backward');
ylabel('Y (mm) - Lateral');
zlabel('Z (mm) - Vertical');
title(sprintf('3-DOF Leg: θ1=%.1f°, θ2=%.1f°, θ3=%.1f°', sample_theta1, sample_theta2, sample_theta3));
legend('Body-Hip', 'Upper Leg (L1)', 'Knee Offset', 'Lower Leg (L2)', 'Origin', 'Hip', 'Knee', 'Ankle', 'Foot', 'Location', 'best');
view(45, 20);

fprintf('Sample configuration:\n');
fprintf('  θ1 = %.1f°, θ2 = %.1f°, θ3 = %.1f°\n', sample_theta1, sample_theta2, sample_theta3);
fprintf('  Foot position: (%.2f, %.2f, %.2f) mm\n\n', foot_x, foot_y, foot_z);

%% ===== GENERATE TRAINING DATASET =====
fprintf('===== Generating Training Dataset =====\n');

% Number of samples
num_samples = 50000;

% Pre-allocate arrays
theta1_data = zeros(num_samples, 1);
theta2_data = zeros(num_samples, 1);
theta3_data = zeros(num_samples, 1);
x_data = zeros(num_samples, 1);
y_data = zeros(num_samples, 1);
z_data = zeros(num_samples, 1);

% Generate random valid joint angles
fprintf('Generating %d samples...\n', num_samples);
for i = 1:num_samples
    % Random joint angles within limits
    theta1 = theta1_min + (theta1_max - theta1_min) * rand();
    theta2 = theta2_min + (theta2_max - theta2_min) * rand();
    theta3 = theta3_min + (theta3_max - theta3_min) * rand();
    
    % Calculate forward kinematics
    [x, y, z] = forward_kinematics(theta1, theta2, theta3, d1, L1, d2, L2);
    
    % Store data
    theta1_data(i) = theta1;
    theta2_data(i) = theta2;
    theta3_data(i) = theta3;
    x_data(i) = x;
    y_data(i) = y;
    z_data(i) = z;
    
    if mod(i, 10000) == 0
        fprintf('  Progress: %d/%d samples\n', i, num_samples);
    end
end

%% ===== SAVE DATASET =====
% Create dataset table
dataset = table(x_data, y_data, z_data, theta1_data, theta2_data, theta3_data, ...
    'VariableNames', {'x_mm', 'y_mm', 'z_mm', 'theta1_deg', 'theta2_deg', 'theta3_deg'});

% Save as CSV
csv_filename = 'leg_ik_dataset.csv';
writetable(dataset, csv_filename);
fprintf('\n✓ Dataset saved to: %s\n', csv_filename);

% Save as MAT file (for MATLAB training)
mat_filename = 'leg_ik_dataset.mat';
save(mat_filename, 'x_data', 'y_data', 'z_data', 'theta1_data', 'theta2_data', 'theta3_data', ...
     'd1', 'L1', 'd2', 'L2', 'theta1_min', 'theta1_max', 'theta2_min', 'theta2_max', 'theta3_min', 'theta3_max');
fprintf('✓ Dataset saved to: %s\n', mat_filename);

%% ===== DATASET STATISTICS =====
fprintf('\n===== Dataset Statistics =====\n');
fprintf('Total samples: %d\n', num_samples);
fprintf('\nJoint Angles (degrees):\n');
fprintf('  θ1: [%.1f, %.1f] → Range used: [%.1f, %.1f]\n', theta1_min, theta1_max, min(theta1_data), max(theta1_data));
fprintf('  θ2: [%.1f, %.1f] → Range used: [%.1f, %.1f]\n', theta2_min, theta2_max, min(theta2_data), max(theta2_data));
fprintf('  θ3: [%.1f, %.1f] → Range used: [%.1f, %.1f]\n', theta3_min, theta3_max, min(theta3_data), max(theta3_data));
fprintf('\nEnd-effector Position (mm):\n');
fprintf('  X: [%.2f, %.2f]\n', min(x_data), max(x_data));
fprintf('  Y: [%.2f, %.2f]\n', min(y_data), max(y_data));
fprintf('  Z: [%.2f, %.2f]\n', min(z_data), max(z_data));

%% ===== VISUALIZE WORKSPACE =====
fprintf('\n===== Visualizing Reachable Workspace =====\n');

% Sample subset for visualization (plotting all points is slow)
sample_indices = randperm(num_samples, min(5000, num_samples));

figure('Name', 'Reachable Workspace', 'Position', [150 150 800 600]);
scatter3(x_data(sample_indices), y_data(sample_indices), z_data(sample_indices), 1, 'b', 'filled', 'MarkerFaceAlpha', 0.3);
hold on; grid on; axis equal;
plot3(0, 0, 0, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r'); % Origin
xlabel('X (mm) - Forward/Backward');
ylabel('Y (mm) - Lateral');
zlabel('Z (mm) - Vertical');
title('3-DOF Leg Reachable Workspace');
view(45, 20);

fprintf('\n✓ All visualizations complete!\n');
fprintf('\n========================================\n');
fprintf('NEXT STEPS:\n');
fprintf('1. Run "train_ann_model.m" to train the neural network\n');
fprintf('2. Export model for Raspberry Pi deployment\n');
fprintf('========================================\n');
