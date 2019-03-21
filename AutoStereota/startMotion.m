function mStatus = startMotion(idx, grid, stepperHandles, panelHandles)
%
% Function: 
%
global currentPositionX  currentPositionY  currentPositionZ
global pausePositionX pausePositionY pausePositionZ 
global useEncoderX useEncoderY useEncoderZ
global surgIdx isPause isFinished isStop

mStatus = 0;%0-normal 1-paused 2-stoped
unitStep = fix(360/0.13*16);% pulses per mm
delaytime = 5;%ms
stepNum = size(grid,1);

stepperHandleX = stepperHandles.stepperHandleX;
stepperHandleY = stepperHandles.stepperHandleY;
stepperHandleZ = stepperHandles.stepperHandleZ;
encoderHandle = stepperHandles.encoderHandle;
panelHandleX = panelHandles.panelHandleX;
panelHandleY = panelHandles.panelHandleY;
panelHandleZ = panelHandles.panelHandleZ;
hview_ax = panelHandles.hview_ax;

for m = idx:stepNum
    if isStop
        isStop = false;
        mStatus = 2;
        return;
    end
    if isPause
        if m > 1
            deltaPositionX = fix(grid(m,1)*unitStep - grid(m-1,1)*unitStep);
            deltaPositionY = fix(grid(m,2)*unitStep - grid(m-1,2)*unitStep);
            targetPositionX = currentPositionX + deltaPositionX; 
            targetPositionY = currentPositionY + deltaPositionY;
            
            if isStop
                isStop = false;
                mStatus = 2;
                return;
            end
            hp_x = plot3(hview_ax, grid(m,1),grid(m,2),-grid(m,3),'ro','MarkerFaceColor','r');
            java.lang.Thread.sleep(delaytime);
            currentPositionX = moveToPosition(targetPositionX, stepperHandleX, panelHandleX, encoderHandle,0,useEncoderX);%Move x-axis
            delete(hp_x)
            if isStop
                isStop = false;
                mStatus = 2;
                return;
            end
            hp_y = plot3(hview_ax, grid(m,1),grid(m,2),-grid(m,3),'ro','MarkerFaceColor','r');
            java.lang.Thread.sleep(delaytime);
            currentPositionY = moveToPosition(targetPositionY, stepperHandleY, panelHandleY, encoderHandle,1,useEncoderY);%Move y-axis
            delete(hp_y)
        end
        
        
        % Move z-axis
        deltaPositionZ = fix(grid(m,3)*unitStep);
        targetPositionZ = currentPositionZ - deltaPositionZ;
        
        if isStop
            isStop = false;
            mStatus = 2;
            return;
        end
        hp_z_u = plot3(hview_ax, grid(m,1),grid(m,2),-grid(m,3),'rv','MarkerFaceColor','r');
        java.lang.Thread.sleep(delaytime);
        currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, panelHandleZ, encoderHandle,2,useEncoderZ);%Move z-axis
        delete(hp_z_u);
        
        if isStop
            isStop = false;
            mStatus = 2;
            return;
        end
        targetPositionZ = currentPositionZ + deltaPositionZ;
        hp_z_d = plot3(hview_ax, grid(m,1),grid(m,2),-grid(m,3),'r^','MarkerFaceColor','r');
        java.lang.Thread.sleep(delaytime);
        currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, panelHandleZ, encoderHandle,2,useEncoderZ);%Move z-axis
        delete(hp_z_d)
    else
        mStatus = 1;
        surgIdx = m;
        pausePositionX = currentPositionX;
        pausePositionY = currentPositionY;
        pausePositionZ = currentPositionZ;
        return;
    end
    
    if m == stepNum
        isFinished = true;
    end
end

end