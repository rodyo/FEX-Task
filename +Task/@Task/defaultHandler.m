% Default handler
function varargout = defaultHandler(obj) %#ok<STOUT> (attack of the evil eval())

    % The default is to repeat the task until it issues no
    % more warnings.

    warnstates = struct([]);
    wME = {};

    while true

        lastwarn('');
        lasterror('reset'); %#ok<LERR>

        try
            % Run task, suppressing any text output            
            text = evalc(['[varargout{1:nargout}] = '...
                          'obj.callback(obj.parameters{:});']);

            % If there was no text, and we en up here, we know
            % for sure that no warning was displayed, so we can exit
            if isempty(text)
                break; end
            
            % Otherwise, we'll have to manually check for warnings. When
            % found, switch them off by converting them into an error
            [S, wME, warnstates] = check_and_toggle_warnings(wME, warnstates);
            switch S
                case {'no more warnings'
                        'sloppy implementation'}
                    break;
                    
                case 'warning converted'
                    continue;
            end


        catch ME
            % If we end up here, one of two things might have happened:
            %
            %   1. a genuine error occurred ni the task function
            %   2. an error occurred that we intentioanlly converted
            %      into an error
            %
            % In the first case, we can immediately rethrow.
            %
            % In the second case, we'll have to check whether there have been
            % any more warnings. If so, they are converted into errors like before,
            % and we continue. If there are none, we are done!

            % Case 1
            if isempty(wME)
                throwAsCaller(ME);

            else
                all_warnings_so_far = cellfun(@(x) x.identifier, wME, 'UniformOutput', false);

                % Case 2
                if any(strcmp(all_warnings_so_far, ME.identifier))
                    
                    [S, wME, warnstates] = check_and_toggle_warnings(wME, warnstates);

                    switch S
                        case {'no more warnings'
                              'sloppy implementation'}
                            break;

                        case 'warning converted'
                            continue;
                    end

                % Case 1 - reset warnings before rethrowing
                else
                    display_and_reset_all_warnings(wME, warnstates)
                    throwAsCaller(ME);
                end

            end

        end

    end

    % All warnings are switched back to their previous states, and
    % re-issued after termination of the task progress printer.
    if isempty(wME)
        obj.terminateTask(Task.ExitStatus.COMPLETED);
    else        
        % Terminate task with WARNING 
        obj.terminateTask(Task.ExitStatus.WARNING);
        display_and_reset_all_warnings(wME, warnstates);        
    end

end

function display_and_reset_all_warnings(wME, warnstates)
    

    % The warnings are collected back-to-front; 
    % sort in the right order
    wME = wME(end:-1:1);

    % Reset all warnings to their original states
    if all(isfield(warnstates, {'state' 'identifier'}))
        warning(warnstates); end

    % And show collected warnings as plain strings
    warnstates = warning('off', 'backtrace');
    cellfun(@(x) warning(regexprep(x.message, '\\', '\\')), wME);
    warning(warnstates);
    
end

% Check for warnings and collect/convert if any are found
function [status, wME, warnstates] = check_and_toggle_warnings(wME,warnstates)

    status = 'no more warnings';

    % Get warning message, ID
    [wMsg, wId] = lastwarn();

    if ~isempty(wMsg) || ~isempty(wId)

        % Process any URLs (and file paths on Windows) in the message, and
        % collect for reissuing later on
        wMsg = regexprep(wMsg, '\\', '\\\\');
        wMsg = regexprep(wMsg, '%', '%%');

        % Collect corresponding exception objects
        wME{end+1} = MException(wId, wMsg);

        % Switch off the warning, by converting it into an error
        if ~isempty(wId)
            status     = 'warning converted';
            warnstates = [warnstates;
                          warning('error', wId)]; %#ok<WNTAG,CTPCT>
        else
            status     = 'sloppy implementation';
            wME{end+1} = MException([obj.msgId() ':execute:sloppy_implementation'], [...
                                    'Warning found without warning ID; cannot continue ',...
                                    'further warning detection.']);
        end
    end

end
