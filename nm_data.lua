-- NMTimer bundled data: NMs from Empyrean weapon Magian trials and from the "Investigate the Vana'diel Anomalies" event whose respawn is worth counting.
-- NMs you add yourself are saved in data/user.lua (this file may be overwritten by updates).
--
-- Fields:
--   key        internal name (lowercase letters, digits and _). Can also be used to name the NM in commands
--   name       displayed name (English)
--   alias      other names (e.g. the name shown by the Japanese client). Only the ones that are known. Add missing ones with //nmt alias
--   kind       "lottery" = lottery type (killing a PH can spawn the NM. For a fixed time after the NM dies, no lottery runs)
--              "timed"   = timed type (respawns a fixed time after being killed)
--   zones      zones where it appears (English names, same as `en` in res/zones.lua)
--   ph         names of the PHs of a lottery NM (English). Used to remember PH kills
--   min, max   minutes. Lottery: "from the NM's death until the lottery starts"; timed: "until respawn". max only for those with a range
--   approx     when true, the number is a rough guide (the wiki wording is vague). Correct it with measurements
--   ph_repop   lottery: minutes from killing a PH until the next PH spawns
--   job        job of an Abyssean NM (display only)
--   hint       how to find it / how to tell which mob is the lottery target (display only)
--   src        source (an article on wiki.ffo.jp, the Japanese FFXI wiki). Text is not copied; only numbers and names are used
--
-- The numbers come from the wiki and have not been checked in game (as of 2026-10-16).
-- The hints are short English summaries of the Japanese wiki articles (map squares are the in-game grid, e.g. K-6). Where I do not know the official English name of a place or item, the wording is descriptive.

local S = "https://wiki.ffo.jp/html/"

