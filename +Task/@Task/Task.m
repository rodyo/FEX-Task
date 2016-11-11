classdef Task < handle
% TASK      Task object
%
% Give a professional look to a set of tasks.
%
% See also TaskGroup, ExitStatus, disp, fprintf.

% Author:
% Name: Rody Oldenhuis
% Email: oldenhuis@gmail.com   (personal)
%        oldenhuis@luxspace.lu (professional)
%

% Reusability info:
% --------------------
% PLATFORM    : at least Windows, MacOS, Linux
% MIN. MATLAB : at least R2010a and up
% CODEGEN     : no
% DEPENDENCIES: Task.ExitStatus


% If you find this work useful, please consider a donation:
% https://www.paypal.me/RodyO/3.5


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
        varargout = execute(obj);

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
        startTask(obj);

        % Default handler
        varargout = defaultHandler(obj);

        % End tasks: print colored message based on exit status.
        terminateTask(obj, code, ME);

    end


    methods (Hidden, Access = private)

        % helper for setters: check datatype of input
        function data = checkDatatype(obj, propertyname, data, expectedtype)
            assert(isa(data, expectedtype),...
                  [obj.msgId() ':invalid_datatype'], ...
                  'Task property ''%s'' must have type ''%s''.',...
                  propertyname, expectedtype);
        end

    end

    methods (Hidden, Static, Access = private)

        function ID = msgId()
            ID = regexprep(mfilename('class'), '\.', ':');
        end

    end

end
