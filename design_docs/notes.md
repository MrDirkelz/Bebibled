rocedural Level System — Implementation Plan (Bebibled)
0. Reconnaissance findings that change the design (read these first)
These are verified facts that contradict or refine the stated design direction. Address them before coding.

Data files are NOT registered as GameMaker Included Files. Bebibled.yyp:28 is "IncludedFiles":[]. The bible JSON lives in datafiles/openbible-main/KJV/ on disk but GameMaker will not copy it into the runtime sandbox, so file_text_open() / buffer_load() against working_directory or program_directory will fail at runtime. You must register the data as Included Files via the gamemaker-resource-tool MCP server before any loader works. This is a hard blocker and belongs in Phase 0.

The JSON shape is nested ARRAYS, not maps. Verified: bible[bookIdx][chapterIdx][verseIdx] = string. 66 books, 0-indexed throughout. bible.json book order is canonical KJV (chapter counts [50,40,27,36,34,24,21,4,31,24,...] = Genesis…2 Samuel). bible.clean.json is identical shape with stop-words stripped (proper nouns retained with capitalization: "generations sons Noah Shem Ham Japheth unto sons born flood"). bible.tokens.json is the raw verse minus trailing punctuation. Per-book files (books/john.json) drop the book wrapper: book[chapterIdx][verseIdx]. This means get_level_rules and level_load index by integer, and JSON parsing returns nested GML arrays directly via json_parse.

There are 31,103 verses, not 31,102. Minor, but size your bitset off the real count, computed at load time, never a hard-coded constant.

Matchability is overwhelmingly already solvable. Across all verses: 0% have zero clean tokens of length ≥3; only 15 verses (0.05%) have no plantable 3–7-char key word. The planting fallback is a rare edge case (15 verses), not a common path. This de-risks the core mechanic substantially and argues for keeping the bag/plant logic simple.

Verse word-count distribution (for HP tuning): min 2, max 90, median 24, mean 25.4, p10=13, p90=41. A linear HP = base + perWord*wordCount with clamps is reasonable; expect to clamp the long tail.

The board is built in obj_grid_manager Create (lines 209–219), and the manager is created BEFORE the controller (Room1 instanceCreationOrder: grid_manager → hero → boss → input → ui → controller). So the board self-builds at room start, before any level_load can install per-verse rules. This is the central sequencing problem. The controller's BOARD_INIT state exists but currently does nothing except wait. You must move authoritative board construction out of the manager's Create and have level_load run first, or have the manager read already-installed level state. See Phase 1.

No RNG seeding exists anywhere. All randomness is bare irandom (scr_tile_struct.gml:60, scr_grid_logic.gml:116, obj_boss_base/Create_0.gml:13, obj_grid_manager/Create_0.gml:122,196). Introducing random_set_seed for determinism is clean, but GameMaker's irandom shares one global RNG stream — boss intent, shuffles, and deadlock-shuffle all draw from it. True per-verse determinism requires either (a) accepting that only board construction is deterministic (seed → build → immediately stop relying on the seed), or (b) routing puzzle-critical randomness through your own seeded PRNG struct. See Risk R5. I recommend (a): determinism for the initial board only.

datafiles/CLAUDE.md says "Never read the files in this folder directly." The plan below uses only structural probes (already done). The runtime loader respects this by going through one wrapper module; no other code touches the JSON.

1. Architecture overview
Three new subsystems plus surgical edits to two chokepoints.


                 ┌────────────────────────────────────────────┐
                 │  scr_bible_data   (lazy book loader)         │
                 │  scr_level_rules  (themes + merge/fallback)  │
                 │  scr_level        (level_load orchestrator)  │
                 │  scr_letter_bag   (weighted bag + planting)  │
                 │  scr_word_trace   (trace input + validation) │
                 │  scr_save         (compact bitset progress)  │
                 └───────────────┬────────────────────────────┘
                                 │ installs global.level (merged rules,
                                 │ letter bag, plant list, enemy, hp)
                                 ▼
   tile_random_letter() ───► reads global.level.bag (THE chokepoint)
   grid_manager board build ─► consumes plant list, then bag
   obj_battle_controller ───► new RESOLVING_WORD state, request_word_trace()
   obj_battle_input ────────► drag = swap (existing) | trace = word (new)
Design principle: one merged global.level struct is the single source of truth for a battle. Everything procedural is computed once in level_load and cached there. The hot path (tile_random_letter) only does a cheap weighted pick from a pre-built table.

2. New resources to create (via gamemaker-resource-tool MCP)
GameMaker requires .yy/.yyp registration for every new script and object. All of the following must be created with mcp__gamemaker-resource-tool__resource_create (and Included Files registered) — they cannot be added by writing .gml alone. Once the resource exists, its .gml body is edited directly.

New scripts (resource_create type GMScript):

scr_bible_data — lazy per-book loader, index→book-filename map, verse accessor.
scr_level_rules — global.themes, default rules, get_level_rules() merge walk + memo, validator.
scr_level — level_load(book,chap,verse), HP/enemy/seed derivation, installs global.level.
scr_letter_bag — bag build, tile_pick_letter(), tokenization, plant path-search + color assignment.
scr_word_trace — word_trace_* validation, divine-crit check, route into resolve pipeline.
scr_save — buffer/bitset progress, save/load, star write/read, unlock check.
scr_text_helpers — display_ref(book,chap,verse) 1-indexed formatter, book display names.
New objects (resource_create type GMObject):

