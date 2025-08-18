%% Satellite Collision Avoidance Project
% Author: Joshua Devasahayam
% MATLAB Simulink Challenge Project 225
% Description: Load TLEs, propagate using SGP4, and visualize orbits

clear; clc; close all;

%% Add Aerospace Toolbox (ensure license is available)
assert(license('test','Aerospace_Toolbox'), 'Aerospace Toolbox is required.');

% Create Satellite Scenario
startTime = datetime(2024,5,11,12,35,38);
stopTime = startTime + days(7);
sampleTime = 60;
sc = satelliteScenario(startTime,stopTime,sampleTime)

% Constants
mu = 3.986004418e14;  % Earth's gravitational parameter [m^3/s^2]

% Read all lines and remove name lines
lines = readlines("COSMOS_2251_debris.txt");
lines(1:3:end) = [];  % Remove every third line (name lines)

%debrisList = satellite.empty;
% === Initialize debris storage ===
debrisList = {};  % Use a cell array for handle objects
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

        % Add to list (cell array)
        count = count + 1;
        debrisList{count} = sat;

    catch ME
        warning("Failed to create debris from TLE at lines %d–%d: %s", ...
            i, i+1, ME.message);
    end
end

disp("Successfully loaded " + count + " debris objects using manual orbit setup.");

%Add Satellites and Debris
tleFile = "deb2.txt";
tleSat = "Iridium_174.txt" ;

satSGP4 = satellite(sc,tleSat, ...
    "Name","satSGP4", ...
    "OrbitPropagator","sgp4")

debSGP4 = satellite(sc, tleFile, ....
    "Name", "debSGP40", ...
    "OrbitPropagator", "sgp4")

%testChild = sc.Children

% Set up the satellite properties for visualization
satSGP4.MarkerColor = "green";
satSGP4.Orbit.LineColor = "green";
satSGP4.LabelFontColor = "green";

debSGP4.MarkerColor = "red";
debSGP4.Orbit.LineColor = "red";
debSGP4.LabelFontColor = "red";

%play(sc)

%% Satellite Conjuction

% Check for Aerospace Toolbox license again (safety)
assert(license('test','Aerospace_Toolbox'), 'Aerospace Toolbox is required for conjunction detection.');

% Identify your main satellite (the Iridium)
% Combine all debris + extra SGP4 debris
mainSat = satSGP4;
targets = [debrisList{:}, debSGP4];

% Call your custom finder
distanceThreshold = 50000;
conjs = findConjunctions(sc, mainSat, targets, distanceThreshold);

%Add forced collision
forcedDebris = forceConjunctionSatellite(sc, satSGP4, 1);  % 1 deg offset

% Add it to your target list
targets = [debrisList{:}, debSGP4, forcedDebris];

% Rerun detection
conjs = findConjunctions(sc, satSGP4, targets, 1000);

if ~isempty(conjs)
    fprintf("\n Forced conjunction detected!\n");

    % Plan an avoidance maneuver ~30 min before TCA
    tCA = conjs.TimeOfClosestApproach(1);
    tManeuver = tCA - minutes(30);
    deltaV_mag = -0.1;  % retrograde push

    satAvoid = planAvoidanceManeuver(sc, satSGP4, tManeuver, deltaV_mag);

    % Check new orbit
    conjs_after = findConjunctions(sc, satAvoid, targets, 1000);

    if isempty(conjs_after)
        fprintf("\n Dodge success: no more conjunction!\n");
    else
        fprintf("\n Still at risk — try a different ΔV or maneuver timing!\n");
        disp(conjs_after);
    end

else
    fprintf("\n No forced conjunction detected — adjust your offset.\n");
end


% Display results
%{
if isempty(conjs)
    disp(" No conjunctions detected manually.");
else
    disp("  Manual conjunctions found:");
    disp(conjs);
end
%}

%% Avoidance Maneuver
maneuverTime = sc.StartTime + hours(24);

% Example: -0.1 m/s retrograde burn
deltaV_mag = -0.1;  % m/s (negative = retrograde)

% Call your new function
satAvoid = planAvoidanceManeuver(sc, satSGP4, maneuverTime, deltaV_mag);

% Rerun conjunction check for the new orbit
newTargets = [debrisList{:}, debSGP4];
conjs_after = findConjunctions(sc, satAvoid, newTargets, 1000);

if isempty(conjs_after)
    fprintf("\n No conjunctions detected after avoidance maneuver.\n");
else
    fprintf("\n️ Conjunctions still exist after avoidance! Check your ΔV.\n");
    disp(conjs_after);
end

