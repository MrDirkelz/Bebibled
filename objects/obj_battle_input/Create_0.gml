/// obj_battle_input :: Create
/// Input abstraction. Translates mouse/touch into grid swap intents and forwards
/// them to the controller — only while the controller is in PLAYER_INPUT.

ctrl    = noone;
sel_col = -1;       // currently picked-up cell (-1 = none)
sel_row = -1;
