# NMTimer (v0.5.2, English edition)

**A respawn timer for NMs, for FFXI (Windower 4).**

NMTimer remembers when and where an NM from a Magian trial (Empyrean weapon materials) was killed, and shows the time left until it can spawn again on a small on-screen HUD. If someone else killed it before you got there, you can still aim for the next spawn once you know when and where it died.

> **Status of this English edition:** the text of the addon (chat messages, HUD, data hints, comments) is in English, and the addon passes the same simulated-environment tests as the Japanese edition. I have **not yet played it on an English client**. The Japanese edition was checked in game on a Japanese client (2026-10-16): kill detection and recording, HUD, position and distance, NMs you add yourself, PH set / record / respawn measurement / removal, a lottery NM (Golden Bat), an Abyssean NM (Tammuz), and Ogopogo.
> Not checked in game in either edition: `//nmt scan`, name matching for most of the other bundled NMs, the Anomalies event NMs (the event is not running), the sound and the early notice, and measured respawns of timed NMs.
> The bundled times come from a Japanese wiki and only some of them have been confirmed in game. Rough ones are shown as "(approx.)". Correct them with measurements or `//nmt time` as you play.

Japanese edition: https://github.com/hikaruoshino/NMTimer

---

## What it does

* Records kills automatically. It notices when an enemy dies (the HP bar turns black) in your view range, whoever killed it. It only reads incoming packets and enemy data through the Windower API; there is no code that sends anything to the game server and none that reads or writes game memory.
* Shows the time left on a HUD. Several NMs can be tracked at once. Drag the HUD to move it. Counting continues across zone changes and logout.
* Warns you before the spawn. By default 5 minutes before it can spawn (change it with `//nmt lead`), and again when it can spawn, in the chat log and with a sound.
* Remembers where. The kill position and your current distance to it are shown.
* Works for NMs with an unknown time. It tells you "The respawn time is unknown" and you set the minutes with `//nmt time`.
* Measures real respawn times. If you stay in the zone and an enemy of the same name appears again, the elapsed time is remembered and listed.
* Measures PH respawn times too. When you kill a PH, it remembers the time and the enemy ID. When an enemy with the same ID appears again, the elapsed time becomes a measurement. Up to 10 measurements are kept per ID and zone. The next time you kill a PH, the HUD counts down with the median of that ID's measurements (or, if there are none, of the zone's) and shows something like "PH respawn in 4:52 (measured)". PH respawn times can differ per PH and per zone, so a first measurement is used as soon as it exists.
* Any number of PHs can be registered. This covers NMs where one of two PHs with different IDs is the lottery target. If a non-PH enemy was counted by mistake, `//nmt ph del` removes it (its record goes too).
* Kills you did not see can be entered by hand. When you hear about one (a shout, for example), type `//nmt tod` with how many minutes ago it died.
* NMs that are finished can be hidden with `//nmt off`, and you can add your own NMs with `//nmt add`.

## Bundled NMs (73)

NMs from Empyrean weapon Magian trials that have a fixed zone (weapon NMs, Abyssean NMs, Uleguerand NMs), and NMs from the event "Investigate the Vana'diel Anomalies". **Brulo, Maere, NMs spawned with trigger items (Ironclad and others) and Dynamis NMs are not included**; you can add them yourself.

