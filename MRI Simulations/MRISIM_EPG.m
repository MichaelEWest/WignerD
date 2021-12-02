
%This file written to "simulate" a 2D Cartesian MRI sequence
%Assume cat is a representation of T1s or T2s of a homogeneous image
%
%
%
%
clear 
clc
catt = imread('CatGrayscale.gif');
birb = imread('BirdGrayscale.gif');
%%
%Gradient strengths-- assume 30 mT/m max
%assume voxel spacing is 1mm center to center (512 ~ .5 meters)
%      __
% RF  |  |
%    _|  |________________________________________________
%     0  1   
%            1    2
%             ____
%GPE (x)     /____\
%    _______/______\______________________________________
%           \ ____ /
%            \____/
%
%                    2           3
%GFE (y)             _________________________________
%    ______         /                                 \___
%          \       /
%           \_____/
%            1   2
%                                ()
%                             ()()()()
%                           ()()    ()()
% SIG___________________()()()        ()()()_______________
%                    2           3             
%
%
%       |          TE            |

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSTANTS
G_max = 3; %G/cm
GFE = -3;
GPEmax = 3;
GFEwind = 3;

N_PE = 32;   %Number of phase encodes
N_RO = 32;   %Number of readout points
ImageSize = 16;  %"size" of image, cm
IMS = 32;      %Number of pixels per side of square image
Del_y = 0.1; %Spatial resolution of voxels, cm
gratio = 4248; %Gyromagnetic ratio, Hz/G

T1scale = 5000;
T2scale = 0.0005;

catt = imresize(catt,IMS/512);
birb = imresize(birb,IMS/512);

T1map = double(birb)/256*T1scale;
T2map = double(catt)/256*T2scale;

Del_ky = 1/(N_PE*Del_y);  %k-space voxel spacing
ky_max = 1/2*(N_PE-1)*Del_ky;  %cm^-1
%Tau_PE = ky_max/gratio/G_max;  %Phase encode time 

%Tau_RO = -2*Tau_PE*GFEwind/GFE;

res = ImageSize/IMS; %cm/pixel
resG = gratio*G_max*res; %Hz/pixel
windtime = (resG)^-1;  %Amount of time to wind the most-central voxels by 1 integer twist

Q0 = zeros(3,17,N_PE,N_RO);
Q1 = zeros(3,17,N_PE,N_RO);
Q2 = zeros(3,17,N_PE,N_RO);
Q0(3,1,:,:) = 1;
for mm = 1:1:N_PE
    for nn =1:1:N_RO
        Q1(:,:,mm,nn) = Ry(pi/2)*Q0(:,:,mm,nn);
    end
end

%PHASE ENCODE GRADIENT (3rd dimension)
for mm = 1:1:8
   Q2(2,10-mm,mm,:)= Q1(1,1,mm,:);
end
for mm = 9:1:16
   Q2(1,mm+1-8,mm,:)= Q1(1,1,mm,:);
end
%unit gradient 
test1 =-8:-1;
test2 =1:8;
test = cat(2,test1,test2);

%First phase encode half
Q2(2,8) = Q1(1,1);


%%
function val = xGrad(rho,ImageSize,IMS,thetam)  
    for mm = 1:1:IMS
        xdisp(mm) = -ImageSize/2+ImageSize/(IMS-1)*(mm-1);
        for nn = 1:1:IMS
            val(mm,nn,:) = Rz(thetam*xdisp(mm))*squeeze(rho(mm,nn,:));
        end
    end
end
function val = yGrad(rho,ImageSize,IMS,thetam)  
    for mm = 1:1:IMS
        for nn = 1:1:IMS
            ydisp(mm) = -ImageSize/2+ImageSize/(IMS-1)*(nn-1);
            val(mm,nn,:) = Rz(thetam*ydisp(mm))*squeeze(rho(mm,nn,:));
        end
    end
end
function val = Relax(rho,tau,IMS,T1map,T2map)
    for mm = 1:1:IMS
        for nn =1:1:IMS
            T1 = T1map(mm,nn);
            T2 = T2map(mm,nn);
            E1 = exp(-tau/T1);
            E2 = exp(-tau/T2);
            Relmat =  [E2 0 0 0;
                       0 E2 0 0;
                       0 0 E1 1-E1;
                       0 0  0 1];
           val(mm,nn,:) = Relmat*squeeze(rho(mm,nn,:));
        end
    end


end
function val = Rot(rho,rmat,IMS)
    for mm = 1:1:IMS
        for nn = 1:1:IMS
            val(mm,nn,:) = rmat*squeeze(rho(mm,nn,:));
        end
    end
end
function val = Rx(theta)
    val = [1 0           0         ;
           0 cos(theta) -sin(theta);
           0 sin(theta)  cos(theta)];
end
function val = Ry(theta)
    val = [ cos(theta) 0 sin(theta);
            0          1 0         ;
           -sin(theta) 0 cos(theta)];
end
function val = Rz(theta)
    val = [cos(theta) -sin(theta) 0;
           sin(theta)  cos(theta) 0;
           0           0          1];
end


