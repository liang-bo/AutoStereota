function motionGrid = stepGenerator(sampleNum,sampleStep,mode,dMatrix,orient,holeDepth)
% Mode: 1 - cylinder
%       2 - Flat circle
%       3 - Triangular prism
%       4 - Cube
% % -- Debug --
% sampleNum = 11;
% sampleStep = 0.08;
% mode = 3;
% dMatrix = [1,1.2,1;
%            1,0.2,3;
%            1,0.1,2;
%            0,0.5,3;
%            0,0.5,3;];
% orient = 4;
% holeDepth = 1.0;

switch mode

    case 1 % cylinder
        sampNumRad = sampleNum/2;
        [x_Cor,y_Cor] = meshgrid(-sampNumRad:sampNumRad,-sampNumRad:sampNumRad);
        xy_mask = sqrt(x_Cor.^2+y_Cor.^2)<=(sampNumRad+0.5);
        N = sum(sum(xy_mask));
        repM = sum(dMatrix(:,1));
        accDepth = 0;
        M = N*sum(dMatrix(1:repM,3));
        motionGrid=zeros(M,3);
        n=1;%grid row index        
        for m = 1:repM           
            for t = 1:dMatrix(m,3)
                
                accDepth = accDepth + dMatrix(m,2);
                x=0;%x,y,z coordinate
                y=0; 
                flag=1;
                                
                for i=1:sampleNum+1
                    for j=1:i
                        
                        if sqrt(x^2+y^2)<=(sampNumRad+0.5)
                            motionGrid(n,1)=x*sampleStep;
                            motionGrid(n,2)=y*sampleStep;
                            motionGrid(n,3)=accDepth;
                            n=n+1;
                        end
                        
                        x=x+flag;
                    end
                    
                    for j=1:i
                        
                        if sqrt(x^2+y^2)<=(sampNumRad+0.5)
                            motionGrid(n,1)=x*sampleStep;
                            motionGrid(n,2)=y*sampleStep;
                            motionGrid(n,3)=accDepth;
                            n=n+1;
                        end
                        y=y+flag;
                        
                    end
                    flag=flag*(-1);
                end
            end
            
        end
        
    case 2
        
        sampNumRad = sampleNum/2;
        [x_Cor,y_Cor] = meshgrid(-sampNumRad:sampNumRad,-sampNumRad:sampNumRad);
        xy_mask = sqrt(x_Cor.^2+y_Cor.^2)<=(sampNumRad+0.5);
        N = sum(sum(xy_mask));
        
        accDepth = 0;
        
        motionGrid=zeros(N,3);
        n=1;%grid row index        
        x=0;%x,y,z coordinate
        y=0;
        flag=1;
        
        for i=1:sampleNum+1
            for j=1:i
                
                if sqrt(x^2+y^2)<=(sampNumRad+0.5)
                    motionGrid(n,1)=x*sampleStep;
                    motionGrid(n,2)=y*sampleStep;
                    motionGrid(n,3)=accDepth;
                    n=n+1;
                end
                
                x=x+flag;
            end
            
            for j=1:i
                
                if sqrt(x^2+y^2)<=(sampNumRad+0.5)
                    motionGrid(n,1)=x*sampleStep;
                    motionGrid(n,2)=y*sampleStep;
                    motionGrid(n,3)=accDepth;
                    n=n+1;
                end
                y=y+flag;
                
            end
            flag=flag*(-1);
        end    
    case 3
        repM = sum(dMatrix(:,1));
        deltaDepth = sum(dMatrix(:,1).*dMatrix(:,2).*dMatrix(:,3)) - holeDepth;
        N = sampleNum^3;
%         Depth1 = dMatrix(1,2) - deltaDepth;
        motionGrid=zeros(N,3);
        accDepth = 0;
        n =1;
        
        switch orient
            case 1
                flag1 = 1;
                flag2 = 1;
                x_idx = 1;
                y_idx = 2;
            case 2
                flag1 = 1;
                flag2 = -1;
                x_idx = 1;
                y_idx = 2;
            case 3
                flag1 = 1;
                flag2 = 1;
                x_idx = 2;
                y_idx = 1;
            case 4
                flag1 = 1;
                flag2 = -1;
                x_idx = 2;
                y_idx = 1;
        end
                
        for m = 1:repM
            for t = 1:dMatrix(m,3)
                
                x = 0;
                accDepth = accDepth + dMatrix(m,2);
                k = ceil((holeDepth - (accDepth - deltaDepth))/sampleStep);
                flag = flag1;
                
                for j = 0:(k-1)
                    
                    for i = 1:sampleNum
                        
                        motionGrid(n,x_idx)=x*sampleStep;
                        motionGrid(n,y_idx)=flag2*j*sampleStep;
                        motionGrid(n,3)=accDepth;
                        x=x+flag;
                        n = n + 1;
                    end
                    
                    motionGrid(n,x_idx)=x*sampleStep;
                    motionGrid(n,y_idx)=flag2*j*sampleStep;
                    motionGrid(n,3)=accDepth;
                    n = n + 1;
                    flag=flag*(-1);
                    
                end
            end
        end
        motionGrid = motionGrid(1:(n-1),:);      
    case 4
        
        N = sampleNum^3;
        motionGrid=zeros(N,3);
        accDepth = 0;
        n =1;
        
        switch orient
            case 1
                flag1 = 1;
                x_idx = 1;
                y_idx = 2;
            case 2
                flag1 = -1;
                x_idx = 1;
                y_idx = 2;
            case 3
                flag1 = 1;
                x_idx = 2;
                y_idx = 1;
            case 4
                flag1 = -1;
                x_idx = 2;
                y_idx = 1;
        end
        
        for k = 1:sampleNum

            x = 0;
            y = 0;
            accDepth = accDepth + sampleStep;
            flag = flag1;
            
            for j = 1:sampleNum

                for i = 1:sampleNum-1
                    
                    motionGrid(n,x_idx)=x*sampleStep;
                    motionGrid(n,y_idx)=(j-1)*sampleStep;
                    motionGrid(n,3)=accDepth;
                    x=x+flag;
                    n = n + 1;
                end
                
                motionGrid(n,x_idx)=x*sampleStep;
                motionGrid(n,y_idx)=(j-1)*sampleStep;
                motionGrid(n,3)=accDepth;
                n = n + 1;
                flag=flag*(-1);

            end
        end
        
    otherwise
        
end

% %%
% figure;plot3(motionGrid(:,1),motionGrid(:,2),-motionGrid(:,3),'o--','color',[0.15 0.15 0.15])

end