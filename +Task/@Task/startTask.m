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
