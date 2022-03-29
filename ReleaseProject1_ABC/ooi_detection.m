for i=1:size(rr,2)-1
        
        if (abs(rr(i+1)-rr(i)))>1.1 % if diff is greater than 1m then take a look
            j=1;
            temp=[];
            temp=[temp,i+1]; %store index of point of interest
            %group cluster of points if present by taking start and end
            %index
            while((i+1+j)<size(rr,2))
                if(abs(rr(i+1)-rr(i+1+j))>1)
                    temp=[temp,i+1+j]
                    if i+j+2<size(rr,2)
                       i=i+j+2 %skip next point if possible as pole to wall
                               %movement will trigger detection 
                    end
                    break
                end
                j=j+1;
            end
            tempx=[];
            tempy=[];
            if size(temp,2)==1
                hhx=[hhx,rr(temp(1))*cos(temp(1))];
                hhy=[hhy,rr(temp(1))*sin(temp(1))];
            else
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

    for i=1:size(cart,2)-1
        x_cart(i+1)
        y_cart(i+1)
        dist=sqrt((x_cart(i+1)-x_cart(i))^2+(y_cart(i+1)-y_cart(i))^2)
        if(dist>=1)
            j=1;
            temp=[];
            temp=[temp,i+1]; %store index of point of interest
            while((i+j+2)<size(x_cart,2))
                dist1=sqrt((x_cart(i+1+j)-x_cart(i)^2)+(y_cart(i+1+j)-y_cart(i)^2));
                if(dist1>=1)
                    temp=[temp,i+1+j]
%                     if i+j+2<size(rr,2)
%                        i=i+j+2; %skip next point if possible as pole to wall
                               %movement will trigger detection 
%                     end
                    break
                end
                 j=j+1;
            end
            tempx=[];
            tempy=[];
            if size(temp,2)==1
                hhx=[hhx,x_cart(temp(1))];
                hhy=[hhy,y_cart(temp(1))];
            else
                for k=temp(1):temp(2)
                    tempx=[tempx,x_cart(k)];
                    tempy=[tempy,y_cart(k)];
                end
                s=temp(2)-temp(1)+1;
                hhx=[hhx,sum(tempx)/s];
                hhy=[hhy,sum(tempy)/s];
            end
        end
    end
