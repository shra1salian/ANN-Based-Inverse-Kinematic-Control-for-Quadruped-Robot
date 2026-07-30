%% Train ANN for Inverse Kinematics - 3-DOF Quadruped Leg
% Description: Trains a feedforward neural network to predict joint angles
%              from desired end-effector positions

clear all; close all; clc;

%% ===== LOAD DATASET =====
fprintf('===== Loading Dataset =====\n');
load('leg_ik_dataset.mat');

fprintf('Dataset loaded successfully!\n');
fprintf('  Samples: %d\n', length(x_data));
fprintf('  Inputs: (x, y, z) positions\n');
fprintf('  Outputs: (θ1, θ2, θ3) joint angles\n\n');

%% ===== PREPARE DATA =====
fprintf('===== Preparing Data =====\n');

% Inputs: end-effector positions (x, y, z)
inputs = [x_data, y_data, z_data]';  % 3 x N

% Outputs: joint angles (theta1, theta2, theta3)
outputs = [theta1_data, theta2_data, theta3_data]';  % 3 x N

% Normalize inputs (important for neural network training)
[inputs_norm, input_settings] = mapminmax(inputs);

% Normalize outputs
[outputs_norm, output_settings] = mapminmax(outputs);

fprintf('✓ Data normalized\n');
fprintf('  Input range after normalization: [%.2f, %.2f]\n', min(inputs_norm(:)), max(inputs_norm(:)));
fprintf('  Output range after normalization: [%.2f, %.2f]\n\n', min(outputs_norm(:)), max(outputs_norm(:)));

%% ===== SPLIT DATA (Train/Validation/Test) =====
% 70% training, 15% validation, 15% testing
train_ratio = 0.70;
val_ratio = 0.15;
test_ratio = 0.15;

fprintf('===== Splitting Dataset =====\n');
fprintf('  Training: %.0f%%\n', train_ratio*100);
fprintf('  Validation: %.0f%%\n', val_ratio*100);
fprintf('  Testing: %.0f%%\n\n', test_ratio*100);

%% ===== CREATE NEURAL NETWORK =====
fprintf('===== Creating Neural Network =====\n');

% Network architecture: 3 inputs → 64 → 64 → 3 outputs
hidden_layer1_size = 64;
hidden_layer2_size = 64;

net = fitnet([hidden_layer1_size, hidden_layer2_size], 'trainlm');

fprintf('Architecture:\n');
fprintf('  Input Layer: 3 neurons (x, y, z)\n');
fprintf('  Hidden Layer 1: %d neurons\n', hidden_layer1_size);
fprintf('  Hidden Layer 2: %d neurons\n', hidden_layer2_size);
fprintf('  Output Layer: 3 neurons (θ1, θ2, θ3)\n');
fprintf('  Training Algorithm: Levenberg-Marquardt\n\n');

% Configure training parameters
net.trainParam.epochs = 500;        % Maximum epochs
net.trainParam.goal = 1e-5;         % Performance goal
net.trainParam.max_fail = 20;       % Max validation failures
net.trainParam.showWindow = true;   % Show training GUI

% Setup data division
net.divideFcn = 'dividerand';       % Random division
net.divideParam.trainRatio = train_ratio;
net.divideParam.valRatio = val_ratio;
net.divideParam.testRatio = test_ratio;

% Activation functions
net.layers{1}.transferFcn = 'tansig';  % Hidden layer 1: tanh
net.layers{2}.transferFcn = 'tansig';  % Hidden layer 2: tanh
net.layers{3}.transferFcn = 'purelin'; % Output layer: linear

%% ===== TRAIN NETWORK =====
fprintf('===== Training Network =====\n');
fprintf('Training started... (this may take a few minutes)\n\n');

tic;
[net, tr] = train(net, inputs_norm, outputs_norm);
training_time = toc;

fprintf('\n✓ Training completed in %.2f seconds!\n\n', training_time);

%% ===== EVALUATE PERFORMANCE =====
fprintf('===== Evaluating Performance =====\n');

% Predict on entire dataset
predictions_norm = net(inputs_norm);

% Denormalize predictions
predictions = mapminmax('reverse', predictions_norm, output_settings);

% Calculate errors
errors = outputs - predictions;
abs_errors = abs(errors);

% Error statistics for each joint
fprintf('Mean Absolute Error (MAE) per joint:\n');
fprintf('  θ1: %.3f degrees\n', mean(abs_errors(1,:)));
fprintf('  θ2: %.3f degrees\n', mean(abs_errors(2,:)));
fprintf('  θ3: %.3f degrees\n', mean(abs_errors(3,:)));
fprintf('  Average: %.3f degrees\n\n', mean(abs_errors(:)));

fprintf('Root Mean Square Error (RMSE) per joint:\n');
fprintf('  θ1: %.3f degrees\n', sqrt(mean(errors(1,:).^2)));
fprintf('  θ2: %.3f degrees\n', sqrt(mean(errors(2,:).^2)));
fprintf('  θ3: %.3f degrees\n', sqrt(mean(errors(3,:).^2)));
fprintf('  Average: %.3f degrees\n\n', sqrt(mean(errors(:).^2)));

% R-squared (coefficient of determination)
SS_tot = sum((outputs - mean(outputs, 2)).^2, 2);
SS_res = sum(errors.^2, 2);
R_squared = 1 - SS_res ./ SS_tot;