| Type | NMs | Time counted |
|---|---|---|
| Lottery (killing a PH can spawn the NM; 56) | Tumbling Truffle, Helldiver, Orctrap, Intulo, Ramponneau, Keeper of Halidom, Golden Bat, Nocuous Weapon, Black Triple Stars, Serra, Bugbear Strongman, La Velue, Hovering Hotpot, Serpopard Ishtar, Tottering Toby, Drooling Daisy, Gargantua, Megalobugard, Ratatoskr, Bloodpool Vorax, Slippery Sucker, Seww the Squidlimbed, Ankabut, Okyupete, Panzer Percival, Ge'Dha Evileye, Bashe, Hoo Mjuu the Torrent, Daggerclaw Dracos, Namtar, Ah Puch, Donggu, Slendlix Spindlethumb, Herbage Hunter, Kirata, Zi'Ghi Boneeater, Lumbering Lambert, Deadly Dodo, Vuu Puqu the Beguiler, Buburimboo, Zo'Khu Blackcloud, Stray Mary, Hawkeyed Dnatbat, Dune Widow, Teporingo, Valkurm Emperor, Hyakume, Gloomanita, Mischievous Micholas, Cactuar Cantautor, Be'Hya Hundredwall, Jolly Green, Trembler Tabitha, Desmodont, Moo Ouzi the Swiftblade, Ni'Zho Bladebender | From the NM's death until the lottery starts (0 to 90 minutes; "(approx.)" means the wiki wording is vague) |
| Timed (17) | Abyssea: Capricornus, Yacumama, Lamprey Lord, Shoggoth, Jyeshtha, Farruca Fly, Skuld, Urd, Erebus, Feuerunke, Chesma, Tammuz (about 60 minutes after being defeated, one per zone). Also Ogopogo (Abyssea - Uleguerand, 15 to 20 minutes), Barbastelle (King Ranperre's Tomb, 15 to 20 minutes), and the Anomalies event's Kirin (Ru'Aun Gardens), Fafnir (The Boyahda Tree) and Alexander (Alzadaal Undersea Ruins; spawn point is random), 55 minutes after the kill | From the kill until the respawn |

* A lottery NM works like this: killing its PH does not spawn it for a fixed time after the NM died. The addon counts down that time. For NMs whose PH respawn interval is known (Ramponneau, Keeper of Halidom, Serra and others), it also counts down until the PH spawns again.
* The 2013-11-05 update greatly shortened the time before the lottery for the first-stage NM of many Magian weapons.** Where the wiki gives no exact number, the figure is based on "it appeared after about N minutes" reports and is marked "(approx.)". Deadly Dodo has no known time, so its time is left empty (set it with `//nmt time`).
* The event's NMs drop a treasure chest when killed. The wiki says they respawn 45 minutes after the chest disappears, which is 55 minutes from the kill (measured by the page's author). The official notice says "about 45 minutes later", so there is a discrepancy. They do not spawn outside the event period.
* Abyssean NMs are invisible; you find them by healing with a jade. Only the kill gets recorded. Only the NMs whose jade stage is up to the 2nd (Tammuz and the like) are bundled. The 3rd stage and above (Dawon and others) take long to respawn and not everyone needs them, so they are not bundled; add them with `//nmt add` (give the minutes too if you know them, for example `//nmt add 180`). The exception is Ogopogo, which is needed for a Magian trial item (the Japanese wiki calls it 無色の魂, "Colorless Soul") and is included.
* `//nmt list` shows how to find each NM and how to tell which mob is the lottery target.

## Installation

1. Put the folder in `Windower4/addons/` and name it `NMTimer` (the repository folder may be called `NMTimer-EN`, but the addon folder must be `NMTimer`). (If you also use the Japanese edition, use one of them, not both: they share the folder name and the `data/` files.)
2. In game, type `//lua l NMTimer`.
3. To load it automatically, add `lua l NMTimer` to `Windower4/scripts/init.txt`.

It needs only Windower's standard libraries (`config`, `texts`, `resources`).

## Commands (`//nmt` or `//nmtimer`)

`<NM>` can be the NM's name (`Tumbling Truffle`), its key (`tumbling_truffle`) or its number in `//nmt list`.

| Command | What it does |
|---|---|
| `//nmt list` / `//nmt list all` | List the NMs of this zone (or all) |
| `//nmt status` | Print the current records to the chat log |
| `//nmt off <NM>` / `//nmt on <NM>` | Stop tracking (it leaves the HUD) / resume |
| `//nmt tod <NM> [min ago]` | Record a kill time by hand (example: `//nmt tod 1 10` = 10 minutes ago) |
| `//nmt time <NM> <min> [max]` | Set the respawn time. `//nmt time <NM> reset` restores the default |
| `//nmt add [name] [min]` | Add the targeted enemy (or a name) |
| `//nmt alias <NM>` | Make the targeted enemy's name an alias of that NM |
| `//nmt ph` | Add the targeted enemy as a PH of the lottery (any number; while any is set, only the set ones are counted) |
| `//nmt ph del [ID]` | Remove a PH, by target or by ID number (its record and measurements go too, and it is not counted afterwards). The ID is shown by `//nmt ph list` and in the notice when a PH is recorded |
| `//nmt ph list` | PHs of this zone (set IDs, IDs being recorded, measurements per ID) |
| `//nmt ph clear <NM>` | Clear all PH settings of that NM (back to counting every same-named enemy killed nearby) |
| `//nmt phtime <NM> <min>` | Set a PH respawn time yourself (`reset` goes back to measured) |
| `//nmt remove <NM>` | Remove an NM you added |
| `//nmt clear [<NM>]` | Clear records (all, or only that NM) |
| `//nmt lead <min>` | Minutes before the spawn to give the early notice (0 = none) |
| `//nmt expire <min>` | Minutes to keep an entry on the HUD after it can spawn (default 30) |
| `//nmt sound` / `chat` / `hud` / `coord` `[on\|off]` | Sound / chat notices / HUD / position and distance display |
| `//nmt pos <X> <Y>` / `//nmt size <N>` | HUD position / text size |
| `//nmt debug` | Print the names of dead enemies to chat (for finding why something was not recorded) |
| `//nmt scan [all\|near [y]\|name]` | Inspect the enemy list (read-only). `near` lists every enemy within y yalms of you (default 60), `all` every enemy that is not drawn, including ones with no name; a name fragment narrows the list. Results are also saved in `data/scan.log` |

### Examples

* **After killing Tumbling Truffle:** nothing to do. The HUD shows something like "lottery start in 17:42".
* **You killed Shoggoth and nothing was recorded:** the name the game shows may differ from the bundled one. Target Shoggoth and type `//nmt alias shoggoth`; that name will then be recorded too. `//nmt debug` shows the names of the enemies that died.
* **Adding an NM with an unknown time:** target the enemy and type `//nmt add 60` (60 minutes). If you do not know the time, type just `//nmt add` and set it later with `//nmt time`.

## How it works, and cautions

* The enemy update packet (0x00E) tells it that an enemy died (status 2 or 3). The experience-gain notice (0x02D) is also used as a supplement. Only kills inside your own view range are seen.
* Time is real time. It keeps counting across logout and zone changes (`data/state.lua`).
* Enemy names are matched against the bundled names (English). If something is not recorded, check the name with `//nmt debug` and add an alias with `//nmt alias`.
* A PH name is shared by many enemies, and only one or two of them are the lottery target. `//nmt list` explains how to tell. If you target the right PH and type `//nmt ph`, only that enemy's respawn is measured. If you do not, every same-named enemy that died within 50 yalms of you is counted; if it counted the wrong one, remove it with `//nmt ph del`.
* A PH respawn is measured only if you stayed in the zone. Leaving the zone, or an update within 30 seconds of the kill, is not treated as a respawn. Records older than 3 hours are discarded. The same applies to the measured respawn of an NM itself: it needs you to stay in the zone, and an appearance within 60 seconds of the kill is not counted.
* NMs you add are saved in `data/user.lua`. The bundled data (`nm_data.lua`) may be overwritten by updates.
* Using external tools, Windower included, is not permitted by the FFXI Terms of Service. I cannot guarantee that this addon is allowed or that it will not be detected. Please use it at your own risk; the author accepts no responsibility for any consequences.

## Data sources

NM names, zones, respawn times, PHs and how to find them were read from articles of the Japanese FFXI wiki [FF11用語辞典 (wiki.ffo.jp)](https://wiki.ffo.jp/), and only the numbers and names were taken; the wording was not copied. The URL of the source of each entry is in the `src` field of `nm_data.lua`. The hints are short English summaries I wrote myself. Where I do not know the official English name of a place or an item, the wording is descriptive.

* The "Investigate the Vana'diel Anomalies" event article
* The Magian trial pages (weapons) and the articles of Tumbling Truffle, Helldiver, Orctrap, Intulo, Ramponneau, Keeper of Halidom and Ogopogo
* The Abyssean NM article

Numbers on the wiki can change with game updates. If one is wrong, fix it with `//nmt time`.

## License

MIT License. See `LICENSE`.

## Changelog

* **v0.5.2 (2026-10-23)** English edition. Distances use yalms.
* The version history before that belongs to the Japanese edition (v0.1.0 to v0.5.2): lottery and timed NMs, the HUD, sound and chat notices, measurements, manual records, adding NMs; PH respawn measurement per ID and zone; `//nmt ph del` / `ph list`; `//nmt scan`.

## Feedback

A one-line "it works" is welcome too. With a GitHub account you can post from [Issues](../../issues/new/choose).
