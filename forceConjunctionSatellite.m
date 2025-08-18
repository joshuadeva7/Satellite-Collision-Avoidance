% === forceConjunctionSatellite.m ===
% Creates a debris satellite guaranteed to intersect the main satellite's orbit
% by cloning its elements and offsetting the true anomaly.
%
% Inputs:
%   sc      - satelliteScenario object
%   sat     - main satellite to clone
%   offset  - degrees, offset to true anomaly to create forced conjunction
%
% Output:
%   forcedDebris - new satellite handle

function forcedDebris = forceConjunctionSatellite(sc, sat, offset)

% Use states to get current position & velocity
% Then convert to orbital elements
mu = 3.986004418e14; % [m^3/s^2]

% Use current scenario start time as snapshot
[pos, vel] = states(sat, sc.StartTime, "CoordinateFrame", "inertial");
coe = rv2coe(pos, vel, mu);

sma  = coe(1);
ecc  = coe(2);
inc  = coe(3);
raan = coe(4);
argp = coe(5);
ta   = coe(6);

% Offset the true anomaly to shift position along the orbit
ta_forced = ta + offset;

fprintf("\n📌 Forced conjunction debris created with true anomaly offset: %.2f deg\n", offset);

% Add debris to scenario
forcedDebris = satellite(sc, ...
    sma, ecc, inc, raan, argp, ta_forced, ...
    "OrbitPropagator", "two-body-keplerian", ...
    "Name", "ForcedDebris");

forcedDebris.MarkerColor = "red";
forcedDebris.Orbit.LineColor = "red";
forcedDebris.LabelFontColor = "red";

fprintf("✅ Forced debris satellite added: %s\n", forcedDebris.Name);

end
