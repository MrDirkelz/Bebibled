/// scr_word_system
/// The Bookworm axis. Cleared tiles contribute their letters here. For the
/// foundation this accumulates a Scrabble-style score into the hero's word meter;
/// the word_is_valid() hook is ready for a dictionary-driven mechanic later.

/// @desc Scrabble-style point value for a single letter.
function word_letter_value(_ch) {
    switch (string_upper(_ch)) {
        case "A": case "E": case "I": case "O": case "U":
        case "L": case "N": case "S": case "T": case "R": return 1;
        case "D": case "G": return 2;
        case "B": case "C": case "M": case "P": return 3;
        case "F": case "H": case "V": case "W": case "Y": return 4;
        case "K": return 5;
        case "J": case "X": return 8;
        case "Q": case "Z": return 10;
        default: return 0;
    }
}

/// @desc Total word-meter value for a string of cleared letters (length-bonus included).
function word_score(_letters) {
    var _sum = 0;
    var _len = string_length(_letters);
    for (var i = 1; i <= _len; i++) {
        _sum += word_letter_value(string_char_at(_letters, i));
    }
    // small bonus for clearing more letters at once
    return _sum + max(0, _len - 2);
}

/// @desc Initialise the (stub) dictionary. Swap for an Included File load later.
function word_init_dictionary() {
    global.word_dict = {};
    var _words = ["CAT", "DOG", "SUN", "STAR", "FIRE", "ICE", "GEM", "RUNE", "MAGE", "HERO"];
    for (var i = 0; i < array_length(_words); i++) {
        global.word_dict[$ _words[i]] = true;
    }
}

/// @desc Is the given string a known word? (hook for the exact-word mechanic)
function word_is_valid(_str) {
    if (!variable_global_exists("word_dict")) return false;
    return variable_struct_exists(global.word_dict, string_upper(_str));
}
