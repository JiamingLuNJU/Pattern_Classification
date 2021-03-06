function [Accuracy Sensitivity Specificity Category] = Logistic_QuasiNewton_2group_10Folder(Subjects_Data, Subjects_Label, Pre_Method, ResultantFolder)
%
% Subject_Data:
%           m*n matrix
%           m is the number of subjects
%           n is the number of features
%
% Subject_Label:
%           array of 0 or 1
%
% Pre_Method:
%           'Normalize' or 'Scale'
%
% ResultantFolder:
%           the path of folder storing resultant files
%

if nargin >= 4
    if ~exist(ResultantFolder, 'dir')
        mkdir(ResultantFolder);
    end
end

[Subjects_Quantity Feature_Quantity] = size(Subjects_Data);
[Splited_Data, Splited_Data_Label, Origin_ID_Cell] = Split_NFolders(Subjects_Data, Subjects_Label, 10);

predicted_labels = [];
decision_values = [];

t=weka.classifiers.functions.Logistic();
% tmp=wekaArgumentString({'-R', 0.0});
% t.setOptions(tmp);
for i = 1:10
    
    disp(['The ' num2str(i) ' iteration!']);
    
    % Select training data and testing data
    test_label = Splited_Data_Label{i};
    test_data = Splited_Data{i};
    
    Training_all_data = [];
    Label = [];
    for j = 1:10
        if j == i
            continue;
        end
        Training_all_data = [Training_all_data; Splited_Data{j}];
        Label = [Label; Splited_Data_Label{j}];
    end

    if strcmp(Pre_Method, 'Normalize')
        %Normalizing
        MeanValue = mean(Training_all_data);
        StandardDeviation = std(Training_all_data);
        [rows, columns_quantity] = size(Training_all_data);
        for j = 1:columns_quantity
            Training_all_data(:, j) = (Training_all_data(:, j) - MeanValue(j)) / StandardDeviation(j);
        end
    elseif strcmp(Pre_Method, 'Scale')
        % Scaling to [0 1]
        MinValue = min(Training_all_data);
        MaxValue = max(Training_all_data);
        [rows, columns_quantity] = size(Training_all_data);
        for j = 1:columns_quantity
            Training_all_data(:, j) = (Training_all_data(:, j) - MinValue(j)) / (MaxValue(j) - MinValue(j));
        end
    end

    % Logistic classification
    Label = reshape(Label, length(Label), 1);
    Training_all_data = double(Training_all_data);
    
    X_Y = data(Training_all_data, Label);
    cat = wekaCategoricalData(X_Y);
    t.buildClassifier(cat);

    if strcmp(Pre_Method, 'Normalize')
        % Normalizing
        MeanValue_New = repmat(MeanValue, length(test_label), 1);
        StandardDeviation_New = repmat(StandardDeviation, length(test_label), 1);
        test_data = (test_data - MeanValue_New) ./ StandardDeviation_New;
    elseif strcmp(Pre_Method, 'Scale')
        % Scale
        MaxValue_New = repmat(MaxValue, length(test_label), 1);
        MinValue_New = repmat(MinValue, length(test_label), 1);
        test_data = (test_data - MinValue_New) ./ (MaxValue_New - MinValue_New);
    end

    % predicts
    test_data = double(test_data);
    X_Y = data(test_data, test_label);
    dw = wekaCategoricalData(X_Y);
    for j = 1:length(test_label)
        predicted_labels_tmp(j) = t.classifyInstance(dw.instance(j - 1));
    end
    predicted_labels = [predicted_labels predicted_labels_tmp];
    clear predicted_labels_tmp;
%     decision_values(i) = [1 test_data] * t.coefficients;
    
end

predicted_labels(find(~predicted_labels)) = -1;

Origin_ID = [];
for i = 1:length(Origin_ID_Cell)
    Origin_ID = [Origin_ID; Origin_ID_Cell{i}];
end

Group1_Index = find(Subjects_Label(Origin_ID) == 1);
Group0_Index = find(Subjects_Label(Origin_ID) == -1);
Category_group1 = predicted_labels(Group1_Index);
% Y_group1 = decision_values(Group1_Index);
Category_group0 = predicted_labels(Group0_Index);
% Y_group0 = decision_values(Group0_Index);

if nargin >= 4
%     save([ResultantFolder filesep 'Y.mat'], 'Y_group1', 'Y_group0');
    save([ResultantFolder filesep 'Category.mat'], 'Category_group1', 'Category_group0');
end

Category.Category_group0 = Category_group0;
Category.Category_group1 = Category_group1;

group0_Wrong_ID = find(Category_group0 == 1);
group0_Wrong_Quantity = length(group0_Wrong_ID);
group1_Wrong_ID = find(Category_group1 == -1);
group1_Wrong_Quantity = length(group1_Wrong_ID);
Accuracy = (Subjects_Quantity - group0_Wrong_Quantity - group1_Wrong_Quantity) / Subjects_Quantity;
Sensitivity = (length(Group0_Index) - group0_Wrong_Quantity) / length(Group0_Index);
Specificity = (length(Group1_Index) - group1_Wrong_Quantity) / length(Group1_Index);

if nargin >= 4
    disp(['group0: ' num2str(group0_Wrong_Quantity) ' subjects are wrong ' mat2str(group0_Wrong_ID) ]);
    disp(['group1: ' num2str(group1_Wrong_Quantity) ' subjects are wrong ' mat2str(group1_Wrong_ID) ]);
    save([ResultantFolder filesep 'WrongInfo.mat'], 'group0_Wrong_Quantity', 'group0_Wrong_ID', 'group1_Wrong_Quantity', 'group1_Wrong_ID');
    disp(['Accuracy is ' num2str(Accuracy) ' !']);
    save([ResultantFolder filesep 'Accuracy.mat'], 'Accuracy');
    disp(['Sensitivity is ' num2str(Sensitivity) ' !']);
    save([ResultantFolder filesep 'Sensitivity.mat'], 'Sensitivity');
    disp(['Specificity is ' num2str(Specificity) ' !']);
    save([ResultantFolder filesep 'Specificity.mat'], 'Specificity');


    % Calculating w
    if strcmp(Pre_Method, 'Normalize')
        %Normalizing
        MeanValue = mean(Subjects_Data);
        StandardDeviation = std(Subjects_Data);
        [rows, columns_quantity] = size(Subjects_Data);
        for j = 1:columns_quantity
            Subjects_Data(:, j) = (Subjects_Data(:, j) - MeanValue(j)) / StandardDeviation(j);
        end
    elseif strcmp(Pre_Method, 'Scale')
        % Scaling to [0 1]
        MinValue = min(Subjects_Data);
        MaxValue = max(Subjects_Data);
        [rows, columns_quantity] = size(Subjects_Data);
        for j = 1:columns_quantity
            Subjects_Data(:, j) = (Subjects_Data(:, j) - MinValue(j)) / (MaxValue(j) - MinValue(j));
        end
    end
    X_Y = data(Subjects_Data, Subjects_Label');
    cat = wekaCategoricalData(X_Y);
    t.buildClassifier(cat);
    Logistic_Coefficients = t.coefficients;
    w_Brain = Logistic_Coefficients(2:end)';
    w_Brain = w_Brain / norm(w_Brain);
    save([ResultantFolder filesep 'w_Brain.mat'], 'w_Brain');
end