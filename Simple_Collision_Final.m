%% Simple Collision Demo - 1 Hour
% Clean, working version

clear; clc; close all;

%% Basic Setup
assert(license('test','Aerospace_Toolbox'), 'Aerospace Toolbox is required.');

startTime = datetime(2024,5,11,12,35,38);
stopTime = startTime + minutes(70);
sampleTime = 30;
sc = satelliteScenario(startTime,stopTime,sampleTime);

fprintf("=== Simple 1-Hour Collision Demo ===\n");

%% Create Target Satellite
target = satellite(sc, "Iridium_174.txt", ...
    "Name", "Target", ...
    "OrbitPropagator", "sgp4");

target.MarkerColor = "green";
target.Orbit.LineColor = "green";
target.MarkerSize = 20;

%% Create Interceptor with True Collision Course
mu = 3.986004418e14;

% Get target's position at collision time (T+30 minutes for example)
collisionTargetTime = startTime + minutes(30);
[targetCollisionPos, targetCollisionVel] = states(target, collisionTargetTime, "CoordinateFrame", "inertial");

% Create interceptor starting far away but aimed at collision point
% Start interceptor 5000 km away in opposite direction from Earth
earthCenter = [0; 0; 0];
directionToTarget = targetCollisionPos / norm(targetCollisionPos);
interceptorStartPos = targetCollisionPos - 8000000 * directionToTarget;  % 8000 km away

% Calculate velocity needed to reach collision point in 30 minutes
timeToCollision = 30 * 60;  % 30 minutes in seconds
requiredVelocity = (targetCollisionPos - interceptorStartPos) / timeToCollision;

% Convert to orbital elements (try-catch in case of hyperbolic orbit)
try
    interceptor_coe = rv2coe(interceptorStartPos, requiredVelocity, mu);
    
    interceptor = satellite(sc, ...
        interceptor_coe(1), interceptor_coe(2), interceptor_coe(3), ...
        interceptor_coe(4), interceptor_coe(5), interceptor_coe(6), ...
        "OrbitPropagator", "two-body-keplerian", ...
        "Name", "Interceptor");
catch
    % If orbital elements fail, use a simpler approach with velocity scaling
    fprintf("Using simplified interceptor trajectory...\n");
    [pos0, vel0] = states(target, startTime, "CoordinateFrame", "inertial");
    
    % Create interceptor with much faster velocity to catch up
    interceptor_vel = vel0 * 1.1;  % 10% faster velocity
    interceptor_coe = rv2coe(pos0, interceptor_vel, mu);
    
    interceptor = satellite(sc, ...
        interceptor_coe(1), interceptor_coe(2), interceptor_coe(3), ...
        interceptor_coe(4), interceptor_coe(5), interceptor_coe(6) - deg2rad(30), ...
        "OrbitPropagator", "two-body-keplerian", ...
        "Name", "Interceptor");
end

    interceptor = satellite(sc, ...
        interceptor_coe(1), interceptor_coe(2), interceptor_coe(3), ...
        interceptor_coe(4), interceptor_coe(5), interceptor_coe(6), ...
        "OrbitPropagator", "two-body-keplerian", ...
        "Name", "Interceptor");interceptor.MarkerColor = "red";
interceptor.Orbit.LineColor = "red";
interceptor.MarkerSize = 20;

fprintf("Target: %s (Green)\n", target.Name);
fprintf("Interceptor: %s (Red)\n", interceptor.Name);

%% Find Collision with High Resolution
fprintf("\n=== Finding Collision ===\n");

% First pass: Every 5 minutes for overview
timePoints = 0:5:70;
coarseDistances = [];

for t = timePoints
    checkTime = startTime + minutes(t);
    [pos1, ~] = states(target, checkTime, "CoordinateFrame", "inertial");
    [pos2, ~] = states(interceptor, checkTime, "CoordinateFrame", "inertial");
    distance = norm(pos1 - pos2);
    coarseDistances = [coarseDistances, distance];
    
    if t == 60
        fprintf("T+%02d min: %6.1f km  <-- TARGET\n", t, distance/1000);
    else
        fprintf("T+%02d min: %6.1f km\n", t, distance/1000);
    end
end

% Second pass: High resolution around minimum (every 30 seconds)
fprintf("\n=== High Resolution Analysis ===\n");
fineTimePoints = 0:0.5:70;  % Every 30 seconds
minDist = inf;
collisionTime = 0;

for t = fineTimePoints
    checkTime = startTime + minutes(t);
    [pos1, ~] = states(target, checkTime, "CoordinateFrame", "inertial");
    [pos2, ~] = states(interceptor, checkTime, "CoordinateFrame", "inertial");
    distance = norm(pos1 - pos2);
    
    if distance < minDist
        minDist = distance;
        collisionTime = t;
    end
