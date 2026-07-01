/// obj_map :: Draw GUI
/// Placeholder-art path map. The Background layer is where finished art goes;
/// this draws a flat fill + the programmatic path and oval nodes on top.

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

// backdrop fill (art layer sits behind this; tint differs per tier for now)
draw_set_color(mode == MAP_MODE.WORLD ? make_color_rgb(24, 28, 48) : make_color_rgb(20, 34, 30));
draw_rectangle(0, 0, gui_w, gui_h, false);

var _total = node_total();
var _range = map_visible_range(_total, scroll, gui_h);

// path line through visible nodes
draw_set_color(make_color_rgb(74, 78, 104));
for (var i = _range.lo; i < _range.hi; i++) {
    var _a = map_node_screen_pos(i,     scroll, gui_w, gui_h);
    var _b = map_node_screen_pos(i + 1, scroll, gui_w, gui_h);
    draw_line_width(_a.x, _a.y, _b.x, _b.y, 10);
}

// nodes
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

for (var i = _range.lo; i <= _range.hi; i++) {
    var _p = map_node_screen_pos(i, scroll, gui_w, gui_h);
    var _l = _p.x - MAP_NODE_RX, _t = _p.y - MAP_NODE_RY;
    var _r = _p.x + MAP_NODE_RX, _bm = _p.y + MAP_NODE_RY;

    if (mode == MAP_MODE.WORLD) {
        var _prog = book_progress[i];
        var _done = (_prog.total > 0 && _prog.cleared >= _prog.total);
        var _started = (_prog.cleared > 0);
        draw_set_color(_done ? make_color_rgb(212, 176, 68)
                     : (_started ? make_color_rgb(96, 122, 184) : make_color_rgb(72, 84, 120)));
        draw_ellipse(_l, _t, _r, _bm, false);
        draw_set_color(c_white);
        draw_ellipse(_l, _t, _r, _bm, true);
        draw_text(_p.x, _p.y - 10, book_short_name(i));
        draw_text(_p.x, _p.y + 12, string(_prog.cleared) + "/" + string(_prog.total));
    } else {
        var _ref = book_local_to_ref(sel_book, i);
        var _unlocked = save_is_unlocked(sel_book, _ref.chapter, _ref.verse);
        var _stars = save_get_stars(sel_book, _ref.chapter, _ref.verse);

        var _col = !_unlocked ? make_color_rgb(58, 58, 72)
                 : (_stars > 0 ? make_color_rgb(92, 162, 112) : make_color_rgb(120, 140, 176));
        if (i == locked_flash) _col = make_color_rgb(150, 70, 70);
        draw_set_color(_col);
        draw_ellipse(_l, _t, _r, _bm, false);
        draw_set_color(c_white);
        draw_ellipse(_l, _t, _r, _bm, true);

        if (!_unlocked) {
            draw_text(_p.x, _p.y, "LOCK");
        } else {
            draw_text(_p.x, _p.y - 8, string(_ref.chapter + 1) + ":" + string(_ref.verse + 1));
            draw_text(_p.x, _p.y + 12, string_repeat("*", _stars));
        }

        if (_ref.verse == 0) {
            draw_set_color(c_yellow);
            draw_set_halign(fa_left);
            draw_text(_r + 18, _p.y, "Chapter " + string(_ref.chapter + 1));
            draw_set_halign(fa_center);
            draw_set_color(c_white);
        }
    }
}

// header / back button
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);

if (mode == MAP_MODE.WORLD) {
    draw_text(24, 26, "The Word  -  Genesis to Revelation");
} else {
    draw_set_color(make_color_rgb(60, 64, 88));
    draw_rectangle(20, 20, 140, 76, false);
    draw_set_color(c_white);
    draw_rectangle(20, 20, 140, 76, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(80, 48, "Back");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    var _bp = book_progress[sel_book];
    draw_text(160, 30, book_names[sel_book]);
    draw_text(160, 52, string(_bp.cleared) + " / " + string(_bp.total) + " cleared   " + string(_bp.stars) + " stars");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
