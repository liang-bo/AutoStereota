function isMotorStop = motorStop(stepperHandle, panelHandle)

unitStep = fix(360/0.13*16);% pulses per mm
timeDelay = 5;

valPtr = libpointer('int64Ptr', 0);
calllib('phidget21', 'CPhidgetStepper_getCurrentPosition', stepperHandle, 0, valPtr);
currPosition = get(valPtr, 'Value');

calllib('phidget21', 'CPhidgetStepper_setEngaged', stepperHandle, 0, 0);
display('Motor Stopped!'); java.lang.Thread.sleep(timeDelay);
isMotorStop = true;

calllib('phidget21', 'CPhidgetStepper_setEngaged', stepperHandle, 0, 1);
calllib('phidget21', 'CPhidgetStepper_setTargetPosition', stepperHandle, 0, currPosition);

positionTxt = -double(currPosition);%/unitStep
currPositionStr = num2str(positionTxt/unitStep,'%0.4f');
set(panelHandle.h_positionEdt,'String',currPositionStr)
set(panelHandle.h_active,'BackgroundColor','green')
drawnow;
java.lang.Thread.sleep(timeDelay);

end