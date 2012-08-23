function machine = DestroyMachine(machine)

%Destroys behavioral control state machine.
%
% Created 5/17/12 by TJB


%% Stop DAQ sessions and objects

if machine.IsDAQInitialized,
    for i = 1:machine.NumInputDAQSession,
        machine.InputDAQSession(i).stop;
        machine.InputDAQSession(i).release;
    end
    for i = 1:machine.NumDigitalInputObject,
        stop(machine.DigitalInputObject(i));
    end
    for i = 1:machine.NumAnalogOutputs,
        machine.AnalogOutputs(i).DAQSession.stop;
        machine.AnalogOutputs(i).DAQSession.release;
    end
    for i = 1:machine.NumDigitalOutputs,
        stop(machine.DigitalOutputs(i).DigitalOutputObject);
    end
    machine.IsDAQInitialized = 0;
end

%% Set variables and flags
machine.Active = 0;
machine.Interruptable = 1;
machine.EndTime = now;
