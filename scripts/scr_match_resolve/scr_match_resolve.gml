/// scr_match_resolve
/// Turn raw match groups into an actionable resolution:
///   - the full set of cells to clear (dedup + special AoE expansion)
///   - the special/power tiles to spawn (match-4 -> line, match-5 -> rainbow, L/T -> bomb)
///   - the cleared letters (for the word system) and the boss damage (with cascade combo)

/// @desc "col_row" key for a cell.
function match_key(_col, _row) {
    return string(_col) + "_" + string(_row);
}

/// @desc Choose where a run's special spawns: the swapped cell if it's in the run, else the middle.
function match_pick_cell(_group, _swap_cells) {
    if (_swap_cells != undefined) {
        for (var i = 0; i < array_length(_group.cells); i++) {
            var _c = _group.cells[i];
            for (var s = 0; s < array_length(_swap_cells); s++) {
                if (_c.col == _swap_cells[s].col && _c.row == _swap_cells[s].row) return _c;
            }
        }
    }
    return _group.cells[floor(array_length(_group.cells) / 2)];
}

/// @desc Build the resolution for a set of match groups.
/// @returns { clear_cells, specials, letters, tiles_cleared, damage }
function match_resolve(_grid, _groups, _swap_cells, _combo, _cols, _rows) {
    var _clearmap = {};
    var _clearlist = [];
    var _hmap = {};
    var _vmap = {};

    // base clear set (dedup) + per-axis membership maps (for L/T detection)
    for (var g = 0; g < array_length(_groups); g++) {
        var _grp = _groups[g];
        var _axis_map = (_grp.axis == "H") ? _hmap : _vmap;
        for (var j = 0; j < array_length(_grp.cells); j++) {
            var _cell = _grp.cells[j];
            var _k = match_key(_cell.col, _cell.row);
            _axis_map[$ _k] = true;
            if (!variable_struct_exists(_clearmap, _k)) {
                _clearmap[$ _k] = true;
                array_push(_clearlist, { col: _cell.col, row: _cell.row });
            }
        }
    }

    // --- decide specials ---
    var _spec_map = {};   // key -> { col, row, type, color }

    // long runs -> line (4) or rainbow (5+)
    for (var g = 0; g < array_length(_groups); g++) {
        var _grp = _groups[g];
        if (_grp.len >= 4) {
            var _pick = match_pick_cell(_grp, _swap_cells);
            var _type = (_grp.len >= 5) ? TILE_TYPE.RAINBOW
                      : ((_grp.axis == "H") ? TILE_TYPE.LINE_H : TILE_TYPE.LINE_V);
            _spec_map[$ match_key(_pick.col, _pick.row)] =
                { col: _pick.col, row: _pick.row, type: _type, color: _grp.color };
        }
    }

    // intersections (a cell in both an H and a V run) -> bomb (overrides line)
    for (var i = 0; i < array_length(_clearlist); i++) {
        var _cell = _clearlist[i];
        var _k = match_key(_cell.col, _cell.row);
        if (variable_struct_exists(_hmap, _k) && variable_struct_exists(_vmap, _k)) {
            var _ct = _grid[_cell.col][_cell.row];
            var _col = (_ct != undefined) ? _ct.color_id : COLOR.RED;
            _spec_map[$ _k] = { col: _cell.col, row: _cell.row, type: TILE_TYPE.BOMB, color: _col };
        }
    }

    // --- expand any PRE-EXISTING special tiles caught in the clear (chain reactions) ---
    var _idx = 0;
    while (_idx < array_length(_clearlist)) {
        var _cell = _clearlist[_idx];
        var _t = _grid[_cell.col][_cell.row];
        if (_t != undefined) {
            switch (_t.type) {
                case TILE_TYPE.LINE_H:
                    for (var _c = 0; _c < _cols; _c++) _match_add(_clearmap, _clearlist, _c, _cell.row);
                    break;
                case TILE_TYPE.LINE_V:
                    for (var _r = 0; _r < _rows; _r++) _match_add(_clearmap, _clearlist, _cell.col, _r);
                    break;
                case TILE_TYPE.BOMB:
                    for (var _dc = -1; _dc <= 1; _dc++) {
                        for (var _dr = -1; _dr <= 1; _dr++) {
                            var _nc = _cell.col + _dc, _nr = _cell.row + _dr;
                            if (_nc >= 0 && _nc < _cols && _nr >= 0 && _nr < _rows) {
                                _match_add(_clearmap, _clearlist, _nc, _nr);
                            }
                        }
                    }
                    break;
                case TILE_TYPE.RAINBOW:
                    var _target = _t.color_id;
                    for (var _c = 0; _c < _cols; _c++) {
                        for (var _r = 0; _r < _rows; _r++) {
                            var _o = _grid[_c][_r];
                            if (_o != undefined && _o.color_id == _target) {
                                _match_add(_clearmap, _clearlist, _c, _r);
                            }
                        }
                    }
                    break;
            }
        }
        _idx++;
    }

    // --- collect letters + count for damage (a spawned-special cell still counts as cleared) ---
    var _letters = "";
    for (var i = 0; i < array_length(_clearlist); i++) {
        var _cell = _clearlist[i];
        var _t = _grid[_cell.col][_cell.row];
        if (_t != undefined) _letters += string(_t.letter);
    }

    var _n = array_length(_clearlist);
    var _damage = round(_n * DMG_PER_TILE * (1 + (_combo - 1) * CASCADE_BONUS));

    // flatten special map
    var _specials = [];
    var _names = variable_struct_get_names(_spec_map);
    for (var i = 0; i < array_length(_names); i++) {
        array_push(_specials, _spec_map[$ _names[i]]);
    }

    return {
        clear_cells   : _clearlist,
        specials      : _specials,
        letters       : _letters,
        tiles_cleared : _n,
        damage        : _damage
    };
}

/// @desc Append (col,row) to the clear list if not already present.
function _match_add(_map, _list, _col, _row) {
    var _k = match_key(_col, _row);
    if (!variable_struct_exists(_map, _k)) {
        _map[$ _k] = true;
        array_push(_list, { col: _col, row: _row });
    }
}