obj_game_boot — persistent, runs once at game start: randomize() baseline, bible_data_init(), level_rules_init(), save_load(), word_load_dictionary(). Place it as the first instance, or better, make the controller call a game_boot_once() guard so order doesn't matter.
Included Files to register (via the MCP server's resource/options path for IncludedFiles — Bebibled.yyp:28 currently empty):

Either the 66 per-book files books/*.json (recommended, see §9), or bible.json + bible.clean.json. Register only what the loader actually reads.
Optional (defer): per-biome bg_*, mus_* sprite/sound resources. The asset-fallback (§7) means missing ones never crash, so these can be authored later.

Enums (add to scr_tile_struct or a new scr_level_rules — GML enums are global once their script is registered):

enum SPECIAL_RULE { NONE, BOSS, EXTRA_VOWELS, NO_VOWEL_FLOOR, DOUBLE_PLANT, LOCKED_START, ... } — the validated special_rules vocabulary mapped to a handler registry (§7).
Reuse existing COLOR (6 + COUNT) unchanged. The 6 match colors are invariant; biomes only reskin — do not extend COLOR.
3. Files / functions to MODIFY (with anchors)
File:anchor	Change
scr_tile_struct.gml:59 tile_random_letter()	Replace uniform body with: if global.level exists and has a bag, return tile_pick_letter() (weighted); else fall back to current uniform chr(ord("A")+irandom(25)). This single edit makes every spawn path (fill/refill/specials) honor the verse's letter distribution. Keep the fallback so the game runs before a level loads.
obj_grid_manager/Create_0.gml:209-219 (board build)	Extract the build into a manager method build_board() that (1) seeds RNG from global.level.seed, (2) calls grid_fill_no_matches, (3) calls plant_words(global.level.plant_list) to overwrite cells with planted key-word paths (re-checking no-instant-match), (4) spawns views. Do not auto-build in Create if global.level isn't ready — guard it, or have build_board() called from the controller's BOARD_INIT.
obj_grid_manager/Create_0.gml:87 collapse_and_refill	After refill, optionally call maybe_replant() to re-seed a fresh key-word path when the previous plant was consumed (see §5.4). Gate behind a flag so cascades aren't disrupted mid-chain.
obj_grid_manager/Create_0.gml:80 spawn_specials	No logic change needed — tile_random_letter() now weighted automatically.
obj_battle_controller/Create_0.gml:5 state init / :24 word_init_dictionary()	Call game_boot_once(); replace stub word_init_dictionary() with real dictionary load. Add request_word_trace = function(_path){...} mirroring request_swap (:27).
obj_battle_controller/Step_0.gml:30-57 RESOLVING_MATCHES	No structural change; word-trace routes into the existing CLEARING_MATCHES→CASCADING→RESOLVING_MATCHES loop. Add one new state RESOLVING_WORD (see §6) that converts a validated trace into a clear_cells + damage call, then jumps to CLEARING_MATCHES.
obj_battle_controller/Step_0.gml:35 damage application	Add divine-crit multiplier when the traced word ∈ verse target set.
obj_battle_controller/Step_0.gml:95 END_PLAYER_TURN victory	On VICTORY, call save_mark_clear(book,chap,verse, stars) and save_store().
scr_battle_fsm.gml:9 enum BATTLE_STATE	Add RESOLVING_WORD (and optionally TRACING if you want a dedicated input-capture state). Add its name to battle_state_name() (:28).
obj_boss_base/Create_0.gml:5 hp_max=300	Replace hard-coded 300 with global.level.enemy_hp. Pull abilities from global.level.enemy.abilities (book pool) instead of always boss_default_abilities().
obj_battle_hero/Create_0.gml:5 hp_max=100	Optionally read from rules (global.level.hero_hp), else keep 100.
obj_battle_input/Step_0.gml:14-33	Add a second input mode: a drag-through-multiple-cells gesture builds a path → ctrl.request_word_trace(path). Distinguish from swap by gesture length (release on adjacent single cell = swap; release after crossing ≥3 cells = trace) or a modifier/second button. See §6.2.
obj_ui_battle/Draw_64.gml:14 (empty top strip y0–42)	Draw the verse reference + target words (the "verse slot"). Draw the current trace string while tracing.
No other files change.

4. Data structures
4.1 Merged rules struct (global.level.rules, output of get_level_rules)

rules = {
    // identity (0-indexed)
    book:        int,        // 0..65
    chapter:     int,        // 0-based
    verse:       int,        // 0-based

    // presentation (asset refs are STRINGS, resolved with fallback at use)
    palette:     string,     // e.g. "pal_desert" or "" -> default
    bg:          string,     // "bg_desert" or ""
    music:       string,     // "mus_desert" or ""
    enemy_pool:  [string],   // enemy archetype ids; pick one deterministically

    // combat tuning (numbers, all overridable)
    hp_base:     int,        // default 60
    hp_per_word: real,       // default 6
    hp_min:      int,        // default 80
    hp_max:      int,        // default 600

    // letter system tuning
    vowel_floor:    real,    // default 0.22  (min vowel mass in bag)
    freq_floor:     real,    // default 0.35  (blend weight of English-freq baseline)
    plant_min_len:  int,     // default 3
    plant_max_len:  int,     // default 7
    plant_count:    int,     // default 1   (DOUBLE_PLANT -> 2)

    // word mechanic
    divine_crit_mult: real,  // default 2.0
    trace_gated:      bool,  // default false (free trace) — see §6.1 recommendation

    // behavior
    special_rules: [SPECIAL_RULE],   // enumerated + validated vocabulary
}
get_level_rules returns a fully-merged struct — callers never walk the fallback chain. It is memoized by a "b_c_v" key.

4.2 Theme authoring schema (the ~66 per-book JSON + sparse overrides)
One authored file (e.g. an Included File themes.json, or embedded as a GML literal in scr_level_rules). Shape:


{
  "default": { hp_base:60, hp_per_word:6, vowel_floor:0.22, ... },   // global default
  "books": {
     "0":  { palette:"pal_eden", enemy_pool:["serpent","beast"], music:"mus_genesis" },
     "18": { palette:"pal_psalter", hp_per_word:5 },
     ...                                                              // up to 66 entries
  },
  "overrides": {                                                       // sparse bosses
     "0/0/0":   { enemy_pool:["the_void"], hp_base:200, special_rules:["BOSS"] },
     "42/2/0":  { ... }                                                // "book/chap/verse"
  }
}
Keys are 0-indexed integer strings. A 1-indexed display helper (display_ref) converts for the UI only.

4.3 Letter bag (global.level.bag)
A precomputed cumulative-weight table for O(log n) or O(26) sampling:


bag = {
    weights: array[26] of real,   // index 0=A..25=Z, normalized so sum>0
    cum:     array[26] of real,   // prefix sums for binary-search pick
    total:   real
}
tile_pick_letter() = draw irandom_range(0,total) (or random(total)), binary-search cum, return chr(ord("A")+i). Cheap, no allocation per call.

4.4 Plant list (global.level.plant_list)

plant_list = [
    { word:"FAITH", placed:false, cells:[] }   // cells filled by the path-search at build time
]
4.5 Save buffer (compact, global.save)
Do not store a 31k struct. Use a GML buffer of fixed width. For 2 bits per verse (0=locked, 1=cleared/0★, 2=1★, 3=2★ — or use a separate stars bitset):

N = total_verses (computed from loaded metadata, ~31,103).
bytes = ceil(N * BITS_PER_VERSE / 8) ≈ 7.8 KB for 2 bits, ~3.9 KB for 1 bit clear-only.
buffer_create(bytes, buffer_fixed, 1); bit ops via buffer_peek/buffer_poke on bytes with masks (GML has no native bit-buffer, so address byte = idx*BITS div 8, shift = (idx*BITS) mod 8).
Persist with buffer_save(buf, "save_progress.dat") / buffer_load. A small separate header struct (version, total_verses, furthest-unlocked linear index) is saved as JSON alongside.
Verse linear index: precompute per-book chapter/verse offsets at boot (book_offset[66], chapter_offset flattened) so (b,c,v) → linearIdx is O(1).
Linear unlock: store one int furthest_unlocked (linear index). A verse is playable if linearIdx <= furthest_unlocked. On clear, furthest_unlocked = max(furthest_unlocked, linearIdx+1).

5. Core algorithms (pseudocode)
5.1 get_level_rules(book, chap, verse) — merge walk + memo

function get_level_rules(b, c, v):
    key = string(b)+"_"+string(c)+"_"+string(v)
    if memo has key: return memo[key]

    merged = struct_clone(global.themes.default)          // start from global default
    if global.themes.books has string(b):
        struct_merge_into(merged, global.themes.books[$ string(b)])   // book layer
    okey = string(b)+"/"+string(c)+"/"+string(v)
    if global.themes.overrides has okey:
        struct_merge_into(merged, global.themes.overrides[$ okey])    // verse/boss layer

    merged.book=b; merged.chapter=c; merged.verse=v
    validate_rules(merged)            // clamp numbers, validate special_rules vocab, fix bad asset refs to ""
    memo[$ key] = merged
    return merged

function struct_merge_into(dst, src):   // per-field MERGE POLICY (see table §7)
    for each field f in src:
        if f is a "union" field (special_rules, enemy_pool extension):
            dst[f] = array_union(dst[f], src[f])      // UNION
        else:
            dst[f] = src[f]                            // REPLACE (scalars, palette, hp_*)
Memoization caveat: memo holds merged structs for visited verses only (sparse), not 31k. Fine.

5.2 Tokenization → verse target set + key words

function verse_targets(b, c, v):
    clean = bible_clean_verse(b, c, v)          // from clean.json OR runtime stopword strip
    raw   = bible_raw_verse(b, c, v)            // for the full-verse divine-crit set
    toks = string_split(clean, " ")
    out = {}                                     // dedupe via struct keys
    for t in toks:
        u = string_upper(strip_punct(t))
        if string_length(u) < 3: continue
        if not is_alpha(u): continue             // drops numerals, "&c."
        out[$ u] = true
    targetWords = struct_keys(out)               // for divine-crit membership test
    plantCandidates = filter(targetWords, len in [plant_min_len, plant_max_len])
    return { targets: out, plant: plantCandidates }
Divine-crit set = every key word of the verse (len ≥3). A traced word that is in targets triggers the multiplier.
Plant candidates = subset length 3–7.
Dedup via struct keys (O(1) membership later).
5.3 Build the letter bag (blend + vowel floor + injection)

function build_letter_bag(targetWords, rules):
    w = array_create(26, 0)
    // (1) verse mass: count letters of key words
    for word in targetWords:
        for ch in word: w[idx(ch)] += 1
    normalize(w)                                  // -> verseDist sums to 1 (if any)

    // (2) English-frequency floor (constant table ENG_FREQ[26])
    blend = rules.freq_floor                      // e.g. 0.35
    for i in 0..25: w[i] = (1-blend)*w[i] + blend*ENG_FREQ[i]

    // (3) guaranteed vowel floor: ensure A,E,I,O,U mass >= vowel_floor
    vmass = sum(w[vowels]); 
    if vmass < rules.vowel_floor:
        scale_up_vowels_to(w, rules.vowel_floor)  // multiply vowel entries, renormalize
    // (4) NO_VOWEL_FLOOR / EXTRA_VOWELS special_rules tweak here

    normalize(w); return make_cum_table(w)
This guarantees: every verse's key letters are over-represented, common English letters always present (so generic words still form), and you never get a vowel-starved unplayable board. Injected at tile_random_letter via tile_pick_letter.

5.4 Word planting — path search on 7×8 grid
The hard part. Place one (or plant_count) key word as a connected path so the player can trace it. Two sub-problems: where (path geometry) and what color (no unwanted instant match-3).


function plant_words(grid, plant_list, rules):
    for entry in plant_list:
        word = entry.word
        path = find_path_for_word(grid, len(word))   // 8-directional, see below
        if path == NO_PATH:
            entry.placed = false; continue           // GRACEFUL FALLBACK (bag still helps)
        // assign letters
        for k in 0..len-1:
            cell = path[k]
            grid[cell.col][cell.row].letter = char_at(word,k+1)
        // assign colors avoiding instant 3-in-a-row (color is independent of letter)
        recolor_path_safe(grid, path, rules)
        entry.placed = true; entry.cells = path

function find_path_for_word(grid, L):
    // randomized DFS to find ANY simple path of length L using 8-dir adjacency
    tries = 0
    while tries < PLANT_MAX_TRIES (e.g. 40):
        start = random matchable cell
        path = [start]; visited = {start}
        if dfs_extend(path, visited, L): return path
        tries++
    return NO_PATH

function dfs_extend(path, visited, L):
    if len(path) == L: return true
    last = path[-1]
    neighbors = shuffle(8_dir_neighbors(last) that are in-bounds, matchable, not visited)
    for n in neighbors:
        path.push(n); visited.add(n)
        if dfs_extend(path,visited,L): return true
        path.pop(); visited.remove(n)
    return false
Coloring planted cells without creating an instant match-3 (recolor_path_safe):

The planted path defines letters; colors are still free. The board was built by grid_fill_no_matches (no 3-runs). Overwriting only letters keeps colors valid — so the simplest correct approach is: plant letters only, leave the existing safe colors untouched. The path's tiles keep whatever color grid_fill_no_matches gave them; no new match is possible because colors didn't change. This sidesteps the entire "planted tiles create unwanted match-3" problem.

If a design reason requires recoloring planted tiles (e.g. to make the word visually pop), then after recolor, run the same _bad_h/_bad_v 3-neighbor check used in grid_fill_no_matches (scr_grid_logic.gml:117-122) for each planted cell and reject colors that form a run, with a safety counter.
Interaction with the color-rejection fill: build order is (1) grid_fill_no_matches fills all 56 cells with safe colors + bag letters, (2) plant_words overwrites letters only on the path. No conflict.

Re-planting after consumption (maybe_replant in collapse_and_refill):

Track which planted cells were cleared. When all cells of a plant entry are gone (word consumed), set entry.placed=false.
After gravity+refill settles (in collapse_and_refill, obj_grid_manager:87), if entry.placed==false and the FSM is at a stable point (not mid-cascade — gate with a replant_allowed flag the controller sets at START_PLAYER_TURN), run find_path_for_word again on the new board and re-plant letters. Do not re-plant during an active cascade chain or you'll mutate letters under the player's feet.
5.5 level_load(book, chap, verse)

function level_load(b, c, v):
    bible_ensure_book_loaded(b)                  // lazy load per-book (§9)
    rules = get_level_rules(b, c, v)             // merged + memoized
    tgt = verse_targets(b, c, v)                 // targets + plant candidates

    // HP from WORD COUNT (raw verse) with clamps
    wc = word_count(bible_raw_verse(b,c,v))
    hp = clamp(rules.hp_base + round(rules.hp_per_word*wc), rules.hp_min, rules.hp_max)

    // deterministic enemy choice from book pool
    seed = level_seed(b,c,v)                      // stable hash -> int
    enemy_id = rules.enemy_pool[ seed mod len(pool) ]

    // letter bag + plant list
    bag = build_letter_bag(tgt.targets, rules)
    plant = pick_plant_words(tgt.plant, rules.plant_count)   // choose up to N

    global.level = {
        rules, targets: tgt.targets, raw_set: full_verse_word_set,
        bag, plant_list: plant, enemy_hp: hp, enemy_id, seed,
        book:b, chapter:c, verse:v
    }
    // RNG determinism: seed ONLY the board build
    random_set_seed(seed)
    // (board build happens next in BOARD_INIT / grid_mgr.build_board())
level_seed = a stable integer hash of (b,c,v) (e.g. ((b*1000+c)*1000+v) folded, or a small FNV over the string key). Same verse → same initial puzzle.

6. Word-trace mechanic + FSM
6.1 Gated vs free — recommendation
Recommend: FREE trace, once per turn, NOT word_charge-gated — for the first iteration. Rationale:

word_charge currently accumulates with no consumer (obj_battle_controller/Step_0.gml:36). Gating trace behind it couples two systems before either is tuned, and makes early turns (empty meter) trace-less and dull.
Free-each-turn keeps the FSM simple: one swap or one trace per player turn (both transition to END_PLAYER_TURN). This mirrors the existing "one action = one turn" rule (scr_battle_fsm comment).
Keep trace_gated as a rules flag (default false) so bosses can later require a charged meter. When gated, spend word_charge on trace and block if insufficient.
So: trace is an alternative to swapping, both consume the turn. This is the smallest change to the turn structure.

6.2 Input (obj_battle_input/Step_0.gml)
Add a path-accumulating drag mode alongside the existing swap. Two coexisting gestures:

Press records the first cell (existing sel_col/sel_row).
While held, on entering a new cell that is 8-dir adjacent to the last path cell and not already in the path, push it to a trace_path array. Draw the in-progress word in the UI.
On release:
If trace_path length ≤ 2 and release cell is orthogonally adjacent to start → treat as swap (existing request_swap).
If trace_path length ≥ 3 → ctrl.request_word_trace(trace_path).
Else cancel.
Gate to PLAYER_INPUT (existing guard at :8).
Tiles need no new persistent state; the path lives in the input object. Optionally add a transient in_trace flag to obj_grid_tile purely for highlight rendering (read in Draw), set/cleared by the input object each step.

6.3 Controller: request_word_trace(path) (mirror request_swap)

request_word_trace = function(_path):
    if state != PLAYER_INPUT: return
    if grid_mgr == noone: return
    if array_length(_path) < 3: return
    if !path_is_8dir_connected(_path): return            // adjacency validation
    if !path_cells_matchable(_path): return              // no blockers/locked/frozen
    word = string_from_path(grid_mgr.grid, _path)        // concat letters
    if !word_is_valid(word): return                      // REAL dictionary (§8)
    pending_word = { path:_path, word:word }
    state = RESOLVING_WORD
6.4 New FSM state RESOLVING_WORD (scr_battle_fsm.gml:9 enum + Step_0.gml)

case BATTLE_STATE.RESOLVING_WORD:
    // turn the validated path into a clear + damage, then reuse the cascade pipeline
    var cells = pending_word.path
    var base  = array_length(cells) * DMG_PER_TILE
    var crit  = struct_has(global.level.targets, pending_word.word)
              ? global.level.rules.divine_crit_mult : 1.0
    var dmg   = round(base * crit + word_score(pending_word.word))   // blend word value
    if (boss != noone) boss.hp = max(0, boss.hp - dmg)
    if (hero != noone) hero.word_charge += word_score(pending_word.word)
    grid_mgr.clear_cells(cells)            // EXISTING manager method -> views animate out
    pending_word = undefined
    state = BATTLE_STATE.CLEARING_MATCHES  // EXISTING: collapse+refill+cascade loop
    break
This is the key reuse: a traced word produces a clear_cells list exactly like a match does, then enters CLEARING_MATCHES → collapse_and_refill → CASCADING → RESOLVING_MATCHES. Cascades from the gap created by the traced word are handled by the existing machinery for free. After cascades settle and from_player_swap/is_boss_phase are both false, it flows to CHECK_DEADLOCK → END_PLAYER_TURN, consuming the turn. No new cascade code.

One subtlety: RESOLVING_WORD enters CLEARING_MATCHES, but from_player_swap must be false (a trace is not a swap that needs revert), and cascade_count should start at 1 for the trace's own damage tier. Set cascade_count=1 before transitioning so subsequent cascades increment correctly.

6.5 Divine Critical
Already in 6.4: struct_has(global.level.targets, word) → rules.divine_crit_mult (default 2.0). Optionally escalate (e.g. ×3) if the word is the verse's longest key word, or chain a screen-flash + verse-line reveal in the UI.

7. JSON rules schema — merge policy, validation, asset fallback
7.1 Per-field merge policy
Field	Policy	Why
hp_base, hp_per_word, hp_min, hp_max	REPLACE	scalar tuning; deeper layer wins
vowel_floor, freq_floor, plant_min/max_len, plant_count, divine_crit_mult, trace_gated	REPLACE	scalars
palette, bg, music	REPLACE	single asset ref
enemy_pool	REPLACE (default)	a book defines its roster; a boss override usually wants to narrow to one enemy, so replace is safer than union. (If you want "add to book pool," make a separate enemy_pool_add union field.)
special_rules	UNION	rules are additive flags; a boss adds BOSS without dropping book-level rules
Document this in the schema header. Merge-policy surprises are a top risk (R6) — e.g. an author expecting enemy_pool to append. Make the policy explicit and validated.

7.2 special_rules vocabulary + handler registry

enum SPECIAL_RULE { NONE, BOSS, EXTRA_VOWELS, NO_VOWEL_FLOOR, DOUBLE_PLANT, LOCKED_START }

global.special_rule_handlers = {
   BOSS:           function(level){ /* bump hp, pick boss enemy, banner */ },
   EXTRA_VOWELS:   function(level){ level.rules.vowel_floor = 0.35 },
   NO_VOWEL_FLOOR: function(level){ level.rules.vowel_floor = 0 },
   DOUBLE_PLANT:   function(level){ level.rules.plant_count = 2 },
   LOCKED_START:   function(level){ /* lock K cells on build */ },
}
validate_rules maps each authored string → enum; unknown strings are dropped with a logged warning, never crash. apply_special_rules(level) runs the handlers after merge.

