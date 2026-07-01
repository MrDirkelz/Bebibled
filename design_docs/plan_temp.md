Procedural Level System for Bebibled (all 31,103 KJV verses)
Context
Bebibled fuses match-3 (Bejeweled) and word-spelling (Bookworm) over the KJV Bible, where every verse is a battle. The original level-design spec proposed a hand-authored level_rules.json and naive HP/letter handling. We want instead a fully procedural system: ~66 hand-authored per-book themes plus sparse boss overrides, and everything else (enemy HP, letter distribution, enemy choice, board) derived at runtime from the verse string. The hard problem the spec never solved is making verse words actually spellable on the board so the "Divine Critical" (spelling a word from the current verse) is a reliable, skill-based mechanic rather than a luck event.

Reconnaissance (2 Explore + 1 Plan agent) confirmed the codebase already has the right bones — a disciplined battle FSM, a grid-manager mutation API, a word_score/word_charge meter, and a single letter-assignment chokepoint — so this is mostly additive.

Decisions locked with the user
Turn economy: either/or per turn. Each player turn is ONE action — a swap OR a word-trace — then the boss responds. (Smallest change to the existing one-action FSM.)
Valid words: KJV corpus only. A spellable word = any word that appears anywhere in the KJV (~13k unique). Self-contained, thematic, and proper nouns work automatically. Spelling a word from the current verse is the Divine Critical.
Progression: linear-within-book, books open. Any book is selectable any time; verses within a book unlock in order. "Unlocked" is derived from the save bitset (verse v opens when verse v−1 is cleared; verse 0 always open).
Key reconnaissance findings that shape the plan
tile_random_letter() (scr_tile_struct.gml:59) is the single chokepoint for letter assignment (used by grid_fill_no_matches, grid_refill, spawn_specials). One edit makes every spawn honor the verse's letters.
Board is 7×8 = 56 cells (hardcoded obj_grid_manager/Create_0.gml:6). A 3–7 letter planted path fits trivially.
A word_charge meter already exists (obj_battle_hero/Create_0.gml:5, fed at obj_battle_controller/Step_0.gml:36).
Matchability is statistically a non-issue: only 15 of 31,103 verses (0.05%) lack a plantable 3–7-char key word. Verse word-count: min 2, median 24, max 90 → HP needs clamps.
Blocker — Included Files is empty (Bebibled.yyp, "IncludedFiles":[]). The bible JSON on disk is NOT copied into the runtime sandbox, so any loader fails until the data is registered via the gamemaker-resource-tool MCP server.
Blocker — board self-builds too early. obj_grid_manager Create builds the board (obj_grid_manager/Create_0.gml:209-219) before the controller/level data exist (room creation order: grid_manager → … → controller). Board construction must move into a method run after level_load.
Data shape verified: bible[book][chapter][verse] = string, 0-indexed, 66 books in canonical order; per-book files books/<name>.json exist (raw only, ~100 KB each). datafiles/CLAUDE.md says never read these directly — all access goes through one wrapper.
Architecture
One merged global.level struct is the single source of truth for a battle. level_load computes everything procedural once and caches it there; the hot path only does a cheap weighted letter pick.

scr_bible_data    lazy per-book loader + verse accessors + linear-index tables
scr_level_rules   themes (default+book+override), get_level_rules() merge+memo, validator
scr_level         level_load() orchestrator -> installs global.level
scr_letter_bag    weighted bag (build + tile_pick_letter) + word planting (path search)
scr_word_trace    trace input validation, KJV-dictionary check, divine-crit, route to resolve
scr_save          compact bitset progress (clear/stars), unlock derivation
scr_text_helpers  1-indexed display_ref(), book display names
obj_game_boot     persistent; one-time boot: data init, rules init, dictionary, save load
        │
        ▼ installs global.level { rules, targets, bag, plant_list, enemy_hp, enemy_id, seed }
tile_random_letter()  -> reads global.level.bag         (THE chokepoint)
build_board()         -> grid_fill_no_matches, then plant_words (letters only)
obj_battle_controller -> new RESOLVING_WORD state, request_word_trace(), HP/enemy from level
obj_battle_input      -> drag=swap (existing) | trace=word (new dual gesture)
obj_ui_battle         -> verse slot (top strip) + live trace preview
Principle: the 6 match colors (COLOR enum) are invariant; biomes only reskin (palette/sprite/bg/music swap). Planting overwrites letters only, never colors, which is why it can never create an unwanted instant match-3 (the board is already color-safe from grid_fill_no_matches).

