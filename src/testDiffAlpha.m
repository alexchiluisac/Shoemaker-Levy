%% Robot endoscope features.
clc, clear, close all
addpath('kinematics')
addpath('path-planning')
addpath('utils')
addpath('utils/HPR/')
addpath('../anatomical-models')

maxDisplacement = 1; % [mm]
maxRotation     = 2*pi; % [rad]
maxAdvancement  = 10; % [mm]

% Load ear model
path = fullfile('..', 'anatomical-models', 'synthetic-model.stl');
[vertices, faces, ~, ~] = stlRead(path);
earModel.vertices = vertices;
earModel.faces = faces;

% Calculate the centroids of the faces - this will be useful when
% calculating visibility
pcentr = zeros(size(faces, 1), 3);

for ii = 1 : size(faces, 1)
    p1 = vertices(faces(ii,1), :);
    p2 = vertices(faces(ii,2), :);
    p3 = vertices(faces(ii,3), :);
    
    pcentr(ii,1) = 1/3 * (p1(1) + p2(1) + p3(1));
    pcentr(ii,2) = 1/3 * (p1(2) + p2(2) + p3(2));
    pcentr(ii,3) = 1/3 * (p1(3) + p2(3) + p3(3));
end


% Calculate the base transform for the robot
t = [30 10 10];
R = [0 0 -1; 0 1 0; 1 0 0];
T = [R t'; 0 0 0 1];
earModel.baseTransform = T;

% Estimate the reachable volume and 
reachableVolume = zeros(5,1);
alpha = 0;


% Estimate visual range for each design
for ii = 1 : length(alpha)
    cutouts = [];
    cutouts.w = [1 1 1 1];
    cutouts.u = [1 1 1 1];
    cutouts.h = [1 1 1 1];
    cutouts.alpha = [0 0 alpha(ii) 0];
    
    % Create the robot
    robot = Wrist(1.6, 1.85, 4, cutouts);
    
    [qListNormalized,qList,pList,aList] = rrt(robot, ...
        [maxDisplacement maxRotation maxAdvancement], ...
        earModel);
    
    acc = zeros(size(faces, 1), size(pList, 2));
    
    for jj = 1 : length(pList)
        acc(:,ii) = visiblesurface(pList(:,ii), earModel, aList(:,ii));
    end
    
    seenMap = max(acc, [], 2)
end

% % Plot objective function
% figure
% scatter(alpha * 180 / pi, reachableVolume)
% %axis equal
% grid on
% xlabel('Angle [Degree]'), ylabel('Reachable Volume [mm^3]');
% xlim([alpha(1) alpha(end)]  * 180 / pi)
% ylim([0 max(reachableVolume)])

