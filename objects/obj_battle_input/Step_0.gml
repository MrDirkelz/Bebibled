/// obj_battle_input :: Step
/// Press a tile, release on an orthogonally adjacent tile to request a swap.
/// Active only during PLAYER_INPUT.

if (ctrl == noone) ctrl = instance_find(obj_battle_controller, 0);
if (ctrl == noone) exit;

if (ctrl.state == BATTLE_STATE.VICTORY || ctrl.state == BATTLE_STATE.DEFEAT) {
    if (ctrl.state == BATTLE_STATE.DEFEAT && keyboard_check_pressed(ord("R"))) ctrl.request_retry();

    if (mouse_check_button_pressed(mb_left)) {
        var _gx = device_mouse_x_to_gui(0);
        var _gy = device_mouse_y_to_gui(0);
        var _btns = battle_end_buttons(ctrl.state, display_get_gui_width(), display_get_gui_height());
        for (var i = 0; i < array_length(_btns); i++) {
            var _bt = _btns[i];
            if (point_in_rect(_gx, _gy, _bt.x1, _bt.y1, _bt.x2, _bt.y2)) {
                if (_bt.id == "next")       ctrl.next_verse();
                else if (_bt.id == "retry") ctrl.request_retry();
                else if (_bt.id == "map")   ctrl.return_to_map();
            }
        }
    }
    exit;
}

if (ctrl.state != BATTLE_STATE.PLAYER_INPUT) {
    sel_col = -1;
    sel_row = -1;
    trace_path = [];
    exit;
}

if (mouse_check_button_pressed(mb_left)) {
    var _miracle_idx = miracle_button_index_at(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0));
    if (_miracle_idx >= 0) {
        ctrl.request_miracle(_miracle_idx);
        exit;
    }

    var _cell = grid_world_to_cell(mouse_x, mouse_y);
    if (grid_in_bounds(_cell.col, _cell.row)) {
        sel_col = _cell.col;
        sel_row = _cell.row;
        trace_path = [ { col : sel_col, row : sel_row } ];
    }
}

if (mouse_check_button(mb_left) && sel_col >= 0) {
    var _cell = grid_world_to_cell(mouse_x, mouse_y);
    if (grid_in_bounds(_cell.col, _cell.row)) {
        var _last = trace_path[array_length(trace_path) - 1];
        if (_cell.col != _last.col || _cell.row != _last.row) {
            var _adjacent = (abs(_cell.col - _last.col) <= 1 && abs(_cell.row - _last.row) <= 1);
            var _seen = false;
            for (var i = 0; i < array_length(trace_path); i++) {
                if (trace_path[i].col == _cell.col && trace_path[i].row == _cell.row) _seen = true;
            }
            if (_adjacent && !_seen) array_push(trace_path, { col : _cell.col, row : _cell.row });
        }
    }
}

if (mouse_check_button_released(mb_left) && sel_col >= 0) {
    var _cell = grid_world_to_cell(mouse_x, mouse_y);
    if (array_length(trace_path) >= 3) {
        ctrl.request_word_trace(trace_path);
    } else if (grid_in_bounds(_cell.col, _cell.row)) {
        var _dc = _cell.col - sel_col;
        var _dr = _cell.row - sel_row;
        if (abs(_dc) + abs(_dr) == 1) {
            ctrl.request_swap(sel_col, sel_row, _cell.col, _cell.row);
        }
    }
    sel_col = -1;
    sel_row = -1;
    trace_path = [];
}
