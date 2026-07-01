/// scr_letter_bag
/// Per-verse weighted letters plus divine-word planting.

function letter_index(_ch) {
    return ord(string_upper(_ch)) - ord("A");
}

function letter_from_index(_idx) {
    return chr(ord("A") + _idx);
}

function letter_eng_freq() {
    return [
        8.17, 1.49, 2.78, 4.25, 12.70, 2.23, 2.02, 6.09, 6.97,
        0.15, 0.77, 4.03, 2.41, 6.75, 7.51, 1.93, 0.10, 5.99,
        6.33, 9.06, 2.76, 0.98, 2.36, 0.15, 1.97, 0.07
    ];
}

function letter_normalize(_weights) {
    var _sum = 0;
    for (var i = 0; i < 26; i++) _sum += _weights[i];
    if (_sum <= 0) {
        for (var j = 0; j < 26; j++) _weights[j] = 1 / 26;
        return _weights;
    }
    for (var k = 0; k < 26; k++) _weights[k] /= _sum;
    return _weights;
}

function build_letter_bag(_target_words, _rules) {
    var _weights = array_create(26, 0);
    for (var w = 0; w < array_length(_target_words); w++) {
        var _word = _target_words[w];
        for (var i = 1; i <= string_length(_word); i++) {
            var _idx = letter_index(string_char_at(_word, i));
            if (_idx >= 0 && _idx < 26) _weights[_idx] += 1;
        }
    }

    _weights = letter_normalize(_weights);
    var _freq = letter_normalize(letter_eng_freq());
    var _blend = _rules.freq_floor;
    for (var f = 0; f < 26; f++) {
        _weights[f] = (1 - _blend) * _weights[f] + _blend * _freq[f];
    }

    var _floor = _rules.vowel_floor;
    if (level_rules_array_has(_rules.special_rules, SPECIAL_RULE.NO_VOWEL_FLOOR)) _floor = 0;
    if (level_rules_array_has(_rules.special_rules, SPECIAL_RULE.EXTRA_VOWELS)) _floor = min(1, _floor + 0.10);

    _weights = letter_normalize(_weights);
    var _vowel_mass = _weights[0] + _weights[4] + _weights[8] + _weights[14] + _weights[20];
    if (_vowel_mass > 0 && _vowel_mass < _floor && _floor < 1) {
        var _consonant_mass = max(0.0001, 1 - _vowel_mass);
        var _vowel_scale = _floor / _vowel_mass;
        var _consonant_scale = (1 - _floor) / _consonant_mass;
        for (var s = 0; s < 26; s++) {
            _weights[s] *= text_is_vowel(letter_from_index(s)) ? _vowel_scale : _consonant_scale;
        }
    }

    _weights = letter_normalize(_weights);
    var _cum = array_create(26, 0);
    var _total = 0;
    for (var c = 0; c < 26; c++) {
        _total += _weights[c];
        _cum[c] = _total;
    }

    return { weights : _weights, cum : _cum, total : _total };
}

function tile_pick_letter() {
    if (!variable_global_exists("level")) return letter_from_index(irandom(25));
    if (!variable_struct_exists(global.level, "bag")) return letter_from_index(irandom(25));

    var _bag = global.level.bag;
    var _roll = random(_bag.total);
    for (var i = 0; i < 26; i++) {
        if (_roll <= _bag.cum[i]) return letter_from_index(i);
    }
    return "E";
}

function letter_set_from_words(_words) {
    var _set = {};
    for (var w = 0; w < array_length(_words); w++) {
        var _word = _words[w];
        for (var i = 1; i <= string_length(_word); i++) {
            var _ch = string_char_at(_word, i);
            if (text_is_alpha_char(_ch)) _set[$ string_upper(_ch)] = true;
        }
    }
    return _set;
}

function plant_choose_words(_candidates, _rules, _seed) {
    var _out = [];
    var _count = _rules.plant_count;
    if (level_rules_array_has(_rules.special_rules, SPECIAL_RULE.DOUBLE_PLANT)) _count = max(_count, 2);
    if (array_length(_candidates) <= 0 || _count <= 0) return _out;

    var _start = abs(floor(_seed)) mod array_length(_candidates);
    var _take = min(_count, array_length(_candidates));
    for (var i = 0; i < _take; i++) {
        var _word = _candidates[(_start + i) mod array_length(_candidates)];
        array_push(_out, { word : _word, placed : false, cells : [] });
    }
    return _out;
}

function plant_cell_available(_grid, _col, _row) {
    var _tile = _grid[_col][_row];
    return (_tile != undefined && _tile.type == TILE_TYPE.NORMAL && _tile.status == TILE_STATUS.NONE);
}

function plant_path_key(_col, _row) {
    return string(_col) + "_" + string(_row);
}

function plant_find_path_for_word(_grid, _cols, _rows, _word_len, _rules) {
    for (var _try = 0; _try < _rules.plant_max_tries; _try++) {
        var _col = irandom(_cols - 1);
        var _row = irandom(_rows - 1);
        if (!plant_cell_available(_grid, _col, _row)) continue;

        var _path = [ { col : _col, row : _row } ];
        var _used = {};
        _used[$ plant_path_key(_col, _row)] = true;

        while (array_length(_path) < _word_len) {
            var _last = _path[array_length(_path) - 1];
            var _options = [];
            for (var _dc = -1; _dc <= 1; _dc++) {
                for (var _dr = -1; _dr <= 1; _dr++) {
                    if (_dc == 0 && _dr == 0) continue;
                    var _nc = _last.col + _dc;
                    var _nr = _last.row + _dr;
                    if (_nc < 0 || _nc >= _cols || _nr < 0 || _nr >= _rows) continue;
                    var _key = plant_path_key(_nc, _nr);
                    if (variable_struct_exists(_used, _key)) continue;
                    if (plant_cell_available(_grid, _nc, _nr)) array_push(_options, { col : _nc, row : _nr });
                }
            }

            if (array_length(_options) <= 0) break;
            var _next = _options[irandom(array_length(_options) - 1)];
            _used[$ plant_path_key(_next.col, _next.row)] = true;
            array_push(_path, _next);
        }

        if (array_length(_path) == _word_len) return _path;
    }

    return [];
}

function plant_clear_divine(_grid, _cols, _rows) {
    for (var _col = 0; _col < _cols; _col++) {
        for (var _row = 0; _row < _rows; _row++) {
            var _tile = _grid[_col][_row];
            if (_tile != undefined) _tile.is_divine = false;
        }
    }
}

function plant_words(_grid, _cols, _rows, _plant_list, _rules) {
    plant_clear_divine(_grid, _cols, _rows);

    for (var p = 0; p < array_length(_plant_list); p++) {
        var _entry = _plant_list[p];
        var _word = _entry.word;
        var _path = plant_find_path_for_word(_grid, _cols, _rows, string_length(_word), _rules);
        _entry.cells = _path;
        _entry.placed = (array_length(_path) == string_length(_word));

        if (_entry.placed) {
            for (var i = 0; i < array_length(_path); i++) {
                var _cell = _path[i];
                var _tile = _grid[_cell.col][_cell.row];
                _tile.letter = string_char_at(_word, i + 1);
                _tile.is_divine = true;
            }
        }
    }

    if (variable_global_exists("level")) global.level.plant_consumed = false;
}
