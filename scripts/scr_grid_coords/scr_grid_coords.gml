/// scr_grid_coords
/// Cell <-> world coordinate math. These read board geometry from the singleton
/// grid manager (global.grid_manager), set in obj_grid_manager's Create event.

/// @desc World position of the CENTER of cell (col,row). Returns {x, y}.
function grid_cell_to_world(_col, _row) {
    var _gm = global.grid_manager;
    return {
        x : _gm.origin_x + _col * _gm.cell_size + _gm.cell_size * 0.5,
        y : _gm.origin_y + _row * _gm.cell_size + _gm.cell_size * 0.5
    };
}

/// @desc Which cell does a world point fall in? Returns {col, row} (may be out of bounds).
function grid_world_to_cell(_px, _py) {
    var _gm = global.grid_manager;
    return {
        col : floor((_px - _gm.origin_x) / _gm.cell_size),
        row : floor((_py - _gm.origin_y) / _gm.cell_size)
    };
}

/// @desc Is (col,row) a valid cell on the board?
function grid_in_bounds(_col, _row) {
    var _gm = global.grid_manager;
    return (_col >= 0 && _col < _gm.cols && _row >= 0 && _row < _gm.rows);
}
