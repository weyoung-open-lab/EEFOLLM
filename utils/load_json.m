function data = load_json(file_path)
%LOAD_JSON Load JSON file as MATLAB struct.
fid = fopen(file_path, 'r');
assert(fid > 0, 'Cannot open JSON file: %s', file_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
raw = fread(fid, '*char')';
data = jsondecode(raw);
end
