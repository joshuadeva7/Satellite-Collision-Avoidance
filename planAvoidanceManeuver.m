% === planAvoidanceManeuver.m ===
function satAvoid = planAvoidanceManeuver(sc, sat, tManeuver, deltaV_mag)
% Plan and apply a simple in-track ΔV maneuver
% 
% Inputs:
%   sc         - satelliteScenario object
%   sat        - satellite object to maneuver
%   tManeuver  - datetime of the maneuver
%   deltaV_mag - scalar, m/s, positive for prograde, negative for retrograde
%
% Output:
%   satAvoid   - new satellite object with updated orbit

fprintf("\n=== Planning avoidance maneuver ===\n");
fprintf("Maneuver time: %s\n", tManeuver);

% Get position and velocity at maneuver time
[pos, vel] = states(sat, tManeuver, "CoordinateFrame", "inertial");

fprintf("Original speed: %.3f m/s\n", norm(vel));

% Define ΔV vector: in-track direction means along velocity vector
v_hat = vel / norm(vel);  % unit vector along current motion
deltaV = deltaV_mag * v_hat;  % ΔV vector

% New velocity
newVel = vel + deltaV;

fprintf("Applied ΔV: %.4f m/s\n", deltaV_mag);
fprintf("New speed: %.3f m/s\n", norm(newVel));

% Convert to new orbital elements
mu = 3.986004418e14;  % [m^3/s^2]

% rv2coe expects position [m] and velocity [m/s]
coe = rv2coe(pos, newVel, mu);

sma  = coe(1);
ecc  = coe(2);
inc  = coe(3);
raan = coe(4);
argp = coe(5);
ta   = coe(6);

% Create new satellite object with updated orbit
satAvoid = satellite(sc, ...
    sma, ecc, inc, raan, argp, ta, ...
    "OrbitPropagator", "two-body-keplerian", ...
    "Name", sat.Name + "_Avoid");

satAvoid.MarkerColor = "blue";
satAvoid.Orbit.LineColor = "blue";
satAvoid.LabelFontColor = "blue";

fprintf("✅ Avoidance satellite created: %s\n", satAvoid.Name);

end
