classdef Task < matlab.mixin.Copyable
% TASK      Task object
%
% Give a professional look to a set of tasks.
%
% See also TaskGroup, ExitStatus, disp, fprintf.

% Author:
% Name: Rody Oldenhuis
% Email: oldenhuis@gmail.com

% Reusability info:
% --------------------
% PLATFORM    : at least Windows, MacOS, Linux
% MIN. MATLAB : at least R2011b and up
% CODEGEN     : no
% DEPENDENCIES: Tasking.ExitStatus

    % Properties ----------------------------------------------------------

    properties
        message    = 'Task'
        display    = 'terse'
        callback   = @(varargin)[]
        parameters = {}
        isAtomic   = true

        handler = @()[]
        cleaner = @()[]
    end

    properties (Hidden, Access = private)
        can_terminate   = false;
        %handler_variant = 'ignore_warnings'
        handler_variant = 'collect_warnings'
    end

    properties (Hidden, ...
                GetAccess = private, ...
                Constant)

        spacer = char( 183*ispc() + 45*isunix() );

        completion_msg = ...%status         outstream    message
        {
            Tasking.ExitStatus.ERROR        2            'ERR:\n'
            Tasking.ExitStatus.WARNING      2            'WARN:\n'
            Tasking.ExitStatus.INCOMPLETE   2            'NOK\n'
            Tasking.ExitStatus.COMPLETED    1            'OK\n'
            Tasking.ExitStatus.NOOP         1            'SKIP\n'
            %{
            %}
            Tasking.ExitStatus.YES          1            'YES\n'
            Tasking.ExitStatus.NO           1            'NO\n'
            %{
            %}
            Tasking.ExitStatus.DUH          1            'DUH\n'
            Tasking.ExitStatus.NOPE         1            'NUH UH\n'
            %{
            %}
            Tasking.ExitStatus.PASS         1            'PASS\n'
            Tasking.ExitStatus.FAIL         2            'FAIL\n'
        };

    end

    % Methods -------------------------------------------------------------
    
    % Class basics
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
                obj.terminateTask(Tasking.ExitStatus.INCOMPLETE); end
        end

        % Setters/getters - - - - - - - - - - - - - - - - - - - - - - - - - 

        function set.message(obj, message)
            obj.message = obj.checkDatatype('message', message, 'char');
        end

        function set.display(obj, display)
            
            if isscalar(display) && islogical(display)                
                if display
                    display = 'on';
                else
                    display = 'off';
                end
            end

            new_display = lower( obj.checkDatatype('display', display, 'char') );

            switch new_display
                case {'on' 'off' 'terse' 'verbose'}
                    obj.display = new_display;
                otherwise
                    error([obj.msgId() ':invalid_display_string'], [...
                          'Unsupported display string: ''%s''. ',...
                          'Supported strings are ''off'', ''terse'', or ',...
                          '''verbose''.']);
            end
        end

        function set.isAtomic(obj, isAtomic)
            obj.isAtomic = obj.checkDatatype('isAtomic', isAtomic,...
                                             'logical');
            obj.isAtomic = obj.isAtomic(1);
        end

        function set.callback(obj, callback)
            obj.callback = obj.checkDatatype('callback', callback,...
                                             'function_handle');
        end

        function set.parameters(obj, parameters)
            obj.parameters = obj.checkDatatype('parameters', parameters,...
                                               'cell');
        end

        function set.handler(obj, handler)

            % Allow '[]' input
            if isa(handler, 'double') && isempty(handler)
                handler = ''; end

            new_fcn = obj.checkDatatype('handler', handler,...
                                        {'function_handle', 'char'});

            if ischar(new_fcn)

                % Set back to default when argument is empty
                if isempty(new_fcn)
                    new_fcn = 'ignore_warnings'; end

                % Select variant of default handler
                switch lower(new_fcn)

                    case {'ignore_warnings'
                          'collect_warnings'
                          'treat_as_error'}
                        obj.handler = @()[];
                        obj.handler_variant = new_fcn; %#ok<MCSUP>

                    otherwise
                        error([obj.msgId() ':invalid_default_handler'], [...
                              'Default handlers must be specified by ',...
                              '''ignore_warnings'', ''collect_warnings'' ',...
                              'or ''treat_as_error''.']);
                end

            else
                obj.handler = new_fcn;
            end

        end

        function set.cleaner(obj, cleaner)
            obj.cleaner = obj.checkDatatype('cleaner', cleaner,...
                                            'function_handle');
        end

    end

    % Public functionality
    methods
        % Execute task
        varargout = execute(obj);
    end
    
    % Methods for internal use
    methods (Hidden, Access = private)

        % Start tasks: print message and the appropriate number of 
        % spacing characters
        startTask(obj);

        % Default handler
        varargout = defaultHandler(obj, variant);

        % End tasks: print colored message based on exit status.
        terminateTask(obj, code, ME);

    end

    methods (Hidden, Access = private)

        % helper for setters: check datatype of input
        function data = checkDatatype(obj,...
                                      propertyname,...
                                      data, ...
                                      expectedtype)
  
            if ischar(expectedtype)
                expectedtype = {expectedtype}; end

            fmt = '''%s''.';
            if numel(expectedtype) > 1
                if numel(expectedtype) == 2
                    fmt = '''%s'' or ''%s''.';
                else
                    fmt = [repmat('''%s'', ', 1, numel(expectedtype)-1),...
                           'or ''%s''.'];
                end
            end

            try
                assert(any( cellfun(@(x) isa(data,x), expectedtype) ),...
                          [obj.msgId() ':invalid_datatype'], [...
                          'Task property ''%s'' must have type ' fmt],...
                          propertyname, expectedtype{:});
            catch ME
                throwAsCaller(ME);
            end

        end

    end

    methods (Hidden, Static, Access = private)
                
        % Unique+valid error/warning message ID
        function ID = msgId()
            ID = strrep(mfilename('class'),'.',':');
        end
        
        % Something akin to throwAsCaller(): remove all traces of Task from
        % the error stack, then throw it
        function ThrowWithoutTaskStack(ME)
            
            old_stack = ME.stack;
            pth       = fullfile(fileparts(mfilename('fullpath')), '..');
            pth       = cd(cd(pth));
            
            keepers   = ~strncmp({old_stack.file}, pth,numel(pth));
            new_stack = old_stack(keepers);
            
            new_ME = struct('identifier', ME.identifier,...
                            'stack'     , new_stack,...
                            'message'   , getReport(ME,...
                                                    'extended', ...
                                                    'hyperlinks', 'default') ...
                            );
            rethrow(new_ME);
            
        end
        
    end

end
