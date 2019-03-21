function [stepperHandle,isOpen] = stepperInit(initData)
% function: [stepperHandle,isOpen] = stepperInit(initData)
% Input: 
% initData = [VelocityLimit Acceleration CurrentLimit serialNumber]
% Return: 
% stepperHandle: stepper motor handle
% status: is OPEN

isOpen = false;
VelocityLimit = initData(1);
Acceleration = initData(2);
CurrentLimit = initData(3);
serialNumber = initData(4);

unitStep = fix(360/0.13*16);% pulses per mm
initPosition = -initData(6)*unitStep;
timeDelay = 20;

stepperHandle = libpointer('int32Ptr');
calllib('phidget21', 'CPhidgetStepper_create', stepperHandle);
calllib('phidget21', 'CPhidget_open', stepperHandle, serialNumber);

if calllib('phidget21', 'CPhidget_waitForAttachment', stepperHandle, 2500) == 0
    isOpen = true;
    disp('Opened Stepper');   

    %set parameters for stepper motor in index 0 (velocity, acceleration, current)
    %these values were set basd on some testing based on a 1063 and a stepper motor I had here to test with
    %might need to modify these values for your particular case
    calllib('phidget21', 'CPhidgetStepper_setVelocityLimit', stepperHandle, 0, VelocityLimit);
    calllib('phidget21', 'CPhidgetStepper_setAcceleration', stepperHandle, 0, Acceleration);
    calllib('phidget21', 'CPhidgetStepper_setCurrentLimit', stepperHandle, 0, CurrentLimit);
    
    %For the 1063 Bipolar stepper controller
    calllib('phidget21', 'CPhidgetStepper_setCurrentPosition', stepperHandle, 0, initPosition);
    java.lang.Thread.sleep(timeDelay); disp('Engage Motor');
    
    %engage the stepper motor in index 0
    calllib('phidget21', 'CPhidgetStepper_setEngaged', stepperHandle, 0, 1);
    java.lang.Thread.sleep(timeDelay);   
else
    disp('Could Not Open Stepper');
end

end