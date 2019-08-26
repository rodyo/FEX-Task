function logicalColloquialProgrammerspeak(terminateTask, varargin)
    
    task_exit_status = varargin{1};
    
    switch task_exit_status
        case true
            terminateTask(Tasking.ExitStatus.DUH);
        case false
            terminateTask(Tasking.ExitStatus.NOPE);
        otherwise % (should be unreachable, unless cosmic rays attack)
            terminateTask(Tasking.ExitStatus.ERROR, MException(...
                [mfilename ':attack_of_the_cosmic_rays'],...
                'zOMG YOU WERE STRUCK BY A COSMIC RAY!!'));
    end
    
end
