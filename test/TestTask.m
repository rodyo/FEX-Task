classdef (TestTags = {'Unit Tests'})...
          TestTask < matlab.unittest.TestCase
      
	%#ok<*CHARTEN> nag about newline() - introduced in R2016b
      
	properties (Constant)
        sep = char( 183*ispc() + 45*isunix() ); 
    end
    
    % Setup & teardown ----------------------------------------------------
    
    methods (TestClassSetup)
        function addPaths(~)
            pth = fullfile(fileparts(mfilename('fullpath')), '..');
            addpath(genpath(pth)); 
        end 
    end
    
    % Test cases ---------------------------------------------------------- 
       
    methods (Test,...
             TestTags = {'Functionality'})
        % TODO         
    end
        
    methods (Test,...
             TestTags = {'Display'})
         
        function doSimpleTasksDisplayCorrectly(tst)
                        
            msg = 'simple task';            
            T   = Tasking.Task(msg);
            
            % OK            
            tsk = T.copy(); %#ok<NASGU> (used in evalc)
            dsp = evalc('tsk.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sOK' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            
            % With warning
            tsk = T.copy(); 
            tsk.handler = 'collect_warnings';
            tsk.callback = @()warning('A:B','C');
            dsp = evalc('tsk.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sWARN:' char(10)]);
            
            tst.verifyEqual(mtc, 1);
            
            % With error 
            tsk = T.copy();             
            tsk.callback = @()error('A:B','C');
            dsp = evalc('try tsk.execute(); end');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sERR:' char(10)]);
            
            tst.verifyEqual(mtc, 1);
            
        end    
        
        function doesOkSkipDisplayCorrectly(tst)
                        
            msg = 'ok/skip task';            
            T   = Tasking.Task(msg);
            T.handler = @Tasking.CommonHandlers.logicalOkSkip;
            
            % OK
            T.callback = @true;
            dsp = evalc('T.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sOK' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            
            % SKIP
            T.callback = @false;
            dsp = evalc('T.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sSKIP' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            
            % With warning
            % TODO: (Rody) ...doesn't work properly
            %{
            T.callback = @()warning('A:B','C');
            dsp = evalc('T1.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sWARN:' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            %}
            
        end
        
        function doesPassFailDisplayCorrectly(tst)
            
            msg = 'ok/skip task';            
            T   = Tasking.Task(msg);
            T.handler = @Tasking.CommonHandlers.logicalPassFail;
                        
            % PASS
            T.callback = @true;
            dsp = evalc('T.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sPASS' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            
            % FAIL
            T.callback = @false;
            dsp = evalc('T.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sFAIL' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            
            % With warning
            % TODO: (Rody) ...doesn't work properly
            %{
            T.callback = @()warning('A:B','C');
            dsp = evalc('T1.execute();');
            mtc = regexp(dsp, ['^' msg tst.sep '+\sWARN:' char(10)]); 
            
            tst.verifyEqual(mtc, 1);
            %}
            
        end  
                 
    end
        
    methods (Test,...
             TestTags = {'Dependencies'})
         
        % Does the demo run? 
        function testDemo(tst)
            
            % These are the only warnings that should happen:
            ws = {warning('off', 'Task_DEMO:some_warning')
                  warning('off', 'Task_DEMO:some_other_warning')};
            OC = onCleanup(@()cellfun(@warning, ws));
            
            % So, with these disabled, there should be no further warning:
            tst.verifyWarningFree(@()evalc('Task_DEMO')); 
            
        end
        
    end
    
end
