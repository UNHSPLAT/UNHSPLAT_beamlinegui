function addPathsSansGit
%ADDPATHSSANSGIT Add all subfolders of current directory to path omitting .git folders

% Generate path list from current directory
pathlist = genpath(pwd);

% Split into individual directory strings
tokes = regexp(pathlist,';','split');
tokes = tokes(1:end-1);

% Remove all subfolders containing .git
tokes = tokes(~contains(tokes,'.git'));

% Add all remaining subfolders to path
addpath(tokes{:});

end

