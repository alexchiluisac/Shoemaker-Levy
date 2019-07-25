function newCurve = partitioncurve(varargin)
    %SELECTPTS Runs an algorithm that selects the dominant points in the
    %curve
    
    % Input handling
    defaultM = 5;
    defaultPlot = false;
    
    p = inputParser;
    addRequired(p, 'curve');
    addOptional(p, 'm', defaultM);
    addParameter(p, 'plot', defaultPlot);
    parse(p, varargin{:});
    
    curve = p.Results.curve;
    m     = p.Results.m;
    plot  = p.Results.plot;
    
    col = distinguishable_colors(10);
    
    % Split the curve into chords
    chords = vecnorm(diff(curve.arc')');
    
    % Calculate the integral of curvature
    totalKappa = 0.5 * chords(1) * curve.kappa(1) + ...
        0.5 * chords(end) * curve.kappa(end);
    
    totalTau = 0.5 * chords(1) * curve.tau(1) + ...
        0.5 * chords(end) * curve.tau(end);
    
    for ii = 2 : length(curve.arc) - 1
        totalKappa = totalKappa + ...
            curve.kappa(ii) * (chords(ii-1) + chords(ii));
    end
    
    for ii = 2 : length(curve.arc) - 1
        totalTau = totalTau + ...
            curve.tau(ii) * (chords(ii-1) + chords(ii));
    end
    
    % Now partition the curve into sections.
    % Each section should have total curvature == totalKappa / m
    quantumKappa = totalKappa / m;
    
    t = zeros(1, m);
    arcIndexes = zeros(1, m);
    averageKappa = zeros(1, m);
    kappaAcc = 0.5 * chords(1) * curve.kappa(1);
    ii = 2;
    
    
    for jj = 1 : m
        targetKappa = jj * quantumKappa;
        kappaArcSegment = 0;
        kk = 0;
        
        while kappaAcc <= targetKappa
            if ii == length(curve.arc)
                break;
            end
            
            kappaAcc = kappaAcc + ...
                curve.kappa(ii) * (chords(ii-1) + chords(ii));
            
            kappaArcSegment = kappaArcSegment + ...
                curve.kappa(ii);
            
            ii = ii + 1;
            kk = kk + 1;
        end
        
        t(jj) = curve.l(ii);
        averageKappa(jj) = kappaArcSegment / kk;
        arcIndexes(jj) = ii;
    end
    
    dominantPts = curve.arc(:,arcIndexes);
    dominantPts = [curve.arc(:,1) dominantPts];
    
    newCurve.arc = dominantPts;
    newCurve.l   = [curve.l(1); curve.l(arcIndexes)];
    newCurve.t   = [curve.t(:,1) curve.t(:,arcIndexes)];
    newCurve.n   = [curve.n(:,1) curve.n(:,arcIndexes)];
    newCurve.b   = [curve.b(:,1) curve.b(:,arcIndexes)];
    newCurve.averageKappa = averageKappa;
    
    if plot
        figure
        %scatter3(curve.arc(1,:), curve.arc(2,:), curve.arc(3,:), 40, 'filled', 'MarkerFaceColor', col(7,:));
        plot3(curve.arc(1,:), curve.arc(2,:), curve.arc(3,:), 'LineWidth',3,'Color',(1/256)*[255 128 0]);

        axis equal, grid on, hold on
        triad('scale', 1e-3/2, 'linewidth', 2.5);
        scatter3(dominantPts(1,:), dominantPts(2,:), dominantPts(3,:), 80, 'filled', 'MarkerFaceColor', (1/256)*[96 96 96]);
%         xlim([min(curve.arc(1,:)) max(curve.arc(1,:))+0.01])
%         ylim([min(curve.arc(2,:)) max(curve.arc(2,:))+0.01])
%         zlim([min(curve.arc(3,:)) max(curve.arc(3,:))+0.01]);
        xlabel('X [m]'), ylabel('Y [m]'), zlabel('Z [m]')
        legend({'Original Curve', 'Dominant Points'});
        view(0.26, 20.5)
        title('Partitioned Curve');
        set(gca,'FontSize',16);
    end
end
