% Start tasks: print message and the appropriate amount of spacing characters
function startTask(obj)

    % end unterminated tasks with error when starting a new task
    if obj.can_terminate
        obj.terminateTask(Tasking.ExitStatus.INCOMPLETE); end

    % Update # of displayable colums
    cols = get(0, 'CommandWindowSize');
    cols = cols(1);
    % TODO: (Rody Oldenhuis) is the 'set matrix display width to eighty 
    % columns ' option is set (in MATLAB preferences/command window
    % section), 'cols' will always be equal to 80. There is no known
    % workaround to (temporarily) override this...

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
