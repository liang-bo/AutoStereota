function phidgetClose(Handle)
% function: phidgetClose(Handle)
% Handle: phidget device handle
% Turn off this device

calllib('phidget21', 'CPhidget_close', Handle);
calllib('phidget21', 'CPhidget_delete', Handle);
disp('Device Closed');

end