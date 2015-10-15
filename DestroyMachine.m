function machine = DestroyMachine(machine)

%Destroys behavioral control state machine.
%
% Created 5/17/12 by TJB


%% Stop DAQ sessions and objects

if machine.IsDAQInitialized,
    for i = 1:machine.NumInputDAQSession,
        fprintf('Cleaning up analog inputs...\n');
        while machine.InputDAQSession(i).IsRunning,
            machine.InputDAQSession(i).stop;
        end
        machine.InputDAQSession(i).release;
    end
    for i = 1:machine.NumDigitalInputObject,
        fprintf('Cleaning up digital inputs...\n');
        stop(machine.DigitalInputObject(i));
    end
    for i = 1:machine.NumAnalogOutputs,
        fprintf('Cleaning up analog outputs...\n');
        while machine.AnalogOutputs(i).DAQSession.IsRunning,
            machine.AnalogOutputs(i).DAQSession.stop;
        end
        machine.AnalogOutputs(i).DAQSession.release;
    end
    for i = 1:machine.NumCounterOutputs,
        fprintf('Cleaning up counter outputs...\n');
        while machine.CounterOutputs(i).DAQSession.IsRunning && ~machine.CounterOutputs(i).DAQSession.IsDone,
            try
                machine.CounterOutputs(i).DAQSession.stop;
            catch err
                fprintf('STUPID NIDAQ\n');
            end
        end
        machine.CounterOutputs(i).DAQSession.release;
    end
    for i = 1:machine.NumDigitalOutputs,
        fprintf('Cleaning up digital outputs...\n');
        stop(machine.DigitalOutputs(i).DigitalOutputObject);
    end
    machine.IsDAQInitialized = 0;
end

%% Set variables and flags
machine.Active = 0;
machine.Interruptable = 1;
machine.EndTime = now;
