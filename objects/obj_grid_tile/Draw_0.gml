/// obj_grid_tile :: Draw
/// Placeholder pixel-art rendering: a colored gem, its letter, a special marker,
/// and any boss-applied status overlay. All visuals are read from the `tile` struct.

if (tile == undefined) exit;

var _gm = global.grid_manager;
var _half = (_gm.cell_size * 0.5 - 5) * gem_scale;
if (_half <= 0) exit;

var _l = draw_x - _half, _t = draw_y - _half;
var _r = draw_x + _half, _b = draw_y + _half;

// ---- blocker (junk) tiles look distinct and carry no letter ----
if (tile.type == TILE_TYPE.BLOCKER) {
    draw_rectangle_color(_l, _t, _r, _b, c_dkgray, c_dkgray, c_gray, c_gray, false);
    draw_set_color(c_black);
    draw_rectangle(_l, _t, _r, _b, true);
    draw_set_color(c_white);
    exit;
}

// ---- gem body ----
var _gem = tile_color_to_colour(tile.color_id);
draw_rectangle_color(_l, _t, _r, _b, _gem, _gem, _gem, _gem, false);

// ---- special outline + corner marker ----
if (tile.type != TILE_TYPE.NORMAL) {
    var _mark = "";
    switch (tile.type) {
        case TILE_TYPE.LINE_H:  _mark = "="; break;
        case TILE_TYPE.LINE_V:  _mark = "||"; break;
        case TILE_TYPE.BOMB:    _mark = "*"; break;
        case TILE_TYPE.RAINBOW: _mark = "@"; break;
    }
    draw_set_color(c_white);
    draw_rectangle(_l, _t, _r, _b, true);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_l + 3, _t + 2, _mark);
}

// ---- divine verse-word marker ----
if (tile.is_divine) {
    draw_set_alpha(0.45);
    draw_set_color(c_yellow);
    draw_rectangle(_l - 4, _t - 4, _r + 4, _b + 4, true);
    draw_rectangle(_l - 7, _t - 7, _r + 7, _b + 7, true);
    draw_set_alpha(1);
}

// ---- letter glyph ----
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_black);
draw_text_transformed(draw_x, draw_y, string(tile.letter), 2, 2, 0);

// ---- status overlays ----
if (tile.status == TILE_STATUS.LOCKED) {
    draw_set_alpha(0.45);
    draw_set_color(c_black);
    draw_rectangle(_l, _t, _r, _b, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_line(_l, _t, _r, _b);
    draw_line(_l, _b, _r, _t);
} else if (tile.status == TILE_STATUS.FROZEN) {
    draw_set_alpha(0.4);
    draw_rectangle_color(_l, _t, _r, _b, c_aqua, c_aqua, c_white, c_white, false);
    draw_set_alpha(1);
}

// reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
