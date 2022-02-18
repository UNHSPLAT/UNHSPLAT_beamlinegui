function addPathsSansGit
%ADDPATHSSANSGIT Summary of this function goes here
%   Detailed explanation goes here

pathlist = genpath(pwd);

tokes = regexp(pathlist,';','split');
tokes = tokes(1:end-1);
tokes = tokes(~contains(tokes,'.git'));

addpath(tokes{:});

end

