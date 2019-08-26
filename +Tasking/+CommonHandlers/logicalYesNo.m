function logicalYesNo(terminateTask, varargin)
    
    task_exit_status = varargin{1};
    
    switch task_exit_status
        case true
            terminateTask(Tasking.ExitStatus.YES);
        case false
            terminateTask(Tasking.ExitStatus.NO);
        otherwise % (should be unreachable, unless cosmic rays attack)
            terminateTask(Tasking.ExitStatus.ERROR, MException(...
                [mfilename ':unknown_exit_status'],...
                'Unsupported task exit status: ''%d''.',...
                task_exit_status));
    end
    
end
