/// scr_tile_struct
/// Tile data model: enums, the Tile() constructor, and tile helper predicates.
/// A tile carries BOTH a color (match-3 axis) and a letter (Bookworm word axis).

enum COLOR {
    RED,
    ORANGE,
    YELLOW,
    GREEN,
    BLUE,
    PURPLE,
    COUNT          // sentinel: number of real colors
}

enum TILE_TYPE {
    NORMAL,
    LINE_H,        // clears its whole row when activated
    LINE_V,        // clears its whole column when activated
    BOMB,          // clears a 3x3 area when activated
    RAINBOW,       // clears all tiles of one color when activated
    BLOCKER        // junk: never matches, just occupies a cell
}

enum TILE_STATUS {
    NONE,
    LOCKED,        // boss-applied: non-matchable / non-swappable until it expires
    FROZEN,        // boss-applied: non-matchable / non-swappable until it expires
    BURNING        // reserved for future damage-over-time mechanics
}

/// @desc Construct a tile data struct (the authoritative unit stored in the grid array).
/// @param {real} _color   COLOR.*
/// @param {string} _letter single uppercase character
/// @param {real} _type    TILE_TYPE.* (defaults to NORMAL)
function Tile(_color, _letter, _type = TILE_TYPE.NORMAL) constructor {
    color_id     = _color;
    letter       = _letter;
    type         = _type;
    status       = TILE_STATUS.NONE;
    status_turns = 0;
    is_divine    = false;
    view         = noone;   // the obj_grid_tile instance rendering this cell (or noone)
}

/// @desc Can this tile participate in a color match? Walls (blocker/locked/frozen) cannot.
function tile_is_matchable(_tile) {
    if (_tile == undefined) return false;
    if (_tile.type == TILE_TYPE.BLOCKER) return false;
    if (_tile.status == TILE_STATUS.LOCKED) return false;
    if (_tile.status == TILE_STATUS.FROZEN) return false;
    return true;
}

/// @desc Can the player pick this tile up for a swap? Same rule set as matchability.
function tile_is_swappable(_tile) {
    return tile_is_matchable(_tile);
}

/// @desc A random uppercase letter A-Z (uniform for now; can be weighted later).
function tile_random_letter() {
    if (variable_global_exists("level") && variable_struct_exists(global.level, "bag")) {
        return tile_pick_letter();
    }
    return chr(ord("A") + irandom(25));
}

/// @desc Map a COLOR enum to a draw colour (placeholder pixel-art gem fill).
function tile_color_to_colour(_color_id) {
    switch (_color_id) {
        case COLOR.RED:    return make_colour_rgb(220,  64,  64);
        case COLOR.ORANGE: return make_colour_rgb(230, 140,  40);
        case COLOR.YELLOW: return make_colour_rgb(235, 215,  70);
        case COLOR.GREEN:  return make_colour_rgb( 80, 190,  90);
        case COLOR.BLUE:   return make_colour_rgb( 70, 130, 220);
        case COLOR.PURPLE: return make_colour_rgb(165,  90, 205);
        default:           return c_white;
    }
}
