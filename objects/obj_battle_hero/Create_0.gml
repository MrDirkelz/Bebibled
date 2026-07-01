/// obj_battle_hero :: Create
/// Player stat holder. Receives damage from the boss; accumulates the word meter
/// from cleared letters. Pure data — no FSM.

hp_max      = 100;
hp          = hp_max;
word_charge = 0;

take_damage = function(_amount) {
    hp = max(0, hp - _amount);
};
