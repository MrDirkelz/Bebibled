/// obj_grid_tile :: Step
/// Smoothly tween toward the target cell position; run the clear animation.
/// Report busy/idle to the manager's animation barrier via `is_busy`.

if (state == "clearing") {
    clear_t++;
    gem_scale = 1 - (clear_t / CLEAR_FRAMES);
    is_busy = true;
    if (clear_t >= CLEAR_FRAMES) {
        instance_destroy();
        exit;
    }
    exit;
}

// position smoothing
draw_x = lerp(draw_x, target_x, TILE_LERP);
draw_y = lerp(draw_y, target_y, TILE_LERP);

var _arrived = (point_distance(draw_x, draw_y, target_x, target_y) < 1);
if (_arrived) {
    draw_x = target_x;
    draw_y = target_y;
}
is_busy = !_arrived;
