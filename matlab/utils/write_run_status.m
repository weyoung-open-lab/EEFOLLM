function write_run_status(cfg, msg)
%WRITE_RUN_STATUS Append timestamped line to logs/run_status.txt for user monitoring.
if nargin < 1 || isempty(cfg)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    log_dir = fullfile(root, 'logs');
else
    log_dir = cfg.paths.logs;
end
if ~exist(log_dir, 'dir')
    mkdir(log_dir);
end
path_file = fullfile(log_dir, 'run_status.txt');
ts = datestr(now, 'yyyy-mm-dd HH:MM:SS');
line = sprintf('[%s] %s\n', ts, msg);
fid = fopen(path_file, 'a');
if fid > 0
    fprintf(fid, '%s', line);
    fclose(fid);
end
fprintf(1, '%s', line);
drawnow;
end
