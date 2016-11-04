function logicalPassFail(terminateTask, varargin)
    
    task_exit_status = varargin{1};
    
    switch task_exit_status
        case true
            terminateTask(Task.ExitStatus.PASS);
        case false
            terminateTask(Task.ExitStatus.FAIL);
        otherwise % (should be unreachable, unless cosmic rays attack)
            terminateTask(Task.ExitStatus.ERROR, MException(...
                [mfilename ':unknown_exit_status'],...
                'Unsupported task exit status: ''%d''.',...
                task_exit_status));
    end
    
end
