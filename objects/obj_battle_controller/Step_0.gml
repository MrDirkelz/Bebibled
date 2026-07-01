/// obj_battle_controller :: Step
/// The state machine. Animated states wait on the manager's animation barrier
/// (grid_mgr.anim_active == 0) before advancing.

// resolve references once they exist
if (grid_mgr == noone) grid_mgr = instance_find(obj_grid_manager, 0);
if (boss     == noone) boss     = instance_find(obj_boss_base, 0);
if (hero     == noone) hero     = instance_find(obj_battle_hero, 0);
if (grid_mgr == noone) exit;

var _busy = (grid_mgr.anim_active > 0);

switch (state) {

    case BATTLE_STATE.BOARD_INIT:
        if (!_busy) state = BATTLE_STATE.PLAYER_INPUT;
        break;

    case BATTLE_STATE.PLAYER_INPUT:
        // idle — request_swap() drives the transition out
        break;

    case BATTLE_STATE.ANIMATING_SWAP:
        if (!_busy) {
            from_player_swap = true;
            state = BATTLE_STATE.RESOLVING_MATCHES;
        }
        break;

    case BATTLE_STATE.RESOLVING_MATCHES:
        var _groups = grid_find_matches(grid_mgr.grid, grid_mgr.cols, grid_mgr.rows);
        if (array_length(_groups) > 0) {
            cascade_count++;
            var _res = match_resolve(grid_mgr.grid, _groups, last_swap, cascade_count, grid_mgr.cols, grid_mgr.rows);
            if (boss != noone) boss.hp = max(0, boss.hp - _res.damage);
            if (hero != noone) hero.word_charge += word_score(_res.letters);
            grid_mgr.clear_cells(_res.clear_cells);
            grid_mgr.spawn_specials(_res.specials);
            from_player_swap = false;
            last_swap = undefined;                 // specials home on the swap only, not cascades
            state = BATTLE_STATE.CLEARING_MATCHES;
        } else if (from_player_swap) {
            state = BATTLE_STATE.SWAP_BACK;         // no match -> illegal move
        } else if (is_boss_phase) {
            // boss-induced changes have settled
            if (grid_mgr.has_empty()) {
                grid_mgr.collapse_and_refill();
                state = BATTLE_STATE.CASCADING;
            } else if (hero != noone && hero.hp <= 0) {
                state = BATTLE_STATE.DEFEAT;
            } else {
                state = BATTLE_STATE.START_PLAYER_TURN;
            }
        } else {
            state = BATTLE_STATE.CHECK_DEADLOCK;
        }
        break;

    case BATTLE_STATE.SWAP_BACK:
        if (swap_a != undefined) {
            grid_mgr.swap_cells(swap_a.col, swap_a.row, swap_b.col, swap_b.row);
            swap_a = undefined;
            from_player_swap = false;
        }
        if (!_busy) state = BATTLE_STATE.PLAYER_INPUT;
        break;

    case BATTLE_STATE.CLEARING_MATCHES:
        if (!_busy) {
            grid_mgr.collapse_and_refill();
            state = BATTLE_STATE.CASCADING;
        }
        break;

    case BATTLE_STATE.CASCADING:
        if (!_busy) state = BATTLE_STATE.RESOLVING_MATCHES;
        break;

    case BATTLE_STATE.CHECK_DEADLOCK:
        cascade_count = 0;
        if (!grid_has_valid_move(grid_mgr.grid, grid_mgr.cols, grid_mgr.rows)) {
            grid_mgr.shuffle_board();
            state = BATTLE_STATE.BOARD_SHUFFLE;
        } else {
            state = BATTLE_STATE.END_PLAYER_TURN;
        }
        break;

    case BATTLE_STATE.BOARD_SHUFFLE:
        if (!_busy) state = BATTLE_STATE.RESOLVING_MATCHES;
        break;

    case BATTLE_STATE.END_PLAYER_TURN:
        turn++;
        if (boss != noone && boss.hp <= 0) { state = BATTLE_STATE.VICTORY; break; }
        if (boss != noone) boss.choose_intent();
        is_boss_phase = true;
        boss_acted = false;
        state = BATTLE_STATE.BOSS_ATTACK;
        break;

    case BATTLE_STATE.BOSS_ATTACK:
        if (!boss_acted) {
            if (boss != noone) boss.execute_intent(grid_mgr, hero);
            boss_acted = true;
        }
        if (!_busy) state = BATTLE_STATE.BOSS_RESOLVE;
        break;

    case BATTLE_STATE.BOSS_RESOLVE:
        if (!_busy) {
            if (grid_mgr.has_empty()) {
                grid_mgr.collapse_and_refill();
                state = BATTLE_STATE.CASCADING;     // reuse the cascade loop (is_boss_phase stays true)
            } else {
                var _g = grid_find_matches(grid_mgr.grid, grid_mgr.cols, grid_mgr.rows);
                if (array_length(_g) > 0) {
                    state = BATTLE_STATE.RESOLVING_MATCHES;
                } else if (hero != noone && hero.hp <= 0) {
                    state = BATTLE_STATE.DEFEAT;
                } else {
                    state = BATTLE_STATE.START_PLAYER_TURN;
                }
            }
        }
        break;

    case BATTLE_STATE.START_PLAYER_TURN:
        grid_mgr.tick_statuses();
        is_boss_phase = false;
        cascade_count = 0;
        state = BATTLE_STATE.PLAYER_INPUT;
        break;

    case BATTLE_STATE.VICTORY:
    case BATTLE_STATE.DEFEAT:
        // terminal — the HUD shows the outcome
        break;
}
