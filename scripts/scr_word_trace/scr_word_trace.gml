/// scr_word_trace
/// Validates traced cell paths and turns accepted words into clear resolutions.

function word_trace_key(_col, _row) {
    return string(_col) + "_" + string(_row);
}

function word_trace_letters(_grid, _path) {
    var _word = "";
    for (var i = 0; i < array_length(_path); i++) {
        var _cell = _path[i];
        var _tile = _grid[_cell.col][_cell.row];
        if (_tile != undefined) _word += string_upper(string(_tile.letter));
    }
    return _word;
}

function word_trace_validate_path(_grid, _path, _cols, _rows) {
    if (!is_array(_path)) return false;
    if (!variable_global_exists("level")) return false;
    if (array_length(_path) < global.level.rules.trace_min_len) return false;

    var _seen = {};
    for (var i = 0; i < array_length(_path); i++) {
        var _cell = _path[i];
        if (_cell.col < 0 || _cell.col >= _cols || _cell.row < 0 || _cell.row >= _rows) return false;

        var _key = word_trace_key(_cell.col, _cell.row);
        if (variable_struct_exists(_seen, _key)) return false;
        _seen[$ _key] = true;

        var _tile = _grid[_cell.col][_cell.row];
        if (!tile_is_matchable(_tile)) return false;

        if (i > 0) {
            var _prev = _path[i - 1];
            var _dc = abs(_cell.col - _prev.col);
            var _dr = abs(_cell.row - _prev.row);
            if (_dc > 1 || _dr > 1 || (_dc == 0 && _dr == 0)) return false;
        }
    }

    return true;
}

function word_trace_is_divine(_word) {
    if (!variable_global_exists("level")) return false;
    return variable_struct_exists(global.level.targets, string_upper(_word));
}

function word_trace_resolve(_grid, _path, _cols, _rows) {
    if (!word_trace_validate_path(_grid, _path, _cols, _rows)) {
        return { ok : false, reason : "Invalid path" };
    }

    var _word = word_trace_letters(_grid, _path);
    if (!word_is_valid(_word)) {
        return { ok : false, reason : "Not in KJV" };
    }

    var _clearlist = expand_specials(_grid, _path, _cols, _rows);
    var _clear_res = clearlist_resolve(_grid, _clearlist, 1, _cols, _rows);
    var _divine = word_trace_is_divine(_word);
    var _crit = _divine ? global.level.rules.divine_crit_mult : 1;
    var _word_bonus = word_score(_word);
    var _damage = round((_clear_res.damage + _word_bonus) * _crit);

    return {
        ok : true,
        word : _word,
        divine : _divine,
        clear_cells : _clear_res.clear_cells,
        letters : _clear_res.letters,
        tiles_cleared : _clear_res.tiles_cleared,
        damage : _damage,
        charge : _clear_res.charge + _word_bonus
    };
}
