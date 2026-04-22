function save_json(file_path, data_struct)
%SAVE_JSON Save struct to JSON file with pretty format.
txt = jsonencode(data_struct, 'PrettyPrint', true);
fid = fopen(file_path, 'w');
assert(fid > 0, 'Cannot open JSON file for writing: %s', file_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', txt);
end
