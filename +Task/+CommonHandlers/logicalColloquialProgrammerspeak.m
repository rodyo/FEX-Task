function logicalColloquialProgrammerspeak(terminateTask, varargin)
    
    task_exit_status = varargin{1};
    
    switch task_exit_status
        case true
            terminateTask(Task.ExitStatus.DUH);
        case false
            terminateTask(Task.ExitStatus.NOPE);
        otherwise % (should be unreachable, unless cosmic rays attack)
            terminateTask(Task.ExitStatus.ERROR, MException(...
                [mfilename ':attack_of_the_cosmic_rays'],...
                'zOMG YOU WERE STRUCK BY A COSMIC RAY!!'));
    end
    
end
