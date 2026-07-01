/// scr_bible_data
/// One wrapper for KJV JSON access. Other systems ask this script for verses and
/// offsets instead of touching files directly.

function bible_book_files() {
    return [
        "genesis.json", "exodus.json", "leviticus.json", "numbers.json", "deuteronomy.json",
        "joshua.json", "judges.json", "ruth.json", "samuel1.json", "samuel2.json",
        "kings1.json", "kings2.json", "chronicles1.json", "chronicles2.json", "ezra.json",
        "nehemiah.json", "esther.json", "job.json", "psalms.json", "proverbs.json",
        "ecclesiastes.json", "songofsolomon.json", "isaiah.json", "jeremiah.json", "lamentations.json",
        "ezekiel.json", "daniel.json", "hosea.json", "joel.json", "amos.json",
        "obadiah.json", "jonah.json", "micah.json", "nahum.json", "habakkuk.json",
        "zephaniah.json", "haggai.json", "zechariah.json", "malachi.json", "matthew.json",
        "mark.json", "luke.json", "john.json", "acts.json", "romans.json",
        "corinthians1.json", "corinthians2.json", "galatians.json", "ephesians.json", "philippians.json",
        "colossians.json", "thessalonians1.json", "thessalonians2.json", "timothy1.json", "timothy2.json",
        "titus.json", "philemon.json", "hebrews.json", "james.json", "peter1.json",
        "peter2.json", "john1.json", "john2.json", "john3.json", "jude.json",
        "revelation.json"
    ];
}

function bible_data_init() {
    if (variable_global_exists("bible_data_ready") && global.bible_data_ready) return;

    global.bible_files = bible_book_files();
    global.bible_books = array_create(array_length(global.bible_files), undefined);
    global.bible_book_offsets = array_create(array_length(global.bible_files), 0);
    global.bible_chapter_offsets = array_create(array_length(global.bible_files), undefined);
    global.bible_book_verse_totals = array_create(array_length(global.bible_files), 0);
    global.bible_total_verses = 0;
    global.bible_indices_ready = false;
    global.bible_data_ready = true;
}

function bible_file_path(_book) {
    bible_data_init();
    return "datafiles/openbible-main/KJV/books/" + global.bible_files[_book];
}

function bible_resolve_path(_relative_path) {
    // _relative_path is "datafiles/openbible-main/KJV/books/genesis.json".
    // At runtime GameMaker copies the contents of the project's datafiles/ folder
    // into the included-files root and DROPS the "datafiles/" prefix (subfolders
    // are kept), so the exported file lives at "openbible-main/KJV/books/genesis.json".
    var _no_datafiles = string_replace(_relative_path, "datafiles/", "");
    var _bare = string_replace(_relative_path, "datafiles/openbible-main/KJV/books/", "");

    var _candidates = [
        _no_datafiles,                       // exported build (most common)
        working_directory + _no_datafiles,
        _relative_path,                      // running from the project folder
        working_directory + _relative_path,
        program_directory + _no_datafiles,
        program_directory + _relative_path,
        working_directory + _bare,           // flattened fallback
        _bare
    ];

    for (var i = 0; i < array_length(_candidates); i++) {
        if (file_exists(_candidates[i])) return _candidates[i];
    }
    return _no_datafiles;
}

function bible_read_text_file(_path) {
    var _resolved = bible_resolve_path(_path);
    if (!file_exists(_resolved)) {
        show_debug_message("Missing KJV data file: " + _path);
        return "";
    }

    // buffer_load reads the whole file in one shot. file_text_readln can silently
    // truncate very long JSON lines (a chapter of verses), which then makes
    // json_parse fail and every verse come back empty.
    var _buffer = buffer_load(_resolved);
    if (_buffer < 0) {
        show_debug_message("Failed to load KJV data file: " + _resolved);
        return "";
    }
    buffer_seek(_buffer, buffer_seek_start, 0);
    var _text = buffer_read(_buffer, buffer_text);
    buffer_delete(_buffer);
    return _text;
}

function bible_ensure_book_loaded(_book) {
    bible_data_init();
    if (_book < 0 || _book >= array_length(global.bible_files)) return undefined;
    if (global.bible_books[_book] != undefined) return global.bible_books[_book];

    var _raw = bible_read_text_file(bible_file_path(_book));
    if (_raw == "") {
        global.bible_books[_book] = [];
        return global.bible_books[_book];
    }

    global.bible_books[_book] = json_parse(_raw);
    return global.bible_books[_book];
}

function bible_get_verse(_book, _chapter, _verse) {
    var _book_data = bible_ensure_book_loaded(_book);
    if (!is_array(_book_data)) return "";
    if (_chapter < 0 || _chapter >= array_length(_book_data)) return "";
    var _chapter_data = _book_data[_chapter];
    if (!is_array(_chapter_data)) return "";
    if (_verse < 0 || _verse >= array_length(_chapter_data)) return "";
    return string(_chapter_data[_verse]);
}

function bible_chapter_count(_book) {
    var _book_data = bible_ensure_book_loaded(_book);
    return is_array(_book_data) ? array_length(_book_data) : 0;
}

function bible_verse_count(_book, _chapter) {
    var _book_data = bible_ensure_book_loaded(_book);
    if (!is_array(_book_data)) return 0;
    if (_chapter < 0 || _chapter >= array_length(_book_data)) return 0;
    return array_length(_book_data[_chapter]);
}

function bible_build_indices() {
    bible_data_init();
    if (global.bible_indices_ready) return;

    var _total = 0;
    for (var _book = 0; _book < array_length(global.bible_files); _book++) {
        global.bible_book_offsets[_book] = _total;
        var _book_total = 0;
        var _chapter_offsets = [];
        var _book_data = bible_ensure_book_loaded(_book);

        if (is_array(_book_data)) {
            for (var _chapter = 0; _chapter < array_length(_book_data); _chapter++) {
                _chapter_offsets[_chapter] = _book_total;
                var _verse_total = array_length(_book_data[_chapter]);
                _book_total += _verse_total;
                _total += _verse_total;
            }
        }

        global.bible_chapter_offsets[_book] = _chapter_offsets;
        global.bible_book_verse_totals[_book] = _book_total;
    }

    global.bible_total_verses = _total;
    global.bible_indices_ready = true;
}

function bible_linear_index(_book, _chapter, _verse) {
    bible_build_indices();
    if (_book < 0 || _book >= array_length(global.bible_book_offsets)) return 0;
    var _chapter_offsets = global.bible_chapter_offsets[_book];
    if (!is_array(_chapter_offsets) || _chapter < 0 || _chapter >= array_length(_chapter_offsets)) return global.bible_book_offsets[_book];
    return global.bible_book_offsets[_book] + _chapter_offsets[_chapter] + _verse;
}

function bible_book_local_index(_book, _chapter, _verse) {
    bible_build_indices();
    var _chapter_offsets = global.bible_chapter_offsets[_book];
    if (!is_array(_chapter_offsets) || _chapter < 0 || _chapter >= array_length(_chapter_offsets)) return 0;
    return _chapter_offsets[_chapter] + _verse;
}
