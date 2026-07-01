/// scr_grid_logic
/// Pure-ish algorithms over the board array. The grid is column-major:
///   grid[col][row], col in [0,cols), row in [0,rows), row 0 = top.
/// Empty cells are `undefined`. Gravity pulls toward higher row indices.
/// These functions never touch instances; the manager syncs views from their output.

/// @desc Run-length scan for horizontal + vertical color runs of length >= 3.
/// @returns array of groups: { cells:[{col,row}...], color, len, axis:"H"|"V" }
function grid_find_matches(_grid, _cols, _rows) {
    var _groups = [];

    // --- horizontal pass ---
    for (var _r = 0; _r < _rows; _r++) {
        var _run_color = -1;
        var _run_start = 0;
        var _run_len   = 0;
        for (var _c = 0; _c <= _cols; _c++) {
            var _matchable = false;
            var _cid = -1;
            if (_c < _cols) {
                var _t = _grid[_c][_r];
                if (tile_is_matchable(_t)) { _matchable = true; _cid = _t.color_id; }
            }
            if (_matchable && _cid == _run_color) {
                _run_len++;
            } else {
                if (_run_len >= 3) {
                    var _cells = [];
                    for (var _k = _run_start; _k < _run_start + _run_len; _k++) {
                        array_push(_cells, { col: _k, row: _r });
                    }
                    array_push(_groups, { cells: _cells, color: _run_color, len: _run_len, axis: "H" });
                }
                if (_matchable) { _run_color = _cid; _run_start = _c; _run_len = 1; }
                else            { _run_color = -1;  _run_len = 0; }
            }
        }
    }

    // --- vertical pass ---
    for (var _c = 0; _c < _cols; _c++) {
        var _run_color = -1;
        var _run_start = 0;
        var _run_len   = 0;
        for (var _r = 0; _r <= _rows; _r++) {
            var _matchable = false;
            var _cid = -1;
            if (_r < _rows) {
                var _t = _grid[_c][_r];
                if (tile_is_matchable(_t)) { _matchable = true; _cid = _t.color_id; }
            }
            if (_matchable && _cid == _run_color) {
                _run_len++;
            } else {
                if (_run_len >= 3) {
                    var _cells = [];
                    for (var _k = _run_start; _k < _run_start + _run_len; _k++) {
                        array_push(_cells, { col: _c, row: _k });
                    }
                    array_push(_groups, { cells: _cells, color: _run_color, len: _run_len, axis: "V" });
                }
                if (_matchable) { _run_color = _cid; _run_start = _r; _run_len = 1; }
                else            { _run_color = -1;  _run_len = 0; }
            }
        }
    }

    return _groups;
}

/// @desc Compact each column downward into empty (undefined) slots.
/// Mutates _grid. Returns move records: [{ tile, col, from_row, to_row }...]
function grid_apply_gravity(_grid, _cols, _rows) {
    var _moves = [];
    for (var _c = 0; _c < _cols; _c++) {
        var _write = _rows - 1;
        for (var _r = _rows - 1; _r >= 0; _r--) {
            var _t = _grid[_c][_r];
            if (_t != undefined) {
                if (_r != _write) {
                    _grid[_c][_write] = _t;
                    _grid[_c][_r] = undefined;
                    array_push(_moves, { tile: _t, col: _c, from_row: _r, to_row: _write });
                }
                _write--;
            }
        }
    }
    return _moves;
}

/// @desc Fill every empty cell (which sit at the top after gravity) with a new tile.
/// Mutates _grid. Returns spawn records: [{ tile, col, row }...]
function grid_refill(_grid, _cols, _rows) {
    var _spawns = [];
    for (var _c = 0; _c < _cols; _c++) {
        for (var _r = 0; _r < _rows; _r++) {
            if (_grid[_c][_r] == undefined) {
                var _t = new Tile(irandom(COLOR.COUNT - 1), tile_random_letter());
                _grid[_c][_r] = _t;
                array_push(_spawns, { tile: _t, col: _c, row: _r });
            }
        }
    }
    return _spawns;
}

/// @desc Fill the whole board avoiding any starting run of 3 (greedy reject).
/// Mutates _grid (assumes columns already allocated).
function grid_fill_no_matches(_grid, _cols, _rows) {
    for (var _c = 0; _c < _cols; _c++) {
        for (var _r = 0; _r < _rows; _r++) {
            var _color;
            var _safety = 0;
            do {
                _color = irandom(COLOR.COUNT - 1);
                var _bad_h = (_c >= 2
                    && _grid[_c-1][_r] != undefined && _grid[_c-2][_r] != undefined
                    && _grid[_c-1][_r].color_id == _color && _grid[_c-2][_r].color_id == _color);
                var _bad_v = (_r >= 2
                    && _grid[_c][_r-1] != undefined && _grid[_c][_r-2] != undefined
                    && _grid[_c][_r-1].color_id == _color && _grid[_c][_r-2].color_id == _color);
                _safety++;
            } until ((!_bad_h && !_bad_v) || _safety > 50);
            _grid[_c][_r] = new Tile(_color, tile_random_letter());
        }
    }
}

/// @desc Does any single adjacent swap create a match? (deadlock detection)
function grid_has_valid_move(_grid, _cols, _rows) {
    for (var _c = 0; _c < _cols; _c++) {
        for (var _r = 0; _r < _rows; _r++) {
            if (_c < _cols - 1 && grid_swap_makes_match(_grid, _c, _r, _c+1, _r, _cols, _rows)) return true;
            if (_r < _rows - 1 && grid_swap_makes_match(_grid, _c, _r, _c, _r+1, _cols, _rows)) return true;
        }
    }
    return false;
}

/// @desc Temporarily swap two cells, test for any match, then restore.
function grid_swap_makes_match(_grid, _c1, _r1, _c2, _r2, _cols, _rows) {
    var _a = _grid[_c1][_r1];
    var _b = _grid[_c2][_r2];
    if (!tile_is_swappable(_a) || !tile_is_swappable(_b)) return false;
    _grid[_c1][_r1] = _b; _grid[_c2][_r2] = _a;
    var _has = (array_length(grid_find_matches(_grid, _cols, _rows)) > 0);
    _grid[_c1][_r1] = _a; _grid[_c2][_r2] = _b;
    return _has;
}
