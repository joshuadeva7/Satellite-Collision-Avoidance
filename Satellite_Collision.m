%% Satellite Collision Avoidance Project
% Author: Joshua Devasahayam
% MATLAB Simulink Challenge Project 225
% Description: Load TLEs, propagate using SGP4, and visualize orbits

clear; clc; close all;

%% Add Aerospace Toolbox (ensure license is available)
assert(license('test','Aerospace_Toolbox'), 'Aerospace Toolbox is required.');

% Create Satellite Scenario
startTime = datetime(2024,5,11,12,35,38);
stopTime = startTime + days(2);
sampleTime = 60;
sc = satelliteScenario(startTime,stopTime,sampleTime)

% Constants
mu = 3.986004418e14;  % Earth's gravitational parameter [m^3/s^2]

% Read all lines and remove name lines
lines = readlines("COSMOS_2251_debris.txt");
lines(1:3:end) = [];  % Remove every third line (name lines)

%debrisList = satellite.empty;
count = 0;

for i = 1:2:length(lines)-1
    try
        % Get TLE line 1 and 2
        line1 = lines(i);
        line2 = lines(i+1);

        % Parse orbital elements from TLE line 2
        tokens = split(line2);
        inc  = str2double(tokens{3});  % Inclination [deg]
        raan = str2double(tokens{4});  % RAAN [deg]
        eccStr = tokens{5};            % Eccentricity (decimal missing)
        ecc  = str2double("0." + eccStr);  % Add decimal point
        argp = str2double(tokens{6});  % Argument of perigee [deg]
        M    = str2double(tokens{7});  % Mean anomaly [deg]
        n    = str2double(tokens{8});  % Mean motion [rev/day]

        % Convert mean motion to semi-major axis (m)
        n_rad = 2 * pi * n / 86400;  % [rad/s]
        sma = (mu / n_rad^2)^(1/3);  % [m]

        % Approximate true anomaly = mean anomaly
        % (ok for circular orbits / visual sim)
        trueAnomaly = M;

        % Create debris satellite
        name = "Debris_" + string((i+1)/2);
        sat = satellite(sc, ...
            sma, ecc, inc, ...
            raan, argp, trueAnomaly, ...
            "OrbitPropagator", "two-body-keplerian", ...
            "Name", name);
        
        % Add to list
        count = count + 1;
        %debrisList(count) = sat;

    catch ME
        warning("Failed to create debris from TLE at lines %d–%d: %s", i, i+1, ME.message);
    end
end

disp("Successfully loaded " + count + " debris objects using manual orbit setup.");


%Add Satellites and Debris
tleFile = "deb2.txt";
tleSat = "Iridium_174.txt" 

satSGP4 = satellite(sc,tleSat, ...
    "Name","satSGP4", ...
    "OrbitPropagator","sgp4")

debSGP4 = satellite(sc, tleFile, ....
    "Name", "debSGP40", ...
    "OrbitPropagator", "sgp4")


% Set up the satellite properties for visualization
satSGP4.MarkerColor = "green";
satSGP4.Orbit.LineColor = "green";
satSGP4.LabelFontColor = "green";

debSGP4.MarkerColor = "red";
debSGP4.Orbit.LineColor = "red";
debSGP4.LabelFontColor = "red";

play(sc)

%% Satellite Conjuction

%% Conjunction Detection

% Check for Aerospace Toolbox license again (safety)
assert(license('test','Aerospace_Toolbox'), 'Aerospace Toolbox is required for conjunction detection.');

% Create conjunction finder
finder = satelliteConjunctions(sc);

% Add the Iridium satellite (main object of interest)
add(finder, satSGP4);

% Add the manually generated debris
% Loop through all children in the scenario to find debris (by name)
for obj = sc.Children
    if contains(obj.Name, "Debris_")
        add(finder, obj);
    end
end

% Also add the other SGP4 debris satellite
add(finder, debSGP4);

% Configure detection thresholds (optional)
finder.DistanceThreshold = 1000;  % meters
finder.CollisionProbabilityThreshold = 1e-10;  % very conservative

% Run the analysis
conjs = run(finder);

% Display results
if isempty(conjs)
    disp("✅ No conjunctions detected.");
else
    disp("⚠️ Conjunctions detected:");
    disp(conjs);

    % Optionally format each conjunction
    for i = 1:height(conjs)
        fprintf("\nConjunction %d:\n", i);
        fprintf("  Between: %s and %s\n", ...
            conjs.Satellite1Name(i), conjs.Satellite2Name(i));
        fprintf("  Time of Closest Approach: %s\n", conjs.TimeOfClosestApproach(i));
        fprintf("  Closest Approach Distance: %.2f m\n", conjs.ClosestApproachDistance(i));
    end
end

