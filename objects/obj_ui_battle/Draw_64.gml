/// obj_ui_battle :: Draw GUI
/// Pure view: boss/hero HP bars, word meter, boss intent telegraph, state debug,
/// and the win/lose banner. Reads from the controller / boss / hero.

var _ctrl = instance_find(obj_battle_controller, 0);
var _boss = instance_find(obj_boss_base, 0);
var _hero = instance_find(obj_battle_hero, 0);

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ---- boss HP (top) ----
if (_boss != noone) {
    var _x1 = 40, _y1 = 70, _x2 = _gw - 40, _y2 = 100;
    draw_set_color(c_black); draw_rectangle(_x1 - 2, _y1 - 2, _x2 + 2, _y2 + 2, false);
    draw_set_color(c_gray);  draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_color(c_red);   draw_rectangle(_x1, _y1, lerp(_x1, _x2, _boss.hp / _boss.hp_max), _y2, false);
    draw_set_color(c_white);
    draw_text(_x1, _y1 - 28, "BOSS  " + string(_boss.hp) + " / " + string(_boss.hp_max));
    if (_boss.intent != undefined) {
        draw_text(_x1, _y2 + 6, "Next: " + _boss.intent.name + " (" + _boss.intent.telegraph + ")");
    }
}

// ---- hero HP + word meter (bottom) ----
if (_hero != noone) {
    var _hy = _gh - 120;
    var _x1 = 40, _x2 = _gw - 40;
    draw_set_color(c_black); draw_rectangle(_x1 - 2, _hy - 2, _x2 + 2, _hy + 30, false);
    draw_set_color(c_gray);  draw_rectangle(_x1, _hy, _x2, _hy + 28, false);
    draw_set_color(c_lime);  draw_rectangle(_x1, _hy, lerp(_x1, _x2, _hero.hp / _hero.hp_max), _hy + 28, false);
    draw_set_color(c_white);
    draw_text(_x1, _hy - 28, "HERO  " + string(_hero.hp) + " / " + string(_hero.hp_max));
    draw_text(_x1, _hy + 38, "WORD CHARGE: " + string(_hero.word_charge));
}

// ---- state debug + outcome banner ----
if (_ctrl != noone) {
    draw_set_color(c_white);
    draw_text(40, _gh - 44, "State: " + battle_state_name(_ctrl.state) + "    Turn: " + string(_ctrl.turn));

    if (_ctrl.state == BATTLE_STATE.VICTORY || _ctrl.state == BATTLE_STATE.DEFEAT) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_yellow);
        var _msg = (_ctrl.state == BATTLE_STATE.VICTORY) ? "VICTORY!" : "DEFEAT";
        draw_text_transformed(_gw * 0.5, _gh * 0.5, _msg, 4, 4, 0);
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