Key design solutions
Matchability (the core problem) — bag + planting hybrid
Weighted letter bag (raises word density, never starves the board). Built per verse: count letters of the verse's key words → blend with an English-frequency floor (BAG_FREQ_FLOOR ≈ 0.35) → enforce a vowel floor (BAG_VOWEL_FLOOR ≈ 0.22). Stored as a 26-entry cumulative table; tile_pick_letter() binary-searches it. Injected at the tile_random_letter chokepoint with the current uniform logic as fallback.
Guaranteed planting (makes ≥1 verse word always traceable). On board build, pick a key word (len 3–7), find a connected 8-directional path via bounded randomized DFS, and overwrite those cells' letter fields in order. Colors untouched → no match side-effects. Graceful fallback: if no path/word (the 0.05% case), skip planting; the bag still helps. Re-plant after the word is consumed, gated to turn boundaries (never mid-cascade).
Turn fusion (either/or)
A traced word is validated, converted to a clear_cells list + damage, then routed into the existing CLEARING_MATCHES → CASCADING → RESOLVING_MATCHES pipeline — reusing all cascade machinery. Both swap and trace flow to END_PLAYER_TURN, so each is exactly one turn.

HP, enemy, determinism
HP = clamp(hp_base + round(hp_per_word * wordCount), hp_min, hp_max) using word count of the raw verse (not char length). Defaults 60 / 6 / 80 / 600.
Enemy chosen deterministically from the book pool via a stable hash of (b,c,v).
Board build is seeded from that hash (random_set_seed) so each verse is a fixed, fair starting puzzle. Determinism covers the initial board only (GameMaker shares one RNG stream; boss AI/shuffles draw from it afterward). obj_game_boot must not randomize() after a level seed.
New resources (create via gamemaker-resource-tool MCP — cannot be added by writing .gml alone)
Scripts (resource_create type GMScript): scr_bible_data, scr_level_rules, scr_level, scr_letter_bag, scr_word_trace, scr_save, scr_text_helpers.

Object (resource_create type GMObject): obj_game_boot (persistent; or a game_boot_once() guard the controller calls so instance order is irrelevant).

Included Files (register the currently-empty IncludedFiles via MCP):

The 66 books/<name>.json files (lazy per-book text — do NOT register the 3–5 MB monoliths).
dictionary_kjv.txt — the precomputed unique-word list (see Dictionary section).
Enums (add in scr_level_rules): SPECIAL_RULE { NONE, BOSS, EXTRA_VOWELS, NO_VOWEL_FLOOR, DOUBLE_PLANT, LOCKED_START }. Reuse COLOR unchanged.

Files to modify (with anchors)
File:anchor	Change
scr_tile_struct.gml:59 tile_random_letter()	Delegate to tile_pick_letter() (weighted bag) when global.level has a bag; else keep uniform fallback. Single edit covers all spawn paths.
obj_grid_manager/Create_0.gml:209-219	Extract board build into build_board(): seed RNG from global.level.seed, grid_fill_no_matches, then plant_words(global.level.plant_list). Do NOT auto-build in Create when global.level is absent — let the controller's BOARD_INIT call it.
obj_grid_manager/Create_0.gml:87 collapse_and_refill	After refill settles, call maybe_replant() when a plant was consumed — gated by a controller flag set only at START_PLAYER_TURN (never mid-cascade).
scr_battle_fsm.gml:9 enum BATTLE_STATE + :28	Add RESOLVING_WORD; add its name to battle_state_name(). Reuse existing DMG_PER_TILE/CASCADE_BONUS.
obj_battle_controller/Create_0.gml:27	Add request_word_trace(_path) mirroring request_swap. Replace stub word_init_dictionary() call (:24) with game_boot_once().
obj_battle_controller/Step_0.gml:30-57	Add RESOLVING_WORD case (validate→damage→clear_cells→CLEARING_MATCHES); apply divine-crit multiplier at the damage site (:35); set from_player_swap=false, cascade_count=1 before entering the cascade pipeline. On VICTORY (:95) call save_mark_clear(...).
obj_battle_input/Step_0.gml:14-33	Dual gesture: short adjacent drag = swap (existing); drag across ≥3 cells = build trace_path → ctrl.request_word_trace(path). Gate to PLAYER_INPUT.
obj_ui_battle/Draw_64.gml:14	Draw the verse reference + blanked target words in the empty top strip (y 0–42); draw the live trace string while tracing.
obj_boss_base/Create_0.gml:5	hp_max = global.level.enemy_hp; pull abilities from the chosen enemy archetype instead of always boss_default_abilities().
scr_word_system.gml:33-45	Replace 10-word stub: load dictionary_kjv.txt into global.word_dict; word_is_valid = in dict (verse words are in the corpus, so they validate automatically).
No other files change.

