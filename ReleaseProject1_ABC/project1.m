
%Example, showing how to read the data which is used in some problems in
%Tutorial2.problem 4, and in Project1/parts A,B,C.
%MTRN4010.T1.2022

% if you have questions, ask the lecturer, via Moodle or email(
% j.guivant@unsw.edu.au)

%%
function Main(file)

% load data, to be played back.
file='.\data015a.mat';   %one of the datasets we can use (simulated data, noise free, for Project 1).
load(file); % will load a variable named data (it is a structure)  
ExploreData(data);
end
%%
function ExploreData(data)
figure(1); clf();    % global CF.
% show the map landmarks and, if it is of interest to verify your solution, the
% walls/infrastructure present there.
% (All of them are provided in Global CF)
landmarks=data.Landmarks;
sortedLandmarks=zeros(2,size(landmarks,2),'double');
[sortedLandmarks(1,:),i]=sort(landmarks(1,:));
landmarksY=landmarks(2,:);
sortedLandmarks(2,:)=landmarksY(i);
clear i;
% plot centres of landmarks. 
%plot(landmarks(1,:),landmarks(2,:),'+');
hold on;
h0=[plot(0,0,'rs');plot(0,0,'b');plot(0,0,'-m');plot(0,0,'k+');plot(NaN,NaN,'r+')]; %plot pose, lidar, heading,OOI
plot(landmarks(1,:),landmarks(2,:),'o' ,'color',0*[0,1/3,0])
% some pixels will appear close to some of these crosses. It means the LiDAR scan is
% detecting the associated poles (5cm radius).

