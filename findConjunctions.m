% === findConjunctions.m ===
function conjs = findConjunctions(sc, mainSat, targets, dMinTarget)
    % Inputs:
    %   sc         - satelliteScenario object
    %   mainSat    - satellite object (your main satellite)
    %   targets    - array of satellite objects to check against
    %   dMinTarget - min distance threshold in meters

    results = [];
    fprintf("Running manual conjunction finder...\n");
    fprintf("Checking %d debris objects...\n", length(targets));

    for j = 1:length(targets)
        secSat = targets(j);
        %fprintf("\nChecking: %s vs. %s\n", mainSat.Name, secSat.Name);

        % Compute range over scenario
        [~,~,range,tOut] = aer(mainSat, secSat);

        % Find indices where range is below threshold
        kCloseIdx = find(range < dMinTarget);

        if isempty(kCloseIdx)
            %fprintf("  No coarse windows found for %s vs %s\n", mainSat.Name, secSat.Name);
            continue;  % Skip to next target
        end

        % Compute difference between close indices
        dW = [0 diff(kCloseIdx)];

        % Preallocate window array
        kWindow = zeros(2,length(kCloseIdx));
        winCount = 0;

        for m = 1:length(dW)
            if dW(m) ~= 1
                winCount = winCount + 1;
                kWindow(1,winCount) = max(1,kCloseIdx(m)-1);
                kWindow(2,winCount) = kCloseIdx(m)+1;
            elseif winCount > 0
                kWindow(2,winCount) = kCloseIdx(m)+1;
            end
        end

        % Trim unused columns
        if winCount == 0
            fprintf("  No valid windows found for %s vs %s\n", mainSat.Name, secSat.Name);
            continue;
        end

        kWindow = kWindow(:,1:winCount);
        fprintf("  %d coarse windows found.\n", winCount);

        % Process each window
        for k = 1:winCount
            window = tOut(kWindow(:,k));

            % Find TCA using fzero
            tMin = fzero(@(t) gradientScenario(t, mainSat, secSat, sc.StartTime), ...
                          days(window - sc.StartTime));
            
            [~, dR] = gradientScenario(tMin, mainSat, secSat, sc.StartTime);
            tCA = sc.StartTime + days(tMin);

            % Relative velocity at TCA
            [~, vel] = states([mainSat secSat], tCA);
            relVel = norm(vel(:,:,1) - vel(:,:,2));

            % Append to results
            results = [results; 
                {mainSat.Name, secSat.Name, tCA, dR, relVel}];

            fprintf("    -> Window %d TCA: %s | Range: %.2f m | RelVel: %.2f m/s\n", ...
                k, tCA, dR, relVel);
        end
    end

    if isempty(results)
        fprintf("✅ No conjunctions found.\n");
        conjs = [];
    else
        conjs = cell2table(results, ...
            "VariableNames", ["Satellite1Name", "Satellite2Name", ...
                              "TimeOfClosestApproach", "ClosestApproachDistance", ...
                              "RelativeVelocity"]);
    end
end
