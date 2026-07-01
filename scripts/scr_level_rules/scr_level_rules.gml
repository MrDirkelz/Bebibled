/// scr_level_rules
/// Procedural tuning defaults plus sparse book/verse overrides.

enum SPECIAL_RULE {
    NONE,
    BOSS,
    EXTRA_VOWELS,
    NO_VOWEL_FLOOR,
    DOUBLE_PLANT,
    LOCKED_START
}

function level_rules_default() {
    return {
        palette : "",
        bg : "",
        music : "",
        enemy_pool : [ "default" ],

        hp_base : 60,
        hp_per_word : 6,
        hp_min : 80,
        hp_max : 600,
        book_tier : 1.0,
        intra_book_slope : 0.5,

        vowel_floor : 0.22,
        freq_floor : 0.35,
        plant_min_len : 3,
        plant_max_len : 7,
        plant_count : 1,
        plant_max_tries : 40,

        divine_crit_mult : 2.0,
        trace_min_len : 3,
        verse_letter_bonus : 1,
        blanks_max : 5,

        faith_max : 240,
        miracle_heal : 25,
        manna_k : 8,

        special_rules : []
    };
}

/// @desc Per-book theme + enemy roster (canonical order 0..65). One row per book:
/// [ theme_keyword, [enemy_pool...] ]. Palette/bg/music derive from the keyword,
/// so authoring art later is just adding pal_/bg_/mus_ assets by that name.
function level_rules_book_table() {
    return [
        [ "eden",         [ "serpent", "thorns" ] ],            // 0  Genesis
        [ "exodus",       [ "taskmaster", "chariot" ] ],       // 1  Exodus
        [ "altar",        [ "plague", "idol" ] ],              // 2  Leviticus
        [ "wilderness",   [ "wanderer", "serpent" ] ],         // 3  Numbers
        [ "covenant",     [ "idol", "wanderer" ] ],            // 4  Deuteronomy
        [ "conquest",     [ "raider", "giant" ] ],             // 5  Joshua
        [ "chaos",        [ "oppressor", "raider" ] ],         // 6  Judges
        [ "harvest",      [ "famine", "despair" ] ],           // 7  Ruth
        [ "kingdom",      [ "giant", "philistine" ] ],         // 8  1 Samuel
        [ "throne",       [ "betrayer", "usurper" ] ],         // 9  2 Samuel
        [ "temple",       [ "idol", "usurper" ] ],             // 10 1 Kings
        [ "exile",        [ "invader", "idol" ] ],             // 11 2 Kings
        [ "lineage",      [ "raider", "idol" ] ],              // 12 1 Chronicles
        [ "temple",       [ "invader", "idol" ] ],             // 13 2 Chronicles
        [ "return",       [ "schemer", "despair" ] ],          // 14 Ezra
        [ "rebuild",      [ "schemer", "oppressor" ] ],        // 15 Nehemiah
        [ "palace",       [ "schemer", "accuser" ] ],          // 16 Esther
        [ "trial",        [ "affliction", "accuser" ] ],       // 17 Job
        [ "praise",       [ "despair", "accuser" ] ],          // 18 Psalms
        [ "wisdom",       [ "folly", "tempter" ] ],            // 19 Proverbs
        [ "vanity",       [ "despair", "folly" ] ],            // 20 Ecclesiastes
        [ "garden",       [ "tempter", "despair" ] ],          // 21 Song of Solomon
        [ "vision",       [ "invader", "idol" ] ],             // 22 Isaiah
        [ "lament",       [ "invader", "false_prophet" ] ],    // 23 Jeremiah
        [ "ruin",         [ "invader", "despair" ] ],          // 24 Lamentations
        [ "vision",       [ "idol", "invader" ] ],             // 25 Ezekiel
        [ "lions",        [ "beast", "tyrant" ] ],             // 26 Daniel
        [ "unfaithful",   [ "idol", "tempter" ] ],             // 27 Hosea
        [ "locust",       [ "locust", "despair" ] ],           // 28 Joel
        [ "justice",      [ "oppressor", "idol" ] ],           // 29 Amos
        [ "judgment",     [ "pride", "invader" ] ],            // 30 Obadiah
        [ "deep",         [ "leviathan", "storm" ] ],          // 31 Jonah
        [ "injustice",    [ "oppressor", "idol" ] ],           // 32 Micah
        [ "downfall",     [ "tyrant", "invader" ] ],           // 33 Nahum
        [ "watch",        [ "invader", "despair" ] ],          // 34 Habakkuk
        [ "day",          [ "idol", "pride" ] ],               // 35 Zephaniah
        [ "rebuild",      [ "despair", "folly" ] ],            // 36 Haggai
        [ "vision",       [ "accuser", "schemer" ] ],          // 37 Zechariah
        [ "refiner",      [ "pride", "folly" ] ],              // 38 Malachi
        [ "kingdom",      [ "tempter", "accuser" ] ],          // 39 Matthew
        [ "servant",      [ "legion", "storm" ] ],             // 40 Mark
        [ "mercy",        [ "legion", "accuser" ] ],           // 41 Luke
        [ "light",        [ "darkness", "accuser" ] ],         // 42 John
        [ "spirit",       [ "persecutor", "schemer" ] ],       // 43 Acts
        [ "grace",        [ "sin", "accuser" ] ],              // 44 Romans
        [ "body",         [ "pride", "folly" ] ],              // 45 1 Corinthians
        [ "comfort",      [ "false_prophet", "affliction" ] ], // 46 2 Corinthians
        [ "freedom",      [ "legalist", "deceiver" ] ],        // 47 Galatians
        [ "armor",        [ "principality", "deceiver" ] ],    // 48 Ephesians
        [ "joy",          [ "despair", "pride" ] ],            // 49 Philippians
        [ "supremacy",    [ "heresy", "deceiver" ] ],          // 50 Colossians
        [ "hope",         [ "persecutor", "despair" ] ],       // 51 1 Thessalonians
        [ "watch",        [ "deceiver", "persecutor" ] ],      // 52 2 Thessalonians
        [ "order",        [ "false_prophet", "pride" ] ],      // 53 1 Timothy
        [ "endurance",    [ "persecutor", "deceiver" ] ],      // 54 2 Timothy
        [ "sound",        [ "deceiver", "folly" ] ],           // 55 Titus
        [ "forgiveness",  [ "pride", "despair" ] ],            // 56 Philemon
        [ "priest",       [ "despair", "deceiver" ] ],         // 57 Hebrews
        [ "works",        [ "folly", "pride" ] ],              // 58 James
        [ "suffering",    [ "persecutor", "accuser" ] ],       // 59 1 Peter
        [ "knowledge",    [ "false_prophet", "scoffer" ] ],    // 60 2 Peter
        [ "love",         [ "antichrist", "deceiver" ] ],      // 61 1 John
        [ "truth",        [ "deceiver", "antichrist" ] ],      // 62 2 John
        [ "hospitality",  [ "pride", "deceiver" ] ],           // 63 3 John
        [ "contend",      [ "deceiver", "scoffer" ] ],         // 64 Jude
        [ "apocalypse",   [ "dragon", "beast" ] ]              // 65 Revelation
    ];
}

