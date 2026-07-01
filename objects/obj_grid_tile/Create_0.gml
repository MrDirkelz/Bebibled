/// obj_grid_tile :: Create
/// A visual puppet for ONE board cell. Holds no authoritative game state — it reads
/// its linked `tile` data struct and tweens toward the position the manager assigns.

col = 0;
row = 0;
tile = undefined;          // reference to the Tile struct in the manager's grid

draw_x = x;
draw_y = y;
target_x = x;
target_y = y;

state   = "idle";          // "idle" | "clearing"
clear_t = 0;               // clear-animation frame counter
gem_scale = 1;             // 0..1 visual scale (shrinks while clearing)
is_busy = false;           // true while moving or clearing (feeds the animation barrier)

/// begin the clear (death) animation; the instance destroys itself when done
begin_clear = function() {
    state   = "clearing";
    clear_t = 0;
};
