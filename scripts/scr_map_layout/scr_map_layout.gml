/// scr_map_layout
/// Geometry + helpers for the winding path level-select map (obj_map) and the
/// battle-end navigation buttons. Pure math: no drawing, no instances.

enum MAP_MODE { WORLD, BOOK }

#macro MAP_NODE_SPACING 158
#macro MAP_NODE_RX      52
#macro MAP_NODE_RY      40
#macro MAP_PATH_AMP     150
#macro MAP_PATH_FREQ    0.7
#macro MAP_BOTTOM_MARGIN 150
#macro MAP_TOP_MARGIN    120

/// @desc Screen position of node _i (0 = bottom) for the current scroll.
function map_node_screen_pos(_i, _scroll, _gui_w, _gui_h) {
    var _cy = _i * MAP_NODE_SPACING;
    var _y  = (_gui_h - MAP_BOTTOM_MARGIN) - _cy + _scroll;
    var _x  = _gui_w * 0.5 + sin(_i * MAP_PATH_FREQ) * MAP_PATH_AMP;
    return { x : _x, y : _y };
}

/// @desc Max scroll so the top node lands just under the header.
function map_scroll_max(_total, _gui_h) {
    var _content = max(0, _total - 1) * MAP_NODE_SPACING;
    var _view    = (_gui_h - MAP_BOTTOM_MARGIN - MAP_TOP_MARGIN);
    return max(0, _content - _view);
}

/// @desc Inclusive node index range currently on screen (plus a margin).
function map_visible_range(_total, _scroll, _gui_h) {
    var _cy_top = (_gui_h - MAP_BOTTOM_MARGIN) - (_gui_h + MAP_NODE_SPACING) + _scroll;
    var _cy_bot = (_gui_h - MAP_BOTTOM_MARGIN) + MAP_NODE_SPACING + _scroll;
    var _lo = max(0, floor(_cy_top / MAP_NODE_SPACING));
    var _hi = min(_total - 1, ceil(_cy_bot / MAP_NODE_SPACING));
    return { lo : _lo, hi : _hi };
}

/// @desc Total verses in a book (uses the prebuilt index tables).
function map_book_verse_total(_book) {
    bible_build_indices();
    if (_book < 0 || _book >= array_length(global.bible_book_verse_totals)) return 0;
    return global.bible_book_verse_totals[_book];
}

/// @desc Convert a book-local verse index into {chapter, verse}.
function book_local_to_ref(_book, _local) {
    bible_build_indices();
    var _offsets = global.bible_chapter_offsets[_book];
    if (!is_array(_offsets) || array_length(_offsets) == 0) return { chapter : 0, verse : _local };
    var _c = 0;
    for (var i = 0; i < array_length(_offsets); i++) {
        if (_offsets[i] <= _local) _c = i; else break;
    }
    return { chapter : _c, verse : _local - _offsets[_c] };
}

/// @desc Next verse within the SAME book (advances chapters). valid=false at book end.
function map_next_ref(_book, _chapter, _verse) {
    var _vc = bible_verse_count(_book, _chapter);
    if (_verse + 1 < _vc) return { book : _book, chapter : _chapter, verse : _verse + 1, valid : true };
    var _cc = bible_chapter_count(_book);
    if (_chapter + 1 < _cc) return { book : _book, chapter : _chapter + 1, verse : 0, valid : true };
    return { book : _book, chapter : _chapter, verse : _verse, valid : false };
}

/// @desc Point-in-rectangle test.
function point_in_rect(_px, _py, _x1, _y1, _x2, _y2) {
    return (_px >= _x1 && _px <= _x2 && _py >= _y1 && _py <= _y2);
}

/// @desc Point-in-ellipse test (centre _cx,_cy, radii _rx,_ry).
function point_in_ellipse(_px, _py, _cx, _cy, _rx, _ry) {
    if (_rx <= 0 || _ry <= 0) return false;
    var _dx = (_px - _cx) / _rx;
    var _dy = (_py - _cy) / _ry;
    return (_dx * _dx + _dy * _dy) <= 1;
}

/// @desc Short label for a book node.
function book_short_name(_book) {
    var _names = text_book_names();
    if (_book < 0 || _book >= array_length(_names)) return "?";
    return string_copy(_names[_book], 1, 4);
}

/// @desc Battle victory/defeat navigation buttons as GUI-space rects.
function battle_end_buttons(_state, _gui_w, _gui_h) {
    var _bw  = 220;
    var _bh  = 60;
    var _gap = 24;
    var _cx  = _gui_w * 0.5;
    var _y   = _gui_h * 0.5 + 90;
    var _out = [];

    if (_state == BATTLE_STATE.VICTORY) {
        array_push(_out, { id : "next", label : "Next Verse", x1 : _cx - _bw - _gap * 0.5, y1 : _y, x2 : _cx - _gap * 0.5, y2 : _y + _bh });
        array_push(_out, { id : "map",  label : "Map",        x1 : _cx + _gap * 0.5,       y1 : _y, x2 : _cx + _bw + _gap * 0.5, y2 : _y + _bh });
    } else if (_state == BATTLE_STATE.DEFEAT) {
        array_push(_out, { id : "retry", label : "Retry (R)", x1 : _cx - _bw - _gap * 0.5, y1 : _y, x2 : _cx - _gap * 0.5, y2 : _y + _bh });
        array_push(_out, { id : "map",   label : "Map",       x1 : _cx + _gap * 0.5,       y1 : _y, x2 : _cx + _bw + _gap * 0.5, y2 : _y + _bh });
    }
    return _out;
}
