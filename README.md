# RogueKit

Personal WoW: Forever addon for Logan's Undead Combat Rogue. One command makes the macros, fills
the action bars (including the stealth bar) and sets the keys. While leveling, every new spell
(and every new rank) drops onto its key by itself.

Made for the stock Blizzard UI. Movement keys (WASD, A/D strafe) are never touched. Only works
on a rogue; on any other character it does nothing.

## Install on Windows (Logan's laptop)

1. Quit WoW completely.
2. Unzip `RogueKit.zip` into
   `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   (right-click the zip > Extract All..., and pick that folder). When you're done this file must
   exist: `...\_forever_\Interface\AddOns\RogueKit\RogueKit.toc`.
   Not `...\AddOns\RogueKit\RogueKit\RogueKit.toc` (one RogueKit folder, not two).
   If `Interface\AddOns` doesn't exist yet, make those two folders.
3. Start WoW. At character select click **AddOns** (bottom left), make sure **RogueKit** is
   ticked. If it says "out of date", tick **Load out of date AddOns** at the top.
4. Log in to your rogue and type `/roguekit setup` in chat.

## Use

- First login prints: `Hi Logan! Type /roguekit setup ...`. Nothing changes until you run it.
- `/roguekit setup` - make/update the macros, fill the reserved slots, set the keys (saved for
  this character only). Prints every key it changed. Safe to run again any time.
- `/roguekit status` - every key, what it does, and whether you've learned it yet.
- `/roguekit undo` - put back every key RogueKit changed. Bars and macros stay; new spells stop
  auto-filling until the next setup.
- `/roguekit help`

Rules it follows:
- Never does anything in combat. Anything you ask for in a fight runs when the fight ends.
- A reserved slot is only filled if it's empty, already holds RogueKit's thing, or still holds a
  spell from the new-character starter bar (Attack, Sinister Strike, ...) noted at the first
  setup. Anything you put there yourself is left alone; setup tells you which slots it skipped.
- New ranks: the slot gets the highest rank you know.
- A key that is your *only* key for moving (move/turn/strafe/jump/autorun) is never taken.
  With A/D set to strafe, Q and E are free to use (they're spare strafe keys by default).
- Macros are per character. If the character macro list is full, setup tells you which ones it
  couldn't make.

## Keys

**Main bar** (normal):

| Key | Action | Slot |
|---|---|---|
| 1 | Sinister Strike | 1 |
| 2 | Eviscerate | 2 |
| 3 | Slice and Dice | 3 |
| 4 | Rupture (20) | 4 |
| 5 | Blade Flurry (talent, 30) | 5 |
| Q | Kick (12) | 6 |
| E | Gouge (6) | 7 |
| R | Kidney Shot (30) | 8 |
| F | macro RK Stealth | 9 |
| G | Vanish (22) | 10 |
| Z | Evasion (8) | 11 |
| V | Sprint (10) | 12 |

**Stealth bar.** Stealth swaps the whole main bar to the rogue stealth page (bonus bar 1 =
action page 7 = slots 73-84), so the same keys do stealth moves:

| Key | Action | Slot |
|---|---|---|
| 1 | Cheap Shot (26) | 73 |
| 2 | Garrote (14) | 74 |
| 3 | Ambush (18, needs a dagger in your main hand) | 75 |
| 4 | macro RK Sap (10; placed once Sap is learned) | 76 |
| 5 | Pick Pocket (4) | 77 |
| Q | Distract (22) | 78 |
| E | (empty) | 79 |
| R | (empty) | 80 |
| F | macro RK Stealth (same key leaves stealth) | 81 |
| G | Vanish | 82 |
| Z | Evasion | 83 |
| V | Sprint | 84 |

**Bar 2** (Blizzard "Bottom Left" bar, action page 6 = slots 61-72, binding MULTIACTIONBAR1BUTTONn):

| Key | Action | Slot |
|---|---|---|
| X | Blind (34) | 61 |
| C | Adrenaline Rush (talent, 40) | 62 |
| SHIFT-Q | Expose Armor (14) | 63 |
| SHIFT-E | Feint (16) | 64 |
| SHIFT-R | macro RK Throw (pull from range) | 65 |
| T | Riposte (talent, 20) | 66 |

Bar 2 is hidden on a new character. Setup tries to switch it on; if you still can't see it, type
`/reload`, or go to Options > Action Bars and tick Bar 2 ("Bottom Left").

With Blizzard's default keys, setup replaces things like Q/E (spare strafe keys), R (reply),
F (assist), Z (sheathe), V (nameplates), X (sit), C (character window; the button on the
menu bar still opens it). All of them come back with `/roguekit undo`.

## Macros

```
RK Stealth
#showtooltip Stealth
/cast [nostealth] !Stealth
/cancelaura [stealth] Stealth

RK Sap
#showtooltip Sap
/cast [@mouseover,harm,nodead][] Sap

RK Throw
#showtooltip
/cast [equipped:Thrown] Throw; [equipped:Bows] Shoot Bow; [equipped:Guns] Shoot Gun; [equipped:Crossbows] Shoot Crossbow
```

RogueKit rewrites these on setup and whenever spells change, so edit them in `RogueKit.lua`,
not in the macro window.

## Editing

Everything is in the config block at the top of `RogueKit.lua`:
- `S` - every spell name (as the spellbook shows it).
- `PROFILES.ROGUE.macros` - macro names and bodies.
- `PROFILES.ROGUE.keys` - key -> slot -> spell/macro. `stealth = true` marks a stealth-page slot
  (it uses the main-bar key, so no binding is set for it).
- `BAR_COMMANDS` - action slot ranges -> binding names.

Saved per character in `RogueKitCharDB` (setup state, replaced keys, what was placed).

## Not verified in game (no Forever client was running when this was written)

- Stealth page = slots 73-84 and bottom-left bar = slots 61-72 come from Blizzard's paging
  formula and ElvUI's Forever profile (rogue `[bonusbar:1] 7`, bar 6 = MULTIACTIONBAR1BUTTON),
  not from a live test.
- Turning bar 2 on from code (`Settings` proxy `PROXY_SHOW_ACTIONBAR_2` / `SetActionBarToggles`);
  may need `/reload` or the manual tick. Whether keys on a hidden bar 2 fire is untested.
- `[stealth]`/`[nostealth]` macro conditionals and `/cancelaura` in Forever; Throw/Shoot spell names.
- Spell ranks and the spellbook API used to find spells by name (with older-API fallbacks).
- What a brand-new Forever rogue's starter bar holds.

## License

MIT. See `LICENSE`.

## Changelog

### 0.2.0
- Macros (Stealth, Sap, Throw) get real icons instead of the red question mark until the
  spell is learned; after that they switch to the automatic icon.
- Setup frees old keys still bound to RogueKit's buttons (e.g. 6-0 once Q/E/R/F/G own them),
  so the bar shows the right key. `/roguekit undo` puts them back.
