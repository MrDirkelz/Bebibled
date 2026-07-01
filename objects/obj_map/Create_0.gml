/// obj_map :: Create
/// Winding path level-select. Two tiers sharing one renderer:
///   WORLD - 66 book nodes, Genesis (bottom) -> Revelation (top)
///   BOOK  - the selected book's verses in order (chapter labels as dividers)
/// Everything is drawn in GUI space with a manual vertical scroll.

game_boot_once();

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

mode          = MAP_MODE.WORLD;
sel_book      = 0;
scroll        = 0;
scroll_target = 0;

drag_active       = false;
drag_start_my     = 0;
drag_start_scroll = 0;
press_mx          = 0;
press_my          = 0;
moved             = false;
locked_flash      = 0;          // node index that flashed as locked (visual only)

book_names = text_book_names();

// per-book progress cache (recomputed on each map open)
book_progress = array_create(66, undefined);
for (var _b = 0; _b < 66; _b++) book_progress[_b] = save_book_progress(_b);

/// number of nodes in the current tier
node_total = function() {
    if (mode == MAP_MODE.WORLD) return 66;
    return max(1, map_book_verse_total(sel_book));
};

/// centre the view on a given node index
focus_on = function(_i, _total) {
    var _view = (gui_h - MAP_BOTTOM_MARGIN - MAP_TOP_MARGIN);
    scroll_target = clamp(_i * MAP_NODE_SPACING - _view * 0.5, 0, map_scroll_max(_total, gui_h));
    scroll = scroll_target;
};

/// react to a tap on node _i in the current tier
on_node_tap = function(_i) {
    if (mode == MAP_MODE.WORLD) {
        sel_book = _i;
        mode = MAP_MODE.BOOK;
        var _bt = map_book_verse_total(sel_book);
        var _focus = clamp(book_progress[sel_book].cleared, 0, max(0, _bt - 1));
        focus_on(_focus, _bt);
    } else {
        var _ref = book_local_to_ref(sel_book, _i);
        if (!save_is_unlocked(sel_book, _ref.chapter, _ref.verse)) { locked_flash = _i; return; }
        global.pending_level = { book : sel_book, chapter : _ref.chapter, verse : _ref.verse };
        global.map_return    = { mode : MAP_MODE.BOOK, book : sel_book, scroll : scroll_target };
        room_goto(Room1);
    }
};

/// resolve a tap in GUI space (back button, then nodes)
handle_tap = function(_mx, _my) {
    if (mode == MAP_MODE.BOOK) {
        if (point_in_rect(_mx, _my, 20, 20, 140, 76)) {
            mode = MAP_MODE.WORLD;
            focus_on(sel_book, 66);
            return;
        }
    }
    var _total = node_total();
    var _range = map_visible_range(_total, scroll, gui_h);
    for (var i = _range.lo; i <= _range.hi; i++) {
        var _p = map_node_screen_pos(i, scroll, gui_w, gui_h);
        if (point_in_ellipse(_mx, _my, _p.x, _p.y, MAP_NODE_RX, MAP_NODE_RY)) {
            on_node_tap(i);
            return;
        }
    }
};

// restore where we were if returning from a battle
if (variable_global_exists("map_return") && global.map_return != undefined) {
    mode          = global.map_return.mode;
    sel_book      = global.map_return.book;
    scroll        = global.map_return.scroll;
    scroll_target = scroll;
}
