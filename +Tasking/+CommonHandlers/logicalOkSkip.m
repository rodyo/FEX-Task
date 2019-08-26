function logicalOkSkip(terminateTask, varargin)
    
    task_exit_status = varargin{1};
    
    switch task_exit_status
        case true
            terminateTask(Tasking.ExitStatus.COMPLETED);
        case false
            terminateTask(Tasking.ExitStatus.NOOP);
        otherwise % (should be unreachable, unless cosmic rays attack)
            terminateTask(Tasking.ExitStatus.ERROR, MException(...
                [mfilename ':unknown_exit_status'],...
                'Unsupported task exit status: ''%d''.',...
                task_exit_status));
    end
    
end
