function encoderHandle = encoderInit(serialNumber,initPosition)
% function: encoderHandle = encoderInit(serialNumber,initPosition)
% serialNumber: phidget device encoder device serial number
% initPosition: initial position for all the stepper motors
% Return: encoderHandle

timeDelay = 5;
encoderHandle = libpointer('int32Ptr');

calllib('phidget21', 'CPhidgetEncoder_create', encoderHandle);
calllib('phidget21', 'CPhidget_open', encoderHandle, serialNumber);%

if calllib('phidget21', 'CPhidget_waitForAttachment', encoderHandle, 2500) == 0
    
    % x axis
    calllib('phidget21', 'CPhidgetEncoder_setPosition', encoderHandle, 0, initPosition(1));
    calllib('phidget21', 'CPhidgetEncoder_setEnabled', encoderHandle, 0, true);
    
    % y axis
    calllib('phidget21', 'CPhidgetEncoder_setPosition', encoderHandle, 1, initPosition(2));
    calllib('phidget21', 'CPhidgetEncoder_setEnabled', encoderHandle, 1, true);
    
    % z axis
    calllib('phidget21', 'CPhidgetEncoder_setPosition', encoderHandle, 2, initPosition(3));
    calllib('phidget21', 'CPhidgetEncoder_setEnabled', encoderHandle, 2, true);
    
    disp('Opened Encoder'); java.lang.Thread.sleep(timeDelay);
    
else
    disp('Could not open Encoder')
end
end