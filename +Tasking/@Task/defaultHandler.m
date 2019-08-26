% Default handler
function varargout = defaultHandler(obj, variant)

    % The top-level method is just a wrapper for everything below
    
    % Use default handler when argument is abscent or empty
    if nargin < 2 || isempty(variant)
        variant = 'collect_warnings'; end

    % Call the appropriate variant
    try
        switch lower(variant)
            case 'collect_warnings',  [varargout{1:nargout}] = collect_all_warnings(obj);
            case 'ignore_warnings',   [varargout{1:nargout}] = ignore_all_warnings(obj);
            case 'treat_as_error',    [varargout{1:nargout}] = treat_warnings_as_errors(obj);
            otherwise
        end

    catch ME
        rethrow(ME);
    end

end

% Helper function: carry out the user task. Capture any textual output for
% further processing later on. Make sure the information emitted by
% warning() is at its maximum verbosity. 
function [text, varargout] = do_task(obj) %#ok<INUSD,STOUT> (attack of the evil eval())

    % Make sure stack info and IDs are present in all warnings
    verb_state  = warning('on', 'verbose');
    trace_state = warning('on', 'backtrace');
    
    % Reset settings to whatever they were before task
    oC1 = onCleanup(@() warning(verb_state) );
    oC2 = onCleanup(@() warning(trace_state));
    
    % Run task, suppressing any text output
    text = evalc(['[varargout{1:nargout-1}] = '...
                 'obj.callback(obj.parameters{:});']);
             
end


