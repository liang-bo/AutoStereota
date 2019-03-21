function currPosition = moveToPosition(position, stepperHandle, panelHandle, encoderHandle, axisIdx, useEncoder)
%
% Function: 
%
global isMotorStop

unitStep = fix(360/0.13*16);% pulses per mm
tolPulseNum = 2;
timeDelay = 10;%ms

valPtr = libpointer('int64Ptr', 0);
calllib('phidget21', 'CPhidgetStepper_getCurrentPosition', stepperHandle, 0, valPtr);
currPosition = get(valPtr, 'Value');
position = -position; % Reverse the motor direction

% Set motor to position
calllib('phidget21', 'CPhidgetStepper_setTargetPosition', stepperHandle, 0, position);

% set the indicator
set(panelHandle.h_active,'BackgroundColor','red')
drawnow;java.lang.Thread.sleep(timeDelay);

isMotorStop = false;

if useEncoder
    trackingflag = 0;
    lastPosition = currPosition;
    
    dataptr = libpointer('int32Ptr',0);% for encoder
    calllib('phidget21', 'CPhidgetEncoder_getPosition', encoderHandle, axisIdx, dataptr);
    encoderPosition1 = double(get(dataptr, 'Value'));
    
    %wait for motor to arrive
    while abs(currPosition - position) > tolPulseNum

        calllib('phidget21', 'CPhidgetStepper_getCurrentPosition', stepperHandle, 0, valPtr);
        currPosition = double(get(valPtr, 'Value'));
        
        deltaPosition = abs(currPosition - lastPosition);
        lastPosition = currPosition;
        calllib('phidget21', 'CPhidgetEncoder_getPosition', encoderHandle, axisIdx, dataptr);
        deltaEncoderPosition = abs(double(get(dataptr, 'Value'))-encoderPosition1);
        encoderPosition1 = double(get(dataptr, 'Value'));
        
        if deltaEncoderPosition/deltaPosition < 0.1
            trackingflag = trackingflag+1;
            if trackingflag > 2
                calllib('phidget21', 'CPhidgetStepper_setEngaged', stepperHandle, 0, 0);
                display('Error')

                calllib('phidget21', 'CPhidgetStepper_getCurrentPosition', stepperHandle, 0, valPtr);
                currPosition = double(get(valPtr, 'Value'));
                
                calllib('phidget21', 'CPhidgetStepper_setEngaged', stepperHandle, 0, 1);
                calllib('phidget21', 'CPhidgetStepper_setTargetPosition', stepperHandle, 0, currPosition);

                currPosition = -currPosition;
                positionTxt = double(currPosition); %unitStep
                currPositionStr = num2str(positionTxt/unitStep,'%0.4f');
                set(panelHandle.h_positionEdt,'String',currPositionStr)
                set(panelHandle.h_active,'BackgroundColor','green')
                drawnow; java.lang.Thread.sleep(timeDelay);
                isMotorStop = true;
                return;
            end
        end
        java.lang.Thread.sleep(timeDelay);
    end
    
else
    
    while abs(currPosition - position) > tolPulseNum

        calllib('phidget21', 'CPhidgetStepper_getCurrentPosition', stepperHandle, 0, valPtr);
        currPosition = double(get(valPtr, 'Value'));
        java.lang.Thread.sleep(timeDelay);
        
    end
 
end

isMotorStop = true;
currPosition = -currPosition;
positionTxt = double(currPosition); %unitStep
currPositionStr = num2str(positionTxt/unitStep,'%0.4f');
set(panelHandle.h_positionEdt,'String',currPositionStr)
set(panelHandle.h_active,'BackgroundColor','green')
drawnow; java.lang.Thread.sleep(timeDelay);


end