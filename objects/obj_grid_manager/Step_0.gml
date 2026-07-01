/// obj_grid_manager :: Step
/// Animation barrier: recount how many tile views are still busy (moving or clearing).
/// The controller's animated states wait until anim_active == 0 before advancing.

anim_active = 0;
with (obj_grid_tile) {
    if (is_busy) other.anim_active++;
}
