/// scr_boss_abilities
/// Boss ability definitions. Each ability is a struct with a telegraph string and an
/// `effect(grid_manager, hero)` method that talks ONLY to the grid manager's mutation
/// API (lock/freeze/transform/destroy) plus hero.take_damage — never the array directly.

/// @desc Default ability set for the base boss.
function boss_default_abilities() {
    return [
        {
            name      : "Bind",
            telegraph : "Locks 2 tiles",
            effect : function(_gm, _hero) {
                var _cells = _gm.get_random_cells(2);
                for (var i = 0; i < array_length(_cells); i++) {
                    _gm.lock_tile(_cells[i].col, _cells[i].row, 2);
                }
                if (_hero != noone) _hero.take_damage(8);
            }
        },
        {
            name      : "Frost",
            telegraph : "Freezes 3 tiles",
            effect : function(_gm, _hero) {
                var _cells = _gm.get_random_cells(3);
                for (var i = 0; i < array_length(_cells); i++) {
                    _gm.freeze_tile(_cells[i].col, _cells[i].row, 2);
                }
                if (_hero != noone) _hero.take_damage(5);
            }
        },
        {
            name      : "Corrupt",
            telegraph : "Spawns junk",
            effect : function(_gm, _hero) {
                var _cells = _gm.get_random_cells(1);
                if (array_length(_cells) > 0) {
                    _gm.transform_tile(_cells[0].col, _cells[0].row, COLOR.PURPLE, TILE_TYPE.BLOCKER);
                }
                if (_hero != noone) _hero.take_damage(6);
            }
        },
        {
            name      : "Smash",
            telegraph : "Heavy attack",
            effect : function(_gm, _hero) {
                if (_hero != noone) _hero.take_damage(18);
            }
        }
    ];
}
