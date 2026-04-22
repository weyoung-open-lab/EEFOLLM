function log_message(log_file, msg)
%LOG_MESSAGE Append timestamped message to log file.
ts = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
line = sprintf('[%s] %s\n', ts, msg);
fprintf('%s', line);
if nargin > 0 && ~isempty(log_file)
    fid = fopen(log_file, 'a');
    if fid > 0
        fprintf(fid, '%s', line);
        fclose(fid);
    end
end
end