Data structures
Merged rules (global.level.rules, from get_level_rules): identity {book,chapter,verse} (0-indexed); presentation {palette,bg,music,enemy_pool} (asset refs are strings, resolved with fallback at use); combat {hp_base,hp_per_word,hp_min,hp_max}; letter tuning {vowel_floor,freq_floor,plant_min_len,plant_max_len,plant_count}; word {divine_crit_mult}; behavior {special_rules:[SPECIAL_RULE]}. Returned fully merged — callers never walk the fallback chain. Memoized by "b_c_v" (sparse; only visited verses).

Theme authoring file (themes.json Included File, or a GML literal in scr_level_rules):

{ "default": { hp_base:60, hp_per_word:6, vowel_floor:0.22, freq_floor:0.35, ... },
  "books":     { "0": {palette:"pal_eden", enemy_pool:["serpent","beast"], music:"mus_genesis"}, ... },
  "overrides": { "0/2/23": {enemy_pool:["the_fall"], special_rules:["BOSS"], hp_base:200}, ... } }
Keys are 0-indexed integer strings. display_ref() converts to 1-indexed for UI only.

Letter bag (global.level.bag): { cum: array[26], total } (prefix-sum table for O(26) pick).

Plant list (global.level.plant_list): [ { word, placed:bool, cells:[] } ].

Save (global.save): a buffer at 2 bits/verse (0=locked,1=clear/0★,2=1★,3=2★) ≈ 7.8 KB for ~31,103 verses. Size from runtime metadata, never a hard-coded count. Precompute book_offset[66] + flattened chapter offsets so (b,c,v) → linearIdx is O(1). Unlock within a book = "verse 0 open, else previous verse cleared"; books always open. Persist via buffer_save/buffer_load; a tiny JSON header stores {version, total_verses}.

Core algorithms (pseudocode)
get_level_rules(b,c,v) — clone default → struct_merge_into book layer → override layer → validate_rules (clamp numbers, map/validate special_rules, blank bad asset refs) → memoize. Per-field merge policy: REPLACE for all scalars + palette/bg/music; enemy_pool REPLACE (offer enemy_pool_add for union); special_rules UNION.

verse_targets(b,c,v) — tokenize the verse (strip stop-words at runtime + punctuation, uppercase, keep len ≥3 alphabetic, dedupe via struct keys). targets = divine-crit membership set; plant = subset len 3–7.

build_letter_bag(targets, rules) — sum key-word letter counts → normalize → blend with ENG_FREQ[26] by freq_floor → enforce vowel_floor (scale vowels up if below) → make cum table.

plant_words(grid, plant_list, rules) — for each entry: find_path_for_word (bounded randomized 8-dir DFS, PLANT_MAX_TRIES≈40); on success overwrite letter along the path (colors untouched); else placed=false (graceful). maybe_replant re-runs after consumption, only at turn boundaries.

level_load(b,c,v) — bible_ensure_book_loaded(b) → get_level_rules → verse_targets → HP from word count (clamped) → deterministic enemy_id from pool → build_letter_bag → pick_plant_words → install global.level → random_set_seed(seed) (board build only).

RESOLVING_WORD (new FSM case) — validate path (8-dir connected, all matchable), word = letters along path, require word_is_valid(word); dmg = round(len*DMG_PER_TILE*crit + word_score(word)) where crit = struct_has(targets, word) ? divine_crit_mult : 1.0; apply to boss.hp; grid_mgr.clear_cells(path); set from_player_swap=false, cascade_count=1; → CLEARING_MATCHES.

JSON schema support
Merge policy documented in the schema header (table above); validator echoes the effective merged rules for overrides in debug mode.
special_rules = enumerated vocabulary mapped to a handler registry (global.special_rule_handlers); unknown tokens dropped with a logged warning, never crash.
Asset fallback asset_or_default(name, fallback) (uses asset_get_index < 0) → missing bg/music/palette/enemy reskin to defaults, never crash. Lets biomes be authored incrementally.
Boot/debug validator level_rules_validate_all() — checks book keys 0–65, override b/c/v in range (against loaded metadata), special_rules ∈ enum, asset refs exist (warn), numeric ranges (hp_min ≤ hp_max, floors ∈ [0,1]). Fail loud in dev, degrade in release.
Dictionary (KJV corpus)
Generate dictionary_kjv.txt once (offline, from bible.tokens.json): the set of unique uppercase alphabetic KJV words. Register as an Included File; word_load_dictionary() loads it into global.word_dict at boot (~13k keys, trivial). Because the corpus contains every verse's own words, current-verse words validate automatically and proper nouns (NOAH) just work.

Data loading
Lazy per-book: bible_ensure_book_loaded(b) parses books/<name>.json on first access, caches in global.bible_books[b]. BOOK_FILES[66] maps canonical index → filename (one-time authored list). Tokenize clean key-words at runtime from the raw verse (no clean.json monolith needed; proper-noun capitalization is readable from the raw text). Never parse the 3–5 MB monoliths; never parse inside Step (do it in a load state).

