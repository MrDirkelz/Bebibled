/// scr_level
/// Builds one deterministic battle level from a KJV verse reference.

function level_hash(_book, _chapter, _verse) {
    var _hash = 2166136261;
    _hash = (_hash * 16777619 + _book + 1) mod 2147483647;
    _hash = (_hash * 16777619 + _chapter + 1) mod 2147483647;
    _hash = (_hash * 16777619 + _verse + 1) mod 2147483647;
    return abs(floor(_hash));
}

function level_targets_from_verse(_verse_text, _rules) {
    var _all_words = text_alpha_words(_verse_text, 3, false);
    var _significant = text_alpha_words(_verse_text, 3, true);
    var _targets = {};
    var _plant = [];

    for (var i = 0; i < array_length(_all_words); i++) {
        var _word = _all_words[i];
        _targets[$ _word] = true;
    }

    for (var s = 0; s < array_length(_significant); s++) {
        var _sig = _significant[s];
        var _len = string_length(_sig);
        if (_len >= _rules.plant_min_len && _len <= _rules.plant_max_len) array_push(_plant, _sig);
    }

    if (array_length(_plant) <= 0) {
        for (var a = 0; a < array_length(_all_words); a++) {
            var _fallback = _all_words[a];
            var _fallback_len = string_length(_fallback);
            if (_fallback_len >= _rules.plant_min_len && _fallback_len <= _rules.plant_max_len) array_push(_plant, _fallback);
        }
    }

    return { words : _all_words, targets : _targets, plant : _plant };
}

function level_make_blanks(_plant_candidates, _rules) {
    var _blanks = [];
    var _take = min(_rules.blanks_max, array_length(_plant_candidates));
    for (var i = 0; i < _take; i++) {
        array_push(_blanks, { word : _plant_candidates[i], filled : false });
    }
    return _blanks;
}

function level_fill_blank(_word) {
    if (!variable_global_exists("level")) return false;
    var _upper = string_upper(_word);
    for (var i = 0; i < array_length(global.level.blanks); i++) {
        var _blank = global.level.blanks[i];
        if (_blank.word == _upper && !_blank.filled) {
            _blank.filled = true;
            global.level.blanks_filled++;
            return true;
        }
    }
    return false;
}

function level_all_blanks_filled() {
    if (!variable_global_exists("level")) return false;
    return (global.level.blanks_total > 0 && global.level.blanks_filled >= global.level.blanks_total);
}

function level_difficulty(_rules, _book, _chapter) {
    var _chapter_count = max(1, bible_chapter_count(_book));
    var _chapter_frac = _chapter / max(1, _chapter_count - 1);
    return _rules.book_tier * (1 + _chapter_frac * _rules.intra_book_slope);
}

function level_load(_book, _chapter, _verse) {
    game_boot_once();

    var _rules = get_level_rules(_book, _chapter, _verse);
    var _verse_text = bible_get_verse(_book, _chapter, _verse);
    var _targets = level_targets_from_verse(_verse_text, _rules);
    var _word_count = max(1, text_word_count(_verse_text));
    var _difficulty = level_difficulty(_rules, _book, _chapter);
    var _seed = level_hash(_book, _chapter, _verse);
    var _enemy_id = enemy_pick_id(_rules.enemy_pool, _seed);
    var _enemy = enemy_get_archetype(_enemy_id, _difficulty);
    var _hp_limit = round(_rules.hp_max * _rules.book_tier);
    var _enemy_hp = clamp(round((_rules.hp_base + _rules.hp_per_word * _word_count) * _difficulty * _enemy.hp_mult), _rules.hp_min, _hp_limit);
    var _bag = build_letter_bag(_targets.words, _rules);
    var _plant_list = plant_choose_words(_targets.plant, _rules, _seed);
    var _blanks = level_make_blanks(_targets.plant, _rules);

    global.level = {
        book : _book,
        chapter : _chapter,
        verse : _verse,
        reference : display_ref(_book, _chapter, _verse),
        verse_text : _verse_text,
        rules : _rules,
        targets : _targets.targets,
        target_words : _targets.words,
        plant_candidates : _targets.plant,
        letter_set : letter_set_from_words(_targets.words),
        bag : _bag,
        plant_list : _plant_list,
        blanks : _blanks,
        blanks_total : array_length(_blanks),
        blanks_filled : 0,
        enemy : _enemy,
        enemy_hp : _enemy_hp,
        difficulty : _difficulty,
        seed : _seed,
        plant_consumed : false
    };

    return global.level;
}

function level_compute_stars(_divine_words_spelled) {
    var _stars = 1;
    if (_divine_words_spelled > 0) _stars = 2;
    if (level_all_blanks_filled()) _stars = 3;
    return _stars;
}

function game_boot_once() {
    if (variable_global_exists("game_booted") && global.game_booted) return;

    global.game_booted = true;
    randomize();
    bible_data_init();
    level_rules_init();
    enemy_archetypes_init();
    miracles_init();
    bible_build_indices();
    save_load();
    word_init_dictionary();
}
