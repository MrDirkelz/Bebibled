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

// ---- verse slot ----
if (variable_global_exists("level")) {
    draw_set_color(c_white);
    draw_text(40, 12, global.level.reference);

    var _blank_text = "";
    for (var i = 0; i < array_length(global.level.blanks); i++) {
        var _blank = global.level.blanks[i];
        _blank_text += _blank.filled ? _blank.word : text_blank_word(_blank.word);
        if (i < array_length(global.level.blanks) - 1) _blank_text += "  ";
    }
    draw_text(40, 34, _blank_text);
}

// ---- boss HP (top) ----
if (_boss != noone) {
    var _x1 = 40, _y1 = 70, _x2 = _gw - 40, _y2 = 100;
    draw_set_color(c_black); draw_rectangle(_x1 - 2, _y1 - 2, _x2 + 2, _y2 + 2, false);
    draw_set_color(c_gray);  draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_color(c_red);   draw_rectangle(_x1, _y1, lerp(_x1, _x2, _boss.hp / _boss.hp_max), _y2, false);
    draw_set_color(c_white);
    draw_text(_x1, _y1 - 28, string(_boss.enemy_name) + "  " + string(_boss.hp) + " / " + string(_boss.hp_max));
    if (_boss.intent != undefined) {
        draw_text(_x1, _y2 + 6, "Next: " + _boss.intent.name + " (" + _boss.intent.telegraph + ")");
    }
}

// ---- hero HP + word meter (bottom) ----
if (_hero != noone) {
    var _hy = _gh - 150;
    var _x1 = 40, _x2 = _gw - 40;
    draw_set_color(c_black); draw_rectangle(_x1 - 2, _hy - 2, _x2 + 2, _hy + 30, false);
    draw_set_color(c_gray);  draw_rectangle(_x1, _hy, _x2, _hy + 28, false);
    draw_set_color(c_lime);  draw_rectangle(_x1, _hy, lerp(_x1, _x2, _hero.hp / _hero.hp_max), _hy + 28, false);
    draw_set_color(c_white);
    draw_text(_x1, _hy - 28, "HERO  " + string(_hero.hp) + " / " + string(_hero.hp_max));
    draw_text(_x1, _hy + 38, "FAITH: " + string(_hero.word_charge) + " / " + string(_hero.faith_max));

    var _button_w = 112;
    var _button_h = 30;
    var _gap = 10;
    var _by = _gh - 72;
    var _miracles = _hero.miracles;
    for (var m = 0; m < array_length(_miracles); m++) {
        var _miracle = _miracles[m];
        var _bx = 40 + m * (_button_w + _gap);
        var _enabled = (_hero.word_charge >= _miracle.cost);
        draw_set_color(_enabled ? c_teal : c_dkgray);
        draw_rectangle(_bx, _by, _bx + _button_w, _by + _button_h, false);
        draw_set_color(c_white);
        draw_rectangle(_bx, _by, _bx + _button_w, _by + _button_h, true);
        draw_text(_bx + 6, _by + 7, _miracle.name + " " + string(_miracle.cost));
    }
}

// ---- state debug + outcome banner ----
if (_ctrl != noone) {
    draw_set_color(c_white);
    draw_text(40, _gh - 44, "State: " + battle_state_name(_ctrl.state) + "    Turn: " + string(_ctrl.turn));
    if (_ctrl.last_trace_feedback != "") draw_text(340, _gh - 44, _ctrl.last_trace_feedback);

    if (_ctrl.state == BATTLE_STATE.VICTORY || _ctrl.state == BATTLE_STATE.DEFEAT) {
        var _win = (_ctrl.state == BATTLE_STATE.VICTORY);

        // readability panel
        var _px1 = 50, _px2 = _gw - 50;
        var _py1 = _gh * 0.14, _py2 = _gh * 0.53;
        draw_set_alpha(0.85);
        draw_set_color(make_color_rgb(16, 20, 34));
        draw_rectangle(_px1, _py1, _px2, _py2, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(_px1, _py1, _px2, _py2, true);

        draw_set_halign(fa_center);
        draw_set_valign(fa_top);

        // banner
        draw_set_color(_win ? c_yellow : make_color_rgb(220, 90, 90));
        draw_text_transformed(_gw * 0.5, _py1 + 20, _win ? "VICTORY!" : "DEFEAT", 3, 3, 0);

        // reward: reveal the full verse
        if (_win && variable_global_exists("level")) {
            draw_set_color(c_aqua);
            draw_text(_gw * 0.5, _py1 + 78, global.level.reference);
            if (_ctrl.last_trace_feedback != "") {
                draw_set_color(c_yellow);
                draw_text(_gw * 0.5, _py1 + 104, _ctrl.last_trace_feedback);
            }
            draw_set_color(c_white);
            draw_text_ext(_gw * 0.5, _py1 + 140, string(global.level.verse_text), 30, _px2 - _px1 - 48);
        }

        // navigation buttons
        var _btns = battle_end_buttons(_ctrl.state, _gw, _gh);
        for (var b = 0; b < array_length(_btns); b++) {
            var _bt = _btns[b];
            draw_set_color(make_color_rgb(40, 60, 90));
            draw_rectangle(_bt.x1, _bt.y1, _bt.x2, _bt.y2, false);
            draw_set_color(c_white);
            draw_rectangle(_bt.x1, _bt.y1, _bt.x2, _bt.y2, true);
            draw_text((_bt.x1 + _bt.x2) * 0.5, (_bt.y1 + _bt.y2) * 0.5, _bt.label);
        }
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