% plot interior of walls (they have ~20cm thickness; but the provided info just includes the ideal center of the walls
% your LiDAR scans will appear at ~ 10cm from some of those lines.    
% Wall transversal section:  :  wall left side [<--10cm-->|<--10cm-->] the other  wall side. 
plot(data.Walls(1,:),data.Walls(2,:),'color',[0,1,0]*0.7,'linewidth',3);
% legend({'Centers of landmarks','Walls (middle planes) '});
zoom on; 
title('Global CF (you should show some results here)');
xlabel('X (m)'); 
ylabel('Y (m)');

figure(2); clf();       % create a figure, or clear it if it does exist.
h1=plot(0,0,'.b');          % h: handle to this graphic object, for subsequent use.  
axis([1,321,0,15]);  % my region of interest, to show.
hold on;     plot([1,321],[10,10],'--r');  % just some line.
zoom on;     % by default, allow zooming in/out
title('LiDAR scans (polar)');  
ylabel('ranges (m)');

figure(3); clf();       % create a figure, or clear it if it does exist.
hold on;
h2=[plot(0,0,'.b');plot(0,0,'r+'),;plot(0,0,'g')];          % h: handle to this graphic object, for subsequent use.  
zoom on;     % by default, allow zooming in/out
title('LiDAR scans (cart)');  
ylabel('ranges (m)');

%table(0) time of event
%table(1) index of sensor data location (in vw)
%table(2) id of sensor
%vw(0) speed
%vw(1) angular velocity
%verify trajectory of the vehicle for verification (x,y,h)
%pose inital pose
%lidarcfg position of lidar on vehicle
%walls corner of walls 
%landmark centre of poles found (for verifying)
% I "copy" variables, for easy access (btw: Matlab copies vars "by reference", if used for reading)
pose=data.pose0;   %platform's initial pose; [x0;y0;heading0]   [meters;meters;radians]
ne=data.n;                   % how many events?
table=data.table;           % table of events.
event = table(:,1);         % first event.
t0=event(1) ; t0=0.0001*double(t0); % initial time.
vw=[0;0];  % To keep last [speed,heading rate] measurement.
etc=data.LidarCfg;  %Info about LiDAR installation (position and orientation, ..
% .. in platform's coordinate frame.). 
% info: 'LiDAR's pose in UGV's CF=[Lx;Ly;Alpha], in [m,m,?]'
% It needs to be considered in your calculations.
% Loop: read entries, one by one, for sequential processing.
pathx=[zeros(1,ne)];
pathy=[zeros(1,ne)];
pathTrix=[];
pathTriy=[];
pathTrih=[];
hhx=[];hhy=[];
hh=[zeros(4,size(landmarks,2))]; %hh(1)=x, hh(2)=y,hh(3)=diff from point to landmark,hh(4)= is point visible
hh(1,:)=NaN;hh(2,:)=NaN;hh(3,:)=inf;hh(4,:)=false;
OOI=[];
goodOOIx=[];goodOOIy=[];
avgtime=[];
xk_G=[];yk_G=[];
poseTri=[zeros(1,3)];
for i=1:ne      
    event = table(:,i);
    sensorID=event(3);                          % source (i.e. which sensor?)
    t=0.0001*double(event(1));                  % when was that measurement taken?
    dt=t-t0;t0=t;                               % dt since last event (needed for predictions steps).
%     pause(dt/30);
    % perform prediction X(t+dt) = f(X,vw,dt) ; vw model's inputs (speed and gyroZ) 
    pose=getPose(pose,vw,dt,h0);

    %saving path to plot later
    if mod(i,2)==0
        pathx(i)=pose(1);
        pathy(i)=pose(2);
    end
    
    here = event(2);                            % where to read it, from that sensor recorder.       
    switch sensorID    %measurement is from?        
        case 1  %  it is a scan from  LiDAR#1!
            %fprintf('LiDAR scan at t=[%d],dt=[%d]\n',t,dt); 
            ranges = data.scans(:,here);       
            tic
            OOI=processLiDAR(pose,ranges,etc,h0,h1,h2);  % e.g. for showing scan in "global CF", etc. 
            avgtime=[avgtime,toc];
            [hh,goodOOIx,goodOOIy,xk_G,yk_G]=dataAssoc(hh,OOI,sortedLandmarks,h0,pose,goodOOIx,goodOOIy,xk_G,yk_G);
            poseTri=localise(hh,h0,h2,pose,goodOOIx,goodOOIy,xk_G,yk_G);
            if ~isnan(poseTri(1))
%                 s=size(pathTrix,2);
%                 if s>2
%                     pathTrix=[pathTrix,pathTrix(s)+pathTrix(s)-pathTrix(s-1)];
%                     pathTriy=[pathTriy,pathTriy(s)+pathTriy(s)-pathTriy(s-1)];
%                     pathTrih=[pathTrih,pathTrih(s)];
%                 else
%                     pathTrix=[pathTrix,pathTrix(s)*2];
%                     pathTriy=[pathTriy,pathTriy(s)*2];
%                     pathTrih=[pathTrih,pathTrih(s-1)];
%                 end
                pathTrix=[pathTrix,poseTri(1)];
                pathTriy=[pathTriy,poseTri(2)];
                pathTrih=[pathTrih,poseTri(3)];
            end
%             figure(1)
%             hold on;
%             plot(pathTrix,pathTriy,'c.');
%             heading=[pathTrix(end),pathTrix(end)+1.1*cos(pathTrih(end));pathTriy(end),pathTriy(end)+1.1*sin(pathTrih(end))]
%             plot(heading(1,:),heading(2,:),'-y');
        continue;      
        case 2  %  it is speed encoder + gyro  (they are packed together)
            vw=data.vw(:,here);    % speed and gyroZ, last updated copy.                
            %fprintf('new measurement: v=[%.2f]m/s,w=[%.2f]deg/sec\n',vw.*[1;180/pi]);
        continue;  %"next!"        
        otherwise  % It may happen if the dataset contains measurements from sensors 
                     %which you had not expected to process.
        %fprintf('unknown sensor, type[%d], at t=[%d]\n',sensorID, t);         
        continue;
    end
end   
disp('Loop of events ends.');
disp('Showing ground truth (you would not achieve that, exactly.)');
format longG
avg=sum(avgtime)/size(avgtime,2)
ShowVerification1(data,pathx,pathy,pathTrix,pathTriy,pathTrih);
end
%%
function poseNext=getPose(pose,vw,dt,h0)
    %part a
    h=pose(3); %heading
    dpose=[vw(1)*cos(h);vw(1)*sin(h);vw(2)]; %translate x with lidar pos
    poseNext=pose+dt*dpose;
    heading=[poseNext(1),1.1*cos(poseNext(3))+poseNext(1);poseNext(2),1.1*sin(poseNext(3))+pose(2)];    
    set(h0(1),'xdata',poseNext(1),'ydata',poseNext(2));
    set(h0(3),'xdata',heading(1,:),'ydata',heading(2,:));
    
end
%%
function OOI=processLiDAR(pose,ranges,etc,h0,h1,h2)
%part b
% process LiDAR scan.  
    %getting lidar scan
    rr=double(ranges)/100;     
    set(h1,'xdata',[1:1:321],'ydata',rr);
    %break up data
    aa=deg2rad(-80:0.5:80);
    ii=find((rr>1)&(rr<20)); %return index of all values between 1m and 20m
    rr=rr(ii)';
    aa=aa(ii);
    %converting polar to cartesian
    x_cart=rr.*cos(aa);
    y_cart=rr.*sin(aa);
    cart=[x_cart+etc.Lx;y_cart+etc.Ly];    
    set(h2(1),'xdata',x_cart,'ydata',y_cart);   
    %do OOI detection   
    hhx=[];
    hhy=[];
    xk_G=[];
    yk_G=[];
    for i=1:size(rr,2)-1
        if (abs(rr(i+1)-rr(i)))>0.8 % if diff is greater than 1m then take a look
            j=1;
            temp=[];
            temp=[temp,i+1]; %store index of point of interest
            %group cluster of points if present by taking start and end index
            while((i+1+j)<size(rr,2))
                if(abs(rr(i+1)-rr(i+1+j))>0.5)
                    temp=[temp,i+j];
                    if i+j+2<size(rr,2)
                       i=i+j+1; %skip next point if possible as pole to wall
                               %movement will trigger detection 
                    end
                    break
                end
                j=j+1;
            end
            tempx=[];
            tempy=[];
            if size(temp,2)==1
                hhx=[hhx,rr(temp(1))*cos(aa(temp(1)))];
                hhy=[hhy,rr(temp(1))*sin(aa(temp(1)))];
            elseif temp(1)==temp(2)
                hhx=[hhx,rr(temp(1))*cos(aa(temp(1)))];
                hhy=[hhy,rr(temp(1))*sin(aa(temp(1)))];
            elseif (0.05<=sqrt((x_cart(temp(2))-x_cart(temp(1)))^2+(y_cart(temp(2))-y_cart(temp(1)))^2))& ...
                (sqrt((x_cart(temp(2))-x_cart(temp(1)))^2+(y_cart(temp(2))-y_cart(temp(1)))^2)<=0.3)
                for k=temp(1):temp(2)
                    tempx=[tempx,rr(k)*cos(aa(k))];
                    tempy=[tempy,rr(k)*sin(aa(k))];
                end
                s=temp(2)-temp(1)+1;
                hhx=[hhx,sum(tempx)/s+etc.Lx];
                hhy=[hhy,sum(tempy)/s+etc.Ly];
            end           
        end
    end
    OOI=[hhx;hhy];
    
    %converting local to global
    h=pose(3);
    R=[[cos(h),-sin(h)];[sin(h),cos(h)]]; %rotate then translate
    cart=R*cart;    
    cart(1,:)=cart(1,:)+pose(1);
    cart(2,:)=cart(2,:)+pose(2);   
    set(h0(2),'xdata',cart(1,:),'ydata',cart(2,:));

  
end
%%
function [hh,goodOOIx,goodOOIy,xk_G,yk_G]=dataAssoc(hh,OOI,sortedLandmarks,h0,pose,goodOOIx,goodOOIy,xk_G,yk_G)
    if size(OOI,1)~=0&&size(OOI,2)~=0
        %sort first so a local copy of the OOI can be kept
        sortedOOI=zeros(2,size(OOI,2),'double');
        [sortedOOI(1,:),i]=sort(OOI(1,:));
        y=OOI(2,:);
        sortedOOI(2,:)=y(i);
        clear i;
        clear y;
        sortedLocalOOI=sortedOOI;
        %convert to global
        h=pose(3);
        R=[[cos(h),-sin(h)];[sin(h),cos(h)]];
        sortedOOI=R*sortedOOI;
        sortedOOI(1,:)=sortedOOI(1,:)+pose(1);
        sortedOOI(2,:)=sortedOOI(2,:)+pose(2);
        figure(1)
        hold on;
        set(h0(5),'xdata',sortedOOI(1,:),'ydata',sortedOOI(2,:));
        hh(4,:)=false;
        goodOOIx=[];
        goodOOIy=[];
        xk_G=[];
        yk_G=[];
        for i=1:size(sortedOOI,2)
              sortedOOI(1,i) %x
%               sortedOOI(2,i) %y
            for j=1:size(sortedLandmarks,2)
%                 sortedLandmarks(1,j)
%                 sortedLandmarks(2,j)
                dist=sqrt((sortedLandmarks(1,j)-sortedOOI(1,i)).^2+(sortedLandmarks(2,j)-sortedOOI(2,i)).^2);
                if dist<0.051
                    goodOOIx=[goodOOIx,sortedLocalOOI(1,i)];
                    goodOOIy=[goodOOIy,sortedLocalOOI(2,i)];
                    hh(4,j)=true;
                    xk_G=[xk_G,sortedLandmarks(1,j)];
                    yk_G=[yk_G,sortedLandmarks(2,j)];
                    if dist<hh(3,j)
                        hh(1,j)=sortedOOI(1,i);
                        hh(2,j)=sortedOOI(2,i);
                        hh(3,j)=dist;
%                         hh
                        break; %move to next OOI as there shouldn't be any more OOIs of current landmark
                    end
                end
            end
        end
%         hh
%         good=[zeros(2,size(goodOOIx,2))];
%         good(1,:)=goodOOIx;
%         good(2,:)=goodOOIy;
%         good=R*good;
%         good(1,:)=good(1,:)+pose(1);
%         good(2,:)=good(2,:)+pose(2);
        figure(1)
        hold on;
        set(h0(4),'xdata',hh(1,:),'ydata',hh(2,:));
%         set(h0(5),'xdata',good(1,:),'ydata',good(2,:));
    end
end
%%
function poseTri=localise(hh,h0,h2,pose,goodOOIx,goodOOIy,xk_G,yk_G)
    if size(goodOOIx,2)~=0        
        figure(3);
        hold on;
        set(h2(2),'xdata',goodOOIx,'ydata',goodOOIy);
        r=[zeros(1,size(goodOOIx,2))];
        a=[zeros(1,size(goodOOIx,2))];
        
        xk_L = goodOOIx;
        yk_L = goodOOIy;
        
%         y = [sqrt(xk_L;]
        
        for i=1:size(goodOOIx,2)
            [theta,rho]=cart2pol(goodOOIx(1,i),goodOOIy(1,i));
            r(i)=rho;
            a(i)=theta;       
        end
        y = [r; a];
        %y = f(parameters,x)
        %data is [x landmark global;y landmark global]
        %params is [x,y,phi] global
        f = @(params,data) [sqrt( (data(1,:) - params(1)).^2 + (data(2,:) - params(2)).^2); ...
            atan2(data(2,:) - params(2), data(1,:) - params(1)) - params(3)];
        
        output = lsqcurvefit(f, double([pose(1);pose(2);pose(3)]), [xk_G; yk_G], y);
        poseTri=output;
    else
        poseTri=[NaN,NaN,NaN];
    end
    
end

%%
function ShowVerification1(data,pathx,pathy,pathTrix,pathTriy,pathTrih)
% part c
% plot some provided verification points (of platfom's pose).
% those are the ground truth.
% Do not expect your solution path to intesect those points, as those are
% the real positions, and yours are approximate ones, based on
% predictions, and using sampled inputs. 
% The discrepancy should be just fraction of cm, as the inputs are not
% polluted by noise, and the simulated model is the nominal analog model.
% The errors are mostly due to time discretization and sampled inputs.
% Inputs were sampled @100Hz (10ms) (you can infer that from "dt".
figure(1)
hold on;
p=data.verify.poseL;
plot(p(1,:),p(2,:),'r.');
plot(pathTrix,pathTriy,'c*');
plot(pathx,pathy,'b.','MarkerSize',4);
heading=[pathTrix(end),pathTrix(end)+1.1*cos(pathTrih(end));pathTriy(end),pathTriy(end)+1.1*sin(pathTrih(end))];
plot(heading(1,:),heading(2,:),'-y');
h0=legend({'UGV','lidar scan','heading','COG of poles from lidar','landmarks','Walls (middle planes)','Ground truth (subsampled)','path taken (subsampled)','path taken (localised)'});
end
