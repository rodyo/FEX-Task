% End tasks: print colored message based on exit status.
function terminateTask(obj, code, ME)

    if ~obj.can_terminate
        return; end

    if nargin == 1
        code = Task.ExitStatus.COMPLETED; end

    assert(isa(code, 'Task.ExitStatus'), ...
           [obj.msgId() ':bad_exitstatus'],...
           'First argument must be an ''Task.ExitStatus'' (enumeration).');

    % Toggle flag (NOTE: has to be BEFORE throws/warnings)
    obj.can_terminate = false;

    % Cleanup tasks
    OC = onCleanup(obj.cleaner);

    % Handle text display
    if obj.display

        % Display exit message
        fprintf(obj.completion_msg{[obj.completion_msg{:,1}]==code,2:3});

        % show/throw exception
        if nargin>2 && isa(ME, 'MException')
            % NOTE: (Rody Oldenhuis) switch() in MATLAB2010a with
            % enum classes has a bug
            if code==Task.ExitStatus.ERROR
                throwAsCaller(ME);
            elseif code==Task.ExitStatus.WARNING
                warning off backtrace
                warning(ME.identifier, ME.message);
                warning on backtrace
            else
                getReport(ME, 'extended', 'hyperlinks','on')
            end
        end

    end

end
