/// obj_battle_controller :: Create
/// The director. Owns the battle FSM and sequences player turn -> boss turn.
/// It never touches the grid array directly — it calls obj_grid_manager methods.

state = BATTLE_STATE.BOARD_INIT;
game_boot_once();

// references (resolved lazily in Step, so room creation order doesn't matter)
grid_mgr = noone;
boss     = noone;
hero     = noone;

// turn / resolution bookkeeping
from_player_swap = false;   // true only for the first resolve after a player swap
is_boss_phase    = false;   // are we resolving the board during the boss's turn?
cascade_count    = 0;       // combo depth within the current resolution chain
turn             = 0;
boss_acted       = false;   // ensures the boss ability fires once per BOSS_ATTACK
level_ready      = false;
victory_saved    = false;

// pending swap (for SWAP_BACK + special homing)
swap_a    = undefined;      // {col,row}
swap_b    = undefined;      // {col,row}
last_swap = undefined;      // [swap_a, swap_b]

// current verse selection; the map hands one over via global.pending_level
current_book    = 0;
current_chapter = 0;
current_verse   = 0;
has_pending     = false;
if (variable_global_exists("pending_level") && global.pending_level != undefined) {
    current_book    = global.pending_level.book;
    current_chapter = global.pending_level.chapter;
    current_verse   = global.pending_level.verse;
    has_pending     = true;
}

pending_word_path = [];
pending_miracle_clear = [];
last_trace_word = "";
last_trace_feedback = "";
divine_words_spelled = 0;

/// @desc Prepare/restart the current verse battle.
prepare_level = function() {
    if (grid_mgr == noone || boss == noone || hero == noone) return false;

    level_load(current_book, current_chapter, current_verse);
    hero.apply_level();
    boss.apply_level();
    grid_mgr.build_board();

    from_player_swap = false;
    is_boss_phase = false;
    cascade_count = 0;
    turn = 0;
    boss_acted = false;
    swap_a = undefined;
    swap_b = undefined;
    last_swap = undefined;
    pending_word_path = [];
    pending_miracle_clear = [];
    last_trace_word = "";
    last_trace_feedback = "";
    divine_words_spelled = 0;
    victory_saved = false;
    level_ready = true;
    return true;
};

/// @desc Called by UI/input to reload the same deterministic verse.
request_retry = function() {
    level_ready = false;
    state = BATTLE_STATE.BOARD_INIT;
};

/// @desc Return to the level-select map (remembering where we came from).
return_to_map = function() {
    var _scroll = (variable_global_exists("map_return") && global.map_return != undefined) ? global.map_return.scroll : 0;
    global.map_return = { mode : MAP_MODE.BOOK, book : current_book, scroll : _scroll };
    room_goto(rm_map);
};

/// @desc After a win: advance to the next verse in this book, else go to the map.
next_verse = function() {
    var _n = map_next_ref(current_book, current_chapter, current_verse);
    if (!_n.valid || !save_is_unlocked(_n.book, _n.chapter, _n.verse)) {
        return_to_map();
        return;
    }
    current_book    = _n.book;
    current_chapter = _n.chapter;
    current_verse   = _n.verse;
    global.pending_level = { book : current_book, chapter : current_chapter, verse : current_verse };
    level_ready = false;
    state = BATTLE_STATE.BOARD_INIT;
};

/// @desc Called by the input handler during PLAYER_INPUT to attempt a swap.
request_swap = function(_c1, _r1, _c2, _r2) {
    if (state != BATTLE_STATE.PLAYER_INPUT) return;
    if (grid_mgr == noone) return;
    if (!grid_in_bounds(_c1, _r1) || !grid_in_bounds(_c2, _r2)) return;
    if (abs(_c1 - _c2) + abs(_r1 - _r2) != 1) return;            // orthogonally adjacent only

    var _a = grid_mgr.grid[_c1][_r1];
    var _b = grid_mgr.grid[_c2][_r2];
    if (!tile_is_swappable(_a) || !tile_is_swappable(_b)) return;

    swap_a = { col: _c1, row: _r1 };
    swap_b = { col: _c2, row: _r2 };
    last_swap = [ swap_a, swap_b ];
    grid_mgr.swap_cells(_c1, _r1, _c2, _r2);
    state = BATTLE_STATE.ANIMATING_SWAP;
};

/// @desc Called by input during PLAYER_INPUT to attempt a word trace.
request_word_trace = function(_path) {
    if (state != BATTLE_STATE.PLAYER_INPUT) return;
    if (grid_mgr == noone) return;
    pending_word_path = _path;
    last_trace_feedback = "";
    state = BATTLE_STATE.RESOLVING_WORD;
};

/// @desc Called by input/UI during PLAYER_INPUT to cast a miracle.
request_miracle = function(_idx) {
    if (state != BATTLE_STATE.PLAYER_INPUT) return;
    if (grid_mgr == noone || hero == noone) return;
    if (!variable_global_exists("miracles")) return;
    if (_idx < 0 || _idx >= array_length(global.miracles)) return;

    var _miracle = global.miracles[_idx];
    if (!hero.spend_faith(_miracle.cost)) {
        last_trace_feedback = "Need more Faith";
        return;
    }

    var _result = _miracle.effect(grid_mgr, hero, global.level);
    if (_miracle.kind == "clear") {
        pending_miracle_clear = _result;
        state = BATTLE_STATE.RESOLVING_MIRACLE;
    }
};
