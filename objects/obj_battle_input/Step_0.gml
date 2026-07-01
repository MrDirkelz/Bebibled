/// obj_battle_input :: Step
/// Press a tile, release on an orthogonally adjacent tile to request a swap.
/// Active only during PLAYER_INPUT.

if (ctrl == noone) ctrl = instance_find(obj_battle_controller, 0);
if (ctrl == noone) exit;

if (ctrl.state != BATTLE_STATE.PLAYER_INPUT) {
    sel_col = -1;
    sel_row = -1;
    exit;
}

if (mouse_check_button_pressed(mb_left)) {
    var _cell = grid_world_to_cell(mouse_x, mouse_y);
    if (grid_in_bounds(_cell.col, _cell.row)) {
        sel_col = _cell.col;
        sel_row = _cell.row;
    }
}

if (mouse_check_button_released(mb_left) && sel_col >= 0) {
    var _cell = grid_world_to_cell(mouse_x, mouse_y);
    if (grid_in_bounds(_cell.col, _cell.row)) {
        var _dc = _cell.col - sel_col;
        var _dr = _cell.row - sel_row;
        if (abs(_dc) + abs(_dr) == 1) {
            ctrl.request_swap(sel_col, sel_row, _cell.col, _cell.row);
        }
    }
    sel_col = -1;
    sel_row = -1;
}
