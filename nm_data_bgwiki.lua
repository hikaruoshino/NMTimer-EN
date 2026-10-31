-- NMTimer bundled data (taken from BG-Wiki zone pages, one zone at a time in zone ID order).
-- Loaded after nm_data.lua (Magian / anomaly NMs). If a key is in both, nm_data.lua wins.
-- This file may be overwritten by updates. NMs you add yourself are saved in data/user.lua.
-- Generated with the author's own tooling from an extract of the BG-Wiki zone pages. Hand edits are overwritten by the next update.
--
-- Only names, zones, placeholders and numbers are used (no text is copied). Only lottery and timed NMs are included;
-- forced (item trade), quest / mission, Unity, Voidwatch / Voidwalker, fished-up, special and Dynamis NMs are not.
-- No IDs are stored. An NM is matched by the name it has when it appears, and its ID is learned then (learn_nm_id in NMTimer.lua).
-- An NM with no time on the wiki has no min. After you kill it and see it spawn, the time is learned from the measurement.
--
--   L(name, zone, {PH...})                  lottery. Write the PH if known (nil if not)
--   T(name, zone, min minutes, max minutes) timed. Leave the times out if unknown
--   zone is the English name in res/zones.lua (a table if several). The source is the zone page (fetched 2026-10-31)
--
-- The numbers have not been verified in game.

local B = "https://www.bg-wiki.com/ffxi/"
local data = {}

