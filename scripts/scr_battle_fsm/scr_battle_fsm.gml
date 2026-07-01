/// scr_battle_fsm
/// Battle state machine enum + tuning macros + debug helper.

#macro DMG_PER_TILE   12     // base boss damage per cleared tile
#macro CASCADE_BONUS  0.5    // extra damage multiplier per cascade depth beyond the first
#macro TILE_LERP      0.30   // view position smoothing factor (0..1)
#macro CLEAR_FRAMES   10     // how many frames a tile's clear animation lasts

enum BATTLE_STATE {
    BOARD_INIT,         // build the board, wait for it to settle
    PLAYER_INPUT,       // idle; awaiting a swap intent from the input handler
    ANIMATING_SWAP,     // the two swapped tiles tween into place
    RESOLVING_MATCHES,  // scan the board (the decision hub)
    SWAP_BACK,          // illegal move: revert the swap
    CLEARING_MATCHES,   // matched tiles animate out
    CASCADING,          // gravity falls + refill spawns, tiles tween down
    CHECK_DEADLOCK,     // any legal move left?
    BOARD_SHUFFLE,      // no moves: reshuffle the board
    END_PLAYER_TURN,    // check victory, publish boss intent
    BOSS_ATTACK,        // boss executes its ability against the grid / hero
    BOSS_RESOLVE,       // resolve any cascades the boss action created
    START_PLAYER_TURN,  // begin-of-turn upkeep (tick statuses)
    VICTORY,
    DEFEAT
}

/// @desc Human-readable state name (for on-screen debug).
function battle_state_name(_s) {
    switch (_s) {
        case BATTLE_STATE.BOARD_INIT:        return "BOARD_INIT";
        case BATTLE_STATE.PLAYER_INPUT:      return "PLAYER_INPUT";
        case BATTLE_STATE.ANIMATING_SWAP:    return "ANIMATING_SWAP";
        case BATTLE_STATE.RESOLVING_MATCHES: return "RESOLVING_MATCHES";
        case BATTLE_STATE.SWAP_BACK:         return "SWAP_BACK";
        case BATTLE_STATE.CLEARING_MATCHES:  return "CLEARING_MATCHES";
        case BATTLE_STATE.CASCADING:         return "CASCADING";
        case BATTLE_STATE.CHECK_DEADLOCK:    return "CHECK_DEADLOCK";
        case BATTLE_STATE.BOARD_SHUFFLE:     return "BOARD_SHUFFLE";
        case BATTLE_STATE.END_PLAYER_TURN:   return "END_PLAYER_TURN";
        case BATTLE_STATE.BOSS_ATTACK:       return "BOSS_ATTACK";
        case BATTLE_STATE.BOSS_RESOLVE:      return "BOSS_RESOLVE";
        case BATTLE_STATE.START_PLAYER_TURN: return "START_PLAYER_TURN";
        case BATTLE_STATE.VICTORY:           return "VICTORY";
        case BATTLE_STATE.DEFEAT:            return "DEFEAT";
        default:                             return "?";
    }
}
