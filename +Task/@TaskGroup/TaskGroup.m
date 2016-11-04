classdef TaskGroup < handle 

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
        
        Tasks      = {}
        
        hasTopTask = false
        isAtomic   = false
        executeAll = true;
        
    end

    %% Class functionality

    methods

        % Constructor
        function obj = TaskGroup(varargin)
            
            if nargin == 0
                return; end
            
            isTask = cellfun('isclass', varargin, 'Task.Task') | ...
                     cellfun('isclass', varargin, 'Task.TaskGroup');
            
            if all(isTask)
                obj.Tasks = varargin;
                
            else
                pvstart   = find(~isTask, 1, 'first');
                obj.Tasks = varargin( 1:pvstart-1 );
                
                parameters = varargin(pvstart+0 : 2 : end);
                values     = varargin(pvstart+1 : 2 : end);
                
                assert(...
                    ~all(ischar(parameters)) || mod(nargin - pvstart + 1, 2) ~= 0,...
                    [mfilename ':invalid_arguments'],...
                    ['Invalid input arguments. %s expects a list of Task.Task() ',...
                    'or Task.TaskGroup() objects, optionally followed by ',...
                    'parameter/value pairs.'],...
                    mfilename('class'));
                
                for ii = 1:numel(parameters)
                    
                    parameter = parameters{ii};
                    value     = values{ii};
                    
                    switch lower(parameter)
                        
                        case {'toplevel' 'top' 'toptask' 'decision' 'main' 'decisive'}
                            assert(...
                                isa(value, 'Task.Task'),...
                                [mfilename ':invalid_datatype'],...
                                'Top-level task must be of type Task.Task.');
                            
                            assert(...
                                isempty(obj.hasTopTask) || ~obj.hasTopTask,...
                                [mfilename ':multiple_toptasks_unsupported'],...
                                'Multiple top-level tasks are not supported.');
                            
                            obj.demote();
                            obj.hasTopTask = true; 
                            obj.Tasks = [{value} obj.Tasks];
                    end
                    
                end
                
            end
                
        end
        
        % Deep copy existing TaskGroup object
        function new_obj = copy(obj)
            
            new_obj = Task.TaskGroup();
            
            new_obj.Tasks      = obj.Tasks;
            
            new_obj.isAtomic   = obj.isAtomic;
            new_obj.hasTopTask = obj.hasTopTask;            
            new_obj.executeAll = obj.executeAll;
            
        end
        
        % Execute task
        function OK = execute(obj)
            
            OK     = true;
            start  = 1;
            doWork = true;
            
            if obj.hasTopTask                
                start = 2;
                doWork = obj.Tasks{1}.execute();
                assert(...
                    isscalar(doWork) && islogical(doWork),...
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
        
        %% Setters/getters
        
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
    
    methods (Hidden, Access = private)
        
        % Demote task messages by one level, recursively
        function demote(obj)            
            for ii = 1:numel(obj.Tasks)                
                if isa(obj.Tasks{ii}, 'Task.Task')
                    obj.Tasks{ii}.message = regexprep(obj.Tasks{ii}.message, ...
                                                      '^(\s*)(-*)\s*(.*)$',...
                                                      '  $1- $3');
                else
                    obj.Tasks{ii}.demote();
                end 
            end
        end
        
    end

    
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
