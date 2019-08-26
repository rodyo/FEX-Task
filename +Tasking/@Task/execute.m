% Execute task
function varargout = execute(obj)

    try
        % Display task startup message        
        obj.startTask();
        
        % Default: detect and re-issue all warnings
        if isequal(func2str(obj.handler), '@()[]')
            [varargout{1:nargout}] = obj.defaultHandler(obj.handler_variant);

        % Custom handler
        else
            [varargout{1:nargout}] = obj.callback(obj.parameters{:});
            try
                obj.handler(@obj.terminateTask, varargout{:});
            catch ME

                % Error occurred before task was complete
                if obj.can_terminate
                    obj.terminateTask(Tasking.ExitStatus.COMPLETED);
                    warning([obj.msgId() ':handler_failure'], [...
                            'Failure in user-defined task handler. The ',...
                            'error was:\n%s (%s).'], ...
                            ME.message, ME.identifier);

                % Error was thrown deliberately ("successful failure")
                else
                    rethrow(ME);
                end
            end
        end

    % Task failed
    catch ME 
        obj.terminateTask(Tasking.ExitStatus.ERROR);        
        if obj.isAtomic            
            Tasking.Task.ThrowWithoutTaskStack(ME);
        else
            disp(ME.getReport())        
        end
    end
    
end
