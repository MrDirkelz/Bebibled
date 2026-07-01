/// scr_text_helpers
/// Shared display and token helpers for KJV verse text.

function text_book_names() {
    return [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
        "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
        "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
        "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
        "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
        "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew",
        "Mark", "Luke", "John", "Acts", "Romans",
        "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians",
        "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy",
        "Titus", "Philemon", "Hebrews", "James", "1 Peter",
        "2 Peter", "1 John", "2 John", "3 John", "Jude",
        "Revelation"
    ];
}

function display_ref(_book, _chapter, _verse) {
    var _names = text_book_names();
    var _name = (_book >= 0 && _book < array_length(_names)) ? _names[_book] : "Book " + string(_book + 1);
    return _name + " " + string(_chapter + 1) + ":" + string(_verse + 1);
}

function text_is_alpha_char(_ch) {
    var _code = ord(string_upper(_ch));
    return (_code >= ord("A") && _code <= ord("Z"));
}

function text_is_vowel(_ch) {
    var _u = string_upper(_ch);
    return (_u == "A" || _u == "E" || _u == "I" || _u == "O" || _u == "U");
}

function text_is_stopword(_word) {
    switch (string_upper(_word)) {
        case "THE": case "AND": case "THAT": case "FOR": case "WITH":
        case "HIS": case "HER": case "HIM": case "YOU": case "YOUR":
        case "THOU": case "THEE": case "THY": case "THEY": case "THEM":
        case "ARE": case "WAS": case "WERE": case "HAVE": case "HATH":
        case "HAS": case "NOT": case "BUT": case "FROM": case "UNTO":
        case "INTO": case "THIS": case "SHALL": case "WILL": case "ALL":
        case "ANY": case "WHO": case "WHOM": case "WHAT": case "WHEN":
        case "WHERE": case "THERE": case "THEIR": case "OUR": case "OUT":
        case "ONE": case "TWO": case "UPON": case "ALSO": case "THEN":
            return true;
    }
    return false;
}

function text_alpha_words(_text, _min_len = 1, _skip_stopwords = false) {
    var _words = [];
    var _seen = {};
    var _word = "";
    var _len = string_length(_text);

    for (var i = 1; i <= _len; i++) {
        var _ch = string_char_at(_text, i);
        if (text_is_alpha_char(_ch)) {
            _word += string_upper(_ch);
        } else if (_word != "") {
            if (string_length(_word) >= _min_len && (!_skip_stopwords || !text_is_stopword(_word))) {
                if (!variable_struct_exists(_seen, _word)) {
                    _seen[$ _word] = true;
                    array_push(_words, _word);
                }
            }
            _word = "";
        }
    }

    if (_word != "" && string_length(_word) >= _min_len && (!_skip_stopwords || !text_is_stopword(_word))) {
        if (!variable_struct_exists(_seen, _word)) array_push(_words, _word);
    }

    return _words;
}

function text_word_count(_text) {
    var _count = 0;
    var _in_word = false;
    var _len = string_length(_text);

    for (var i = 1; i <= _len; i++) {
        var _is_alpha = text_is_alpha_char(string_char_at(_text, i));
        if (_is_alpha && !_in_word) _count++;
        _in_word = _is_alpha;
    }

    return _count;
}

function text_blank_word(_word) {
    var _out = "";
    for (var i = 1; i <= string_length(_word); i++) _out += "_";
    return _out;
}