local function key_of(name)
    return (name:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", ""))
end

-- Source: the zone page. A zone with [S] uses the page "Name_(S)"
local function add(e, zone)
    e.key = key_of(e.name)
    e.zones = type(zone) == "table" and zone or {zone}
    e.src = B .. (e.zones[1]:gsub(" %[S%]$", "_(S)"):gsub(" ", "_"))
    data[#data + 1] = e
end

local function L(name, zone, ph)
    -- quiet_ph: do not count PH kills until you mark a PH with //nmt ph (many PHs share a name with common enemies). The NM itself is counted by name
    add({name = name, kind = "lottery", ph = ph, quiet_ph = true}, zone)
end

local function T(name, zone, min, max)
    add({name = name, kind = "timed", min = min, max = max}, zone)
end

-- fetched 2026-10-31 ----------------------------------------------------------------
-- ID 1 Phanauet Channel
T("Stubborn Dredvodd", "Phanauet Channel")
T("Vodyanoi", "Phanauet Channel", 720, 900)
-- ID 2 Carpenters' Landing
T("Tempest Tigon", "Carpenters' Landing", 60, 120)
-- ID 5 Uleguerand Range
L("Skvader", "Uleguerand Range", {"Polar Hare"})
L("Magnotaur", "Uleguerand Range", {"Molech"})
T("Frost Flambeau", "Uleguerand Range", 120, 150)
T("Jormungand", "Uleguerand Range", 4320, 7200)
L("Bonnacon", "Uleguerand Range", {"Buffalo"})
-- ID 7 Attohwa Chasm
T("Sargas", "Attohwa Chasm", 90, 120)
T("Sekhmet", "Attohwa Chasm", 60, 90)
T("Xolotl", "Attohwa Chasm", 1260, 1440)
T("Tiamat", "Attohwa Chasm", 4320, 7200)
L("Citipati", "Attohwa Chasm", {"Corse"})
L("Ambusher Antlion", "Attohwa Chasm", {"Trench Antlion"})
-- ID 9 Pso'Xja
L("Gyre-Carlin", "Pso'Xja", {"Diremite"})
-- ID 11 Oldton Movalpolos
T("Bugbear Muscleman", "Oldton Movalpolos")
-- ID 12 Newton Movalpolos
L("Swashstox Beadblinker", "Newton Movalpolos", {"Goblin Swordsman"})
-- ID 15 Abyssea - Konschtat
T("Turul", "Abyssea - Konschtat", 10, 15)
T("Pavan", "Abyssea - Konschtat", 20)
T("Raskovnik", "Abyssea - Konschtat", 10, 15)
L("Tonberry Lieje", "Abyssea - Konschtat", {"Cryptonberry Occultist"})
T("Khalamari", "Abyssea - Konschtat", 10, 15)
L("Gangly Gean", "Abyssea - Konschtat", {"Trotting Sapling"})
L("Guimauve", "Abyssea - Konschtat", {"Licorice"})
T("Bakka", "Abyssea - Konschtat", 10, 15)
T("Balaur", "Abyssea - Konschtat", 10, 15)
T("Fistule", "Abyssea - Konschtat", 15, 20)
-- ID 16 Promyvion - Holla
T("Cerebrator", "Promyvion - Holla")
-- ID 18 Promyvion - Dem
T("Satiator", "Promyvion - Dem", 60, 360)
-- ID 20 Promyvion - Mea
T("Coveter", "Promyvion - Mea")
-- ID 24 Lufaise Meadows
T("Padfoot", "Lufaise Meadows", 1260, 1440)
-- ID 25 Misareaux Coast
T("Upyri", "Misareaux Coast", 1260, 1440)
L("Odqan", "Misareaux Coast", nil)
T("Goaftrap", "Misareaux Coast", 90, 120)
-- ID 27 Phomiuna Aqueducts
T("Eba", "Phomiuna Aqueducts", 480, 720)
T("Tres Duendes", "Phomiuna Aqueducts", 1260, 1440)
T("Minotaur", "Phomiuna Aqueducts", 20)
T("Mahisha", "Phomiuna Aqueducts", 480, 720)
-- ID 28 Sacrarium
T("Keremet", "Sacrarium", 20, 30)
-- ID 29 Riverne - Site #B01
T("Boroka", "Riverne - Site #B01", 1260, 1440)
L("Imdugud", "Riverne - Site #B01", nil)
-- ID 30 Riverne - Site #A01
T("Heliodromos", "Riverne - Site #A01", 720, 900)
T("Carmine Dobsonfly", "Riverne - Site #A01", 1260, 1440)
L("Aiatar", "Riverne - Site #A01", nil)
-- ID 33 Al'Taieu
T("Om'yovra", "Al'Taieu", 30)
T("Aw'euvhi", "Al'Taieu", 5)
T("Ul'yovra", "Al'Taieu", 60)
-- ID 34 Grand Palace of Hu'Xzoi
L("Jailer of Temperance", "Grand Palace of Hu'Xzoi", nil)
-- ID 35 The Garden of Ru'Hmet
L("Ix'aern (DRG)", "The Garden of Ru'Hmet", {"Aw'aern"})
T("Qn'zdei", "The Garden of Ru'Hmet", 5)
-- ID 45 Abyssea - Tahrongi
T("Minhocao", "Abyssea - Tahrongi", 10, 15)
T("Mictlantecuhtli", "Abyssea - Tahrongi", 10, 15)
T("Manananggal", "Abyssea - Tahrongi", 10, 15)
T("Cuelebre", "Abyssea - Tahrongi", 10, 15)
T("Chukwa", "Abyssea - Tahrongi", 10, 15)
T("Adze", "Abyssea - Tahrongi", 10, 15)
-- ID 51 Wajaom Woodlands
T("Jaded Jody", "Wajaom Woodlands", 120)
L("Zoraal Ja's Pkuucha", "Wajaom Woodlands", {"Lesser Colibri"})
T("Chelicerata", "Wajaom Woodlands")
T("Gharial", "Wajaom Woodlands", 120)
-- ID 52 Bhaflau Thickets
L("Mahishasura", "Bhaflau Thickets", {"Marid"})
L("Nis Puk", "Bhaflau Thickets", {"Sea Puk"})
L("Emergent Elm", "Bhaflau Thickets", {"Olden Treant"})
-- ID 54 Arrapago Reef
T("Merrow No.5", "Arrapago Reef", 2880, 4320)
L("Lamia No 19", "Arrapago Reef", nil)
T("Medusa", "Arrapago Reef", 60)
T("Lamie No.9", "Arrapago Reef", 4320)
T("Lamie No.7", "Arrapago Reef")
T("Euryale", "Arrapago Reef")
L("Bloody Bones", "Arrapago Reef", {"Draugar Servant DRK"})
T("Lamie No.8", "Arrapago Reef")
-- ID 61 Mount Zhayolm
L("Ignamoth", "Mount Zhayolm", {"Wamoura"})
L("Energetic Eruca", "Mount Zhayolm", {"Magmatic Eruca"})
L("Fahrafahr the Bloodied", "Mount Zhayolm", {"Hilltroll Puppetmaster"})
-- ID 62 Halvung
T("Gurfurlur the Menacing", "Halvung", 1260, 1440)
-- ID 65 Mamook
L("Zizzy Zillah", "Mamook", nil)
L("Firedance Magmaal Ja", "Mamook", nil)
T("Hundredfaced Hapool Ja", "Mamook")
T("Gulool Ja Ja", "Mamook", 60)
T("Dragonscaled Bugaal Ja", "Mamook")
T("Devout Radol Ja", "Mamook")
T("Darting Kachaal Ja", "Mamook")
-- ID 68 Aydeewa Subterrane
L("Bluestreak Gyugyuroon", "Aydeewa Subterrane", {"Qiqirn Archaeologist"})
T("Lizardtrap", "Aydeewa Subterrane", 120, 130)
-- ID 72 Alzadaal Undersea Ruins
L("Cookieduster Lipiroon", "Alzadaal Undersea Ruins", {"Qiqirn Goldsmith"})
T("Oupire", "Alzadaal Undersea Ruins", 240, 300)
T("Boompadu", "Alzadaal Undersea Ruins", 120, 150)
-- ID 79 Caedarva Mire
L("Peallaidh", "Caedarva Mire", {"Wild Karakul"})
T("Khimaira", "Caedarva Mire", 2880, 4320)
T("Aynu-kaysey", "Caedarva Mire")
-- ID 81 East Ronfaure [S]
T("Myradrosh", "East Ronfaure [S]")
L("Skogs Fru", "East Ronfaure [S]", {"Ladybug"})
T("Melusine", "East Ronfaure [S]")
T("Sandworm", {"East Ronfaure [S]", "Batallia Downs [S]", "North Gustaberg [S]", "Rolanberry Fields [S]", "West Sarutabaruta [S]", "Sauromugue Champaign [S]"}, 1200, 1500)
T("Dark Ixion", {"East Ronfaure [S]", "Jugner Forest [S]", "Batallia Downs [S]", "Grauberg [S]", "Rolanberry Fields [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]"}, 1200, 1440)
L("Goblintrap", "East Ronfaure [S]", {"Battrap"})
-- ID 82 Jugner Forest [S]
L("Drumskull Zogdregg", "Jugner Forest [S]", nil)
T("Voirloup", "Jugner Forest [S]")
T("Boll Weevil", "Jugner Forest [S]")
-- ID 83 Vunkerl Inlet [S]
T("Judgmental Julika", "Vunkerl Inlet [S]", 150)
L("Pallas", "Vunkerl Inlet [S]", {"Gigas Helmsman"})
T("Warabouc", "Vunkerl Inlet [S]", 120, 130)
L("Big Bang", "Vunkerl Inlet [S]", {"Ignis Djinn"})
-- ID 84 Batallia Downs [S]
L("Burlibix Brawnback", "Batallia Downs [S]", {"Goblin Blastmaster"})
L("Habergoass", "Batallia Downs [S]", {"Ba"})
T("Chaneque", "Batallia Downs [S]", 90, 120)
-- ID 85 La Vaule [S]
T("Rugaroo", "La Vaule [S]", 120, 300)
T("Feeblescheme Bhogbigg", "La Vaule [S]", 120, 240)
L("Shatterskull Mippdapp", "La Vaule [S]", nil)
T("Falsespinner Bhudbrodd", "La Vaule [S]", 120, 240)
L("Ashmaker Gotblut", {"La Vaule [S]", "Yughott Grotto"}, {"Orcish Augur", "Orcish Stonechucker", "Orcish Grunt"})
T("Coinbiter Cjaknokk", "La Vaule [S]", 120, 240)
T("Draketrader Zlodgodd", "La Vaule [S]", 120, 240)
T("Agrios", "La Vaule [S]", 120, 240)
T("All-seeing Onyx Eye", "La Vaule [S]", 120, 240)
T("Cogtooth Skagnogg", "La Vaule [S]", 120, 240)
-- ID 88 North Gustaberg [S]
T("Olgoi-Khorkhoi", "North Gustaberg [S]")
T("Peaseblossom", "North Gustaberg [S]")
-- ID 89 Grauberg [S]
L("Scitalis", "Grauberg [S]", nil)
L("Vasiliceratops", "Grauberg [S]", nil)
T("Sarcopsylla", "Grauberg [S]", 120)
L("Kotan-kor Kamuy", "Grauberg [S]", nil)
-- ID 90 Pashhow Marshlands [S]
L("Sugaar", "Pashhow Marshlands [S]", {"Virulent Peiste"})
L("Nommo", "Pashhow Marshlands [S]", {"Lou Carcolh"})
T("Croque-mitaine", "Pashhow Marshlands [S]")
-- ID 91 Rolanberry Fields [S]
T("Lamina", "Rolanberry Fields [S]", 90, 120)
L("Erle", "Rolanberry Fields [S]", {"Death Jacket"})
L("Delicieuse Delphine", "Rolanberry Fields [S]", {"Ochu"})
L("Dyinyinga", "Rolanberry Fields [S]", {"Scabrous Slug"})
-- ID 95 West Sarutabaruta [S]
T("Tiffenotte", "West Sarutabaruta [S]")
L("Jeduah", "West Sarutabaruta [S]", nil)
-- ID 96 Fort Karugo-Narugo [S]
L("Kirtimukha", "Fort Karugo-Narugo [S]", {"Rafflesia"})
T("Emela-ntouka", "Fort Karugo-Narugo [S]", 90, 120)
L("Demoiselle Desolee", "Fort Karugo-Narugo [S]", {"Dragonfly"})
-- ID 97 Meriphataud Mountains [S]
T("Muq Shabeel", "Meriphataud Mountains [S]", 90)
L("Hemodrosophila", "Meriphataud Mountains [S]", nil)
L("Centipedal Centruroides", "Meriphataud Mountains [S]", nil)
-- ID 98 Sauromugue Champaign [S]
T("Hyakinthos", "Sauromugue Champaign [S]", 90, 120)
L("Balam-Quitz", "Sauromugue Champaign [S]", {"Lynx"})
-- ID 99 Castle Oztroja [S]
L("Zhuu Buxu the Silent", {"Castle Oztroja [S]", "Giddeus"}, nil)
T("Marquis Forneus", "Castle Oztroja [S]", 300, 360)
T("Fleshgnasher", "Castle Oztroja [S]", 120, 240)
T("Loo Kutto the Pensive", "Castle Oztroja [S]", 240, 300)
L("Duu Masa the Onecut", "Castle Oztroja [S]", nil)
L("Aa Xalmo the Savage", "Castle Oztroja [S]", {"Yagudo Sentinel"})
-- ID 100 West Ronfaure
L("Fungus Beetle", "West Ronfaure", {"Scarab Beetle"})
L("Jaggedy-Eared Jack", "West Ronfaure", {"Forest Hare"})
T("Amanita", "West Ronfaure", 60, 70)
-- ID 101 East Ronfaure
T("Rambukk", "East Ronfaure", 15, 60)
L("Bigmouth Billy", "East Ronfaure", {"Carrion Worm"})
L("Swamfisk", "East Ronfaure", {"Pugil"})
-- ID 102 La Theine Plateau
L("Bloodtear Baldurf", "La Theine Plateau", {"Lumbering Lambert"})
T("Slumbering Samwell", "La Theine Plateau")
-- ID 103 Valkurm Dunes
T("Hippomaritimus", "Valkurm Dunes")
-- ID 104 Jugner Forest
T("Sappy Sycamore", "Jugner Forest", 60, 70)
L("Supplespine Mujwuj", "Jugner Forest", {"Orcish Grunt"})
T("Meteormauler Zhagtegg", "Jugner Forest", 1260)
T("Fraelissa", "Jugner Forest", 60)
L("Fradubio", "Jugner Forest", {"Fraelissa"})
T("King Arthro", "Jugner Forest", 1260, 1440)
-- ID 105 Batallia Downs
T("Weeping Willow", "Batallia Downs", 1260, 1440)
T("Ahtu", "Batallia Downs", 120, 240)
-- ID 106 North Gustaberg
T("Bedrock Barry", "North Gustaberg", 60)
L("Maighdean Uaine", "North Gustaberg", nil)
L("Stinging Sophie", "North Gustaberg", nil)
-- ID 107 South Gustaberg
L("Carnero", "South Gustaberg", {"Ornery Sheep"})
L("Leaping Lizzy", "South Gustaberg", {"Rock Lizard"})
T("Tococo", "South Gustaberg", 60, 70)
-- ID 108 Konschtat Highlands
T("Highlander Lizard", "Konschtat Highlands", 20, 30)
L("Steelfleece Baldarich", "Konschtat Highlands", {"Rampaging Ram"})
L("Rampaging Ram", "Konschtat Highlands", {"Tremor Ram"})
-- ID 109 Pashhow Marshlands
T("Toxic Tamlyn", "Pashhow Marshlands")
T("Bo'Who Warmonger", "Pashhow Marshlands", 1260)
-- ID 110 Rolanberry Fields
L("Eldritch Edge", "Rolanberry Fields", nil)
T("Simurgh", "Rolanberry Fields", 60, 120)
-- ID 111 Beaucedine Glacier
T("Calcabrina", "Beaucedine Glacier")
L("Nue", "Beaucedine Glacier", {"Tundra Tiger"})
-- ID 112 Xarcabard
T("Duke Focalor", "Xarcabard", 15, 30)
T("Ereshkigal", "Xarcabard", 1260, 1440)
L("Shadow Eye", "Xarcabard", nil)
T("Boreal Tiger", "Xarcabard", 5)
T("Boreal Hound", "Xarcabard", 5)
T("Boreal Coeurl", "Xarcabard", 5)
L("Barbaric Weapon", "Xarcabard", nil)
L("Biast", "Xarcabard", nil)
L("Timeworn Warrior", "Xarcabard", nil)
-- ID 113 Cape Teriggan
T("Zmey Gorynych", "Cape Teriggan")
L("Killer Jonny", "Cape Teriggan", {"Velociraptor"})
T("Tegmine", "Cape Teriggan", 120, 130)
T("Kreutzet", "Cape Teriggan", 540, 720)
L("Frostmane", "Cape Teriggan", {"Greater Manticore"})
-- ID 114 Eastern Altepa Desert
T("Nandi", "Eastern Altepa Desert")
T("Centurio XII-I", "Eastern Altepa Desert", 1260)
T("Cactrot Rapido", "Eastern Altepa Desert", 1260, 1440)
T("Sabotender Corrido", "Eastern Altepa Desert", 120)
L("Donnergugi", "Eastern Altepa Desert", {"Sand Beetle"})
-- ID 115 West Sarutabaruta
T("Numbing Norman", "West Sarutabaruta")
L("Nunyenunc", "West Sarutabaruta", nil)
L("Tom Tit Tat", "West Sarutabaruta", nil)
-- ID 116 East Sarutabaruta
L("Spiny Spipi", "East Sarutabaruta", nil)
L("Sharp-Eared Ropipi", "East Sarutabaruta", nil)
-- ID 118 Buburimu Peninsula
T("Wake Warder Wanda", "Buburimu Peninsula", 60)
T("Backoo", "Buburimu Peninsula", 50, 60)
-- ID 119 Meriphataud Mountains
T("Chonchon", "Meriphataud Mountains", 90, 120)
T("Waraxe Beak", "Meriphataud Mountains", 1260, 1440)
T("Coo Keja the Unseen", "Meriphataud Mountains", 1260)
-- ID 120 Sauromugue Champaign
T("Thunderclaw Thuban", "Sauromugue Champaign", 90, 120)
L("Blighting Brand", "Sauromugue Champaign", nil)
T("Roc", "Sauromugue Champaign", 1260, 1440)
-- ID 121 The Sanctuary of Zi'Tah
T("Blest Bones", "The Sanctuary of Zi'Tah")
T("Holey Horror", "The Sanctuary of Zi'Tah")
T("Skeleton Scuffler", "The Sanctuary of Zi'Tah")
T("Huwasi", "The Sanctuary of Zi'Tah", 120)
T("Bastet", "The Sanctuary of Zi'Tah")
T("Elusive Edwin", "The Sanctuary of Zi'Tah")
-- ID 122 Ro'Maeve
T("Nargun", "Ro'Maeve")
L("Rogue Receptacle", "Ro'Maeve", nil)
T("Martinet", "Ro'Maeve", 120)
L("Nightmare Vase", "Ro'Maeve", nil)
T("Shikigami Weapon", "Ro'Maeve", 1260, 1275)
-- ID 123 Yuhtunga Jungle
T("Koropokkur", "Yuhtunga Jungle", 60, 90)
T("Bayawak", "Yuhtunga Jungle", 90, 120)
T("Meww the Turtlerider", "Yuhtunga Jungle", 1260)
T("Pyuu the Spatemaker", "Yuhtunga Jungle", 90, 120)
-- ID 124 Yhoator Jungle
T("Powderer Penny", "Yhoator Jungle", 90, 120)
L("Hoar-knuckled Rimberry", "Yhoator Jungle", {"Tonberry Shadower", "Tonberry Creeper"})
T("Acolnahuacatl", "Yhoator Jungle", 120)
T("Woodland Sage", "Yhoator Jungle", 1260, 1440)
T("Bright-handed Kunberry", "Yhoator Jungle", 1260)
T("Bisque-heeled Sunberry", "Yhoator Jungle", 60, 120)
-- ID 125 Western Altepa Desert
T("Dahu", "Western Altepa Desert", 60)
L("Picolaton", "Western Altepa Desert", {"Phorusrhacos"})
T("King Vinegarroon", "Western Altepa Desert", 1260, 1440)
L("Calchas", "Western Altepa Desert", {"Tulwar Scorpion"})
L("Celphie", "Western Altepa Desert", {"Desert Dhalmel"})
-- ID 126 Qufim Island
T("Atkorkamuy", "Qufim Island", 30)
T("Qoofim", "Qufim Island")
T("Dosetsu Tree", "Qufim Island", 1260)
L("Trickster Kinetix", "Qufim Island", nil)
-- ID 130 Ru'Aun Gardens
L("Despot", "Ru'Aun Gardens", nil)
-- ID 132 Abyssea - La Theine
T("Megamaw Mikey", "Abyssea - La Theine", 10, 15)
T("Ovni", "Abyssea - La Theine", 15, 20)
T("Piasa", "Abyssea - La Theine", 10, 15)
T("Mangy-tailed Marvin", "Abyssea - La Theine", 10, 15)
T("Keesha Poppo", "Abyssea - La Theine", 10, 15)
T("Irrlicht", "Abyssea - La Theine", 10, 15)
T("Chasmic Hornet", "Abyssea - La Theine", 10, 15)
-- ID 136 Beaucedine Glacier [S]
L("Grand'Goule", "Beaucedine Glacier [S]", {"Gargouille"})
L("Becut", "Beaucedine Glacier [S]", {"Gigas"})
T("Scylla", "Beaucedine Glacier [S]", 240, 300)
-- ID 137 Xarcabard [S]
T("Greater Amphiptere", "Xarcabard [S]")
L("Graoully", "Xarcabard [S]", {"Dire Gargouille"})
T("Tikbalang", "Xarcabard [S]")
-- ID 140 Ghelsba Outpost
T("Warchief Vatgit", "Ghelsba Outpost", 16)
T("Orcish Wallbreacher", "Ghelsba Outpost", 60, 90)
T("Orcish Barricader", "Ghelsba Outpost", 60, 90)
L("Thousandarm Deshglesh", "Ghelsba Outpost", nil)
-- ID 141 Fort Ghelsba
T("Kegpaunch Doshgnosh", "Fort Ghelsba", 60, 90)
L("Hundredscar Hajwaj", "Fort Ghelsba", nil)
T("Orcish Panzer", "Fort Ghelsba", 60, 70)
L("Chariotbuster Byakzak", "Fort Ghelsba", nil)
-- ID 143 Palborough Mines
T("Qu'Vho Deathhurler", "Palborough Mines")
T("No'Mho Crimsonarmor", "Palborough Mines", 1260, 1440)
L("Bu'Ghi Howlblade", "Palborough Mines", {"Copper Beetle"})
-- ID 145 Giddeus
T("Eyy Mon the Ironbreaker", "Giddeus", 5)
L("Juu Duzu the Whirlwind", "Giddeus", nil)
-- ID 147 Beadeaux
T("De'Vyu Headhunter", "Beadeaux", 15)
L("Ga'Bhu Unvanquished", "Beadeaux", {"Emerald Quadav"})
T("Go'Bhu Gascon", "Beadeaux", 20)
L("Bi'Gho Headtaker", "Beadeaux", {"Brass Quadav"})
L("Da'Dha Hundredmask", "Beadeaux", {"Copper Quadav"})
-- ID 148 Qulun Dome
L("Za'Dha Adamantking", "Qulun Dome", {"Diamond Quadav"})
T("Adaman Quadav", "Qulun Dome", 20)
T("Ruby Quadav", "Qulun Dome", 20)
-- ID 149 Davoi
L("Tigerbane Bakdak", "Davoi", nil)
L("Steelbiter Gudrud", "Davoi", nil)
L("Poisonhand Gnadgad", "Davoi", nil)
T("Dirtyhanded Gochakzuk", "Davoi", 5)
L("Blubbery Bulge", "Davoi", nil)
-- ID 150 Monastic Cavern
T("Orcish Warlord", "Monastic Cavern", 20, 20)
T("Orcish Overlord", "Monastic Cavern", 1260, 1440)
L("Overlord Bakgodek", "Monastic Cavern", {"Orcish Overlord"})
T("Orcish Hexspinner", "Monastic Cavern", 20, 20)
-- ID 151 Castle Oztroja
T("Yagudo Templar", "Castle Oztroja", 20, 20)
T("Saa Doyi the Fervid", "Castle Oztroja", 60, 90)
T("Lii Jixa the Somnolist", "Castle Oztroja", 90, 90)
T("Warder Partisan", "Castle Oztroja")
L("Tzee Xicu the Manifest", "Castle Oztroja", nil)
T("Yagudo Avatar", "Castle Oztroja", 1260, 1440)
T("Yagudo High Priest", "Castle Oztroja", 25, 25)
L("Quu Domi the Gallant", "Castle Oztroja", nil)
L("Mee Deggi the Punisher", "Castle Oztroja", nil)
L("Yaa Haqa the Profane", "Castle Oztroja", nil)
-- ID 153 The Boyahda Tree
L("Leshonki", "The Boyahda Tree", {"Boyahda Sapling"})
L("Unut", "The Boyahda Tree", {"Moss Eater"})
L("Ellyllon", "The Boyahda Tree", {"Death Cap"})
T("Ancient Goobbue", "The Boyahda Tree", 1260, 1440)
L("Voluptuous Vivian", "The Boyahda Tree", {"Demonic Rose"})
L("Aquarius", "The Boyahda Tree", {"Robber Crab"})
-- ID 157 Middle Delkfutt's Tower
L("Rhoitos", "Middle Delkfutt's Tower", nil)
L("Polybotes", "Middle Delkfutt's Tower", nil)
L("Ophion", "Middle Delkfutt's Tower", nil)
L("Rhoikos", "Middle Delkfutt's Tower", nil)
L("Ogygos", "Middle Delkfutt's Tower", nil)
L("Eurytos", "Middle Delkfutt's Tower", nil)
-- ID 158 Upper Delkfutt's Tower
T("Porphyrion", "Upper Delkfutt's Tower", 5, 10)
T("Mimas", "Upper Delkfutt's Tower", 15, 15)
L("Ixtab", "Upper Delkfutt's Tower", {"Phasma"})
L("Enkelados", "Upper Delkfutt's Tower", {"Gigas Bonecutter"})
T("Autarch", "Upper Delkfutt's Tower", 30, 180)
-- ID 159 Temple of Uggalepih
L("Sozu Sarberry", "Temple of Uggalepih", nil)
L("Sozu Terberry", "Temple of Uggalepih", nil)
T("Manipulator", "Temple of Uggalepih", 120, 120)
L("Tonberry Kinq", "Temple of Uggalepih", nil)
T("Bonze Marberry", "Temple of Uggalepih", 5, 5)
L("Flauros", "Temple of Uggalepih", nil)
-- ID 160 Den of Rancor
L("Tawny-fingered Mugberry", "Den of Rancor", {"Tonberry Slasher"})
T("Tonberry Decapitator", "Den of Rancor", 24, 24)
T("Tonberry Tracker", "Den of Rancor", 24, 24)
T("Tonberry Pontifex", "Den of Rancor", 1260, 1440)
L("Ogama", "Den of Rancor", {"Doom Toad"})
L("Sozu Bliberry", "Den of Rancor", {"Tonberry Imprecator"})
L("Celeste-eyed Tozberry", "Den of Rancor", {"Tonberry Trailer"})
L("Friar Rush", "Den of Rancor", {"Bifrons"})
L("Bistre-hearted Malberry", "Den of Rancor", {"Tonberry Beleaguerer"})
L("Carmine-tailed Janberry", "Den of Rancor", {"Tonberry Imprecator"})
-- ID 161 Castle Zvahl Baileys
T("Marquis Naberius", "Castle Zvahl Baileys", 60, 120)
T("Marquis Amon", "Castle Zvahl Baileys", 1260, 1440)
T("Marquis Allocen", "Castle Zvahl Baileys", 1260, 1440)
L("Marquis Sabnock", "Castle Zvahl Baileys", {"Abyssal Demon", "Doom Demon", "Blood Demon"})
T("Duke Haborym", "Castle Zvahl Baileys", 1260, 1440)
T("Grand Duke Batym", "Castle Zvahl Baileys", 1260, 1440)
-- ID 162 Castle Zvahl Keep
L("Viscount Morax", "Castle Zvahl Keep", {"Demon Warlock"})
L("Baronet Romwe", "Castle Zvahl Keep", {"Demon Pawn"})
L("Count Bifrons", "Castle Zvahl Keep", {"Demon Knight"})
L("Baron Vapula", "Castle Zvahl Keep", {"Demon Wizard"})
-- ID 164 Garlaige Citadel [S]
T("Buarainech", "Garlaige Citadel [S]", 240)
T("Elatha", "Garlaige Citadel [S]", 240, 300)
-- ID 166 Ranguemont Pass
T("Mucoid Mass", "Ranguemont Pass", 90, 100)
L("Gloom Eye", "Ranguemont Pass", nil)
-- ID 167 Bostaunieux Oubliette
T("Phanduron the Condemned", "Bostaunieux Oubliette", 3600, 4320)
T("Drexerion the Condemned", "Bostaunieux Oubliette", 3600, 4320)
L("Manes", "Bostaunieux Oubliette", {"Gespenst"})
L("Shii", "Bostaunieux Oubliette", {"Garm"})
L("Arioch", "Bostaunieux Oubliette", {"Werebat"})
L("Sewer Syrup", "Bostaunieux Oubliette", {"Mousse"})
-- ID 169 Toraimarai Canal
T("Oni Carcass", "Toraimarai Canal", 1260, 1440)
T("Brazen Bones", "Toraimarai Canal")
T("Hinge Oil", "Toraimarai Canal", 16, 16)
L("Konjac", "Toraimarai Canal", {"Mousse"})
L("Canal Moocher", "Toraimarai Canal", nil)
-- ID 171 Crawlers' Nest [S]
L("Morille Mortelle", "Crawlers' Nest [S]", {"Witch Hazel"})
L("Abatwa", "Crawlers' Nest [S]", {"Witch Hazel"})
T("Lugh", "Crawlers' Nest [S]", 240, 300)
-- ID 173 Korroloka Tunnel
L("Falcatus Aranei", "Korroloka Tunnel", {"Huge Spider"})
L("Dame Blanche", "Korroloka Tunnel", {"Bogy"})
T("Thoon", "Korroloka Tunnel", 60, 60)
L("Cargo Crab Colin", "Korroloka Tunnel", {"Clipper"})
-- ID 174 Kuftal Tunnel
L("Yowie", "Kuftal Tunnel", {"Deinonychus"})
L("Bloodthirster Madkix", "Kuftal Tunnel", {"Goblin Mercenary"})
L("Arachne", "Kuftal Tunnel", {"Recluse Spider"})
L("Sabotender Mariachi", "Kuftal Tunnel", {"Sabotender Sediendo"})
T("Guivre", "Kuftal Tunnel", 1260, 1440)
L("Pelican", "Kuftal Tunnel", {"Greater Cockatrice"})
L("Amemet", "Kuftal Tunnel", {"Sand Lizard"})
-- ID 175 The Eldieme Necropolis [S]
T("Ethniu", "The Eldieme Necropolis [S]", 240, 300)
T("Tethra", "The Eldieme Necropolis [S]")
-- ID 176 Sea Serpent Grotto
L("Wuur the Sandcomber", "Sea Serpent Grotto", {"Spring Sahagin"})
L("Yarr the Pearleyed", "Sea Serpent Grotto", {"Lagoon Sahagin"})
L("Charybdis", "Sea Serpent Grotto", {"Devil Manta"})
L("Voll the Sharkfinned", "Sea Serpent Grotto", {"Marsh Sahagin"})
L("Zuug the Shoreleaper", "Sea Serpent Grotto", {"Sahagin"})
L("Worr the Clawfisted", "Sea Serpent Grotto", {"Marsh Sahagin", "Bog Sahagin", "Swamp Sahagin"})
L("Qull the Shellbuster", "Sea Serpent Grotto", {"Brook Sahagin"})
L("Masan", "Sea Serpent Grotto", {"Royal Leech"})
L("Mouu the Waverider", "Sea Serpent Grotto", {"Bog Sahagin"})
L("Fyuu the Seabellow", "Sea Serpent Grotto", {"Riparian Sahagin"})
T("Coral Sahagin", "Sea Serpent Grotto", 16, 21)
L("Denn the Orcavoiced", "Sea Serpent Grotto", {"Coastal Sahagin"})
L("Sea Hog", "Sea Serpent Grotto", {"Razorjaw Pugil"})
T("Abyss Sahagin", "Sea Serpent Grotto", 16, 21)
T("Ocean Sahagin", "Sea Serpent Grotto", 1260, 1440)
T("Novv the Whitehearted", "Sea Serpent Grotto", 120)
L("Pahh the Gullcaller", "Sea Serpent Grotto", {"Bog Sahagin"})
-- ID 177 Ve'Lugannon Palace
T("Zipacna", "Ve'Lugannon Palace", 120, 240)
-- ID 178 The Shrine of Ru'Avitau
T("Faust", "The Shrine of Ru'Avitau", 180, 240)
T("Mother Globe", "The Shrine of Ru'Avitau", 180, 360)
-- ID 184 Lower Delkfutt's Tower
L("Hippolytos", "Lower Delkfutt's Tower", {"Gigas"})
T("Tyrant", "Lower Delkfutt's Tower")
L("Eurymedon", "Lower Delkfutt's Tower", {"Giant Sentry"})
L("Epialtes", "Lower Delkfutt's Tower", {"Gigas"})
-- ID 190 King Ranperre's Tomb
T("Vrtra", "King Ranperre's Tomb", 4320, 7200)
L("Crypt Ghost", "King Ranperre's Tomb", {"Tomb Bat"})
L("Gwyllgi", "King Ranperre's Tomb", {"Nachzehrer"})
T("Cemetery Cherry", "King Ranperre's Tomb", 3600, 4320)
-- ID 191 Dangruf Wadi
L("Geyser Lizard", "Dangruf Wadi", nil)
-- ID 192 Inner Horutoto Ruins
T("Maltha", "Inner Horutoto Ruins", 90, 120)
-- ID 193 Ordelle's Caves
T("Bombast", "Ordelle's Caves", 90, 90)
T("Morbolger", "Ordelle's Caves", 60, 120)
-- ID 194 Outer Horutoto Ruins
T("Bomb King", "Outer Horutoto Ruins", 8, 8)
T("Legalox Heftyhind", "Outer Horutoto Ruins", 10, 10)
T("Doppelganger Gog", "Outer Horutoto Ruins", 8, 8)
T("Doppelganger Dio", "Outer Horutoto Ruins", 8, 8)
-- ID 195 The Eldieme Necropolis
L("Cwn Cyrff", "The Eldieme Necropolis", nil)
-- ID 196 Gusgen Mines
L("Wounded Wurfel", "Gusgen Mines", nil)
L("Pulverized Pfeffer", "Gusgen Mines", nil)
T("Foul Meat", "Gusgen Mines", 1440, 2160)
T("Juggler Hecatomb", "Gusgen Mines", 1260, 1440)
L("Smothered Schmidt", "Gusgen Mines", nil)
-- ID 197 Crawlers' Nest
T("Dynast Beetle", "Crawlers' Nest", 90, 120)
L("Demonic Tiphia", "Crawlers' Nest", nil)
-- ID 198 Maze of Shakhrami
T("Argus", "Maze of Shakhrami", 60, 120)
T("Leech King", "Maze of Shakhrami", 60, 120)
-- ID 200 Garlaige Citadel
T("Old Two-Wings", "Garlaige Citadel", 1260, 1440)
L("Hazmat", "Garlaige Citadel", {"Explosure"})
T("Skewer Sam", "Garlaige Citadel", 1260, 1440)
T("Serket", "Garlaige Citadel", 1260, 1440)
T("Frogamander", "Garlaige Citadel", 120, 120)
-- ID 204 Fei'Yin
T("Capricious Cassie", "Fei'Yin", 120)
T("Jenglot", "Fei'Yin", 120, 120)
L("Goliath", "Fei'Yin", {"Colossus"})
L("Northern Shadow", "Fei'Yin", {"Specter"})
L("Mind Hoarder", "Fei'Yin", {"Clockwork Pod"})
L("Southern Shadow", "Fei'Yin", {"Specter"})
L("Western Shadow", "Fei'Yin", {"Specter"})
L("Eastern Shadow", "Fei'Yin", {"Specter"})
-- ID 205 Ifrit's Cauldron
L("Vouivre", "Ifrit's Cauldron", {"Hurricane Wyvern"})
L("Tyrannic Tunnok", "Ifrit's Cauldron", {"Sulfur Scorpion"})
T("Ash Dragon", "Ifrit's Cauldron", 4320, 4320)
L("Foreseer Oramix", "Ifrit's Cauldron", {"Goblin Alchemist"})
L("Lindwurm", "Ifrit's Cauldron", {"Eotyrannus"})
-- ID 208 Quicksand Caves
L("Sagittarius X-XIII", "Quicksand Caves", {"Antican Princeps"})
L("Triarius X-XV", "Quicksand Caves", {"Antican Triarius"})
L("Sabotender Bailarin", "Quicksand Caves", {"Sabotender Bailaor"})
T("Proconsul XII", "Quicksand Caves", 120, 120)
L("Sabotender Bailarina", "Quicksand Caves", {"Spelunking Sabotender"})
L("Hastatus XI-XII", "Quicksand Caves", {"Antican Triarius"})
L("Nussknacker", "Quicksand Caves", {"Sand Lizard"})
T("Antican Consul", "Quicksand Caves", 1260, 1440)
T("Antican Legatus", "Quicksand Caves", 20, 20)
L("Antican Praefectus", "Quicksand Caves", {"Antican Princeps"})
L("Antican Magister", "Quicksand Caves", {"Antican Hastatus"})
T("Antican Praetor", "Quicksand Caves", 20, 20)
L("Antican Proconsul", "Quicksand Caves", {"Antican Signifer"})
L("Centurio X-I", "Quicksand Caves", {"Antican Signifer"})
L("Diamond Daig", "Quicksand Caves", {"Helm Beetle"})
L("Antican Tribunus", "Quicksand Caves", {"Antican Aedilis"})
-- ID 212 Gustav Tunnel
T("Bune", "Gustav Tunnel", 1260, 1440)
L("Goblinsavior Heronox", "Gustav Tunnel", {"Goblin Reaper"})
L("Amikiri", "Gustav Tunnel", {"Antares"})
L("Wyvernpoacher Drachlox", "Gustav Tunnel", {"Goblin Mercenary"})
L("Baobhan Sith", "Gustav Tunnel", {"Erlik"})
L("Ungur", "Gustav Tunnel", {"Typhoon Wyvern"})
L("Taxim", "Gustav Tunnel", {"Doom Warlock"})
-- ID 213 Labyrinth of Onzozo
L("Peg Powler", "Labyrinth of Onzozo", nil)
L("Lord of Onzozo", "Labyrinth of Onzozo", nil)
T("Mysticmaker Profblix", "Labyrinth of Onzozo", 120, 150)
L("Narasimha", "Labyrinth of Onzozo", nil)
L("Hellion", "Labyrinth of Onzozo", nil)
L("Ose", "Labyrinth of Onzozo", nil)
L("Soulstealer Skullnix", "Labyrinth of Onzozo", nil)
-- ID 215 Abyssea - Attohwa
T("Tejas", "Abyssea - Attohwa", 20, 20)
T("Amun", "Abyssea - Attohwa", 10, 15)
T("Whiro", "Abyssea - Attohwa", 10, 15)
T("Aggressor Antlion", "Abyssea - Attohwa", 10, 15)
T("Warbler", "Abyssea - Attohwa", 10, 15)
T("Gieremund", "Abyssea - Attohwa", 10, 15)
T("Tunga", "Abyssea - Attohwa", 10, 15)
T("Ironclad Cleaver", "Abyssea - Attohwa", 10, 15)
-- ID 216 Abyssea - Misareaux
T("Abyssic Cluster", "Abyssea - Misareaux", 10, 15)
T("Kutharei", "Abyssea - Misareaux", 20, 60)
T("Asanbosam", "Abyssea - Misareaux", 10, 15)
T("Gukumatz", "Abyssea - Misareaux", 10, 15)
T("Heqet", "Abyssea - Misareaux", 10, 15)
T("Flame Skimmer", "Abyssea - Misareaux", 10, 15)
T("Athamas", "Abyssea - Misareaux", 10, 15)
T("Jala", "Abyssea - Misareaux", 20, 20)
-- ID 217 Abyssea - Vunkerl
T("Div-e Sepid", "Abyssea - Vunkerl", 10, 15)
T("Fulmotondro", "Abyssea - Vunkerl", 20, 20)
T("Lord Varney", "Abyssea - Vunkerl", 10, 15)
T("Hanuman", "Abyssea - Vunkerl", 10, 15)
T("Ayravata", "Abyssea - Vunkerl", 10, 15)
T("Iktomi", "Abyssea - Vunkerl", 10, 15)
T("Ironclad Executioner", "Abyssea - Vunkerl", 10, 15)
T("Hrosshvalur", "Abyssea - Vunkerl", 10, 15)
-- ID 218 Abyssea - Altepa
T("Hedjedjet", "Abyssea - Altepa", 10, 15)
T("Ouzelum", "Abyssea - Altepa", 10, 15)
T("Ansherekh", "Abyssea - Altepa", 10, 15)
T("Cuijatender", "Abyssea - Altepa", 10, 20)
T("Hazhdiha", "Abyssea - Altepa", 10, 15)
T("Battlerigged Chariot", "Abyssea - Altepa", 10, 15)
T("Long-Barreled Chariot", "Abyssea - Altepa", 10, 15)
-- ID 253 Abyssea - Uleguerand
T("Kur", "Abyssea - Uleguerand", 10, 15)
T("Sisyphus", "Abyssea - Uleguerand", 10, 15)
T("Refitted Chariot", "Abyssea - Uleguerand", 10, 15)
T("Indrik", "Abyssea - Uleguerand", 10, 15)
T("Empousa", "Abyssea - Uleguerand", 10, 15)
T("Awahondo", "Abyssea - Uleguerand", 10, 15)
T("Impervious Chariot", "Abyssea - Uleguerand", 10, 15)
-- ID 254 Abyssea - Grauberg
T("Melo Melo", "Abyssea - Grauberg", 10, 15)
T("Jaculus", "Abyssea - Grauberg", 10, 15)
T("Fuath", "Abyssea - Grauberg", 10, 15)
T("Rencounter Chariot", "Abyssea - Grauberg", 10, 15)
T("Deelgeed", "Abyssea - Grauberg", 10, 15)
T("Assailer Chariot", "Abyssea - Grauberg", 10, 15)
T("Fleshflayer Killakriq", "Abyssea - Grauberg", 10, 15)
-- ID 260 Yahse Hunting Grounds
T("Startled Uragnite", "Yahse Hunting Grounds")
-- ID 263 Yorcia Weald
T("Voracious Rafflesia", "Yorcia Weald", 20)
-- ID 274 Outer Ra'Kaznar
T("Suspended Sculpture", {"Outer Ra'Kaznar", "Ra'Kaznar Inner Court"})

return data
