% Execute task
function varargout = execute(obj)

    try
        % Display task startup message
        obj.startTask();

        % Default: detect and re-issue all warnings
        if isequal(func2str(obj.handler), '@()[]')
            [varargout{1:nargout}] = obj.defaultHandler('collect_all_warnings');

        % Custom handler
        else
            [varargout{1:nargout}] = obj.callback(obj.parameters{:});
            try
                obj.handler(@obj.terminateTask, varargout{:});
            catch ME

                % Error occurred before task was complete
                if obj.can_terminate
                    obj.terminateTask(Task.ExitStatus.COMPLETED);
                    warning([mfilename ':handler_failure'], [...
                            'Failure in user-defined task handler. The ',...
                            'error was:\n%s (%s).'], ...
                            ME.message, ME.identifier);

                % Error was thrown deliberately ("successful failure")
                else
                    rethrow(ME);
                end
            end
        end


    catch ME % Task failed

        obj.terminateTask(Task.ExitStatus.ERROR);

        % TODO: (Rody Oldenhuis) rethrow will be removed in a future release.
        % Well, that's cute, but how on Earth would one do the following then:
        %
        % - A user-written task throws an error
        % - I want that error, with only the call stack present in the user's
        %   task, to be shown in the final error. None of the "Task" methods
        %   should be in between, because that's NOT where the error occurred,
        %   and I want to point users directly to the right spot, rather
        %   than look at +Task/@Task code.
        % - throwAsCaller() and throw() will remove the lowest stack entries, 
        %   meaning, the callstack in the task itself is eventually lost 
        % - The only way to bubble up the stack from the bottom to here, is
        %   by using rethrow() everywhere, in conjunction with a
        %   MException. However, that collects the call stack from all
        %   +Task/@Task methods in between, distracting the user
        %   unnecessarily. 
        %
        % So, I have to modify the callstack in the final thrown exception. 
        % I.e., here. This is however not possible with MExceptions, because 
        % the "stack" property is read only.
        %
        % So, MathWorks: valid use case right here, cancel those removal plans.
        
        taskstack_inds = strfind({ME.stack.file}',...
                                 fileparts(mfilename('fullpath')) );
                            
        non_taskstack_inds = cellfun('isempty', taskstack_inds);
        non_taskstack_inds(end) = false;
        
        err = struct(...
            'message'   , ME.message,...
            'identifier', ME.identifier,...
            'stack'     , ME.stack(non_taskstack_inds));

        rethrow(err); %#ok<>

    end
end