local data = {
    ---------------------------------------------------------------------------
    -- Investigate the Vana'diel Anomalies (event. 1st 2026-03, 2nd 2026-05 on, 3rd 2026-09 to 10. The next is undecided)
    -- A treasure chest appears when the NM dies and disappears after 10 minutes. It respawns 45 minutes after the chest disappears
    -- = 55 minutes from the kill (the moment the HP bar turns black) (55:00 measured by the page author).
    -- The official notice says "about 45 minutes later", which does not match the measurement
    ---------------------------------------------------------------------------
    {key = "kirin_event", name = "Kirin", kind = "timed", min = 55,
     zones = {"Ru'Aun Gardens"},
     hint = "Around H-9 to H-10 in Ru'Aun Gardens. Can be killed in just under 3 minutes if fast",
     src = S .. "39989.html"},
    {key = "fafnir_event", name = "Fafnir", kind = "timed", min = 55,
     zones = {"The Boyahda Tree"},
     hint = "Around G-7 to I-9 in The Boyahda Tree. Do not let it aim its breath toward the passage entrance leading to the lightning corridor (descriptive name)",
     src = S .. "39989.html"},
    {key = "alexander_event", name = "Alexander", kind = "timed", min = 55,
     zones = {"Alzadaal Undersea Ruins"},
     hint = "In front of the entrance of one of the ruins in Alzadaal Undersea Ruins. The spawn point is completely random (shout when you find it)",
     src = S .. "39989.html"},

    ---------------------------------------------------------------------------
    -- Lottery type (NMs that appear for the 3-4 kill step of Magian trials: H2H / one-handed axe / two-handed spear / etc.)
    ---------------------------------------------------------------------------
    {key = "tumbling_truffle", name = "Tumbling Truffle", kind = "lottery",
     zones = {"La Theine Plateau"}, ph = {"Poison Funguar"}, min = 18, approx = true,
     hint = "Bottom of the valley at K-6 (go down from H-7). Of the 3 in the southern valley, the top one on the widescan is the target",
     src = S .. "11812.html"},
    {key = "helldiver", name = "Helldiver", kind = "lottery",
     zones = {"Buburimu Peninsula"}, ph = {"Zu"}, min = 30, approx = true,
     hint = "K-9 to L-9. Of the 2 Zu on the east side, the lower one on the widescan is the target",
     src = S .. "11994.html"},
    {key = "orctrap", name = "Orctrap", kind = "lottery",
     zones = {"Carpenters' Landing"}, ph = {"Birdtrap"}, min = 60,
     hint = "Around I-9 and I-10. The top one of the group of 3 Birdtrap is the target",
     src = S .. "12457.html"},
    {key = "intulo", name = "Intulo", kind = "lottery",
     zones = {"Bibiki Bay"}, ph = {"Eft"}, min = 60,
     hint = "The slope at H-7. The Eft below the 3 birds lined up on the widescan is the target",
     src = S .. "12528.html"},
    {key = "ramponneau", name = "Ramponneau", kind = "lottery",
     zones = {"West Sarutabaruta [S]"}, ph = {"Toad"}, min = 90, ph_repop = 5,
     hint = "Southwest of I-9. The top one of 4 Toads in a row is the target",
     src = S .. "18823.html"},
    {key = "keeper_of_halidom", name = "Keeper of Halidom", kind = "lottery",
     zones = {"The Sanctuary of Zi'Tah"}, ph = {"Goobbue Gardener"}, min = 60, ph_repop = 5,
     hint = "Around J-7, along a path not on the map starting from J-9. If you see 2, the lower one is the target",
     src = S .. "8864.html"},

    -- Two-handed sword trial (Sunblade, Attack+3). The lottery re-rolls after 5 minutes (60 minutes before the 2013-11-05 update)
    {key = "golden_bat", name = "Golden Bat", kind = "lottery",
     zones = {"Valkurm Dunes"}, ph = {"Giant Bat"}, min = 5,
     hint = "In front of the entrance of Gustav Tunnel at B-8. Of the 2 Giant Bats, the upper one on the widescan is the target. It appears in the cave at (C-7) or (B-8)",
     src = S .. "11055.html"},

    ---------------------------------------------------------------------------
    -- Magian trials: the NM of the first stage of each weapon (3-4 kills). The 2013-11-05 update shortened the time before the lottery for many of them,
    -- and where the numbers are vague they are marked approx = true. Where the time is unknown, min is left out and you set it with //nmt time
    ---------------------------------------------------------------------------
    {key = "nocuous_weapon", name = "Nocuous Weapon", kind = "lottery", zones = {"Inner Horutoto Ruins"}, ph = {"Boggart"}, min = 15, approx = true, hint = "Around the pillar on the east side of I-9. Of the 6 between the 2 Will-o'-the-Wisps on the widescan, the 3 around the pillar are targets", src = S .. "18691.html"},
    {key = "black_triple_stars", name = "Black Triple Stars", kind = "lottery", zones = {"Rolanberry Fields"}, ph = {"Midnight Wings"}, min = 45, approx = true, hint = "Night only (18:00 to 6:00). The top one of the group of 4 in the north (I-9) or the south (I-10 to I-11) is the target", src = S .. "10740.html"},
    {key = "serra", name = "Serra", kind = "lottery", zones = {"Bibiki Bay"}, ph = {"Jagil"}, min = 15, ph_repop = 5, hint = "F-9 on Purgonorgo Isle (west coast). The Jagil between the Coralline Uragnite and the Coastal Opo-opo is the target", src = S .. "12526.html"},
    {key = "bugbear_strongman", name = "Bugbear Strongman", kind = "lottery", zones = {"Oldton Movalpolos"}, ph = {"Bugbear Bondman"}, min = 60, ph_repop = 14, hint = "North of I-11 or east of J-11. Of the 3 guards, the one that spawns there is the target", src = S .. "15131.html"},
    {key = "la_velue", name = "La Velue", kind = "lottery", zones = {"Batallia Downs [S]"}, ph = {"Smilodon"}, min = 60, ph_repop = 5, hint = "East side of G-7 to G-8. Scan from H-8; the 10th from the top of the line of Smilodon is the target", src = S .. "14837.html"},
    {key = "hovering_hotpot", name = "Hovering Hotpot", kind = "lottery", zones = {"Garlaige Citadel"}, ph = {"Fallen Major", "Fallen Mage"}, min = 10, ph_repop = 5, hint = "In front of the device past the 2nd gate (J-8). 3 Fallen*** are lined up; the side with two of them is the target", src = S .. "18728.html"},
    {key = "serpopard_ishtar", name = "Serpopard Ishtar", kind = "lottery", zones = {"Tahrongi Canyon"}, ph = {"Wild Dhalmel"}, min = 26, approx = true, hint = "Around H-8 and H-6. The top one of each group is the target. Reported to re-roll 26 minutes after the kill", src = S .. "11493.html"},
    {key = "tottering_toby", name = "Tottering Toby", kind = "lottery", zones = {"Batallia Downs"}, ph = {"Stalking Sapling"}, min = 10, approx = true, hint = "G-6 / G-7. The upper Stalking Sapling is the target (killing the lower one too makes sure). Reported as 10 to 15 minutes", src = S .. "12119.html"},
    {key = "drooling_daisy", name = "Drooling Daisy", kind = "lottery", zones = {"Rolanberry Fields"}, ph = {"Ochu"}, min = 15, approx = true, hint = "D-11. There is only one Ochu. Reported as about 15 minutes", src = S .. "12104.html"},
    {key = "gargantua", name = "Gargantua", kind = "lottery", zones = {"Beaucedine Glacier"}, ph = {"Stone Golem"}, min = 8, approx = true, ph_repop = 5, hint = "Bottom level of J-8. In the line of 3 Tundra Tigers, Goblin Poacher and Goblin Trader, the 4th, a Stone Golem, is the target", src = S .. "5791.html"},
    {key = "megalobugard", name = "Megalobugard", kind = "lottery", zones = {"Lufaise Meadows"}, ph = {"Gigantobugard"}, min = 60, hint = "G-8 (lower level). Also appears at G-7 to H-7 (upper level). Tell the target apart with the widescan", src = S .. "12459.html"},
    {key = "ratatoskr", name = "Ratatoskr", kind = "lottery", zones = {"Fort Karugo-Narugo [S]"}, ph = {"Vorpal Bunny"}, min = 60, ph_repop = 5, hint = "H-10 to H-11. Of the 3 on the north side, the top one on the scan is the target (the 2 in the south are not)", src = S .. "18624.html"},
    {key = "bloodpool_vorax", name = "Bloodpool Vorax", kind = "lottery", zones = {"Pashhow Marshlands"}, ph = {"Thread Leech"}, min = 16, approx = true, hint = "F-5. Of the 5 leeches in the clearing, the top one is the target. Reported as about 16 minutes after the kill", src = S .. "8862.html"},
    {key = "slippery_sucker", name = "Slippery Sucker", kind = "lottery", zones = {"Qufim Island"}, min = 16, approx = true, hint = "Around H-8. Shares the lottery with giants (random). The bottom of the line of giants on the scan is the target", src = S .. "18712.html"},
    {key = "seww_the_squidlimbed", name = "Seww the Squidlimbed", kind = "lottery", zones = {"Sea Serpent Grotto"}, ph = {"Riparian Sahagin"}, min = 60, hint = "F-7 to G-7, beyond the door opened with a Silver Beastcoin. There is only one Riparian Sahagin", src = S .. "18857.html"},
    {key = "ankabut", name = "Ankabut", kind = "lottery", zones = {"North Gustaberg [S]"}, ph = {"Huge Spider"}, min = 90, hint = "The high ground at L-7. Of the 3 Huge Spiders, the top one on the scan is the target", src = S .. "18775.html"},
    {key = "okyupete", name = "Okyupete", kind = "lottery", zones = {"Misareaux Coast"}, ph = {"Diatryma"}, min = 60, approx = true, hint = "G-6 to G-5 (south side). The top of the 4 Diatryma is the target. Reports of 60 minutes, 90 to 120 minutes and 104 minutes", src = S .. "18771.html"},
    {key = "panzer_percival", name = "Panzer Percival", kind = "lottery", zones = {"Jugner Forest"}, ph = {"Stag Beetle"}, min = 60, hint = "Two places, around J-5 and around L-7 (separate lotteries). When there is one extra, the top one on the scan is the target", src = S .. "3947.html"},
    {key = "gedha_evileye", name = "Ge'Dha Evileye", kind = "lottery", zones = {"Beadeaux"}, ph = {"Old Quadav"}, min = 20, approx = true, hint = "Below the high ground at E-11. Of the 2 Old Quadav, the lower one on the scan is the target. 20 minutes at the latest", src = S .. "981.html"},
    {key = "bashe", name = "Bashe", kind = "lottery", zones = {"Sauromugue Champaign"}, ph = {"Hill Lizard"}, min = 0, approx = true, ph_repop = 5, hint = "On top of the ledge at L-8 to L-9. Of the 3 lizards, the top one on the scan is the target. The lottery starts right after the kill", src = S .. "18720.html"},
    {key = "hoo_mjuu_the_torrent", name = "Hoo Mjuu the Torrent", kind = "lottery", zones = {"Giddeus"}, ph = {"Yagudo Mendicant"}, min = 60, approx = true, hint = "The high ground at H-10. Of the Yagudo Mendicants (summoners), the bottom one on the scan is the target. Sometimes it spawns quickly", src = S .. "6132.html"},
    {key = "daggerclaw_dracos", name = "Daggerclaw Dracos", kind = "lottery", zones = {"Meriphataud Mountains"}, ph = {"Raptor"}, min = 30, approx = true, ph_repop = 5, hint = "The clearing at K-9 to K-11 (the lottery is from the middle to the south of K-10). The 1st of the 3 between the birds and goblins is the target. Reported as 30 minutes", src = S .. "12106.html"},
    {key = "namtar", name = "Namtar", kind = "lottery", zones = {"Sea Serpent Grotto"}, ph = {"Ghast"}, min = 60, hint = "The clearing at D-8. The Ghasts are lined up as \"5 and 3\" or \"4 and 4\". The bottom one of the upper (or lower) group is the target", src = S .. "13572.html"},
    {key = "barbastelle", name = "Barbastelle", kind = "timed", zones = {"King Ranperre's Tomb"}, min = 15, max = 20, hint = "The above-ground part up the stairs (around J-6). A lone NM. 15 to 20 minutes after the previous kill", src = S .. "18560.html"},
    {key = "ah_puch", name = "Ah Puch", kind = "lottery", zones = {"Outer Horutoto Ruins"}, ph = {"Ghoul"}, min = 30, approx = true, hint = "Around G-8 on the 2nd map of the Amaryllis tower. One random Ghoul of the 7 around is the target", src = S .. "18711.html"},
    {key = "donggu", name = "Donggu", kind = "lottery", zones = {"Ordelle's Caves"}, ph = {"Fly Agaric"}, min = 15, hint = "H-7 on MAP[4] (enter from F-7 of La Theine Plateau). Of the 4 Fly Agaric, the top one on the scan is the target", src = S .. "18706.html"},
    {key = "slendlix_spindlethumb", name = "Slendlix Spindlethumb", kind = "lottery", zones = {"Inner Horutoto Ruins"}, ph = {"Goblin Leecher"}, min = 15, approx = true, hint = "D-11 on MAP2, the room beyond the hidden passage. Kill the target outside the room first. 15 minutes at the longest", src = S .. "18694.html"},
    {key = "herbage_hunter", name = "Herbage Hunter", kind = "lottery", zones = {"Tahrongi Canyon"}, ph = {"Canyon Crawler"}, min = 30, approx = true, hint = "G-5. There is only one Canyon Crawler. 30 minutes at the longest (needs verification)", src = S .. "18479.html"},
    {key = "kirata", name = "Kirata", kind = "lottery", zones = {"Beaucedine Glacier"}, ph = {"Tundra Tiger"}, min = 15, approx = true, hint = "Around the magic tower at H-10. Of the Tundra Tigers, the lower one on the scan is the target", src = S .. "11960.html"},
    {key = "zighi_boneeater", name = "Zi'Ghi Boneeater", kind = "lottery", zones = {"Palborough Mines"}, ph = {"Veteran Quadav"}, min = 16, approx = true, ph_repop = 8, hint = "3F, H-7 to H-8. The small room on the side without the Old ToolBox. Reported to appear after 16 minutes", src = S .. "11514.html"},
    {key = "lumbering_lambert", name = "Lumbering Lambert", kind = "lottery", zones = {"La Theine Plateau"}, ph = {"Battering Ram"}, min = 30, approx = true, hint = "Around G-9 to I-9. The Battering Ram on the east side is the target (not the west). Reported to appear after 30 minutes", src = S .. "3952.html"},
    {key = "deadly_dodo", name = "Deadly Dodo", kind = "lottery", zones = {"Sauromugue Champaign"}, ph = {"Tabar Beak"}, hint = "I-6 to K-6. Of the 2 Tabar Beak, the upper one on the scan is the target. The shortened time is unknown (set it with //nmt time)", src = S .. "9038.html"},
    {key = "vuu_puqu_the_beguiler", name = "Vuu Puqu the Beguiler", kind = "lottery", zones = {"Giddeus"}, ph = {"Yagudo Piper"}, min = 20, hint = "The innermost clearing at H-14. Only the Yagudo Piper is the target", src = S .. "14540.html"},
    {key = "buburimboo", name = "Buburimboo", kind = "lottery", zones = {"Buburimu Peninsula"}, ph = {"Shoal Pugil"}, min = 15, approx = true, hint = "Migoya beach (Japanese wiki: ミゴヤ砂浜) at K-7. Of the 4 Shoal Pugil, the bottom one on the scan is the target. 15 minutes at the latest", src = S .. "11993.html"},
    {key = "zokhu_blackcloud", name = "Zo'Khu Blackcloud", kind = "lottery", zones = {"Beadeaux"}, ph = {"Zircon Quadav"}, min = 20, approx = true, ph_repop = 12, hint = "On top of the high ground at E-11 to F-11. 20 minutes at most", src = S .. "3955.html"},
    {key = "stray_mary", name = "Stray Mary", kind = "lottery", zones = {"Konschtat Highlands"}, ph = {"Mad Sheep"}, min = 40, approx = true, hint = "Two places near the windmills at F-6 and F-9. At F-6 the top of 5, at F-9 the 2nd from the top is the target. 40 minutes or less", src = S .. "3949.html"},
    {key = "hawkeyed_dnatbat", name = "Hawkeyed Dnatbat", kind = "lottery", zones = {"Davoi"}, ph = {"Orcish Cursemaker"}, min = 20, approx = true, hint = "From the pond at L-8 to L-9 along the passage. Reported to appear after about 20 minutes", src = S .. "6435.html"},
    {key = "dune_widow", name = "Dune Widow", kind = "lottery", zones = {"Eastern Altepa Desert"}, ph = {"Giant Spider"}, min = 60, hint = "The middle of G-8. 2 Giant Spiders stand below a Sabotender; the upper one is the target", src = S .. "12765.html"},
    {key = "teporingo", name = "Teporingo", kind = "lottery", zones = {"Dangruf Wadi"}, ph = {"Hoarder Hare"}, min = 10, approx = true, hint = "H-9 to I-9. Of the 3, the bottom one on the scan is the target. Reported to appear after 10 minutes", src = S .. "18710.html"},
    {key = "valkurm_emperor", name = "Valkurm Emperor", kind = "lottery", zones = {"Valkurm Dunes"}, ph = {"Damselfly"}, min = 15, approx = true, ph_repop = 5, hint = "Around E-8 on the west coast. The top of the 4 between the Snipper and the Thread Leech is the target. About 15 minutes", src = S .. "2662.html"},
    {key = "hyakume", name = "Hyakume", kind = "lottery", zones = {"Ranguemont Pass"}, ph = {"Hecteyes"}, min = 18, approx = true, ph_repop = 5, hint = "J-8. Of the 5 Hecteyes, the top one on the scan is the target. Reported to appear after about 18 minutes", src = S .. "18722.html"},
    {key = "gloomanita", name = "Gloomanita", kind = "lottery", zones = {"North Gustaberg [S]"}, ph = {"Coppercap"}, min = 60, approx = true, hint = "H-6 to H-7. In the line of Rock Eater, 5 Coppercap, Rock Eater, the bottom Coppercap is the target", src = S .. "14880.html"},
    {key = "mischievous_micholas", name = "Mischievous Micholas", kind = "lottery", zones = {"Yuhtunga Jungle"}, ph = {"Young Opo-opo"}, min = 60, hint = "Around G-9 (above the Overgrown Rose). The bottom of the 10 Young Opo-opo is the target. 60 minutes to 3 hours", src = S .. "18130.html"},
    {key = "cactuar_cantautor", name = "Cactuar Cantautor", kind = "lottery", zones = {"Western Altepa Desert"}, ph = {"Cactuar"}, min = 60, hint = "F-11 to G-11. The order on the scan differs between day and night. The lower of the 2 Cactuar is the target", src = S .. "17240.html"},
    {key = "behya_hundredwall", name = "Be'Hya Hundredwall", kind = "lottery", zones = {"Palborough Mines"}, ph = {"Copper Quadav", "Old Quadav"}, min = 20, approx = true, ph_repop = 10, hint = "The small room south of J-9 on 3F. The target is a Copper Quadav or an Old Quadav (random each time). About 20 minutes", src = S .. "18690.html"},
    {key = "jolly_green", name = "Jolly Green", kind = "lottery", zones = {"Pashhow Marshlands"}, ph = {"Goobbue"}, min = 20, hint = "I-7 to I-8 and J-8. There is only one Goobbue (it gets a lottery-target mark)", src = S .. "8863.html"},
    {key = "trembler_tabitha", name = "Trembler Tabitha", kind = "lottery", zones = {"Maze of Shakhrami"}, ph = {"Maze Maker"}, min = 15, ph_repop = 5, hint = "The south end of F-8 (enter from Tahrongi Canyon). Of the 2 Maze Makers, the upper one on the scan is the target", src = S .. "18718.html"},
    {key = "desmodont", name = "Desmodont", kind = "lottery", zones = {"Outer Horutoto Ruins"}, ph = {"Stink Bats"}, min = 15, ph_repop = 5, hint = "The small room at G-6 on the first map of the Amaryllis tower. Of the 2, the upper one on the scan is the target", src = S .. "18697.html"},
    {key = "moo_ouzi_the_swiftblade", name = "Moo Ouzi the Swiftblade", kind = "lottery", zones = {"Castle Oztroja"}, ph = {"Yagudo Theologist"}, min = 20, approx = true, ph_repop = 10, hint = "The L-shaped passage at H-9 / I-9 on 1F. The Yagudo Theologist that the wiki calls \"fixed black\" (apparently always the black mage type; unverified) is the target. Reported to appear after 20 minutes", src = S .. "14309.html"},
    {key = "nizho_bladebender", name = "Ni'Zho Bladebender", kind = "lottery", zones = {"Pashhow Marshlands"}, ph = {"Veteran Quadav"}, min = 15, approx = true, ph_repop = 5, hint = "Along the road from E-11 to I-10 (a wide area). The one that joins a line of 5 Quadav to make 6 is the target. About 15 minutes", src = S .. "18885.html"},

    ---------------------------------------------------------------------------
    -- Timed type: Abyssean NMs (2nd stage. One per zone. About 1 hour after being defeated. Invisible; find them by healing with a jade)
    ---------------------------------------------------------------------------
    {key = "capricornus", name = "Capricornus", job = "WAR", kind = "timed", min = 60, approx = true,
     zones = {"East Ronfaure", "East Ronfaure [S]", "Jugner Forest", "Jugner Forest [S]"}, src = S .. "19626.html"},
    {key = "yacumama", name = "Yacumama", job = "MNK", kind = "timed", min = 60, approx = true,
     zones = {"East Ronfaure", "East Ronfaure [S]", "Jugner Forest", "Jugner Forest [S]"}, src = S .. "19626.html"},
    {key = "lamprey_lord", name = "Lamprey Lord", job = "DRK", kind = "timed", min = 60, approx = true,
     zones = {"North Gustaberg", "North Gustaberg [S]", "Pashhow Marshlands", "Pashhow Marshlands [S]"}, src = S .. "19626.html"},
    {key = "shoggoth", name = "Shoggoth", job = "RDM", kind = "timed", min = 60, approx = true,
     zones = {"North Gustaberg", "North Gustaberg [S]", "Pashhow Marshlands", "Pashhow Marshlands [S]"}, src = S .. "19626.html"},
    {key = "jyeshtha", name = "Jyeshtha", job = "WAR", kind = "timed", min = 60, approx = true,
     zones = {"West Sarutabaruta", "West Sarutabaruta [S]", "Meriphataud Mountains", "Meriphataud Mountains [S]"}, src = S .. "19626.html"},
    {key = "farruca_fly", name = "Farruca Fly", job = "THF", kind = "timed", min = 60, approx = true,
     zones = {"West Sarutabaruta", "West Sarutabaruta [S]", "Meriphataud Mountains", "Meriphataud Mountains [S]"}, src = S .. "19626.html"},
    {key = "skuld", name = "Skuld", job = "RDM", kind = "timed", min = 60, approx = true,
     zones = {"Batallia Downs", "Batallia Downs [S]", "Rolanberry Fields", "Rolanberry Fields [S]",
              "Sauromugue Champaign", "Sauromugue Champaign [S]"}, src = S .. "19626.html"},
    {key = "urd", name = "Urd", job = "DNC", kind = "timed", min = 60, approx = true,
     zones = {"Batallia Downs", "Batallia Downs [S]", "Rolanberry Fields", "Rolanberry Fields [S]",
              "Sauromugue Champaign", "Sauromugue Champaign [S]"}, src = S .. "19626.html"},
    {key = "erebus", name = "Erebus", job = "BLM", kind = "timed", min = 60, approx = true,
     zones = {"Beaucedine Glacier", "Beaucedine Glacier [S]", "Xarcabard", "Xarcabard [S]"}, src = S .. "19626.html"},
    {key = "feuerunke", name = "Feuerunke", job = "MNK", kind = "timed", min = 60, approx = true,
     zones = {"Beaucedine Glacier", "Beaucedine Glacier [S]", "Xarcabard", "Xarcabard [S]"}, src = S .. "19626.html"},
    {key = "chesma", name = "Chesma", kind = "timed", min = 60, approx = true,
     zones = {"La Theine Plateau", "Konschtat Highlands", "Tahrongi Canyon"}, src = S .. "19626.html"},
    {key = "tammuz", name = "Tammuz", kind = "timed", min = 60, approx = true,
     zones = {"La Theine Plateau", "Konschtat Highlands", "Tahrongi Canyon"}, src = S .. "19626.html"},

    ---------------------------------------------------------------------------
    -- Timed type: the 3rd stage of the Abyssea zones of Heroes of Abyssea (Colorless Soul). Brulo and Maere are not included because they have not been researched
    ---------------------------------------------------------------------------
    {key = "ogopogo", name = "Ogopogo", kind = "timed", min = 15, max = 20,
     zones = {"Abyssea - Uleguerand"},
     hint = "Crescent-shaped scarlet jade. Around H-8 and G-9 (landmarks the wiki calls アクロリス and ギア)",
     src = S .. "22875.html"},
}

return data
