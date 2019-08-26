classdef TaskGroup < matlab.mixin.Copyable
% TASKGROUP  container for connected tasks
%
% Give a professional look to a set of connected tasks.
%
% See also Task, ExitStatus, disp, fprintf.

% Author:
% Name: Rody Oldenhuis
% Email: oldenhuis@gmail.com

% Reusability info:
% --------------------
% PLATFORM    : at least Windows, MacOS, Linux
% MIN. MATLAB : at least R2011b and up
% CODEGEN     : no
% DEPENDENCIES: Tasking.ExitStatus

% If you find this work useful, please consider a donation:
% https://www.paypal.me/RodyO/3.5

    %% Properties

    properties
        Tasks      = {}

        hasTopTask = false
        isAtomic   = false
        executeAll = true;
    end

    %% Methods

    % Class basics
    methods

        % Constructor
        function obj = TaskGroup(varargin)

            if nargin == 0
                return; end

            isTask = cellfun('isclass', varargin, 'Tasking.Task') | ...
                     cellfun('isclass', varargin, 'Tasking.TaskGroup');

            if all(isTask)
                obj.Tasks = varargin;

            else
                pvstart   = find(~isTask, 1, 'first');
                obj.Tasks = varargin( 1:pvstart-1 );

                parameters = varargin(pvstart+0 : 2 : end);
                values     = varargin(pvstart+1 : 2 : end);

                assert(~all(ischar(parameters)) || mod(nargin - pvstart + 1, 2) ~= 0,...
                       [mfilename ':invalid_arguments'], [...
                       'Invalid input arguments. %s expects a list of Tasking.Task() ',...
                       'or Tasking.TaskGroup() objects, optionally followed by ',...
                       'parameter/value pairs.'],...
                       mfilename('class'));

                for ii = 1:numel(parameters)

                    parameter = parameters{ii};
                    value     = values{ii};

                    switch lower(parameter)

                        case {'toplevel' 'top' 'toptask' 'decision' 'main' 'decisive'}
                            assert(isa(value, 'Tasking.Task'),...
                                   [mfilename ':invalid_datatype'],...
                                   'Top-level task must be of type Tasking.Tasking.');

                            assert(isempty(obj.hasTopTask) || ~obj.hasTopTask,...
                                   [mfilename ':multiple_toptasks_unsupported'],...
                                   'Multiple top-level tasks are not supported.');

                            obj.demote();
                            obj.hasTopTask = true;
                            obj.Tasks = [{value} obj.Tasks];
                    end

                end

            end

        end
        
        % Setters/getters ------------------------------------------------------

        function set.hasTopTask(obj, tf)
            obj.hasTopTask = obj.checkDatatype('hasTopTask', tf, 'logical');
            obj.hasTopTask = obj.hasTopTask(1);
        end

        function set.isAtomic(obj, tf)
            obj.isAtomic = obj.checkDatatype('isAtomic', tf, 'logical');
            obj.isAtomic = obj.isAtomic(1);
        end

        function set.executeAll(obj, tf)
            obj.executeAll = obj.checkDatatype('executeAll', tf, 'logical');
            obj.executeAll = obj.executeAll(1);
        end

    end

    % Public functionality
    methods
        
        % Execute task
        function OK = execute(obj)

            OK     = true;
            start  = 1;
            doWork = true;

            if obj.hasTopTask
                start = 2;
                doWork = obj.Tasks{1}.execute();
                assert(isscalar(doWork) && islogical(doWork),...
                      [mfilename ':invalid_datatype'],...
                      'Output from top-level tasks must be a scalar logical.');
            end

            if doWork
                for ii = start:numel(obj.Tasks)
                    OK = obj.Tasks{ii}.execute() && OK;
                    if ~obj.executeAll && ~OK
                        break; end
                end
            end

        end
        
    end
    
    methods (Hidden, Access = private)

        % Demote task messages by one level, recursively
        function demote(obj)
            for ii = 1:numel(obj.Tasks)
                if isa(obj.Tasks{ii}, 'Tasking.Task')
                    obj.Tasks{ii}.message = regexprep(obj.Tasks{ii}.message, ...
                                                      '^(\s*)(-*)\s*(.*)$',...
                                                      '  $1- $3');
                else
                    obj.Tasks{ii}.demote();
                end
            end
        end

    end

    % Methods for internal use
    methods (Hidden, Static, Access = private)

        % helper for setters: check datatype of input
        function data = checkDatatype(propertyname, data, expectedtype)
            assert(isa(data, expectedtype),...
                  [mfilename ':invalid_datatype'], ...
                  'TaskGroup property ''%s'' must have type ''%s''.',...
                  propertyname, expectedtype);
        end

    end

end
