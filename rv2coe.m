% === rv2coe.m ===
% Convert position and velocity vectors to classical orbital elements (COEs)
% 
% Inputs:
%   r  - position vector [m] (3x1 or 1x3)
%   v  - velocity vector [m/s] (3x1 or 1x3)
%   mu - gravitational parameter [m^3/s^2]
%
% Output:
%   coe - [1x6] vector: [a e i RAAN argp trueAnomaly]
%         Units: a [m], e [-], i [deg], RAAN [deg], argp [deg], nu [deg]

function coe = rv2coe(r, v, mu)

% Ensure column vectors
r = r(:);
v = v(:);

% Magnitudes
R = norm(r);
V = norm(v);

% === Specific angular momentum ===
hVec = cross(r, v);
h = norm(hVec);

% === Eccentricity vector ===
eVec = (1/mu) * ((V^2 - mu/R)*r - dot(r,v)*v);
e = norm(eVec);

% === Energy and semi-major axis ===
energy = V^2/2 - mu/R;

if abs(e - 1) > 1e-6
    a = -mu / (2*energy);  % for ellipse or hyperbola
else
    a = Inf;               % parabolic escape
end

% === Inclination ===
i = acos(hVec(3)/h);

% === Node vector ===
K = [0; 0; 1];
nVec = cross(K, hVec);
n = norm(nVec);

% === Right Ascension of Ascending Node (RAAN) ===
if n ~= 0
    RAAN = acos(nVec(1)/n);
    if nVec(2) < 0
        RAAN = 2*pi - RAAN;
    end
else
    RAAN = 0;
end

% === Argument of Perigee (argp) ===
if n ~= 0 && e > 1e-10
    argp = acos(dot(nVec,eVec)/(n*e));
    if eVec(3) < 0
        argp = 2*pi - argp;
    end
else
    argp = 0;
end

% === True Anomaly (nu) ===
if e > 1e-10
    nu = acos(dot(eVec,r)/(e*R));
    if dot(r,v) < 0
        nu = 2*pi - nu;
    end
else
    % Circular orbit: use angle between node and position vector
    cp = cross(nVec, r);
    if cp(3) >= 0
        nu = acos(dot(nVec, r)/(n*R));
    else
        nu = 2*pi - acos(dot(nVec, r)/(n*R));
    end
end

% === Output: [a e i RAAN argp nu] ===
coe = [a, e, rad2deg(i), rad2deg(RAAN), rad2deg(argp), rad2deg(nu)];

end
