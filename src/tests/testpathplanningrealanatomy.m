%% Script to test RRT and collision detection
clc, clear, close all

% How many configuration points should we sample for testing?
nPoints =  1000;

% Which anatomical model should we use?
modelID = 'atlas';

fprintf('*** RRT and estimation of reachable workspace test ***\n')
fprintf('This script is divided in two parts:\n')
fprintf('1. "Step-by-step" testing of RRT\n');
fprintf('2. Generation of plots to show the results of RRT and of the estimation of the reachable workspace\n\n')
fprintf('Press any key to continue.\n')
pause

% add dependencies
addpath('kinematics')
addpath('utils')
addpath('utils/stlTools')
addpath('path-planning')
addpath('../anatomical-models')

%% Part 1. Step-by-step testing of RRT
fprintf('Testing RRT...\n')
% define the robot's range of motion
maxDisplacement = 1.5e-3;  % [m]
maxRotation     = 4*pi;  % [rad]
maxAdvancement  = 15e-3; % [m]

% Load ear model
% Read the configuration file to extract information about the
% meshes
fid = fopen(fullfile('..', 'anatomical-models', 'configurations.txt'));
text = textscan(fid, '%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
fclose(fid);

configurations = cell2mat(text(2:end));
line_no = find(strcmp(text{1}, modelID));

path       = fullfile('meshes', text{1}(line_no));
path       = path{:}; % converts cell to char
image_size   = configurations(line_no, 1:3);
voxel_size   = configurations(line_no, 4:6);
entry_point  = configurations(line_no, 7:9);
tip_base     = configurations(line_no, 10:12);
%target_point = configurations(line_no, 13:15);

newZ = tip_base .* 1e-3 - entry_point .* 1e-3;
newZ = newZ ./ norm(newZ);
v = cross([0 0 1], newZ);
R = eye(3) + skew(v) + skew(v)^2 * (1-dot([0 0 1], newZ))/norm(v)^2;
t = entry_point .* 1e-3;
T = [R t'; 0 0 0 1];

path = fullfile('..', 'anatomical-models', modelID,'me.stl');
[vertices, faces, ~, ~] = stlRead(path);
earModel.vertices = vertices;
earModel.faces = faces;
earModel.baseTransform = T;

path = fullfile('..', 'anatomical-models', modelID, 'ossicle.stl');
[vertices, faces, ~, ~] = stlRead(path);
osModel.vertices = vertices;
osModel.faces = faces;

% Create a robot
n = 8; % number of cutouts
alpha = pi;
cutouts = [];
cutouts.w = ones(1,n) * 1.20  * 1e-3;
cutouts.u = ones(1,n) * 1.2  * 1e-3;
cutouts.h = ones(1,n) * 0.19  * 1e-3;
cutouts.alpha = zeros(1,n);
robot = Wrist(1.2e-3, 1.4e-3, n, cutouts);

[qListNormalized,qList,pList,aList] = rrt(robot, ...
    [maxDisplacement maxRotation maxAdvancement], ...
    earModel, ...
    osModel, ...
    nPoints);

fprintf(['RRT execution complete. Total sampled points: ' num2str(size(qList,2)) ' \n\n']);

figure('units','normalized','outerposition',[0 0 1 1])

% Visualize the robot inside the cavity
ii = 1;
h1 = stlPlot(earModel.vertices, earModel.faces, 'Collision detection test.');
stlPlot(osModel.vertices, osModel.faces, 'Collision detection test.');
hold on

ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1);
bottom = outerpos(2) + ti(2);
ax_width = outerpos(3) - ti(1) - ti(3);
ax_height = outerpos(4) - ti(2) - ti(4);
ax.Position = [left bottom ax_width ax_height];

robot.fwkine(qList(:,ii), T);
robotPhysicalModel = robot.makePhysicalModel();
h2 = surf(robotPhysicalModel.surface.X, ...
    robotPhysicalModel.surface.Y, ...
    robotPhysicalModel.surface.Z, ...
    'FaceColor','blue');

axis equal

%for ii = 1 : size(pList, 2)
while true
    robot.fwkine(qList(:,ii), T);
    robotPhysicalModel = robot.makePhysicalModel();
    
    h2.XData = robotPhysicalModel.surface.X;
    h2.YData = robotPhysicalModel.surface.Y;
    h2.ZData = robotPhysicalModel.surface.Z;
    title(['Pose ' num2str(ii) ' of ' num2str(size(pList, 2))]);
    
    fprintf('Press "n" to move forward or "p" to move back.\n')
    fprintf('Press any other key to stop testing and generate the reachable workspace.\n\n')
    
    while ~waitforbuttonpress, end
    k = get(gcf, 'CurrentCharacter');
    
    switch k
        case 'p'
            ii = ii - 1;
            if ii < 1, ii = 1; end
        case 'n'
            ii = ii + 1;
            if ii > size(pList, 2), ii = size(pList, 2); end
        otherwise
            break
    end
end

close all

%pList = pList; % converting to mm for plotting

fprintf('\n Generating reachable workspace...\n')
shrinkFactor = 1;
[k,v] = boundary(pList(1,:)', pList(2,:)', pList(3,:)', shrinkFactor);

figure
scatter3(qList(1,:), qList(2,:), qList(3,:));
grid on
xlabel('Pull-wire displacement [mm]');
ylabel('Axial rotation [rad]');
zlabel('Axial translation [mm]');
title('Configurations generated by RRT');

figure
scatter3(qListNormalized(1,:), qListNormalized(2,:), qListNormalized(3,:));
grid on
xlabel('Pull-wire displacement [m]');
ylabel('Axial rotation [rad]');
zlabel('Axial translation [m]');
title('Configurations generated by RRT (normalized)');

% Visualize ear model
figure, hold on
stlPlot(earModel.vertices, earModel.faces, 'Ear Model');
stlPlot(osModel.vertices, osModel.faces, 'Ear Model');
%view([17.8 30.2]);

scatter3(pList(1,:), pList(2,:), pList(3,:),'red','filled');
axis equal, grid on
xlabel('X [m]'), ylabel('Y [m]'), zlabel('Z [m]');
title('Reachable points in the task space');

figure, hold on
stlPlot(earModel.vertices, earModel.faces, 'Ear Model');
stlPlot(osModel.vertices, osModel.faces, 'Ear Model');
%view([17.8 30.2]);
trisurf(k, pList(1,:)', pList(2,:)', pList(3,:)','FaceColor','red','FaceAlpha',0.1)
title('Reachable workspace');

fprintf('Testing complete.\n')