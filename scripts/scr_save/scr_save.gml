/// scr_save
/// Compact 2-bit progress store: 0 uncleared, 1..3 stars.

#macro SAVE_BITS_PER_VERSE 2

function save_init() {
    bible_build_indices();

    if (variable_global_exists("save_ready") && global.save_ready) return;

    var _bytes = max(1, ceil(global.bible_total_verses * SAVE_BITS_PER_VERSE / 8));
    global.save = {
        buffer : buffer_create(_bytes, buffer_fixed, 1),
        bytes : _bytes,
        path : "save_progress.dat"
    };

    buffer_fill(global.save.buffer, 0, buffer_u8, 0, _bytes);
    global.save_ready = true;
}

function save_load() {
    save_init();
    var _path = global.save.path;
    if (!file_exists(_path)) return;

    var _loaded = buffer_load(_path);
    if (_loaded < 0) return;

    var _take = min(buffer_get_size(_loaded), global.save.bytes);
    for (var i = 0; i < _take; i++) {
        buffer_poke(global.save.buffer, i, buffer_u8, buffer_peek(_loaded, i, buffer_u8));
    }
    buffer_delete(_loaded);
}

function save_store() {
    save_init();
    buffer_save(global.save.buffer, global.save.path);
}

function save_get_stars_by_index(_idx) {
    save_init();
    if (_idx < 0 || _idx >= global.bible_total_verses) return 0;
    var _bit = _idx * SAVE_BITS_PER_VERSE;
    var _byte = _bit div 8;
    var _shift = _bit mod 8;
    return (buffer_peek(global.save.buffer, _byte, buffer_u8) >> _shift) & 3;
}

function save_set_stars_by_index(_idx, _stars) {
    save_init();
    if (_idx < 0 || _idx >= global.bible_total_verses) return;

    var _value = clamp(floor(_stars), 0, 3);
    var _bit = _idx * SAVE_BITS_PER_VERSE;
    var _byte = _bit div 8;
    var _shift = _bit mod 8;
    var _old = buffer_peek(global.save.buffer, _byte, buffer_u8);
    var _mask = 3 << _shift;
    var _next = (_old & (255 - _mask)) | (_value << _shift);
    buffer_poke(global.save.buffer, _byte, buffer_u8, _next);
}

function save_get_stars(_book, _chapter, _verse) {
    return save_get_stars_by_index(bible_linear_index(_book, _chapter, _verse));
}

function save_mark_clear(_book, _chapter, _verse, _stars) {
    var _idx = bible_linear_index(_book, _chapter, _verse);
    save_set_stars_by_index(_idx, max(save_get_stars_by_index(_idx), _stars));
}

function save_is_unlocked(_book, _chapter, _verse) {
    if (_book < 0 || _book >= 66) return false;
    var _local = bible_book_local_index(_book, _chapter, _verse);
    if (_local <= 0) return true;
    var _idx = bible_linear_index(_book, _chapter, _verse) - 1;
    return save_get_stars_by_index(_idx) > 0;
}

/// @desc Aggregate progress for a whole book: { stars, cleared, total }.
/// Cleared verses form a contiguous prefix (linear unlock), so `cleared`
/// doubles as the local index of the first unplayed verse.
function save_book_progress(_book) {
    bible_build_indices();
    if (_book < 0 || _book >= array_length(global.bible_book_offsets)) {
        return { stars : 0, cleared : 0, total : 0 };
    }
    var _start = global.bible_book_offsets[_book];
    var _total = global.bible_book_verse_totals[_book];
    var _stars = 0;
    var _cleared = 0;
    for (var i = 0; i < _total; i++) {
        var _s = save_get_stars_by_index(_start + i);
        if (_s > 0) { _cleared++; _stars += _s; }
    }
    return { stars : _stars, cleared : _cleared, total : _total };
}