Tuning constants (single block in scr_level_rules / themes.default)
HP_BASE 60, HP_PER_WORD 6, HP_MIN 80, HP_MAX 600, BAG_VOWEL_FLOOR 0.22, BAG_FREQ_FLOOR 0.35, PLANT_MIN_LEN 3, PLANT_MAX_LEN 7, PLANT_COUNT 1, PLANT_MAX_TRIES 40, DIVINE_CRIT_MULT 2.0, TRACE_MIN_LEN 3, SAVE_BITS_PER_VERSE 2. Reuse existing DMG_PER_TILE 12, CASCADE_BONUS 0.5 (scr_battle_fsm.gml:4).

Implementation phases (ordered)
Phase 0 — Plumbing (blocker work). MCP: register books/*.json + dictionary_kjv.txt as Included Files; create scr_bible_data, scr_text_helpers, obj_game_boot. Implement lazy loader, BOOK_FILES[66], linear-index offsets. Verify a verse round-trips at runtime (debug-draw Genesis 1:1).
Phase 1 — Rules + orchestration. MCP: create scr_level_rules, scr_level. Implement themes (default + a few books), get_level_rules (merge+memo), validator, special-rule registry, asset_or_default, level_load. Wire boss HP/abilities and the build-order refactor (build_board() from BOARD_INIT). Hard-code one verse to start.
Phase 2 — Letter bag. MCP: create scr_letter_bag. Tokenization, build_letter_bag, tile_pick_letter; edit tile_random_letter. Verify boards favor verse letters; vowel floor holds.
Phase 3 — Planting. find_path_for_word (8-dir DFS), plant_words (letters-only), fallback, maybe_replant gating; hook build_board + collapse_and_refill. Verify a key word is traceable on the start board across a sample; confirm the 15 no-keyword verses degrade.
Phase 4 — Word-trace + FSM. MCP: create scr_word_trace; add RESOLVING_WORD. KJV dictionary load; request_word_trace; dual-gesture input; UI verse slot + trace preview; divine-crit.
Phase 5 — Save/progress. MCP: create scr_save. Bitset buffer, offsets, unlock derivation, persist; hook VICTORY.
Phase 6 — Content + verse select. Author ~66 book themes + a few boss overrides; boot validator pass; a book/chapter/verse select entry point (linear-within-book, books open); biome reskins as art arrives.
Risks / edge cases
R-data Included Files empty → loaders silently return nothing at runtime though cat works on disk. Phase 0 verifies a real runtime read; loaders hard-error on a missing book file.
R-order Manager builds board before level installs → bag/plant silently skipped (uniform fallback). Mitigated by the build_board() refactor; manager Create only allocates when global.level absent.
R-determinism GameMaker shares one RNG stream; seed the initial board only, don't promise deterministic cascades/boss AI. obj_game_boot must not randomize() after a seed.
R-plant ~0.05% verses lack a plant word; DFS may rarely fail to fit → placed=false and carry on. Never block board init on planting.
R-replant Re-planting mid-cascade mutates letters under the player → gate to START_PLAYER_TURN only.
R-flags Entering CLEARING_MATCHES from a trace with stale from_player_swap=true would trigger SWAP_BACK → explicitly reset swap flags + cascade_count=1.
R-merge AI-authored overrides may assume append vs replace → explicit policy table + validator echo of effective merged rules.
R-tails 2-word vs 90-word verses → HP clamps (hp_min/hp_max); bag freq_floor keeps tiny-verse boards playable.
R-count Real total is 31,103; size save/index tables from runtime metadata, never a literal.
Verification
Data round-trip (Phase 0): at runtime, debug-draw bible[0][0][0] == "In the beginning…"; confirm a lazily-loaded book parses and a missing-file path hard-errors.
Matchability (Phases 2–3): for a sample of verses (short, long, genealogy), assert the board shows a traceable verse key word on turn 1 and that vowels meet the floor; confirm the 15 no-keyword verses load and play with bag-only.
Turn fusion (Phase 4): trace a valid KJV word → tiles clear, cascade, damage applies, turn passes to the boss; trace a current-verse word → Divine Critical multiplier visible; invalid path/word is rejected without consuming the turn.
HP/enemy determinism (Phase 1): same verse loads identical enemy + identical starting board across runs; HP within clamps for min/median/max-length verses.
Progression (Phase 5): clearing verse v unlocks v+1 in the same book; a different book is selectable immediately; reload restores progress from the bitset.
Build: npx @gamemaker/gm-cli compile --errors-only --toolchain GMS2, then npx @gamemaker/gm-cli run --errors-only --toolchain GMS2 (per memory: GMS2 toolchain required).