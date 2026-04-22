function pts_out = path_postprocess(pts_in, grid_map)
%PATH_POSTPROCESS Optional simple path smoothing by shortcut checks.
pts_out = pts_in;
if size(pts_out, 1) <= 2
    return;
end
i = 1;
while i < size(pts_out, 1) - 1
    j = size(pts_out, 1);
    shortened = false;
    while j > i + 1
        [collide, ~] = line_collision_check(pts_out(i, :), pts_out(j, :), grid_map, 0.5);
        if ~collide
            pts_out = [pts_out(1:i, :); pts_out(j:end, :)]; %#ok<AGROW>
            shortened = true;
            break;
        end
        j = j - 1;
    end
    if ~shortened
        i = i + 1;
    end
end
end