function level_rules_init() {
    if (variable_global_exists("themes_ready") && global.themes_ready) return;

    var _table = level_rules_book_table();
    var _books = {};
    for (var _book = 0; _book < 66; _book++) {
        var _theme = _table[_book][0];
        var _pool  = _table[_book][1];
        _books[$ string(_book)] = {
            book_tier  : 1.0 + (_book / 65) * 1.5,
            palette    : "pal_" + _theme,
            bg         : "bg_" + _theme,
            music      : "mus_" + _theme,
            enemy_pool : _pool
        };
    }

    // iconic boss encounters (0-indexed book/chapter/verse, verified in range)
    var _overrides = {};
    _overrides[$ "0/0/0"]   = { enemy_pool : [ "serpent" ],  hp_base : 90,  special_rules : [ SPECIAL_RULE.BOSS ] };   // Genesis 1:1
    _overrides[$ "0/2/23"]  = { enemy_pool : [ "serpent" ],  hp_base : 120, special_rules : [ SPECIAL_RULE.BOSS ] };   // Genesis 3:24 - the Fall
    _overrides[$ "1/13/30"] = { enemy_pool : [ "chariot" ],  hp_base : 140, special_rules : [ SPECIAL_RULE.BOSS ] };   // Exodus 14:31 - Red Sea
    _overrides[$ "5/5/19"]  = { enemy_pool : [ "giant" ],    hp_base : 150, special_rules : [ SPECIAL_RULE.BOSS ] };   // Joshua 6:20 - Jericho
    _overrides[$ "8/16/49"] = { enemy_pool : [ "giant" ],    hp_base : 170, special_rules : [ SPECIAL_RULE.BOSS ] };   // 1 Samuel 17:50 - Goliath
    _overrides[$ "26/5/21"] = { enemy_pool : [ "beast" ],    hp_base : 180, special_rules : [ SPECIAL_RULE.BOSS ] };   // Daniel 6:22 - the lions
    _overrides[$ "31/0/16"] = { enemy_pool : [ "leviathan" ],hp_base : 160, special_rules : [ SPECIAL_RULE.BOSS ] };   // Jonah 1:17 - the deep
    _overrides[$ "39/3/10"] = { enemy_pool : [ "tempter" ],  hp_base : 175, special_rules : [ SPECIAL_RULE.BOSS ] };   // Matthew 4:11 - the temptation
    _overrides[$ "65/11/8"] = { enemy_pool : [ "dragon" ],   hp_base : 220, special_rules : [ SPECIAL_RULE.BOSS ] };   // Revelation 12:9 - the dragon

    global.themes = {};
    global.themes[$ "default"] = level_rules_default();
    global.themes.books = _books;
    global.themes.overrides = _overrides;
    global.level_rules_memo = {};
    global.themes_ready = true;
}

