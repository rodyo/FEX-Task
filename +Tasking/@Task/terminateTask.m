% End tasks: print colored message based on exit status.
function terminateTask(obj, code, ME)

    if ~obj.can_terminate
        return; end

    if nargin == 1
        code = Tasking.ExitStatus.COMPLETED; end

    assert(isa(code, 'Tasking.ExitStatus'), ...
           [obj.msgId() ':bad_exitstatus'],...
           'First argument must be an ''Tasking.ExitStatus'' (enumeration).');

    % Toggle flag (NOTE: has to be BEFORE throws/warnings)
    obj.can_terminate = false;

    % Cleanup tasks
    OC = onCleanup(obj.cleaner);

    % Handle text display
    if ~strcmp(obj.display, 'off')

        % Display exit message
        fprintf(obj.completion_msg{[obj.completion_msg{:,1}]==code,2:3});

        % show/throw exception
        % NOTE: (Rody Oldenhuis) NOT for 'terse' display
        if strcmp(obj.display, 'on') && nargin>2 && isa(ME, 'MException')
            % NOTE: (Rody Oldenhuis) switch() in MATLAB2010a with
            % enum classes has a bug
            if code==Tasking.ExitStatus.ERROR
                throwAsCaller(ME);
            elseif code==Tasking.ExitStatus.WARNING
                warning off backtrace
                warning(ME.identifier, ME.message);
                warning on backtrace
            else
                getReport(ME, 'extended', 'hyperlinks','on')
            end
        end

    end

end