fprintf('R² Score per joint:\n');
fprintf('  θ1: %.4f\n', R_squared(1));
fprintf('  θ2: %.4f\n', R_squared(2));
fprintf('  θ3: %.4f\n', R_squared(3));
fprintf('  Average: %.4f\n\n', mean(R_squared));

%% ===== VISUALIZE PREDICTIONS VS ACTUAL =====
figure('Name', 'Predictions vs Actual', 'Position', [100 100 1200 400]);

subplot(1,3,1);
scatter(outputs(1,:), predictions(1,:), 5, 'b', 'filled', 'MarkerFaceAlpha', 0.3);
hold on; 
plot([min(outputs(1,:)), max(outputs(1,:))], [min(outputs(1,:)), max(outputs(1,:))], 'r--', 'LineWidth', 2);
xlabel('Actual θ1 (degrees)');
ylabel('Predicted θ1 (degrees)');
title(sprintf('Joint 1 (Hip Ab/Ad) - R²=%.4f', R_squared(1)));
grid on; axis equal;

subplot(1,3,2);
scatter(outputs(2,:), predictions(2,:), 5, 'g', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
plot([min(outputs(2,:)), max(outputs(2,:))], [min(outputs(2,:)), max(outputs(2,:))], 'r--', 'LineWidth', 2);
xlabel('Actual θ2 (degrees)');
ylabel('Predicted θ2 (degrees)');
title(sprintf('Joint 2 (Hip Flex/Ext) - R²=%.4f', R_squared(2)));
grid on; axis equal;

subplot(1,3,3);
scatter(outputs(3,:), predictions(3,:), 5, 'm', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
plot([min(outputs(3,:)), max(outputs(3,:))], [min(outputs(3,:)), max(outputs(3,:))], 'r--', 'LineWidth', 2);
xlabel('Actual θ3 (degrees)');
ylabel('Predicted θ3 (degrees)');
title(sprintf('Joint 3 (Knee) - R²=%.4f', R_squared(3)));
grid on; axis equal;

%% ===== TEST ON NEW SAMPLE POSITIONS =====
fprintf('===== Testing on Sample Positions =====\n');

% Test positions (x, y, z) in mm
test_positions = [
    100, 50, -150;   % Forward, right, down
    150, 0, -200;    % Forward, center, down
    80, -30, -100;   % Forward, left, less down
];

fprintf('\nTest predictions:\n');
fprintf('%-25s | %-30s\n', 'Position (x,y,z) mm', 'Predicted Angles (θ1,θ2,θ3) deg');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:size(test_positions, 1)
    % Normalize input
    test_input = test_positions(i, :)';
    test_input_norm = mapminmax('apply', test_input, input_settings);
    
    % Predict
    pred_norm = net(test_input_norm);
    pred = mapminmax('reverse', pred_norm, output_settings);
    
    fprintf('(%6.1f, %6.1f, %6.1f) | (%6.2f, %6.2f, %6.2f)\n', ...
        test_positions(i,1), test_positions(i,2), test_positions(i,3), ...
        pred(1), pred(2), pred(3));
end

%% ===== SAVE TRAINED MODEL =====
fprintf('\n===== Saving Model =====\n');

% Save complete model with normalization settings
model_data.net = net;
model_data.input_settings = input_settings;
model_data.output_settings = output_settings;
model_data.leg_dimensions.d1 = d1;
model_data.leg_dimensions.L1 = L1;
model_data.leg_dimensions.d2 = d2;
model_data.leg_dimensions.L2 = L2;
model_data.joint_limits.theta1 = [theta1_min, theta1_max];
model_data.joint_limits.theta2 = [theta2_min, theta2_max];
model_data.joint_limits.theta3 = [theta3_min, theta3_max];
model_data.performance.mae = mean(abs_errors(:));
model_data.performance.rmse = sqrt(mean(errors(:).^2));
model_data.performance.r_squared = mean(R_squared);

save('trained_ik_model.mat', 'model_data');
fprintf('✓ Model saved to: trained_ik_model.mat\n');

% Export weights and biases for Python deployment
weights_biases.W1 = net.IW{1};  % Input to hidden layer 1
weights_biases.b1 = net.b{1};
weights_biases.W2 = net.LW{2,1}; % Hidden layer 1 to hidden layer 2
weights_biases.b2 = net.b{2};
weights_biases.W3 = net.LW{3,2}; % Hidden layer 2 to output
weights_biases.b3 = net.b{3};
weights_biases.input_min = input_settings.xmin;
weights_biases.input_max = input_settings.xmax;
weights_biases.output_min = output_settings.xmin;
weights_biases.output_max = output_settings.xmax;

save('model_weights.mat', 'weights_biases');
fprintf('✓ Weights exported to: model_weights.mat\n');

fprintf('\n========================================\n');
fprintf('TRAINING SUMMARY:\n');
fprintf('  Mean Absolute Error: %.3f degrees\n', model_data.performance.mae);
fprintf('  RMSE: %.3f degrees\n', model_data.performance.rmse);
fprintf('  R² Score: %.4f\n', model_data.performance.r_squared);
fprintf('  Training Time: %.2f seconds\n', training_time);
fprintf('\nNEXT STEPS:\n');
fprintf('1. Convert model to Python format (use convert_model_to_python.m)\n');
fprintf('2. Deploy on Raspberry Pi\n');
fprintf('3. Test with Arduino servo control\n');
fprintf('========================================\n');