7.3 Asset-reference fallback
asset_or_default(ref, kind):


function asset_or_default(_name, _fallback):
    if _name == "" or _name == undefined: return _fallback
    if !asset_exists(_name): warn(...); return _fallback   // asset_get_index(_name) == -1
    return asset_get_index(_name)
Used for palette/bg/music/enemy sprite. Missing assets reskin to defaults, never crash. This is what lets you author biomes incrementally.

7.4 Boot/build-time validator (for AI-authored content)
level_rules_validate_all() run once at boot (and in a debug mode):

Parse themes.json; assert default exists and has all required numeric fields.
For each book key: integer 0–65; each override key matches b/c/v and indices are in range (needs chapter/verse counts → from loaded metadata).
Validate every special_rules token ∈ enum.
Validate asset refs with asset_exists (warn-only).
Clamp numeric ranges (e.g. vowel_floor ∈ [0,1], hp_min ≤ hp_max).
Produce a single console report. Fail loudly in dev, degrade gracefully in release.
8. Dictionary (real, replacing the 10-word stub)
scr_word_system.gml:33-39 word_init_dictionary() is a 10-word stub; word_is_valid (:42) is the hook.

Register an English word list (e.g. ENABLE/TWL or a trimmed SOWPODS) as an Included File via the MCP server.
word_load_dictionary(): read the file, build global.word_dict[$ UPPERWORD]=true. ~170k words as struct keys is fine in GML (or use a ds_map).
For memory, consider only loading words of length 3–8 (board-traceable max path realistically ≤ ~10). Trace can be ≤ 56 long in theory but realistically short.
Verse target words (proper nouns like "NOAH") may not be in a standard dictionary — add the current verse's target set to a per-level accepted set so divine words always validate even if absent from the base dictionary. word_is_valid should accept (word ∈ global.word_dict) OR (word ∈ global.level.targets).
9. Data loading strategy — recommendation
Recommend: lazy per-book loading of books/<name>.json, NOT whole-bible at boot.

