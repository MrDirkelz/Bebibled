/// obj_grid_manager :: Create
/// Owns the authoritative board array and every operation that mutates it.
/// obj_grid_tile instances are visual puppets, linked via tile.view.

// ---- board geometry ----
cols      = 7;
rows      = 8;
cell_size = 90;
tile_layer = "Tiles";
board_w   = cols * cell_size;
board_h   = rows * cell_size;
origin_x  = (room_width - board_w) * 0.5;
origin_y  = 400;

anim_active = 0;                 // animation barrier: # of busy tile views (recounted each Step)
global.grid_manager = id;        // singleton handle for coordinate helpers / input / views
board_ready = false;

// =========================================================================
// View helpers
// =========================================================================

/// spawn a tile view for a data struct; _start_y lets newcomers fall from above
spawn_tile_view = function(_c, _r, _tile, _start_y) {
    var _pos = grid_cell_to_world(_c, _r);
    var _sy  = (_start_y == undefined) ? _pos.y : _start_y;
    var _inst = instance_create_layer(_pos.x, _sy, tile_layer, obj_grid_tile);
    _inst.col      = _c;
    _inst.row      = _r;
    _inst.tile     = _tile;
    _inst.draw_x   = _pos.x;
    _inst.draw_y   = _sy;
    _inst.target_x = _pos.x;
    _inst.target_y = _pos.y;
    _tile.view = _inst;
    return _inst;
};

/// point an existing tile's view at a new cell (it will tween there)
retarget_view = function(_tile, _c, _r) {
    if (_tile == undefined) return;
    var _v = _tile.view;
    if (_v == noone || !instance_exists(_v)) return;
    _v.col = _c;
    _v.row = _r;
    var _p = grid_cell_to_world(_c, _r);
    _v.target_x = _p.x;
    _v.target_y = _p.y;
};

// =========================================================================
// Board operations (called by the controller)
// =========================================================================

/// swap two cells in the array and retarget their views
swap_cells = function(_c1, _r1, _c2, _r2) {
    var _a = grid[_c1][_r1];
    var _b = grid[_c2][_r2];
    grid[_c1][_r1] = _b;
    grid[_c2][_r2] = _a;
    retarget_view(_a, _c2, _r2);
    retarget_view(_b, _c1, _r1);
};

/// remove a list of {col,row} cells: data goes empty now, views animate out
clear_cells = function(_list) {
    for (var i = 0; i < array_length(_list); i++) {
        var _cell = _list[i];
        var _t = grid[_cell.col][_cell.row];
        if (_t != undefined) {
            if (_t.is_divine && variable_global_exists("level")) global.level.plant_consumed = true;
            if (_t.view != noone && instance_exists(_t.view)) _t.view.begin_clear();
            grid[_cell.col][_cell.row] = undefined;
        }
    }
};

/// create the special/power tiles produced by a resolution
spawn_specials = function(_list) {
    for (var i = 0; i < array_length(_list); i++) {
        var _s = _list[i];
        var _t = new Tile(_s.color, tile_random_letter(), _s.type);
        grid[_s.col][_s.row] = _t;
        spawn_tile_view(_s.col, _s.row, _t, undefined);
    }
};

/// gravity + refill, syncing views (existing tiles fall, newcomers drop from the top)
collapse_and_refill = function() {
    var _moves = grid_apply_gravity(grid, cols, rows);
    for (var i = 0; i < array_length(_moves); i++) {
        var _m = _moves[i];
        retarget_view(_m.tile, _m.col, _m.to_row);
    }
    var _spawns = grid_refill(grid, cols, rows);
    for (var i = 0; i < array_length(_spawns); i++) {
        var _s = _spawns[i];
        var _p = grid_cell_to_world(_s.col, _s.row);
        spawn_tile_view(_s.col, _s.row, _s.tile, _p.y - board_h); // start above the board
    }
};

/// most common color currently on the board (used by Cleanse)
most_common_color = function() {
    var _counts = array_create(COLOR.COUNT, 0);
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            var _t = grid[_c][_r];
            if (_t != undefined && tile_is_matchable(_t)) _counts[_t.color_id]++;
        }
    }

    var _best = 0;
    for (var i = 1; i < COLOR.COUNT; i++) {
        if (_counts[i] > _counts[_best]) _best = i;
    }
    return _best;
};

/// cells of one color as a clear list (used by Cleanse)
clear_color = function(_color) {
    var _list = [];
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            var _t = grid[_c][_r];
            if (_t != undefined && tile_is_matchable(_t) && _t.color_id == _color) {
                array_push(_list, { col : _c, row : _r });
            }
        }
    }
    return _list;
};

