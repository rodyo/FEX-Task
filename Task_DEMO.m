function Task_DEMO()
    
    import Task.*;
    clc

    %% Singular tasks
    % ===================================================================

    % Simplest use case -- default handler

    % Task without error or warning
    T = Task('Running demo task 0/A (does nothing)',...
             @demo_task_0A);
    T.execute();

    
    % Task with 2 warnings (ignored)
    T.message  = 'Running demo task 0/B, (has 2 warnings, ignored)';
    T.callback = @demo_task_0B;
    T.execute();
    
    % Task with 2 warnings (collected, terse display) 
    T.message  = 'Running demo task 0/B, (has 2 warnings, collected)';
    T.handler = 'collect_warnings';
    T.execute();
    
    % Task with 2 warnings (collected, verbose display) 
    T.message = 'Running demo task 0/B, (has 2 warnings, which are verbosely displayed)';
    T.display = 'verbose';
    T.execute();
    
    % Task with 2 warnings (treated as error) 
    T.display = 'terse';
    try
        T.message = 'Running demo task 0/B, (has 2 warnings, treated as error)';
        T.handler = 'treat_as_error';
        T.execute();
    catch ME %#ok<MUCTH>
        disp(['(When run outside this demo, this would be an error): ' ME.message]);
    end

    % Task with error
    T.handler = [];
    try
        T.message = 'Running demo task 0/C, (has 1 error)';
        T.callback = @demo_task_0C;
        T.execute();
    catch ME %#ok<MUCTH>
        disp(['(When run outside this demo, this would be an error): ' ME.message]);
    end


    %% Different handlers and task functions 
    % ===================================================================
    
    fprintf(1, '\n\n');

    % OK/Skip
    T = Task('Running OK/Skip task (set to return OK)',...
             @demo_task_1A,...
             1);
    T.handler = @CommonHandlers.logicalOkSkip;
    T.execute();

    T.message = 'Running OK/Skip task (set to SKIP)';
    T.callback = @demo_task_1B;
    T.execute();


    % Pass/Fail
    T.handler = @CommonHandlers.logicalPassFail;

    T.message = 'Running Pass/Fail task (set to PASS)';
    T.callback = @demo_task_1A;
    T.execute();

    T.message = 'Running Pass/Fail task (set to FAIL)';
    T.callback = @demo_task_1B;
    T.execute();

    % Yes/No
    T.handler = @CommonHandlers.logicalYesNo;

    T.message = 'Running Yes/No task (set to YES)';
    T.callback = @demo_task_1A;
    T.execute();

    T.message = 'Running Yes/No task (set to NO)';
    T.callback = @demo_task_1B;
    T.execute();


    %% Groups of linked tasks
    % ===================================================================

    fprintf(1, '\n\n');
    
    tasks    = {};
    subtasks = {};
    
    defaultTop = Task('', @() true);    
    defaultTop.handler = @CommonHandlers.logicalYesNo;
    
    defaultTask = Task.Task('', @() true);    
    defaultTask.handler = @Task.CommonHandlers.logicalOkSkip;
    
    TTop = copy(defaultTop);
    TTop.message = 'Do grouped tasks?';
    
    T            = copy(defaultTask);
    T.message    = 'Sub task 1';
    T.callback   = @demo_task_1A;
    tasks{end+1} = T;
    
    T            = copy(defaultTask);
    T.message    = 'Sub task 2';
    T.callback   = @demo_task_1A;
    tasks{end+1} = T;

    subTop         = copy(defaultTop);
    subTop.message = 'Do sub-taskgroup 1?';
    
    sT              = copy(defaultTask);
    sT.message      = 'Sub-sub task 1';
    sT.callback     = @demo_task_1A;
    subtasks{end+1} = sT;
    
    sT              = copy(defaultTask);
    sT.message      = 'Sub-sub task 2';
    sT.callback     = @demo_task_1A;
    subtasks{end+1} = sT;
    
    tasks{end+1} = TaskGroup(subtasks{:}, 'top', subTop);
    
    tasks = TaskGroup(tasks{:}, 'top', TTop);
    
    OK = tasks.execute();
    


end

% Demo task 0/A. Do nothing, successfully
function demo_task_0A()    
end

% Demo task 0/B. Do nothing, with warnings
function demo_task_0B()
    
    warning([mfilename ':some_warning'],...
            'This warning will be ignored or collected.');
           
    warning([mfilename ':some_other_warning'],...
            'Also this warning will be ignored, collected or treated as error.');
        
end

% Demo task 0/C. Do nothing, with error
function demo_task_0C()        
    error([mfilename ':some_error'],...
          'This error will normally fail the task.');
end




% Demo task 1/A. Do nothing, successfully
function succes = demo_task_1A(~)    
    succes = true;
end



% Demo task 2/B. Do nothing, unsuccessfully
function succes = demo_task_1B(~)    
    succes = false;
end






