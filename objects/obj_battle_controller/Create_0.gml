/// obj_battle_controller :: Create
/// The director. Owns the battle FSM and sequences player turn -> boss turn.
/// It never touches the grid array directly — it calls obj_grid_manager methods.

state = BATTLE_STATE.BOARD_INIT;

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

// pending swap (for SWAP_BACK + special homing)
swap_a    = undefined;      // {col,row}
swap_b    = undefined;      // {col,row}
last_swap = undefined;      // [swap_a, swap_b]

word_init_dictionary();

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
