%% Script to test the robot kinematics
clc, clear, close all
addpath('kinematics')
addpath('path-planning')
addpath('utils')

col = distinguishable_colors(10);

% First, let's generate an arc with two sections with different curvatures
l1 = 5 * 10^-3;  % [m] total arc length
k1 = 50;        % [m^-1] curvature
r1 = 1/k1;        % [m] radius of curvature

theta1 = 0:l1*k1/20:l1*k1;

arc1 = r1 .* [(1-cos(theta1)); 
            zeros(1, length(theta1));
            sin(theta1)];
        
xInp = @(k) [0 0 k 0;
             0 0 0 0;
            -k 0 0 1;
             0 0 0 0];

T1 = expm(xInp(k1) * l1);
        
l2 = 3 * 10^-3;  % [m] total arc length
k2 = 100;        % [m^-1] curvature
r2 = 1/k2;        % [m] radius of curvature

theta2 = 0:l2*k2/20:l2*k2;

arc2 = r2 .* [(1-cos(theta2)); 
            zeros(1, length(theta2));
            sin(theta2)];
                
arc2 = applytransform(arc2, T1);
T2 = expm(xInp(k2) * l2);

l3 = 2 * 10^-3;  % [m] total arc length
k3 = 200;        % [m^-1] curvature
r3 = 1/k3;        % [m] radius of curvature

theta3 = 0:l3*k3/20:l3*k3;

arc3 = r3 .* [(1-cos(theta3)); 
            zeros(1, length(theta3));
            sin(theta3)];
        
arc3 = applytransform(arc3, T1*T2);

figure
triad('scale', 10^-3, 'linewidth', 2.5)
hold on
plot3(arc1(1,:), arc1(2,:), arc1(3,:),'MarkerEdgeColor', col(1,:), 'LineWidth', 2.5);
plot3(arc2(1,:), arc2(2,:), arc2(3,:),'MarkerEdgeColor', col(2,:), 'LineWidth', 2.5);
plot3(arc3(1,:), arc3(2,:), arc3(3,:),'MarkerEdgeColor', col(3,:), 'LineWidth', 2.5);
grid on, axis equal
xlabel('X [m]'), ylabel('Y [m]'), zlabel('Z [m]');
view(136, 30);
axis equal

pause

% Now let's synthesize the wrist
OD = 1.85 * 10^-3; % [m] tube outer diameter
ID = 1.60 * 10^-3; % [m] tube inner diameter
ro = OD/2;         % [m] tube outer radius
ri = ID/2;         % [m] tube inner radius

w = .85 * OD; % [m]
d = w - ro;   % [m]
phio = 2 * acos(d / ro); % [rad]
phii = 2 * acos(d / ri); % [rad]
ybaro = (4 * ro * (sin(0.5 * phio)) ^ 3)/ (3 * (phio - sin(phio)));
ybari = (4 * ri * (sin(0.5 * phii)) ^ 3)/ (3 * (phio - sin(phii)));
Ao = ( (ro ^ 2) * ( phio - sin(phio))) / 2;
Ai = ( (ri ^ 2) * ( phii - sin(phii))) / 2;
ybar = (ybaro * Ao - ybari * Ai) / (Ao - Ai);
    
% number of notches
n1 = 1;
n2 = 1;
n3 = 1;

% height of the notches
h1 = k1*l1*(ro+ybar)/n1;
h2 = k2*l2*(ro+ybar)/n2;
h3 = k3*l3*(ro+ybar)/n3;

% length of the uncut section
u1 = (l1 - k1*l1*ro)/n1;
u2 = (l2 - k2*l2*ro)/n2;
u3 = (l3 - k3*l3*ro)/n3;

cutouts1.w = w*10^3 .* ones(1,n1);
cutouts1.u = u1*10^3 .* ones(1,n1);
cutouts1.h = h1*10^3 .* ones(1,n1);
cutouts1.alpha = zeros(1,n1);
cutouts2.w = w*10^3 .* ones(1,n2);
cutouts2.u = u2*10^3 .* ones(1,n2);
cutouts2.h = h2*10^3 .* ones(1,n2);
cutouts2.alpha = zeros(1,n2);
cutouts3.w = w*10^3 .* ones(1,n3);
cutouts3.u = u3*10^3 .* ones(1,n3);
cutouts3.h = h3*10^3 .* ones(1,n3);
cutouts3.alpha = zeros(1,n3);

configuration1 = [h1*10^3, 0, 0];
configuration2 = [h2*10^3, 0, 0];
configuration3 = [h3*10^3, 0, 0];

robot1 = Wrist(ID*10^3, OD*10^3, n1, cutouts1);
robot2 = Wrist(ID*10^3, OD*10^3, n2, cutouts2);
robot3 = Wrist(ID*10^3, OD*10^3, n3, cutouts3);
robot1.fwkine(configuration1, eye(4));

T1real = robot1.transformations(:,:,end);
T1real(1:3,end) = T1real(1:3,end) / 1000;
robot2.fwkine(configuration2, T1real);

T2real = robot2.transformations(:,:,end);
T2real(1:3,end) = T2real(1:3,end) / 1000;
robot3.fwkine(configuration3, T2real);
% Display the wrist
% X = robot.pose(1,:) * 10^-3;
% Y = robot.pose(2,:) * 10^-3;
% Z = robot.pose(3,:) * 10^-3;
% 
% scatter3(X, Y, Z, 100, 'r', 'filled');
%hold on, axis equal

robotModel1 = robot1.makePhysicalModel();
robotModel2 = robot2.makePhysicalModel();
robotModel3 = robot3.makePhysicalModel();

X = robotModel1.backbone(1,:) * 10^-3;
Y = robotModel1.backbone(2,:) * 10^-3;
Z = robotModel1.backbone(3,:) * 10^-3;
scatter3(X, Y, Z, 100, col(7,:), 'filled');

X = robotModel2.backbone(1,:) * 10^-3;
Y = robotModel2.backbone(2,:) * 10^-3;
Z = robotModel2.backbone(3,:) * 10^-3;
scatter3(X, Y, Z, 100, col(7,:), 'filled');

X = robotModel3.backbone(1,:) * 10^-3;
Y = robotModel3.backbone(2,:) * 10^-3;
Z = robotModel3.backbone(3,:) * 10^-3;
scatter3(X, Y, Z, 100, col(7,:), 'filled');

axis equal
pause

X = robotModel1.surface.X * 10^-3;
Y = robotModel1.surface.Y * 10^-3;
Z = robotModel1.surface.Z * 10^-3;
surf(X, Y, Z, 'FaceColor',col(6,:));

X = robotModel2.surface.X * 10^-3;
Y = robotModel2.surface.Y * 10^-3;
Z = robotModel2.surface.Z * 10^-3;
surf(X, Y, Z, 'FaceColor',col(6,:));

X = robotModel3.surface.X * 10^-3;
Y = robotModel3.surface.Y * 10^-3;
Z = robotModel3.surface.Z * 10^-3;
surf(X, Y, Z, 'FaceColor',col(6,:));