function level_rules_array_copy(_arr) {
    var _out = [];
    for (var i = 0; i < array_length(_arr); i++) array_push(_out, _arr[i]);
    return _out;
}

function level_rules_struct_clone(_src) {
    var _dst = {};
    var _names = variable_struct_get_names(_src);
    for (var i = 0; i < array_length(_names); i++) {
        var _name = _names[i];
        var _value = _src[$ _name];
        _dst[$ _name] = is_array(_value) ? level_rules_array_copy(_value) : _value;
    }
    return _dst;
}

function level_rules_array_has(_arr, _value) {
    for (var i = 0; i < array_length(_arr); i++) {
        if (_arr[i] == _value) return true;
    }
    return false;
}

function level_rules_merge_into(_dst, _src) {
    var _names = variable_struct_get_names(_src);
    for (var i = 0; i < array_length(_names); i++) {
        var _name = _names[i];
        var _value = _src[$ _name];

        if (_name == "special_rules") {
            if (!variable_struct_exists(_dst, _name)) _dst[$ _name] = [];
            for (var s = 0; s < array_length(_value); s++) {
                if (!level_rules_array_has(_dst[$ _name], _value[s])) array_push(_dst[$ _name], _value[s]);
            }
        } else {
            _dst[$ _name] = is_array(_value) ? level_rules_array_copy(_value) : _value;
        }
    }
}

function level_rules_validate(_rules) {
    _rules.hp_base = max(1, _rules.hp_base);
    _rules.hp_per_word = max(0, _rules.hp_per_word);
    _rules.hp_min = max(1, _rules.hp_min);
    _rules.hp_max = max(_rules.hp_min, _rules.hp_max);
    _rules.book_tier = max(0.1, _rules.book_tier);
    _rules.intra_book_slope = max(0, _rules.intra_book_slope);
    _rules.vowel_floor = clamp(_rules.vowel_floor, 0, 1);
    _rules.freq_floor = clamp(_rules.freq_floor, 0, 1);
    _rules.plant_min_len = max(1, floor(_rules.plant_min_len));
    _rules.plant_max_len = max(_rules.plant_min_len, floor(_rules.plant_max_len));
    _rules.plant_count = max(0, floor(_rules.plant_count));
    _rules.plant_max_tries = max(1, floor(_rules.plant_max_tries));
    _rules.divine_crit_mult = max(1, _rules.divine_crit_mult);
    _rules.trace_min_len = max(1, floor(_rules.trace_min_len));
    _rules.blanks_max = max(0, floor(_rules.blanks_max));
    _rules.faith_max = max(1, floor(_rules.faith_max));
    return _rules;
}

function get_level_rules(_book, _chapter, _verse) {
    level_rules_init();

    var _key = string(_book) + "_" + string(_chapter) + "_" + string(_verse);
    if (variable_struct_exists(global.level_rules_memo, _key)) return global.level_rules_memo[$ _key];

    var _rules = level_rules_struct_clone(global.themes[$ "default"]);
    var _book_key = string(_book);
    if (variable_struct_exists(global.themes.books, _book_key)) {
        level_rules_merge_into(_rules, global.themes.books[$ _book_key]);
    }

    var _override_key = string(_book) + "/" + string(_chapter) + "/" + string(_verse);
    if (variable_struct_exists(global.themes.overrides, _override_key)) {
        level_rules_merge_into(_rules, global.themes.overrides[$ _override_key]);
    }

    _rules.book = _book;
    _rules.chapter = _chapter;
    _rules.verse = _verse;
    _rules = level_rules_validate(_rules);
    global.level_rules_memo[$ _key] = _rules;
    return _rules;
}

function asset_or_default(_asset_name, _fallback) {
    if (is_string(_asset_name) && _asset_name != "") {
        var _idx = asset_get_index(_asset_name);
        if (_idx >= 0) return _idx;
    }
    return _fallback;
}
