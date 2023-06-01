clc; clear; close all

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["time", "pair1", "pair2", "pair3", "pair4"];
opts.VariableTypes = ["double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the voltage time series data
ts_voltage = readtable("signal.csv", opts);

% Clear temporary variables
clear opts

%% Extract true signal and plot

figure()

% array to store converted 0s and 1s from channel signal voltages
decoded_channels = zeros(length(ts_voltage.time), 4);

% convert table to array for easier access
array_voltage = table2array(ts_voltage);

% convert voltage signal to 0s and 1s
for i = 1:4
    for j = 1:length(ts_voltage.time)
        % if voltage < 1.2 -> convert to 0
        if array_voltage(j, i+1) < 1.2
            decoded_channels(j, i) = 0; 
        % if voltage > 2.2 -> convert to 1
        elseif array_voltage(j, i+1) > 2.2
            decoded_channels(j, i) = 1; 
        end
    end

    % draw subplot
    subplot(2, 2, i)
    plot(ts_voltage.time, decoded_channels(:, i), 'LineWidth', 1.5)
    xlabel('time (seconds)')
    ylabel('logic value')
    title(['true signal - channel #', num2str(i)])
    ylim([-0.5, 1.5])
    yticks([0, 1])
end

%% Plot the noise in each channel

figure()

% array for channel noise
noise_voltage = zeros(size(array_voltage));

% compute and plot noise in all 4 channels
for i = 1:4
    for j = 1:length(ts_voltage.time)
        % if voltage < 1.2 -> noise = voltage - 0
        if array_voltage(j, i+1) < 1.2
            noise_voltage(j, i) = array_voltage(j, i+1) - 0; 
        % if voltage > 2.2 -> noise = voltage - 3.3    
        elseif array_voltage(j, i+1) > 2.2
            noise_voltage(j, i) = array_voltage(j, i+1) - 3.3; 
        end
    end

    % draw subplot
    subplot(2, 2, i)
    plot(ts_voltage.time, noise_voltage(:, i), 'LineWidth', 1.5)
    xlabel('time (seconds)')
    ylabel('voltage (volts)')
    title(['noise in channel #', num2str(i)])
end

%% Plot the Probability Density Function (PDF) of noise of all channels

figure()

% combine all channel noise and plot histogram
% normalised so that total area = 1
noise_pdf = histogram(noise_voltage(:), 'Normalization', 'pdf');
xlabel('noise (volts)')
ylabel('frequency')
title('PDF of noise in all channels')

% check total area
%sum(noise_pdf.Values*noise_pdf.BinWidth) % should be 1.00

%% Decode the message

% data rate is 1/10th of sampling rate
% every 10th sample is transmitted
data_bits = decoded_channels(1:10:end, :);

% combine all channels and reshape into 8 bit rows
data_bits = reshape(data_bits', 8, size(data_bits, 1)/2);
data_bits = data_bits';

% convert every row to an decimal number
exps = 7:-1:0;
num_message = zeros(size(data_bits, 1), 1);
for i = 1:size(data_bits, 1)
    num_message(i) = sum(data_bits(i, :).*(2.^exps));
end

% convert every number to ASCII character
str_message = char(num_message);

% print decoded message
fprintf('Decoded message is \n\n\t%s\n\n', str_message)