end

fprintf("FINEST RESOLUTION: %.1f m at T+%.1f minutes\n", minDist, collisionTime);

% Show detailed timeline around collision
windowStart = max(0, collisionTime - 5);
windowEnd = min(70, collisionTime + 5);

fprintf("\n=== Collision Window (T+%.1f ± 5 min) ===\n", collisionTime);
for t = windowStart:1:windowEnd  % Every minute
    checkTime = startTime + minutes(t);
    [pos1, ~] = states(target, checkTime, "CoordinateFrame", "inertial");
    [pos2, ~] = states(interceptor, checkTime, "CoordinateFrame", "inertial");
    distance = norm(pos1 - pos2);
    
    if abs(t - collisionTime) < 0.6  % Within 30 seconds
        fprintf("T+%04.1f min: %8.1f m  <-- COLLISION ZONE\n", t, distance);
    else
        fprintf("T+%04.1f min: %8.1f m\n", t, distance);
    end
end

%% Create Detailed Plot
figure('Name', 'Collision Analysis - High Resolution', 'Position', [200, 200, 1200, 600]);

% Plot 1: Overview (coarse data)
subplot(1,2,1);
plot(timePoints, coarseDistances/1000, 'b-o', 'LineWidth', 3, 'MarkerSize', 8);
xlabel('Time (minutes)');
ylabel('Distance (km)');
title('Collision Approach - Overview (5-min intervals)');
grid on;
hold on;

% Mark 60-minute target
plot([60, 60], [0, max(coarseDistances/1000)], 'g--', 'LineWidth', 2);
text(60, max(coarseDistances/1000)*0.8, 'TARGET', 'Color', 'green', 'FontWeight', 'bold');

% Mark collision
plot(collisionTime, minDist/1000, 'ro', 'MarkerSize', 15, 'MarkerFaceColor', 'red');
text(collisionTime, minDist/1000 + max(coarseDistances/1000)*0.1, ...
    sprintf('%.1f km\nT+%.1f', minDist/1000, collisionTime), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Plot 2: High resolution around collision
subplot(1,2,2);
% Calculate high-res distances around collision
detailStart = max(0, collisionTime - 10);
detailEnd = min(70, collisionTime + 10);
detailTimes = detailStart:0.5:detailEnd;  % Every 30 seconds
detailDistances = [];

for t = detailTimes
    checkTime = startTime + minutes(t);
    [pos1, ~] = states(target, checkTime, "CoordinateFrame", "inertial");
    [pos2, ~] = states(interceptor, checkTime, "CoordinateFrame", "inertial");
    detailDistances = [detailDistances, norm(pos1 - pos2)];
end

plot(detailTimes, detailDistances/1000, 'r-', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Distance (km)');
title('Collision Detail - High Resolution (30-sec intervals)');
grid on;
hold on;

% Mark minimum
[actualMin, minIdx] = min(detailDistances);
actualMinTime = detailTimes(minIdx);
plot(actualMinTime, actualMin/1000, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'red');

% If very close, also show in meters
if actualMin < 10000
    ylabel('Distance (km) - Log Scale');
    set(gca, 'YScale', 'log');
    text(actualMinTime, actualMin/1000*2, sprintf('%.0f m', actualMin), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
end

%% Setup 3D Viewer
fprintf("\n=== 3D Visualization ===\n");
viewer = satelliteScenarioViewer(sc, "ShowDetails", false);

%% Results
fprintf("\n==============================\n");
fprintf("       COLLISION SUMMARY\n");
fprintf("==============================\n");

if minDist < 1000
    fprintf("STATUS: COLLISION!\n");
elseif minDist < 10000  
    fprintf("STATUS: CLOSE APPROACH!\n");
else
    fprintf("STATUS: Approach detected\n");
end

fprintf("Distance: %.2f km\n", minDist/1000);
fprintf("Time: T+%d minutes\n", collisionTime);
fprintf("Target: T+60 minutes\n");
fprintf("Error: %+d minutes\n", collisionTime - 60);

fprintf("\n==============================\n");
fprintf("     HOW TO WATCH\n");
fprintf("==============================\n");
fprintf("1. Type: play(sc)\n");
fprintf("2. Speed: sc.PlaybackSpeedMultiplier = 20\n");
fprintf("3. GREEN = Target\n");
fprintf("4. RED = Interceptor\n");
fprintf("5. Collision at T+%d min\n", collisionTime);
fprintf("\n>>> Type play(sc) to start! <<<\n");