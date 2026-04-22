function ensure_dir(path_str)
%ENSURE_DIR Create folder if it does not exist.
if ~exist(path_str, 'dir')
    mkdir(path_str);
end
end