% Helper function: parse text that would have been written to the command window
% by the user-task. Detect warning signatures, and render them into data
% that can be processed easily by MException and/or rethrow()
function [wMsg, wId, stack, raw] = process_warnings_in_text(text)
    
    % Text containint warnings with verbose and backtrace switched on has
    % the following signature:
    %
    %     (other, possibly user-generated text)
    % 
    %     {\bWarning: <warning message here>
    %     (Type "warning off warning:id" to suppress this warning.)}\b
    %     > In <a href="matlab: opentoline('/path/to/some/file',10,1)">function_name>subfcn>nested_fcn at 10</a>
    %       In <a href="matlab: opentoline('/path/to/some/other/file',100,1)">function_name>subfcn>nested_fcn at 100</a>                        
    %       ...
    %       In <a href="matlab: opentoline('/ppath/to/yet/another/file',1000,1)">function_name>subfcn>nested_fcn at 1000</a>
    %   
    %     (other, possibly user-generated text)
    %     ...
    %
    % Note that the warning ID may be missing, in which case the line after
    % the warning will be abscent.
    
    %#ok<*CHARTEN> (only if you're on > R2017a) 
    %#ok<*STRCL1>  (only if you're on > R2017a) 
    
    wMsg = {};   stack = {};
    wId  = {};   raw   = {};
    
    escape_terminator = [']' char(8)];
    
    % No text -> no warnings
    if isempty(text)
        return; end

    % First, find the start of all warnings
    text = regexp(text, char(10), 'split')'; 
    hits = regexp(text, '^[\[{]\bWarning: ' );
    hits = find(~cellfun('isempty', hits));

    % None found: hurray!
    if isempty(hits)
        return; end

    % Some warnings are found 
    wMsg_out = cell(size(hits));    stack_out = cell(size(hits));
    wId_out  = cell(size(hits));    raw_out   = cell(size(hits));

    hits = [hits; numel(text)];
    for ii = 1:numel(hits)-1

        hit     = hits(ii);
        nexthit = hits(ii+1);

        % The "text", from the first hit to the end, will
        % contain our stack information.
        warn_txt = text(hit:nexthit);
        stack    = strfind(warn_txt,...
                           'In <a href="matlab');

        % Find the precise extent
        stack_extent = ~cellfun('isempty', stack); 
        stack_start  = find(stack_extent, 1, 'first');
        stack_extent(stack_start:-1:1) = true;
        stack_end    = find(stack_extent == false, 1, 'first') - 1;
        stack_extent = stack_start : stack_end;

        % And slice it off from the rest of the text
        stack = warn_txt(stack_extent);
        
        % The entire, raw warning message:
        raw_out{ii} = [warn_txt(1:stack_end); 
                       escape_terminator];

        % Find warning message, ID
        warnMsg = warn_txt(1:stack_extent(1)-1);
        warnMsg = warnMsg( cellfun('isempty', regexp(warnMsg, '^\s*\]*\b*\s*$')) );
        newWid  = regexp(warnMsg{end}, [...
                         '\(Type ".*warning off (?<wID>[^<"]+)".*to suppress this ',...
                         'warning.\)'], 'names');
        if isempty(newWid)
            newWid = ''; 
        else
            newWid = newWid.wID;
            warnMsg(end) = [];        
        end
        
        warnMsg = regexprep(warnMsg, '^[\[{]\bWarning: ', '');
        warnMsg = [sprintf('%s\n', warnMsg{1:end-1}), warnMsg{end}];

        wMsg_out{ii} = warnMsg;    
        wId_out{ii}  = newWid;

        % Exclude all Task-related files from the stack and raw string
        remove_task = @(x) x( cellfun('isempty', strfind(x, fullfile('+Tasking', '@Task'))) );
        stack       = remove_task(stack);
        raw_out{ii} = remove_task(raw_out{ii});

        % Split the HTML links up in filename, line number and function name 
        % to form a structure like the one returned by dbstack()
        stack = regexp(stack, [...
                       '^[^'']+''',...
                       '(?<file>[^'']+)',...  % FILE
                       '''\s*,\s*',...
                       '(?<line>[\d]+)',...   % LINE
                       '[^"]+">',...
                        '(?<name>[^\s]+)',... % NAME
                       '.*$'],...
                       'names');
                   
        stack = [stack{:}]';
        for s = 1:numel(stack)
            stack(s).line = str2double(stack(s).line); end
        
        stack_out{ii} = stack;
        
    end

    % Rename for output
    wMsg = wMsg_out;    stack = stack_out; 
    wId  = wId_out;     raw   = raw_out;
    
end

% Default handler: ignore all warnings; don't report any of them
function varargout = ignore_all_warnings(obj)

    try
        % Run task, suppressing any text output
        [~, varargout{1:nargout}] = do_task(obj);

        % and forego all kinds of warning detection.
        obj.terminateTask(Tasking.ExitStatus.COMPLETED);

    catch ME
        rethrow(ME);
    end

end

% Variant default handler: collect all warnings. Report all of them, and
% treat the last warning as error
function varargout = treat_warnings_as_errors(obj)

    try        
        % Run task, suppressing any text output
        [text, varargout{1:nargout}] = do_task(obj);

        % If there was no text, and we end up here, we know
        % for sure that no warning was displayed, so we can exit.
        % Otherwise, we'll have to look for warnings, display them, and
        % throw the last one as error.
        if ~isempty(text)
            
            % Parse the text
            [wMsg, wId, stack, raw] = process_warnings_in_text(text);
            
            % Some warnings were indeed present
            if ~isempty(wMsg)

                % TODO: (Rody Oldenhuis) "rethrow" will be removed in a 
                % future release. Well, that's cute 'n all, but how
                % on Earth would one throw the last warning as an error, 
                % without repeating the task? 
                %
                % The only way I can think of is to parse the
                % captured 'text', and look for warning signatures
                % and backtraces, convert those into proper call stacks, 
                % and throw the error as if rethrown from the task.
                % 
                % This is only possible with rethrow() with an
                % error structure, since MExceptions() don't allow
                % user-level control over the call stack. 
                %
                % So, unless there's someone with a better idea,
                % this is what we do here. 
                
                obj.terminateTask(Tasking.ExitStatus.ERROR);
                
                % Display all collected warnings except the last
                switch obj.display
                    case {'on' 'terse'}
                        disp(char(strcat({'Warning: '}, wMsg(1:end-1))));    
                    case 'verbose'
                        cellfun(@(x) disp(char(x)), raw);
                end
                
                % Create error structure for the last warning
                err = struct(...
                    'message'   , wMsg{end},...
                    'identifier', wId{end},...
                    'stack'     , stack{end});

                % And hurl it!
                rethrow(err); %#ok<>

            end

        end
        
        % And terminate task
        obj.terminateTask(Tasking.ExitStatus.COMPLETED);
        
    catch ME     
        rethrow(ME);
    end
    
end


% Variant default handler: collect all warnings, and report all of them. 
function varargout = collect_all_warnings(obj)
 
    % Apparently, the MATLAB command prompt uses escape sequences similar 
    % to ANSII sequences in bash:
    escape_start = ['[' char(8)];
    escape_end   = [char(10) ']' char(8)];
    
    try        
        % Run task, suppressing any text output
        [text, varargout{1:nargout}] = do_task(obj);

        % If there was no text, and we end up here, we know
        % for sure that no warning was displayed, so we can exit.
        % Otherwise, we'll have to look for warnings, display them, and
        % throw the last one as error.
        if ~isempty(text)
            
            % Parse the text
            [wMsg, ~,~, raw] = process_warnings_in_text(text);
            
            % Some warnings were indeed present
            if ~isempty(wMsg)
                
                % Terminate task with WARNING status
                obj.terminateTask(Tasking.ExitStatus.WARNING);
                
                % Display all collected warnings and return. Avoid actually
                % calling warning() - that would mess up lastwarn() and
                % put Tasking/Task on the stack
                switch obj.display
                    case 'terse'
                        % Display warnings without any stack
                        wMsg = strcat({escape_start}, wMsg, {escape_end});
                        cellfun(@disp, wMsg);
                        
                    otherwise
                        % Display FULL warning
                        % NOTE: (Rody Oldenhuis) this RAW string contains
                        % all the correct escape characters, meaning, it
                        % will actually show up as proper warnings
                        cellfun(@(x) disp(char(x)), raw);
                end
                
                return;
            end

        end
        
        obj.terminateTask(Tasking.ExitStatus.COMPLETED);        
        
    catch ME        
        rethrow(ME);
    end
    
end


