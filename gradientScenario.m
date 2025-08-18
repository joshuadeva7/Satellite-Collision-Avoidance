function [dRDot, dR] = gradientScenario(t, sat1, sat2, startTime)
    tActual = startTime + days(t);
    [pos1, vel1] = states(sat1, tActual);
    [pos2, vel2] = states(sat2, tActual);

    rVec = pos1(1:3) - pos2(1:3);
    vVec = vel1(1:3) - vel2(1:3);

    dR = norm(rVec);
    dRDot = dot(rVec, vVec) / dR;
end
