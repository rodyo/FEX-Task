classdef Task < handle

% Author: Rody Oldenhuis (oldenhuis@luxspace.lu)
% Copyright LuxSpace sarl, all rights reserved.

% Reusability info:
% --------------------
% PLATFORM    : at least Windows, MacOS, Linux
% MIN. MATLAB : at least R2010a and up
% CODEGEN     : no
% DEPENDENCIES: Task.ExitStatus
    
    %% Class data

    properties
        
        message    = 'Task'
        display    = true
        callback   = @(varargin)[]
        parameters = {}
        isAtomic   = false

        handler = @()[]
        cleaner = @()[]
        
    end

    properties (Hidden, GetAccess = private, Constant)

        spacer = char(183);

        completion_msg = { %status       outstream    message
            Task.ExitStatus.ERROR        2            'ERR:\n'
            Task.ExitStatus.WARNING      2            'WARN:\n'
            Task.ExitStatus.INCOMPLETE   2            'NOK\n'                 
            Task.ExitStatus.COMPLETED    1            'OK\n'
            Task.ExitStatus.NOOP         1            'SKIP\n'
            %{
            %}
            Task.ExitStatus.YES          1            'YES\n'
            Task.ExitStatus.NO           1            'NO\n'
            %{
            %}
            Task.ExitStatus.DUH          1            'DUH\n'
            Task.ExitStatus.NOPE         1            'NUH UH\n'
            %{
            %}
            Task.ExitStatus.PASS         1            'PASS\n'
            Task.ExitStatus.FAIL         2            'FAIL\n'            
            };
    end

    properties (Hidden, Access = private)
        can_terminate = false;
    end


    %% Class functionality

    methods

        % Constructor
        function obj = Task(message, callback, varargin)
            if nargin == 0, return;                    end
            if nargin >= 1, obj.message    = message;  end
            if nargin >= 2, obj.callback   = callback; end
            if nargin >= 3, obj.parameters = varargin; end
        end

        % Destructor
        function delete(obj)
            if obj.can_terminate
                obj.terminateTask(Task.ExitStatus.INCOMPLETE); end
        end
        
        % Deep copy existing Task object
        function new_obj = copy(obj)
            new_obj = Task.Task(obj.message,...
                                obj.callback,...
                                obj.parameters{:});
                       
            new_obj.handler       = obj.handler;
            new_obj.cleaner       = obj.cleaner;
            new_obj.display       = obj.display;
            new_obj.can_terminate = obj.can_terminate;
            
        end

        % Execute task
        function varargout = execute(obj)

            try
                % Display task startup message
                obj.startTask();

                % Default: detect and re-issue all warnings
                if isequal(func2str(obj.handler), '@()[]')
                    [varargout{1:nargout}] = obj.defaultHandler();

                % Custom handler 
                else
                    [varargout{1:nargout}] = obj.callback(obj.parameters{:});
                    try
                        obj.handler(@obj.terminateTask, varargout{:});
                    catch ME
                        % Error occurred before task was complete
                        if obj.can_terminate
                            obj.terminateTask(Task.ExitStatus.COMPLETED);
                            warning( [...
                                mfilename ':handler_failure'], [...
                                'Failure in user-defined task handler. The ',...
                                'error was:\n%s (%s).'], ...
                                ME.message, ME.identifier);
                        % Error was thrown deliberately ("successful failure")
                        else
                            throw(ME);
                        end
                    end
                end


            catch ME % Task failed
                obj.terminateTask(Task.ExitStatus.ERROR);
                throwAsCaller(ME);                
            end
        end


        %% Setters/getters

        function set.message(obj, message)
            obj.message = obj.checkDatatype('message', message, 'char');
        end

        function set.display(obj, display)
            obj.display = obj.checkDatatype('display', display, 'logical');
            obj.display = obj.display(1);
        end
        
        function set.isAtomic(obj, isAtomic)
            obj.isAtomic = obj.checkDatatype('isAtomic', isAtomic, 'logical');
            obj.isAtomic = obj.isAtomic(1);
        end

        function set.callback(obj, callback)
            obj.callback = obj.checkDatatype('callback', callback, 'function_handle');
        end

        function set.parameters(obj, parameters)
            obj.parameters = obj.checkDatatype('parameters', parameters, 'cell');
        end

        function set.handler(obj, handler)
            obj.handler = obj.checkDatatype('handler', handler, 'function_handle');
        end
        
        function set.cleaner(obj, cleaner)
            obj.cleaner = obj.checkDatatype('cleaner', cleaner, 'function_handle');             
        end

    end

    methods (Hidden, Access = private)

        % Start tasks: print message and the appropriate amount of spacing characters
        function startTask(obj)

            % end unterminated tasks with error when starting a new task
            if obj.can_terminate
                obj.terminateTask(Task.ExitStatus.INCOMPLETE); end

            % Update # of displayable colums
            cols = get(0, 'CommandWindowSize');
            cols = cols(1);
            
            % Print message
            if obj.display
                str = [...
                    obj.message,...
                    repmat(obj.spacer, 1,...
                           cols - numel(obj.message) - ...
                           max(cellfun('prodofsize',obj.completion_msg(:,end))) - 1),...
                           ' '];
                fprintf(1, str);
            end

            % Toggle flag
            obj.can_terminate = true;
        end

        % Default handler
        function varargout = defaultHandler(obj) %#ok<STOUT> (attack of the evil eval())
            
            % The default is to repeat the task until it issues no
            % more warnings.
            
            lastwarn('');
            warnstates = struct([]);
            wME = {};
            while true
                
                text = evalc('[varargout{1:nargout}] = obj.callback(obj.parameters{:});');
                [wMsg, wId] = lastwarn;
                
                if isempty(text)
                    wMsg = '';  wId  = '';  end
                
                if isempty(wMsg)
                    break;
                else
                    wMsg = regexprep(wMsg, '\\', '\\\\');
                    wMsg = regexprep(wMsg, '%', '%%');
                    
                    wME{end+1} = MException(wId,wMsg); %#ok<AGROW>
                    if ~isempty(wId)
                        warnstates = [warnstates; warning('off', wId)]; %#ok<AGROW>
                        lastwarn('');
                    else
                        wME{end+1} = MException(...
                            [mfilename ':execute:sloppy_implementation'], [...
                            'Warning found without warning ID; cannot continue ',...
                            'further warning detection.']); %#ok<AGROW>
                        break;
                    end
                end
            end
            
            % All warnings issued are collected and re-issued after termination
            % of the task progress printer.
            if isempty(wME)
                obj.terminateTask(Task.ExitStatus.COMPLETED);
            else
                obj.terminateTask(Task.ExitStatus.WARNING);
                
                if all(isfield(warnstates, {'state' 'identifier'}))
                    warning(warnstates); end
                
                warnstates = warning('off', 'backtrace');
                cellfun(@(x) warning(regexprep(x.message, '\\', '\\')), wME);
                warning(warnstates);
            end
            
        end
        
        % End tasks: print colored message based on exit status.
        function terminateTask(obj, code, ME)

            if ~obj.can_terminate
                return; end

            if nargin == 1
                code = Task.ExitStatus.COMPLETED; end

            assert(isa(code, 'Task.ExitStatus'), ...
                'First argument must be an ''Task.ExitStatus'' (enumeration).');
            
            % Toggle flag (NOTE: has to be BEFORE throws/warnings)
            obj.can_terminate = false;

            % Handle text display
            if obj.display
                
                % Display exit message
                fprintf(obj.completion_msg{[obj.completion_msg{:,1}]==code,2:3});
                
                % show/throw exception
                if nargin>2 && isa(ME, 'MException')
                    % NOTE: (Rody Oldenhuis) switch() in MATLAB2010a with
                    % enum classes has a bug
                    if code==Task.ExitStatus.ERROR
                        throw(ME);
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

    end

    
    methods (Hidden, Static, Access = private)
        
        % helper for setters: check datatype of input
        function data = checkDatatype(propertyname, data, expectedtype)
            assert(isa(data, expectedtype),...
                [mfilename ':invalid_datatype'], ...
                'Task property ''%s'' must have type ''%s''.',...
                propertyname, expectedtype);
        end
        
    end
end