/// relabel up to _count normal tiles from the current verse bag (used by Manna)
reletter_random = function(_count) {
    var _cells = [];
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            var _t = grid[_c][_r];
            if (_t != undefined && _t.type == TILE_TYPE.NORMAL && _t.status == TILE_STATUS.NONE) {
                array_push(_cells, { col : _c, row : _r });
            }
        }
    }

    for (var i = 0; i < min(_count, array_length(_cells)); i++) {
        var _pick = i + irandom(array_length(_cells) - 1 - i);
        var _tmp = _cells[i]; _cells[i] = _cells[_pick]; _cells[_pick] = _tmp;
        var _cell = _cells[i];
        grid[_cell.col][_cell.row].letter = tile_random_letter();
    }
};

plant_fresh_divine = function() {
    if (!variable_global_exists("level")) return;
    global.level.plant_list = plant_choose_words(global.level.plant_candidates, global.level.rules, irandom(1000000));
    plant_words(grid, cols, rows, global.level.plant_list, global.level.rules);
};

maybe_replant = function() {
    if (!variable_global_exists("level")) return;
    if (!global.level.plant_consumed) return;
    plant_fresh_divine();
};

/// are there any empty cells right now? (boss destroy actions create them)
has_empty = function() {
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            if (grid[_c][_r] == undefined) return true;
        }
    }
    return false;
};

/// reshuffle existing tiles until a legal move exists; retarget views
shuffle_board = function() {
    var _tiles = [];
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            if (grid[_c][_r] != undefined) array_push(_tiles, grid[_c][_r]);
        }
    }
    var _attempts = 0;
    do {
        for (var i = array_length(_tiles) - 1; i > 0; i--) {
            var j = irandom(i);
            var _tmp = _tiles[i]; _tiles[i] = _tiles[j]; _tiles[j] = _tmp;
        }
        var _k = 0;
        for (var _c = 0; _c < cols; _c++) {
            for (var _r = 0; _r < rows; _r++) {
                if (grid[_c][_r] != undefined) { grid[_c][_r] = _tiles[_k]; _k++; }
            }
        }
        _attempts++;
    } until (grid_has_valid_move(grid, cols, rows) || _attempts > 25);

    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            retarget_view(grid[_c][_r], _c, _r);
        }
    }
};

// =========================================================================
// Mutation API (the boss talks only to these)
// =========================================================================

lock_tile = function(_c, _r, _turns) {
    var _t = grid[_c][_r];
    if (_t == undefined) return;
    _t.status = TILE_STATUS.LOCKED;
    _t.status_turns = _turns;
};

freeze_tile = function(_c, _r, _turns) {
    var _t = grid[_c][_r];
    if (_t == undefined) return;
    _t.status = TILE_STATUS.FROZEN;
    _t.status_turns = _turns;
};

transform_tile = function(_c, _r, _color, _type) {
    var _t = grid[_c][_r];
    if (_t == undefined) return;
    if (_t.is_divine && variable_global_exists("level")) global.level.plant_consumed = true;
    _t.color_id = _color;
    _t.type = _type;
    _t.status = TILE_STATUS.NONE;
    _t.is_divine = false;
};

destroy_tile = function(_c, _r) {
    clear_cells([ { col: _c, row: _r } ]);
};

/// decrement timed statuses; expired ones clear (called at the start of the player's turn)
tick_statuses = function() {
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            var _t = grid[_c][_r];
            if (_t != undefined && _t.status != TILE_STATUS.NONE) {
                _t.status_turns--;
                if (_t.status_turns <= 0) _t.status = TILE_STATUS.NONE;
            }
        }
    }
};

/// boss targeting: up to _n random normal, unafflicted cells
get_random_cells = function(_n) {
    var _cands = [];
    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            var _t = grid[_c][_r];
            if (_t != undefined && _t.type == TILE_TYPE.NORMAL && _t.status == TILE_STATUS.NONE) {
                array_push(_cands, { col: _c, row: _r });
            }
        }
    }
    for (var i = array_length(_cands) - 1; i > 0; i--) {
        var j = irandom(i);
        var _tmp = _cands[i]; _cands[i] = _cands[j]; _cands[j] = _tmp;
    }
    var _out = [];
    var _take = min(_n, array_length(_cands));
    for (var i = 0; i < _take; i++) array_push(_out, _cands[i]);
    return _out;
};

// =========================================================================
// Build the starting board (called by the controller after level_load)
// =========================================================================

build_board = function() {
    with (obj_grid_tile) instance_destroy();

    board_ready = false;
    grid = array_create(cols);
    for (var _c = 0; _c < cols; _c++) {
        grid[_c] = array_create(rows, undefined);
    }

    if (variable_global_exists("level")) random_set_seed(global.level.seed);
    grid_fill_no_matches(grid, cols, rows);
    if (variable_global_exists("level")) plant_words(grid, cols, rows, global.level.plant_list, global.level.rules);

    for (var _c = 0; _c < cols; _c++) {
        for (var _r = 0; _r < rows; _r++) {
            spawn_tile_view(_c, _r, grid[_c][_r], undefined);
        }
    }

    anim_active = 0;
    board_ready = true;
};

grid = array_create(cols);
for (var _c = 0; _c < cols; _c++) grid[_c] = array_create(rows, undefined);
