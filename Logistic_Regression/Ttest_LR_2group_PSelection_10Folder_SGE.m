function Ttest_LR_2group_PSelection_10Folder_SGE(Subjects_Data, Subjects_Label, P_Value_Range, Pre_Method, ResultantFolder, QsubOption)
%
% Subject_Data:
%           m*n matrix
%           m is the number of subjects
%           n is the number of features
%
% Subject_Label:
%           array of 1 or -1
%
% P_Value:
%           threshold to delete non-important features
%
% Pre_Method:
%           'Scale' or 'Normalzie'
%
% ResultantFolder:
%           the path of folder storing resultant files
%

if ~exist(ResultantFolder, 'dir')
    mkdir(ResultantFolder);
end

[Subjects_Quantity, Feature_Quantity] = size(Subjects_Data);
[Splited_Data, Splited_Data_Label, Origin_ID_Cell] = Split_NFolders(Subjects_Data, Subjects_Label, 10);

for i = 1:10
    
    test_label = Splited_Data_Label{i};
    test_data = Splited_Data{i};
    
    Training_all_data = [];
    Training_all_Label = [];
    for j = 1:10
        if j == i
            continue;
        end
        Training_all_data = [Training_all_data; Splited_Data{j}];
        Training_all_Label = [Training_all_Label; Splited_Data_Label{j}];
    end
    
    Subjects_Data.Training_all_data = Training_all_data;
    Subjects_Data.Training_all_Label = Training_all_Label';
    Subjects_Data.test_data = test_data;
    Subjects_Data.test_label = test_label;
    
    save([ResultantFolder filesep 'Subjects_Data_' num2str(i) '.mat'], 'Subjects_Data');
    
    Job_Name1 = ['Folder_' num2str(i)];
    pipeline.(Job_Name1).command   = 'Ttest_LR_2group_PSelection_10Folder_SGE_child(opt.SubjectsData_Path, opt.Folder_th, opt.P_Value_Range, opt.Pre_Method, opt.ResultantFolder)';
    pipeline.(Job_Name1).opt.SubjectsData_Path = [ResultantFolder filesep 'Subjects_Data_' num2str(i) '.mat'];
    pipeline.(Job_Name1).opt.Folder_th = i;
    pipeline.(Job_Name1).opt.P_Value_Range = P_Value_Range;
    pipeline.(Job_Name1).opt.Pre_Method = Pre_Method;
    pipeline.(Job_Name1).opt.ResultantFolder = ResultantFolder;
    pipeline.(Job_Name1).files_out{1} = [ResultantFolder filesep 'predicted_labels_' num2str(i) '.mat'];
    pipeline.(Job_Name1).files_out{2} = [ResultantFolder filesep 'decision_values_' num2str(i) '.mat'];
    pipeline.(Job_Name1).files_out{3} = [ResultantFolder filesep 'RetainID_' num2str(i) '.mat'];
    pipeline.(Job_Name1).files_out{4} = [ResultantFolder filesep 'w_' num2str(i) '.mat'];
    
end

Job_Name2 = ['Results_Merge'];
for i = 1:10
    PreJob_Name = ['Folder_' num2str(i)];
    pipeline.(Job_Name2).command   = 'Ttest_LR_2group_PSelection_10Folder_SGE_child2(opt.Origin_ID_Cell, opt.ResultantFolder, opt.Subjects_Label)';
    pipeline.(Job_Name2).files_in{i} = pipeline.(PreJob_Name).files_out{4};
    pipeline.(Job_Name2).opt.Origin_ID_Cell = Origin_ID_Cell;
    pipeline.(Job_Name2).opt.ResultantFolder = ResultantFolder;
    pipeline.(Job_Name2).opt.Subjects_Label = Subjects_Label;
end

psom_gb_vars

Pipeline_opt.mode = 'qsub';
Pipeline_opt.qsub_options = QsubOption;
Pipeline_opt.mode_pipeline_manager = 'batch';
Pipeline_opt.max_queued = 100;
Pipeline_opt.flag_verbose = 1;
Pipeline_opt.flag_pause = 0;
Pipeline_opt.path_logs = [ResultantFolder filesep 'logs'];

psom_run_pipeline(pipeline,Pipeline_opt);