Justification:

A single battle needs exactly one book's text. Parsing 3–4.4 MB at boot (json_parse on bible.json) blocks the first frame and pins ~4 MB+ resident for data you mostly don't need.
Per-book files are 100 KB-ish (john.json = 104 KB); parse cost is negligible and amortized.
Cache loaded books in global.bible_books[$ bookIdx]; bible_ensure_book_loaded(b) parses on first access only. 66 books max resident if a player traverses everything — still small.
Index→filename map: the per-book files are named by book (genesis.json, john.json, john1.json…). Build a constant BOOK_FILES[66] array in canonical order (matching bible.json's book index, which is canonical per the verified chapter counts). One-time authoring of this 66-entry list.

Clean / key-words per verse: Prefer runtime stop-word tokenization over shipping clean.json. Reasons:

If you lazy-load per-book raw files, you'd otherwise need to also ship+load per-book clean files (which don't exist — only the monolithic bible.clean.json does). Loading the 3 MB clean monolith defeats the lazy strategy.
A ~150-word English stop-word set + string_split + length/charset filter reproduces clean.json's behavior at trivial cost per verse (you tokenize one verse at level load, not 31k).
Caveat: clean.json retains proper-noun capitalization, which is a useful proper-noun signal (see Risk R1). If you want that signal cheaply, you can detect "capitalized mid-sentence" from the raw verse during tokenization — no clean.json needed. So runtime tokenization both saves memory and preserves the signal.
Net: register only the 66 books/*.json as Included Files. Do not register the three monoliths. Tokenize at runtime.

10. Tuning constants (single scr_level_rules macro block / themes.default)
Constant	Suggested	Notes
HP_BASE	60	floor before per-word
HP_PER_WORD	6	median verse (24 words) → 60+144=204 (~current boss 300 feel)
HP_MIN	80	2-word verses still a fight
HP_MAX	600	clamps the 90-word tail
BAG_VOWEL_FLOOR	0.22	English ~38% vowels; floor well below keeps key letters prominent but never starves
BAG_FREQ_FLOOR (blend)	0.35	35% English-freq baseline + 65% verse mass
PLANT_MIN_LEN	3	
PLANT_MAX_LEN	7	path of 7 fits easily on 7×8 with 8-dir
PLANT_COUNT	1	DOUBLE_PLANT → 2
PLANT_MAX_TRIES	40	DFS restarts before fallback
DIVINE_CRIT_MULT	2.0	traced word ∈ verse
TRACE_MIN_LEN	3	shortest valid traced word
SAVE_BITS_PER_VERSE	2	0=locked,1=clear,2=1★,3=2★
DMG_PER_TILE	12 (existing, scr_battle_fsm.gml:4)	reused by trace damage
CASCADE_BONUS	0.5 (existing)	reused
Star thresholds (example): 2★ = win using a divine-word trace; 1★ = win within N turns; 0★ = win. Compute at VICTORY.

11. Implementation phases (ordered)
Phase 0 — Plumbing & data access (blocker work).

MCP: register books/*.json (and dictionary file) as Included Files in Bebibled.yyp.
MCP: create scripts scr_bible_data, scr_text_helpers, and obj_game_boot.
Implement bible_data_init, bible_ensure_book_loaded, verse accessors, BOOK_FILES[66], linear-index offset tables.
Verify a verse round-trips at runtime (debug draw of Genesis 1:1).
Phase 1 — Rules & level orchestration.

MCP: create scr_level_rules, scr_level.
Implement themes (default + a few book entries), get_level_rules merge+memo, validate_rules, special-rule handler registry, asset_or_default.
Implement level_load (HP/enemy/seed/targets), install global.level.
Wire obj_boss_base hp/abilities and the controller to call level_load before BOARD_INIT. Resolve the build-order problem: move grid_fill_no_matches out of obj_grid_manager Create into build_board(), called from BOARD_INIT. (Single verse hard-coded for now.)
Phase 2 — Letter bag (matchability part A).

MCP: create scr_letter_bag.
Implement verse_targets tokenization, build_letter_bag, tile_pick_letter, cum-table.
Edit tile_random_letter (scr_tile_struct.gml:59) to delegate to the bag with uniform fallback.
Verify boards visibly favor verse letters; vowel floor holds.
Phase 3 — Word planting (matchability part B).

Implement find_path_for_word (8-dir randomized DFS), plant_words (letters-only overwrite), graceful fallback, maybe_replant gating.
Hook build_board() and collapse_and_refill (obj_grid_manager:87).
Verify a key word is traceable on the starting board for a sample of verses; confirm the 15 no-keyword verses degrade gracefully.
Phase 4 — Word-trace mechanic + FSM.

MCP: create scr_word_trace; add RESOLVING_WORD to BATTLE_STATE (scr_battle_fsm.gml:9) + name.
Real dictionary load (replace stub at scr_word_system.gml:33); word_is_valid accepts verse targets.
request_word_trace on controller; RESOLVING_WORD case routing into CLEARING_MATCHES.
Input: dual gesture in obj_battle_input/Step_0.gml; UI trace preview + verse slot in obj_ui_battle/Draw_64.gml:14.
Divine-crit multiplier.
Phase 5 — Save / progress.

MCP: create scr_save.
Bitset buffer, linear offsets, save_mark_clear/save_is_unlocked, persist; hook VICTORY (obj_battle_controller/Step_0.gml:95).
Phase 6 — Content & validation pass.

Author the ~66 book themes + a handful of boss overrides.
level_rules_validate_all boot check; biome asset reskins as available.
A verse-select entry point (out of scope of battle, but needed to exercise 31k).
12. RISK / EDGE-CASE list
R1 — Proper-noun verses (genealogies). Gen 10:1 clean = "generations sons Noah Shem Ham Japheth...". Most "key words" are names absent from a standard dictionary. Mitigations: (a) divine-crit/validation accepts global.level.targets regardless of dictionary; (b) plant a name as the traceable word so the player has a guaranteed play; (c) the bag still seeds common letters so generic words form. Risk that non-divine dictionary words are scarce on name-dense boards — acceptable since the planted name covers the floor.

R2 — Very short verses. Min is 2 words (e.g. "Jesus wept."). HP clamp hp_min=80 prevents trivial kills; bag derives from only ~1–2 key words, so freq_floor blend is what keeps the board playable. Plant may be a 3–5 letter word ("WEPT", "JESUS"). Fine.

R3 — Very long verses (90 words). hp_max=600 clamp prevents a slog; bag has many key letters (good). No structural issue. Watch tokenization cost — negligible for one verse.

R4 — Plant-path failure. Only 15 verses (0.05%) lack a 3–7 plant candidate, and even those can fall back to no-plant (bag-only) without crashing. DFS may also fail to fit a path on a particular board (rare on 7×8 8-dir for len≤7); PLANT_MAX_TRIES then placed=false is the graceful exit. Always check entry.placed before relying on a plant. Never block board init on planting success.

R5 — Determinism vs GameMaker RNG. irandom uses one shared global stream; random_set_seed(seed) makes the board build reproducible only if nothing else consumes the stream between seed and build. But boss choose_intent (obj_boss_base:13), shuffles, and refills also draw from it, so a verse is a fixed starting puzzle, not a fully deterministic playthrough. Recommendation: seed only the initial build_board(); do not promise deterministic cascades/boss behavior. If full determinism is later required, route puzzle-critical draws through a dedicated seeded PRNG struct (xorshift) stored in global.level, leaving irandom for cosmetic/AI randomness. Also note randomize() at boot must not run after a level seed, or it clobbers it — order matters in obj_game_boot.

R6 — Merge-policy surprises (AI-authored). Authors may assume enemy_pool/special_rules append when they replace (or vice-versa). Mitigation: explicit policy table (§7.1), the boot validator echoes the effective merged rules for overrides in debug, and provide both enemy_pool (replace) and enemy_pool_add (union) if appending is desired.

R7 — JSON parse cost / memory. The 3–4.4 MB monoliths block a frame and waste RAM if loaded at boot. Mitigation: lazy per-book (§9); never register the monoliths as Included Files. Also: json_parse on a 100 KB book is fine, but parsing inside a Step would still hitch — do it at level-load (a loading state), not mid-battle.

R8 — Included Files not registered (silent runtime failure). Because IncludedFiles:[], forgetting the MCP registration means every loader returns empty at runtime while working fine when you cat on disk. Mitigation: Phase 0 explicitly verifies a runtime read; loaders log a hard error if a book file is missing.

R9 — Build-order race (manager builds before level installs). obj_grid_manager Create currently builds the board immediately, before the controller exists. If global.level is absent, the bag/plant won't apply and tile_random_letter falls back to uniform — a silent loss of the feature, not a crash. Mitigation: move build into build_board() invoked from the controller's BOARD_INIT, and have the manager Create only allocate the array (not fill) when global.level isn't ready.

R10 — Trace consuming planted word mid-cascade / replant timing. Re-planting during an active cascade mutates letters under the player. Mitigation: gate maybe_replant behind a controller flag set only at START_PLAYER_TURN; never replant inside CASCADING/RESOLVING_MATCHES.

R11 — RESOLVING_WORD flag hygiene. Entering CLEARING_MATCHES from a trace with stale from_player_swap=true would wrongly trigger SWAP_BACK logic on the follow-up resolve. Mitigation: explicitly set from_player_swap=false, last_swap=undefined, cascade_count=1 before the transition (mirror the cleanup at obj_battle_controller/Step_0.gml:39-40).

R12 — Verse count drift / off-by-one. Real count is 31,103. Size the save bitset and linear-index tables from loaded metadata at runtime, never from a literal 31102/31103, or save files corrupt if data changes.

R13 — Dictionary memory. A full SOWPODS (~270k) as struct keys is heavy. Mitigation: load only lengths 3–8; or a ds_map; benchmark on target platform.

Flags on the proposed design direction (where it may be wrong / simpler exists)
Recoloring planted tiles is unnecessary complexity. The design asks how planted tiles "get colors without creating unwanted instant match-3." Simplest correct answer: don't recolor — plant letters only. The board's colors are already match-safe from grid_fill_no_matches; overwriting only letter cannot create a color run. Drop the recolor sub-problem unless there's a visual requirement.

Word-charge gating for trace is premature. word_charge has no consumer yet; gating couples two untuned systems. Ship free trace (one per turn) first; keep trace_gated as a flag.

clean.json/tokens.json shipping is avoidable. Runtime stop-word tokenization of the lazily-loaded raw book reproduces clean.json, preserves the proper-noun capitalization signal (read from raw), and avoids loading a 3 MB monolith. Don't register the clean/tokens monoliths.

Whole-bible-at-boot is the wrong default despite being simpler to write — the 4 MB parse hitch and resident memory aren't worth it when per-book files already exist.

Planting is a near-non-issue statistically (99.95% of verses have a candidate). Resist over-engineering the path search; a bounded randomized DFS with a clean fallback is sufficient. The bag (part A) is what does most of the matchability work; planting is the guarantee-of-one-divine-word layer.

Critical Files for Implementation
/Users/dirk/GameMakerProjects/Bebibled/scripts/scr_tile_struct/scr_tile_struct.gml (the tile_random_letter() chokepoint at line 59 — single edit makes all spawns honor the bag)
/Users/dirk/GameMakerProjects/Bebibled/objects/obj_grid_manager/Create_0.gml (board build at 209-219 must move to build_board(); collapse_and_refill at 87 hosts replanting)
/Users/dirk/GameMakerProjects/Bebibled/objects/obj_battle_controller/Step_0.gml (add RESOLVING_WORD; HP/enemy from global.level; divine-crit damage; save on victory)
/Users/dirk/GameMakerProjects/Bebibled/scripts/scr_battle_fsm/scr_battle_fsm.gml (extend BATTLE_STATE enum + battle_state_name; reuse DMG_PER_TILE/CASCADE_BONUS)
/Users/dirk/GameMakerProjects/Bebibled/Bebibled.yyp (IncludedFiles is [] at line 28 — register books/*.json + dictionary via the gamemaker-resource-tool MCP before any loader works)