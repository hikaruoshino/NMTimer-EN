-- =============================================================================
-- NMTimer.lua : NM respawn timer (v0.6.0, English edition)
-- =============================================================================
-- Purpose:
-- When an NM from a Magian trial (Empyrean weapon trials) is killed, remember when and where,
-- and show the time left until it can spawn again on a small HUD. Even if someone else killed it
-- before you got there, you can aim for the next spawn if you know when and where it died.
--
-- What it counts:
--   - lottery : the NM spawns when a PH is killed. For a fixed time after the NM dies, no lottery runs.
--                         That waiting time is what is counted
--   - timed   : respawns a fixed time after being killed (Abyssean NMs etc.)
--   Bundled NMs are in nm_data.lua and nm_data_bgwiki.lua. NMs you add yourself are saved in data/user.lua (//nmt add)
--
-- How it works:
--   - The enemy update packet (0x00E) tells it when an enemy has died (status 2 or 3). Only kills within your own
--     view range are seen. For a kill you did not see, enter it by hand with //nmt tod after hearing about it (shout etc.)
--   - It only receives. It never sends anything to the game server
--   - Time is real time (os.time), so counting continues across logout and zone changes (saved in data/state.lua)
--   - The kill position is remembered. If an enemy with the same name appears again in the same zone, the time it took
--     is remembered as a measurement (only if you stayed in the zone the whole time)
--   - A PH also remembers its kill time and enemy ID. An enemy ID is fixed per spawn point, so the gap until the same ID
--     appears again is a measurement of that PH's respawn time. Measurements are kept per ID and zone, up to 10.
--     If the ID has measurements, they are used (individual PHs can differ); otherwise the median for the zone is used.
--     However many PHs there are (e.g. one of two PHs with different IDs is the lottery target), //nmt ph registers any number.
--     If a non-PH enemy was counted by mistake, //nmt ph del removes it
--   - The bundled data holds no enemy IDs. When an update carrying a name arrives (an enemy appears) and it matches a registered NM,
--     its ID is remembered (only while you are in that zone; dropped if a different name shows up on the same ID). If the name cannot
--     be read when it dies, an NM with a remembered ID is still recorded
--   - An NM with no known time (no number on BG-Wiki) gets its time from measurements (lottery: the shortest, timed: the median;
--     measurements under 3 minutes are not used). A record that stays time-unknown is kept on the HUD for 3 hours.
--     PHs in the BG-Wiki data are not counted until you mark one with //nmt ph
--
-- Encoding:
--   - HUD (libs/texts.lua) : UTF-8
--   - Chat (windower.add_to_chat) : plain ASCII (English client), no conversion
-- =============================================================================

_addon.name     = "NMTimer"
_addon.author   = "hikaruoshino"
_addon.version  = "0.6.3"
_addon.commands = {"nmtimer", "nmt"}

local config = require("config")
local texts  = require("texts")
local res    = require("resources")

-- -----------------------------------------------------------------------------
-- Settings (data/settings.xml)
-- -----------------------------------------------------------------------------
local defaults = {}
defaults.pos = {x = 40, y = 300}
defaults.text = {font = "Arial", size = 10, alpha = 255}
defaults.bg = {alpha = 180, red = 10, green = 10, blue = 15}
defaults.padding = 6
defaults.show = true        -- show the HUD
defaults.sound = true       -- play a sound (when sounds/ready.wav exists)
defaults.chat = true        -- also print notices to the chat log
defaults.lead_min = 5       -- minutes before it can spawn to notify (0 = no early notice)
defaults.expire_min = 30    -- minutes to keep an entry on the HUD after it can spawn
defaults.coord = true       -- show the kill position and distance on the HUD (turn off if lines get cut off)
defaults.debug = false      -- print the names of dead enemies to chat (for finding aliases)

local settings = config.load(defaults)

local DATA_DIR   = windower.addon_path .. "data/"
local STATE_FILE = DATA_DIR .. "state.lua"
local USER_FILE  = DATA_DIR .. "user.lua"
local SOUND_FILE = windower.addon_path .. "sounds/ready.wav"

local DEAD_STATUS = {[2] = true, [3] = true}   -- enemy status: 2 / 3 = dead (same handling as BanishgaPull)
local SIGHT_MIN_SEC = 60                       -- an enemy seen sooner than this after the kill is not counted as a respawn
local PH_NEAR_SQ = 50 * 50                     -- range in which PH kills are remembered (50 yalms from you; the distance arrives squared; not used for PHs set with //nmt ph)
local PH_SIGHT_MIN_SEC = 30                    -- a PH seen sooner than this after its kill is not counted as a respawn
local PH_SLOT_KEEP_SEC = 3 * 3600              -- how long a PH record is kept (older ones are not used for measurements either)
local REFRESH_SEC = 0.5
local LEARN_MIN_SEC = 180                          -- lower limit of a measurement used for learning. Stops a short value (just seeing another enemy of the same name soon after the kill) from fixing a too-short time
local ALIVE_KEEP_SEC = 120                -- how long after the last living-state update a dead-state update still counts as a kill (older = not seen alive)
local ALIVE_LIMIT = 4000                 -- cap for alive_seen (when exceeded only the old entries are dropped)
local UNKNOWN_KEEP_SEC = 3 * 3600                  -- how long a record of an NM with an unknown time stays on the HUD (it has no end unless you see it spawn, so it gets a limit)
local SAVED_LIMIT = 5000                 -- most records / learned entries / user NMs read from a save (a damaged or oversized save must not slow things down)
local MEASURE_KEEP = 5                   -- measurements kept per NM
local PH_MEASURE_KEEP = 10               -- measurements kept per PH
local SAVE_RETRY_SEC = 5                 -- when saving after a display update removed a record fails, seconds until the next try
local FUTURE_SLACK_SEC = 300             -- a record whose time (at) is later than now by more than this is not used (PC clock set back, damaged save)
local BROKEN_KEEP = 5                    -- unreadable files (.broken-<date>) kept per save file, newest first
local LOGIN_CHECK_SEC = 1                -- while logged out, how often to check whether we are logged in (in case no login event comes)

-- -----------------------------------------------------------------------------
-- Small helpers
-- -----------------------------------------------------------------------------
local function sjis(str)
    if not str then return "" end
    return str   -- English client: plain ASCII, no Shift-JIS conversion
end

local function chat(text, color)
    windower.add_to_chat(color or 207, sjis(text))
end

local function color_text(str, r, g, b)
    return string.format("\\cs(%d,%d,%d)%s\\cr", r, g, b, tostring(str or ""))
end

-- Format an enemy ID: decimal plus the in-zone number (low 12 bits) in hex, so it can be matched against map tools
local function id_tag(id)
    return string.format("%d / 0x%X", id, id % 4096)
end
local function id_tags(ids)
    local t = {}
    for i, id in ipairs(ids) do t[i] = id_tag(id) end
    return t
end

local function fmt_time(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function clock_text(t)
    return os.date("%H:%M", t)
end

-- Write a table out (numbers, strings, booleans and nested tables only)
local function serialize(v, indent)
    indent = indent or ""
    local kind = type(v)
    if kind == "number" then return string.format("%.14g", v) end
    if kind == "boolean" then return tostring(v) end
    if kind == "string" then return string.format("%q", v) end
    if kind ~= "table" then return "nil" end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)
    local inner = indent .. "    "
    local lines = {}
    for _, k in ipairs(keys) do
        local key
        if type(k) == "number" then
            key = "[" .. string.format("%.14g", k) .. "]"
        elseif tostring(k):match("^[%a_][%w_]*$") then
            key = k
        else
            key = "[" .. string.format("%q", k) .. "]"
        end
        lines[#lines + 1] = inner .. key .. " = " .. serialize(v[k], inner)
    end
    if #lines == 0 then return "{}" end
    return "{\n" .. table.concat(lines, ",\n") .. "\n" .. indent .. "}"
end

local function read_table(path)
    local chunk = loadfile(path)
    if not chunk then return nil end
    setfenv(chunk, {})
    local ok, tbl = pcall(chunk)
    if ok and type(tbl) == "table" then return tbl end
    return nil
end

local function file_present(path)
    local f = io.open(path, "rb")
    if not f then return false end
    f:close()
    return true
end

local function read_text(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- The name an unreadable file is kept under (path.broken-<date>). A second one in the same second gets -02, -03, ... so it
-- does not collide with the first
local function broken_name(path)
    local base = path .. ".broken-" .. os.date("%Y%m%d-%H%M%S", os.time())
    if not file_present(base) then return base end
    for n = 2, 99 do
        local name = string.format("%s-%02d", base, n)
        if not file_present(name) then return name end
    end
    return nil
end

-- Keep only the newest BROKEN_KEEP .broken- files of path (ordered by the date in the name; only names in our own format)
local function prune_broken(path)
    if type(windower.get_dir) ~= "function" then return end
    local dir, file = path:match("^(.*)[/\\]([^/\\]+)$")
    if not dir then return end
    local ok, list = pcall(windower.get_dir, dir)
    if not ok or type(list) ~= "table" then return end
    local prefix = file .. ".broken-"
    local found = {}
    for _, name in pairs(list) do
        if type(name) == "string" and name:sub(1, #prefix) == prefix
                and name:sub(#prefix + 1):find("^%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d") then
            found[#found + 1] = name
        end
    end
    if #found <= BROKEN_KEEP then return end
    table.sort(found)                               -- date order (-02 ... of the same second come after it)
    for i = 1, #found - BROKEN_KEEP do os.remove(dir .. "/" .. found[i]) end
end

-- Paths whose unreadable file could not be renamed. Saving must not rotate such a file into .bak (that would drop a good .bak)
local broken_left = {}

-- Saving goes through a temporary file (.tmp) in the same folder. The write and the close must both succeed and the
-- file must read back intact before it takes the real name, so a full disk or a crash mid-save never costs the last
-- good save. os.rename on Windows cannot replace an existing file, so the current file is moved to .prev, the temporary
-- file takes the real name, and only then does .prev become .bak (the previous save).
-- A good .bak is never deleted before the new file is in place (whichever step fails, the real file or .bak can restore it).
-- If the swap is cut off halfway, loading falls back to .prev and .bak.
-- Returns: success, reason for failure
local function write_table(path, tbl)
    local text = "return " .. serialize(tbl) .. "\n"
    local tmp, prev, bak = path .. ".tmp", path .. ".prev", path .. ".bak"
    local f, err = io.open(tmp, "w")
    if not f then return false, err end
    local wrote, werr = f:write(text)
    local closed, cerr = f:close()
    if not wrote or not closed then
        os.remove(tmp)
        return false, werr or cerr or "write failed"
    end
    if read_text(tmp) ~= text or not read_table(tmp) then
        os.remove(tmp)
        return false, "verify failed: " .. tmp
    end
    if broken_left[path] then
        -- the unreadable file is still there: moving it to .prev / .bak would drop the good .bak, so rename it again or delete it
        local name = broken_name(path)
        if not (name and os.rename(path, name)) then os.remove(path) end
        if file_present(path) then
            os.remove(tmp)
            return false, "could not move the unreadable " .. path
        end
        broken_left[path] = nil
    end
    local moved = false
    if file_present(path) then
        os.remove(prev)                             -- left over from an earlier cut-off save (the real file exists, so it is not needed)
        local ok, merr = os.rename(path, prev)
        if not ok then
            os.remove(tmp)
            return false, merr
        end
        moved = true
    end
    local ok, rerr = os.rename(tmp, path)
    if not ok then
        if moved then os.rename(prev, path) end     -- put the previous save back under the real name (.bak was not touched)
        os.remove(tmp)
        return false, rerr
    end
    if file_present(prev) then                      -- the new file is in place, so the previous one becomes .bak
        os.remove(bak)
        os.rename(prev, bak)                        -- if this fails, .prev stays and loading can still use it
    end
    return true
end

-- -----------------------------------------------------------------------------
-- Checking loaded tables (a file can parse and still hold values of the wrong type)
-- -----------------------------------------------------------------------------
local function finite(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end
local function opt_finite(v) return v == nil or finite(v) end
local function is_string(v) return type(v) == "string" end
local function valid_sight(v) return v == nil or v == true or v == false or v == "returned" end

-- nil, or a table whose array items all pass check
local function list_of(v, check)
    if v == nil then return true end
    if type(v) ~= "table" then return false end
    for _, x in ipairs(v) do
        if not check(x) then return false end
    end
    return true
end

-- Copy the items of a table that pass check(k, v), up to SAVED_LIMIT of them
local function keep_valid(map, check)
    local out, n = {}, 0
    for k, v in pairs(map or {}) do
        if n >= SAVED_LIMIT then break end
        if check(k, v) then out[k] = v; n = n + 1 end
    end
    return out
end

-- Whether the time at is later than now by more than FUTURE_SLACK_SEC. Such a record shows a huge remaining time, and its
-- respawn and learning never come
local function future(at, now)
    return at > now + FUTURE_SLACK_SEC
end

-- now: the current time to compare with (os.time). Omitted: now
local function valid_record(rk, r, now)
    return type(rk) == "string" and type(r) == "table" and is_string(r.key) and finite(r.zone) and finite(r.at)
        and not future(r.at, now or os.time())
        and opt_finite(r.x) and opt_finite(r.y) and opt_finite(r.z) and valid_sight(r.sight)
end

local function valid_slot(id, s, now)
    return finite(id) and type(s) == "table" and is_string(s.key) and finite(s.zone) and finite(s.at)
        and not future(s.at, now or os.time())
        and opt_finite(s.x) and opt_finite(s.y) and valid_sight(s.sight) and (s.name == nil or is_string(s.name))
end

-- Keep the measurements that pass check, at most keep of them (the newest)
local function clean_samples(list, check, keep)
    local out = {}
    for _, v in ipairs(list) do
        if check(v) then out[#out + 1] = v end
    end
    while #out > keep do table.remove(out, 1) end
    return out
end

-- A measurement is 0 seconds or more (a negative one comes from a clock that was set back)
local function valid_secs(v)
    return finite(v) and v >= 0
end

local function valid_ph_sample(smp, now)
    return type(smp) == "table" and finite(smp.id) and valid_secs(smp.secs) and opt_finite(smp.at)
        and (smp.at == nil or not future(smp.at, now or os.time()))
end

-- Check the contents of state.lua. A wrong top-level type returns nil (not used). Bad items are dropped. Missing tables become empty
local function clean_state(s)
    if type(s) ~= "table" then return nil end
    for _, field in ipairs({"records", "ph_slots", "ph_measured", "measured"}) do
        if s[field] ~= nil and type(s[field]) ~= "table" then return nil end
    end
    local now = os.time()                      -- records, PH records and measurements later than this are dropped
    -- Records: over the limit, the newest are kept
    local src, keys = s.records or {}, {}
    for rk, r in pairs(src) do
        if valid_record(rk, r, now) then keys[#keys + 1] = rk end
    end
    if #keys > SAVED_LIMIT then table.sort(keys, function(a, b) return src[a].at > src[b].at end) end
    local records = {}
    for i = 1, math.min(#keys, SAVED_LIMIT) do records[keys[i]] = src[keys[i]] end
    -- PH records: check each per-ID item inside each zone table (SAVED_LIMIT items in total)
    local ph_slots, n = {}, 0
    for rk, slots in pairs(s.ph_slots or {}) do
        if type(rk) == "string" and type(slots) == "table" then
            local kept
            for id, slot in pairs(slots) do
                if n >= SAVED_LIMIT then break end
                if valid_slot(id, slot, now) then
                    kept = kept or {}
                    kept[id] = slot
                    n = n + 1
                end
            end
            if kept then ph_slots[rk] = kept end
        end
    end
    -- Learned data (measurements)
    local ph_measured = keep_valid(s.ph_measured, function(rk, list) return type(rk) == "string" and type(list) == "table" end)
    for rk, list in pairs(ph_measured) do
        local kept = clean_samples(list, valid_ph_sample, PH_MEASURE_KEEP)
        ph_measured[rk] = #kept > 0 and kept or nil
    end
    local measured = keep_valid(s.measured, function(key, list) return type(key) == "string" and type(list) == "table" end)
    for key, list in pairs(measured) do
        local kept = clean_samples(list, valid_secs, MEASURE_KEEP)
        measured[key] = #kept > 0 and kept or nil
    end
    return {records = records, ph_slots = ph_slots, ph_measured = ph_measured, measured = measured}
end

-- An NM you added (the field types that rebuild_index, timing and ph_wait rely on)
local function valid_entry(e)
    return type(e) == "table" and is_string(e.key) and is_string(e.name)
        and list_of(e.zone_ids, finite) and list_of(e.zones, is_string) and list_of(e.alias, is_string) and list_of(e.ph, is_string)
        and opt_finite(e.min) and opt_finite(e.max) and opt_finite(e.ph_repop)
        and (e.job == nil or is_string(e.job)) and (e.hint == nil or is_string(e.hint))
end

local USER_TABLES = {"entries", "alias", "times", "ignored", "ph_ids", "ph_times", "ph_excluded"}

-- Check the contents of user.lua. A wrong top-level type returns nil (not used). Bad items are dropped. Missing tables become empty
local function clean_user(u)
    if type(u) ~= "table" then return nil end
    for _, field in ipairs(USER_TABLES) do
        if u[field] ~= nil and type(u[field]) ~= "table" then return nil end
    end
    local entries = {}
    for _, e in ipairs(u.entries or {}) do
        if #entries >= SAVED_LIMIT then break end
        if valid_entry(e) then entries[#entries + 1] = e end
    end
    local ph_ids = keep_valid(u.ph_ids, function(key, ids) return is_string(key) and type(ids) == "table" end)
    for key, ids in pairs(ph_ids) do
        ph_ids[key] = keep_valid(ids, function(id) return finite(id) end)
    end
    return {
        entries = entries,
        alias = keep_valid(u.alias, function(key, list) return is_string(key) and type(list) == "table" and list_of(list, is_string) end),
        times = keep_valid(u.times, function(key, t) return is_string(key) and type(t) == "table" and finite(t.min) and opt_finite(t.max) end),
        ignored = keep_valid(u.ignored, function(key) return is_string(key) end),
        ph_ids = ph_ids,
        ph_times = keep_valid(u.ph_times, function(key, minutes) return is_string(key) and finite(minutes) end),
        ph_excluded = keep_valid(u.ph_excluded, function(id) return finite(id) end),
    }
end

local last_error_at = {}   -- message (where) -> when it was last shown. Throttled per save file and per kind of error
-- immediate: show it now, without throttling (a failure right after a command is shown at once)
local function report_error(where, err, immediate)
    local now = os.clock()
    if not immediate and last_error_at[where] and now - last_error_at[where] < 10 then return end   -- do not fill the screen with the same error
    last_error_at[where] = now
    chat(string.format("[NMTimer] %s: %s", where, tostring(err)), 123)
end

-- -----------------------------------------------------------------------------
-- Data
-- -----------------------------------------------------------------------------
local builtin = {}          -- contents of nm_data.lua
local user = {entries = {}, alias = {}, times = {}, ignored = {}, ph_ids = {}, ph_times = {}, ph_excluded = {}}   -- data/user.lua
local state = {records = {}, ph_slots = {}, ph_measured = {}, measured = {}}   -- data/state.lua

local entries = {}          -- all NMs (bundled + user)
local by_key = {}
local name_index = {}       -- lowercase name / alias -> list of NMs
local ph_index = {}         -- lowercase PH name -> list of NMs
local zone_sets = {}       -- NM key -> set of IDs of the zones where it appears (not mixed into saved tables)
local nm_zones = {}        -- set of IDs of zones that have at least one registered NM
local zone_by_en = nil
local current_zone = 0
local state_dirty = false  -- flag: a record was removed during a display update, so save again (cleared once a save succeeds)
local logged_in = true      -- the HUD, alerts and packets are handled only while logged in (set from get_info at load, then by login / logout)
local pending_sight = false -- whether any record is waiting for a respawn measurement (keeps the per-packet check light)
local ph_pending = {}       -- ID of a PH waiting for a respawn measurement -> set of record key suffixes (rk)
local ph_told = {}          -- IDs for which a PH record was announced (do not announce the same ID again)

local function ensure_dir()
    if windower.create_dir then windower.create_dir(DATA_DIR) end
end

local function zone_id_of(name)
    if not zone_by_en then
        zone_by_en = {}
        for id, row in pairs(res.zones) do
            if type(row) == "table" and row.en then zone_by_en[row.en] = id end
        end
    end
    return zone_by_en[name]
end

local function zone_label(id)
    local row = res.zones[id]
    return row and row.en or ("Zone " .. tostring(id))
end

local function rebuild_index()
    entries, by_key, name_index, ph_index, zone_sets, nm_zones = {}, {}, {}, {}, {}, {}
    local function add_entry(e)
        if by_key[e.key] then return end
        local set = {}
        for _, z in ipairs(e.zone_ids or {}) do set[z] = true end
        for _, zname in ipairs(e.zones or {}) do
            local id = zone_id_of(zname)
            if id then set[id] = true end
        end
        zone_sets[e.key] = set
        for z in pairs(set) do nm_zones[z] = true end
        entries[#entries + 1] = e
        by_key[e.key] = e
        local function index(map, name)
            if not name or name == "" then return end
            local l = name:lower()
            map[l] = map[l] or {}
            for _, existing in ipairs(map[l]) do
                if existing == e then return end      -- if the name and an alias are the same, add only once
            end
            table.insert(map[l], e)
        end
        index(name_index, e.name)
        for _, a in ipairs(e.alias or {}) do index(name_index, a) end
        for _, a in ipairs(user.alias[e.key] or {}) do index(name_index, a) end
        for _, p in ipairs(e.ph or {}) do index(ph_index, p) end
    end
    for _, e in ipairs(builtin) do add_entry(e) end
    for _, e in ipairs(user.entries) do add_entry(e) end
end

-- immediate: report a failure without throttling (when saving from a command). Returns: whether it was saved
local function save_state(immediate)
    ensure_dir()
    local ok, err = write_table(STATE_FILE, state)
    if ok then
        state_dirty = false                    -- the current records (including removed ones) are on disk
    else
        report_error("could not save state.lua (the previous save is kept)", err, immediate)
    end
    return ok
end

-- user.lua is saved only from commands: a failure is always reported at once. Returns: whether it was saved
local function save_user()
    ensure_dir()
    local ok, err = write_table(USER_FILE, user)
    if not ok then report_error("could not save user.lua (the previous save is kept)", err, true) end
    return ok
end

-- Added to a command's result message: when the save failed, say the change is lost at the next load
local function unsaved_note(saved)
    return saved and "" or " (Could not be saved: this change is lost the next time the addon loads.)"
end

-- Return the table only if it can be read and passes the check (clean)
local function read_valid(path, clean)
    local tbl = read_table(path)
    return tbl and clean(tbl)
end

-- Read the previous save: .prev (the file before a cut-off swap) first, otherwise .bak
local function read_backup(path, clean)
    return read_valid(path .. ".prev", clean) or read_valid(path .. ".bak", clean)
end

-- Read a saved file. If it cannot be read (syntax error or wrong types), keep the damaged file under another name (.broken-<date>) first,
-- then try .bak (the previous save). Without a usable .bak, start empty (returns nil)
-- The kept name gets a number when the same second is already taken, and only the newest BROKEN_KEEP are kept. When it cannot
-- be renamed, the next save does not rotate it into .bak
local function load_saved(path, label, clean)
    broken_left[path] = nil
    if not file_present(path) then
        return read_backup(path, clean)        -- a swap cut off halfway leaves only .prev / .bak behind
    end
    local tbl = read_valid(path, clean)
    if tbl then return tbl end
    local keep = broken_name(path)
    local moved = keep ~= nil and os.rename(path, keep) and true or false
    if moved then prune_broken(path) else broken_left[path] = true end
    local backup = read_backup(path, clean)
    chat(string.format("[NMTimer] Could not read %s. %s %s", label,
        moved and ("The damaged file was kept as " .. keep:match("[^/\\]+$") .. ".")
            or "The damaged file could not be renamed (the next save tries again; the previous save (.bak) is kept).",
        backup and "Loading the previous save (.bak) instead." or "Starting with no records."), 123)
    return backup
end

local function load_all()
    builtin = {}
    -- nm_data.lua (Magian / anomaly NMs) first, then nm_data_bgwiki.lua (per zone, from BG-Wiki). The first entry with a given key wins
    for _, file in ipairs({"nm_data.lua", "nm_data_bgwiki.lua"}) do
        local chunk = loadfile(windower.addon_path .. file)
        if chunk then
            local ok, tbl = pcall(chunk)
            if ok and type(tbl) == "table" then
                for _, e in ipairs(tbl) do builtin[#builtin + 1] = e end
            end
        end
    end
    user = load_saved(USER_FILE, "user.lua", clean_user) or clean_user({})
    state = load_saved(STATE_FILE, "state.lua", clean_state) or clean_state({})
    rebuild_index()
end

-- For an NM with no time in the bundled data (BG-Wiki gives no number), decide it from the respawns you have seen.
-- Lottery: the measurement is "from the kill until it spawned after the PH was killed", so use the shortest one (the lockout is at most that).
-- Timed: the median
local median   -- defined below
local function learned_minutes(e)
    local list = state.measured[e.key]
    if not list or #list == 0 then return nil end
    local usable = {}
    for _, s in ipairs(list) do
        if s >= LEARN_MIN_SEC then usable[#usable + 1] = s end
    end
    if #usable == 0 then return nil end
    local secs
    if e.kind == "lottery" then
        for _, s in ipairs(usable) do
            if not secs or s < secs then secs = s end
        end
    else
        secs = median(usable)
    end
    return math.max(1, math.floor(secs / 60))
end

-- The time actually used (minutes). A value set by the user comes first. Returns: min, max, approx, learned
local function timing(e)
    local u = user.times[e.key]
    if u and u.min then return u.min, u.max, false, false end
    if e.min then return e.min, e.max, e.approx and true or false, false end
    local learned = learned_minutes(e)
    if learned then return learned, nil, true, true end
    return nil, nil, false, false
end

local function tracked(e)
    return not user.ignored[e.key]
end

local function rec_key(e, zone)
    return e.key .. "|" .. tostring(zone)
end

local function recount_pending()
    pending_sight = false
    for _, rec in pairs(state.records) do
        if rec.sight and rec.zone == current_zone then pending_sight = true break end
    end
    ph_pending = {}
    for rk, slots in pairs(state.ph_slots) do
        for id, slot in pairs(slots) do
            if slot.sight and slot.zone == current_zone then
                -- a PH listed under two or more NMs gives one ID several records; keep track of all of them
                local set = ph_pending[id]
                if not set then set = {}; ph_pending[id] = set end
                set[rk] = true
            end
        end
    end
end

function median(list)
    local copy = {}
    for _, v in ipairs(list) do copy[#copy + 1] = v end
    table.sort(copy)
    local n = #copy
    if n == 0 then return nil end
    if n % 2 == 1 then return copy[(n + 1) / 2] end
    return (copy[n / 2] + copy[n / 2 + 1]) / 2
end

-- PH respawn time (minutes). User-set value > median of this ID's measurements > median of this zone's measurements > bundled data.
-- Returns: minutes, source ("user" / "id" / "area" / "data"), number of measurements used
local function ph_wait(e, zone, id)
    local u = user.ph_times[e.key]
    if u then return u, "user", 0 end
    local samples = zone and state.ph_measured[rec_key(e, zone)]
    if samples and #samples > 0 then
        local mine, all = {}, {}
        for _, smp in ipairs(samples) do
            if type(smp) == "table" and smp.secs then
                all[#all + 1] = smp.secs
                if id and smp.id == id then mine[#mine + 1] = smp.secs end
            end
        end
        if #mine > 0 then return median(mine) / 60, "id", #mine end
        if #all > 0 then return median(all) / 60, "area", #all end
    end
    if e.ph_repop then return e.ph_repop, "data", 0 end
    return nil
end

-- -----------------------------------------------------------------------------
-- Records
-- -----------------------------------------------------------------------------
local function describe_wait(e)
    local min, max, approx, learned = timing(e)
    if not min then return nil end
    local text
    if max and max > min then text = string.format("%d-%d min", min, max) else text = string.format("%d min", min) end
    if learned then text = text .. " (learned)" elseif approx then text = text .. " (approx.)" end
    return text
end

-- immediate: a record made by a command (//nmt tod). A save failure is reported without throttling
local function record_kill(e, zone, x, y, z, when, immediate)
    if not tracked(e) then return end
    local rk = rec_key(e, zone)
    state.records[rk] = {key = e.key, zone = zone, at = when, x = x, y = y, z = z, sight = (zone == current_zone)}
    save_state(immediate)
    recount_pending()
    local wait = describe_wait(e)
    local label = e.kind == "lottery" and "lottery start" or "respawn"
    if wait then
        chat(string.format("[NMTimer] Recorded %s (%s). %s in %s", e.name, zone_label(zone), label, wait))
    else
        chat(string.format("[NMTimer] Recorded %s (%s). The time is unknown. It will be learned when you see it spawn (or set it with //nmt time %s <min>)", e.name, zone_label(zone), e.key), 167)
    end
end

-- name: the enemy's name checked when it died (to tell when a different enemy appears on the same ID at respawn)
local function record_ph(e, zone, id, x, y, when, name)
    if not tracked(e) then return end
    local rk = rec_key(e, zone)
    local slots = state.ph_slots[rk] or {}
    slots[id] = {key = e.key, zone = zone, at = when, x = x, y = y, sight = (zone == current_zone), name = name}
    state.ph_slots[rk] = slots
    save_state()
    recount_pending()
    if settings.chat and not ph_told[id] then
        ph_told[id] = true
        chat(string.format("[NMTimer] Recorded PH %s (ID %s) for %s. If this enemy is not a PH, use //nmt ph del %d", e.ph and e.ph[1] or "PH", id_tag(id), e.name, id), 160)
    end
end

-- A PH appeared again (same ID). Only if you kept watching since the kill, remember the elapsed time as a measurement
-- When the same ID has records under several NMs (one PH listed for two NMs), the same update handles all of them
-- name: the current enemy's name (nil if unknown). If it differs from the name at the kill, a different enemy appeared on that ID:
-- nothing is learned and the record is just removed
local function on_ph_respawn(id, when, name)
    local set = ph_pending[id]
    if not set then return end
    local changed, stale = false, false
    for rk in pairs(set) do
        local slots = state.ph_slots[rk]
        local slot = slots and slots[id]
        if not slot then
            stale = true                                     -- the record is gone: recount
        elseif name and slot.name and name:lower() ~= slot.name:lower() then
            slots[id] = nil                                  -- a different enemy: not learned as a PH respawn
            changed = true
            if next(slots) == nil then state.ph_slots[rk] = nil end
        elseif when - slot.at >= PH_SIGHT_MIN_SEC then       -- anything sooner could be an update while it is still dying
            local secs = when - slot.at
            slots[id] = nil
            changed = true
            local e = by_key[slot.key]
            if e and slot.sight == true and secs <= PH_SLOT_KEEP_SEC then
                local list = state.ph_measured[rk] or {}
                list[#list + 1] = {id = id, secs = secs, at = when}
                while #list > PH_MEASURE_KEEP do table.remove(list, 1) end
                state.ph_measured[rk] = list
                chat(string.format("[NMTimer] %s: PH (%s ID %s) respawned after about %d min (measured %s).", e.name, e.ph and e.ph[1] or "PH", id_tag(id),
                    math.floor(secs / 60 + 0.5), fmt_time(secs)))
            end
            if next(slots) == nil then state.ph_slots[rk] = nil end
        end
    end
    if changed then save_state() end
    if changed or stale then recount_pending() end
end

local function note_sighting(e, rec, rk, when)
    local secs = when - rec.at
    local list = state.measured[e.key] or {}
    list[#list + 1] = secs
    while #list > MEASURE_KEEP do table.remove(list, 1) end
    state.measured[e.key] = list
    state.records[rk] = nil
    save_state()
    recount_pending()
    chat(string.format("[NMTimer] %s appeared after about %d min (measured %s).", e.name, math.floor(secs / 60 + 0.5), fmt_time(secs)))
end

-- -----------------------------------------------------------------------------
-- Packet handling (0x00E: enemy update)
-- -----------------------------------------------------------------------------
local seen_dead = {}      -- ID of an enemy known to be dead -> time (do not count the same enemy twice)
local alive_seen = {}  -- IDs of enemies seen in a living state. An enemy whose first update says dead (an NM that has not popped yet arrives that way when you get close) is not counted as killed
local alive_n = 0

-- is the last living-state update (os.clock) within ALIVE_KEEP_SEC?
local function alive_fresh(id)
    local t = alive_seen[id]
    return t ~= nil and os.clock() - t <= ALIVE_KEEP_SEC
end

-- drop only the old entries (older than ALIVE_KEEP_SEC) and recount
local function alive_prune(now_c)
    local n = 0
    for k, t in pairs(alive_seen) do
        if now_c - t > ALIVE_KEEP_SEC then alive_seen[k] = nil else n = n + 1 end
    end
    alive_n = n
end
local nm_ids = {}         -- "zone:ID" -> NM key, learned from the name when it appears. IDs can be reused, so it is dropped when you change zones (not saved)
local nm_id_count = 0

local function nm_id_key(zone, id)
    return tostring(zone) .. ":" .. tostring(id)
end

-- Drop what the receiving side has observed (dead, alive, learned IDs). On zone change, login and logout
local function reset_observed()
    seen_dead = {}
    alive_seen = {}
    alive_n = 0
    nm_ids = {}
    nm_id_count = 0
end

local function u32(data, offset)
    local a, b, c, d = data:byte(offset, offset + 3)
    if not d then return nil end
    return a + b * 256 + c * 65536 + d * 16777216
end

-- When an NM appears (an update that carries a name) and the name matches a registered NM, remember that enemy's ID.
-- The bundled data holds no IDs (the ID is taken from the enemy you actually saw, each time it appears).
-- If the same name is in two entries for this zone, do not remember it.
-- If a different name later shows up on the same ID, forget it (list = nil means a name that is not registered)
local NM_ID_LIMIT = 3000
-- is it a readable name (letters, digits, spaces, ' - . only)? An NM update carries the name elsewhere, so unreadable bytes can appear
local function readable_name(name)
    return name ~= nil and name:find("^[%w][%w '%-%.]*$") ~= nil
end

local function learn_nm_id(list, id, name)
    if not list and next(nm_ids) == nil then return end     -- unregistered name and nothing learned: do nothing (no strings built)
    local k = nm_id_key(current_zone, id)
    local match
    for _, e in ipairs(list or {}) do
        if zone_sets[e.key][current_zone] then
            if match then match = nil break end
            match = e
        end
    end
    if not match then
        local cur = by_key[nm_ids[k]]
        if cur then -- keep it when the name in the update is merely unreadable: the enemy list has the same name, or has no info and the name is unreadable
            local mob = windower.ffxi.get_mob_by_id(id)
            if mob and mob.name then
                if mob.name:lower() == cur.name:lower() then return end
            elseif not readable_name(name) then
                return
            end
        end
        if nm_ids[k] then -- drop it when a different enemy has taken over the same ID
            nm_ids[k] = nil
            nm_id_count = nm_id_count - 1
        end
        return
    end
    if nm_ids[k] == match.key then return end
    nm_ids[k] = match.key
    nm_id_count = nm_id_count + 1
    if settings.debug then chat(string.format("[NMTimer debug] remembered the ID: %s (ID %s)", match.name, id_tag(id)), 160) end
    if nm_id_count > NM_ID_LIMIT then            -- too many: drop them and learn again
        nm_ids = {[k] = match.key}
        nm_id_count = 1
    end
end

local function on_death(id)
    if alive_seen[id] then alive_seen[id] = nil; alive_n = alive_n - 1 end
    local now_c = os.clock()
    if seen_dead[id] and now_c - seen_dead[id] < 120 then return end   -- updates for a dead enemy arrive many times, so count it once
    seen_dead[id] = now_c
    local mob = windower.ffxi.get_mob_by_id(id)
    local known = by_key[nm_ids[nm_id_key(current_zone, id)]]   -- an ID learned from its name when it appeared in this zone
    if mob and mob.is_npc == false then return end
    if not mob or not mob.name then
        -- even if the name cannot be read, record an NM whose ID we learned
        if known and zone_sets[known.key][current_zone] then record_kill(known, current_zone, nil, nil, nil, os.time()) end
        return
    end
    if settings.debug then chat(string.format("[NMTimer debug] defeated: %s (ID %s)", mob.name, id_tag(id)), 160) end
    local l = mob.name:lower()
    local when = os.time()
    learn_nm_id(name_index[l], id, mob.name)               -- learn the ID by name when it is killed (so the next appearance is recognised even if the name cannot be read)
    if settings.debug then
        -- print why nothing is recorded (name not registered / wrong zone / tracking turned off)
        local found = name_index[l]
        if not found and ph_index[l] then
            chat(string.format("[NMTimer debug]   -> '%s' is registered as a PH (respawns of PHs killed nearby are counted)", mob.name), 160)
        elseif not found then
            chat(string.format("[NMTimer debug]   -> '%s' is not a registered name (current zone ID %d)", mob.name, current_zone), 160)
        else
            for _, e in ipairs(found) do
                local why = "will be recorded"
                if not zone_sets[e.key][current_zone] then why = "wrong zone"
                elseif not tracked(e) then why = "tracking is off (//nmt on)" end
                chat(string.format("[NMTimer debug]   -> registered: %s (%s) / current zone ID %d -> %s", e.name, e.key, current_zone, why), 160)
            end
        end
    end
    for _, e in ipairs(name_index[l] or {}) do
        if zone_sets[e.key][current_zone] then
            record_kill(e, current_zone, mob.x, mob.y, mob.z, when)
        end
    end
    for _, e in ipairs(ph_index[l] or {}) do
        if zone_sets[e.key][current_zone] then
            -- if a PH was set with //nmt ph, only that enemy; otherwise any same-named enemy killed near you
            local marked = user.ph_ids[e.key]
            local counted
            if user.ph_excluded[id] then counted = false
            elseif marked and next(marked) then counted = marked[id]
            elseif e.quiet_ph then counted = false      -- PHs in the BG-Wiki data often share a name with common enemies: not counted until you mark one with //nmt ph
            else counted = type(mob.distance) == "number" and mob.distance <= PH_NEAR_SQ end   -- not counted when the distance is unknown
            if counted then record_ph(e, current_zone, id, mob.x, mob.y, when, mob.name) end
        end
    end
end

-- It was seen up after you were away (zone change, logout, unload). When it appeared is unknown, so it is neither measured nor learned: the record is just removed and you are told
local function note_returned(e, rec, rk, when)
    state.records[rk] = nil
    save_state()
    recount_pending()
    chat(string.format("[NMTimer] %s was already up when you came back (within about %d min of the kill).", e.name, math.floor((when - rec.at) / 60 + 0.5)))
end

-- hold: it cannot be decided whose respawn this is (two or more entries share the name). Nothing is learned and the record stays
local function sight_entry(e, when, hold)
    local rk = rec_key(e, current_zone)
    local rec = state.records[rk]
    if rec and future(rec.at, when) then
        -- a record later than now (the PC clock was set back): its respawn and learning never come, so remove it
        state.records[rk] = nil
        save_state()
        recount_pending()
        return
    end
    if rec and rec.sight and when - rec.at >= SIGHT_MIN_SEC then
        if rec.sight ~= true then note_returned(e, rec, rk, when)
        elseif not hold then note_sighting(e, rec, rk, when) end
    end
end

-- Whether this zone has two or more entries with this name
local function ambiguous_here(list)
    local n = 0
    for _, e in ipairs(list) do
        if zone_sets[e.key][current_zone] then
            n = n + 1
            if n > 1 then return true end
        end
    end
    return false
end

local function on_sighted(name)
    local list = name_index[name:lower()]
    if not list then return end
    local when = os.time()
    local hold = ambiguous_here(list)
    for _, e in ipairs(list) do sight_entry(e, when, hold) end
end

-- An update in a living state arrived for the first time (it popped). PH respawns and NM reappearances are judged here.
-- A named update (position and name only) also arrives when you merely get close to an enemy that has not popped, so it is not taken as a pop (confirmed in game 2026-10-31)
-- Whether the name (or one of the aliases) belongs to this NM
local function named_as(e, name)
    for _, x in ipairs(name_index[name:lower()] or {}) do
        if x == e then return true end
    end
    return false
end

local function on_alive(id, name)
    if ph_pending[id] then
        -- the current enemy's name (from the enemy list if the update's name cannot be read), checked against the PH's name at the kill
        local current = name and readable_name(name) and name or nil
        if not current then
            local mob = windower.ffxi.get_mob_by_id(id)
            if mob and mob.name and mob.name ~= "" then current = mob.name end
        end
        on_ph_respawn(id, os.time(), current)
    end
    if pending_sight then
        local known = by_key[nm_ids[nm_id_key(current_zone, id)]]
        if known then
            -- An ID learned by name when the NM was killed. Check the name of whatever holds the ID now, when it can be read,
            -- because another enemy can reuse the ID. With no readable name, the ID alone counts as a reappearance
            -- (an NM update can carry the name elsewhere)
            local current = name and readable_name(name) and name or nil
            if not current then
                local mob = windower.ffxi.get_mob_by_id(id)
                if mob and mob.name and mob.name ~= "" then current = mob.name end
            end
            if not current or named_as(known, current) then
                sight_entry(known, os.time())
                return
            end
            name = current                    -- a different name: not a reappearance by ID, and the record stays (only a lookup by the current name)
        end
        if not name then
            local mob = windower.ffxi.get_mob_by_id(id)
            name = mob and mob.name
        end
        if name and name ~= "" then on_sighted(name) end
    end
end

-- diagnostic: with debug on, show every update that arrives for an ID set by //nmt watch (not saved)
local watch_ids = {}

local function on_npc_update(data)
    if #data < 0x20 then return end
    local mask = data:byte(0x0B)
    if not mask then return end
    if settings.debug and next(watch_ids) then
        local wid = u32(data, 0x05)
        if wid and watch_ids[wid] then
            chat(string.format("[NMTimer debug] watched update: ID %s / mask %d / status %s / length %d", id_tag(wid), mask, mask % 8 >= 4 and tostring(data:byte(0x20)) or "-", #data), 160)
        end
    end
    local alive_id = nil                        -- ID of the enemy if this was a living update with HP above zero
    if mask % 8 >= 4 then                       -- bit 2: HP (0x1E) and status (0x1F) are included
        local status = data:byte(0x20)
        if status and DEAD_STATUS[status] then
            local id = u32(data, 0x05)
            if id and alive_fresh(id) then on_death(id) end      -- count only an enemy seen alive first (an NM that has not popped arrives as dead when you get close; that is not a kill)
        elseif status then
            -- the living side also needs HP above zero (0x1E = HP percent 0-100, per libs/packets/fields.lua). An HP 0 update is not taken as alive
            local hpp = data:byte(0x1F)
            local id = hpp and hpp > 0 and u32(data, 0x05)
            if id then
                alive_id = id
                local now_c = os.clock()
                local fresh = alive_seen[id] ~= nil and now_c - alive_seen[id] <= ALIVE_KEEP_SEC
                if alive_seen[id] == nil then alive_n = alive_n + 1 end
                alive_seen[id] = now_c
                if alive_n > ALIVE_LIMIT then alive_prune(now_c) end
                if not fresh then
                    local nm = mask % 16 >= 8 and #data >= 0x35 and data:sub(0x35):match("^[^%z]*") or nil
                    on_alive(id, nm)
                end
            end
        end
    end
    -- bit 3 (name) together with bit 2 (alive with HP above zero) = it respawned. If the same enemy dies again, count it again.
    -- A name-only update (no HP data) also arrives when you merely get close to an enemy that has not popped, so the dead mark stays
    if alive_id and mask % 16 >= 8 then
        seen_dead[alive_id] = nil
    end
    -- bit 3: name included (when it appears). In a zone with no registered NM the name is not read (keeps per-packet work down)
    if mask % 16 >= 8 and #data >= 0x35 and nm_zones[current_zone] then
        local name = data:sub(0x35):match("^[^%z]*")
        if name and name ~= "" then
            if nm_zones[current_zone] then
                local id = u32(data, 0x05)
                if id then learn_nm_id(name_index[name:lower()], id, name) end
            end
        end
    end
end

-- 0x02D : notice that arrives when you gain experience etc. (Target = ID of the enemy you killed; in an RoE update the Target is the player).
-- It does not arrive for every kill (an enemy only others killed, or one that gives no experience), so it is used as a supplement to 0x00E.
-- Counted only when the enemy really is dead. A repeated notice for a kill already counted (experience, limit points etc.) does not
-- overwrite the kill time (the dead mark seen_dead is cleared by a respawn update or a zone change)
local EXP_MIN_LEN = 0x1A    -- length that reaches Message (0x18-0x19, 0x02D in libs/packets/fields.lua). Shorter packets are dropped
local function on_exp_message(data)
    if #data < EXP_MIN_LEN then return end
    local target = u32(data, 0x09)
    if not target or seen_dead[target] then return end
    local mob = windower.ffxi.get_mob_by_id(target)
    if mob and mob.is_npc ~= false and ((mob.hpp or 100) == 0 or DEAD_STATUS[mob.status or -1]) then
        on_death(target)
    end
end

windower.register_event("incoming chunk", function(id, data)
    if not logged_in then return end            -- nothing that arrives while logged out is used (no save, no chat)
    local handler = id == 0x00E and on_npc_update or id == 0x02D and on_exp_message
    if not handler then return end
    local ok, err = pcall(handler, data)
    if not ok then report_error("packet handling error", err) end
end)

-- -----------------------------------------------------------------------------
-- State calculation and HUD
-- -----------------------------------------------------------------------------
-- Turn one record into {text, order, ready_at, done_at} for display
local function describe(rec, e, now)
    local min, max, approx, learned = timing(e)
    local elapsed = now - rec.at
    local mark = (learned and color_text("(learned)", 150, 150, 150)) or (approx and color_text("(approx.)", 150, 150, 150)) or ""
    local state_text, order, done_at
    if not min then
        state_text = color_text("time unknown", 180, 180, 180) .. string.format(" killed %s  //nmt time %s <min>", clock_text(rec.at), e.key)
        order = math.huge
        done_at = rec.at + UNKNOWN_KEEP_SEC
    else
        local first = min * 60
        local last = (max and max > min) and max * 60 or first
        done_at = rec.at + last + (settings.expire_min or 30) * 60
        order = rec.at + first
        local what = e.kind == "lottery" and "lottery start" or "respawn"
        if elapsed < first then
            state_text = color_text(string.format("%s in %s", what, fmt_time(first - elapsed)), 255, 220, 100) .. mark
        elseif elapsed < last then
            state_text = color_text(string.format("may appear, %s left", fmt_time(last - elapsed)), 255, 150, 60) .. mark
        else
            local ready = e.kind == "lottery" and "lottery is open" or "may be up"
            state_text = color_text(string.format("%s (+%s)", ready, fmt_time(elapsed - last)), 120, 255, 120)
        end
    end
    local where = ""
    if settings.coord and rec.x and rec.y then
        where = string.format("  (X:%d Y:%d", math.floor(rec.x + 0.5), math.floor(rec.y + 0.5))
        if rec.zone == current_zone then
            local me = windower.ffxi.get_mob_by_target("me")
            if me and me.x and me.y then
                where = where .. string.format(" %d yalms away", math.floor(math.sqrt((me.x - rec.x) ^ 2 + (me.y - rec.y) ^ 2) + 0.5))
            end
        end
        where = where .. ")"
    end
    local job = e.job and (" [" .. e.job .. "]") or ""
    local text = string.format("%s %s%s %s%s", color_text("[" .. zone_label(rec.zone) .. "]", 150, 200, 255), e.name, job, state_text, where)
    return {text = text, order = order, done_at = done_at}
end

local function build_rows(now)
    local rows = {}
    for rk, rec in pairs(state.records) do
        local e = by_key[rec.key]
        if future(rec.at, now) then
            state.records[rk] = nil               -- later than now (the PC clock was set back): it would show a huge time, so remove it
            state_dirty = true
        elseif e and tracked(e) then
            local row = describe(rec, e, now)
            if row.done_at and now >= row.done_at then
                state.records[rk] = nil           -- remove once it has been available for long enough
                state_dirty = true
            else
                rows[#rows + 1] = row
            end
        end
    end
    for rk, slots in pairs(state.ph_slots) do
        local soonest, soonest_slot, soonest_id, count = nil, nil, nil, 0
        for id, slot in pairs(slots) do
            local e = by_key[slot.key]
            if not e or now - slot.at > PH_SLOT_KEEP_SEC or future(slot.at, now) then
                slots[id] = nil                       -- discard old records (also not used for measurements) and records later than now
                state_dirty = true
            else
                local wait = ph_wait(e, slot.zone, id)
                local remain = wait and (slot.at + wait * 60 - now)
                if remain and remain > 0 then
                    count = count + 1
                    if not soonest or remain < soonest then soonest, soonest_slot, soonest_id = remain, slot, id end
                end
            end
        end
        if next(slots) == nil then state.ph_slots[rk] = nil; state_dirty = true end
        local e = soonest_slot and by_key[soonest_slot.key]
        if e and tracked(e) then
            local _, source = ph_wait(e, soonest_slot.zone, soonest_id)
            local note = (source == "id" or source == "area") and color_text("(measured)", 150, 150, 150) or ""
            local more = count > 1 and string.format(" +%d more", count - 1) or ""
            rows[#rows + 1] = {order = now + soonest, text = string.format("%s %s(%s) %s%s%s",
                color_text("[" .. zone_label(soonest_slot.zone) .. "]", 150, 200, 255), e.ph and e.ph[1] or "PH", e.name,
                color_text("PH respawn in " .. fmt_time(soonest), 255, 220, 100), note, more)}
        end
    end
    table.sort(rows, function(a, b) return a.order < b.order end)
    return rows
end

local hud = texts.new("", settings)
local last_hud_text = nil
local next_save_retry = 0   -- when saving removed records fails, the time (os.clock) of the next try

local function refresh_hud(now)
    local rows = build_rows(now)
    -- Save again after records were removed. On failure the flag (state_dirty) stays and it is retried every SAVE_RETRY_SEC seconds
    if state_dirty and os.clock() >= next_save_retry and not save_state() then
        next_save_retry = os.clock() + SAVE_RETRY_SEC
    end
    if not settings.show then
        if last_hud_text ~= "" then hud:hide() end
        last_hud_text = ""
        return
    end
    -- show a small line even with no records, so you can tell it is running
    local lines = {color_text("NMTimer", 255, 255, 255) .. (#rows == 0 and color_text("  no records (shown when an NM dies)", 150, 150, 150) or "")}
    for _, row in ipairs(rows) do lines[#lines + 1] = row.text end
    local text = table.concat(lines, "\n")
    if text ~= last_hud_text then
        hud:text(text)
        last_hud_text = text
    end
    hud:show()
end

-- -----------------------------------------------------------------------------
-- Notices (shortly before it can spawn, and when it can)
-- -----------------------------------------------------------------------------
local function play_sound()
    if settings.sound and windower.file_exists and windower.file_exists(SOUND_FILE) then
        windower.play_sound(SOUND_FILE)
    end
end

local function notify(text)
    if settings.chat then chat(text, 209) end
    play_sound()
end

local function check_alerts(now)
    for _, rec in pairs(state.records) do
        local e = by_key[rec.key]
        if e and tracked(e) then
            local min = timing(e)
            if min then
                local at = rec.at + min * 60
                local lead = (tonumber(settings.lead_min) or 0) * 60
                -- do not announce what had already passed at startup (only what passed within the last 30 seconds)
                if lead > 0 and min * 60 > lead and not rec.lead_done and now >= at - lead then
                    rec.lead_done = true
                    if now < at then notify(string.format("[NMTimer] %s (%s) in about %d min", e.name, zone_label(rec.zone), math.ceil((at - now) / 60))) end
                end
                if not rec.ready_done and now >= at then
                    rec.ready_done = true
                    if now - at < 30 then
                        notify(string.format("[NMTimer] %s(%s) %s", e.name, zone_label(rec.zone),
                            e.kind == "lottery" and "lottery is open" or "may be up"))
                    end
                end
            end
        end
    end
end

local next_refresh = 0
local next_login_check = 0
local on_login                                 -- defined below (the same work as the login event)
windower.register_event("prerender", function()
    if not logged_in then
        -- loaded while logged out, everything waits for the login event. Check get_info every second and resume when logged in
        local check_c = os.clock()
        if check_c < next_login_check then return end
        next_login_check = check_c + LOGIN_CHECK_SEC
        local info = windower.ffxi.get_info()
        if not (info and info.logged_in) then return end
        on_login()
    end
    local now_c = os.clock()
    if now_c < next_refresh then return end
    next_refresh = now_c + REFRESH_SEC
    local ok, err = pcall(function()
        local now = os.time()
        check_alerts(now)
        refresh_hud(now)
    end)
    if not ok then
        next_refresh = now_c + 5
        report_error("display error", err)
    end
end)

-- -----------------------------------------------------------------------------
-- Lifecycle
-- -----------------------------------------------------------------------------
local function update_zone()
    local info = windower.ffxi.get_info()
    current_zone = info and info.zone or 0
end

-- Mark every measurement-waiting state (sight) as "away". If it is seen afterwards the record is just removed and you are told (it is not used for measurement or learning)
local function mark_returned()
    for _, rec in pairs(state.records) do if rec.sight then rec.sight = "returned" end end
    for _, slots in pairs(state.ph_slots) do
        for _, slot in pairs(slots) do if slot.sight then slot.sight = "returned" end end
    end
end

windower.register_event("zone change", function(new_id)
    reset_observed()                           -- learned IDs are used only while you are in that zone
    -- Once you leave the zone nothing is measured (when it appeared is unknown by the time you return). If it is seen later the record is just removed
    mark_returned()
    current_zone = tonumber(new_id) or current_zone
    recount_pending()
    save_state()
end)

on_login = function()
    logged_in = true
    update_zone()
    mark_returned()                            -- we were not watching while logged out or after a crash
    reset_observed()
    recount_pending()
end
windower.register_event("login", function() on_login() end)

-- Save the settings (data/settings.xml). An error from libs/config.lua when the file cannot be written must not stop a command or shutdown.
-- Returns: whether it was saved (a failure is reported in chat)
local function save_settings()
    local ok, err = pcall(config.save, settings)
    if not ok then chat("[NMTimer] Could not save the settings (they apply only until the addon is reloaded): " .. tostring(err), 123) end
    return ok
end

local function stop()
    save_state()
    save_settings()
    if hud then hud:hide() end
end

windower.register_event("logout", function()
    logged_in = false                          -- keeps the next prerender from showing the HUD again or firing alerts, and packets from being used
    reset_observed()
    mark_returned()
    stop()
end)

windower.register_event("unload", function()
    mark_returned()
    stop()
    if hud then hud:destroy() end
end)

-- -----------------------------------------------------------------------------
-- Commands (//nmt or //nmtimer)
-- -----------------------------------------------------------------------------
local function zone_entries()
    local list = {}
    for _, e in ipairs(entries) do
        if zone_sets[e.key][current_zone] then list[#list + 1] = e end
    end
    return list
end

-- Find an NM at the start of the arguments. A number = index in this zone's list; otherwise a key or name. Returns: NM, remaining arguments
local function resolve(args)
    if #args == 0 then return nil, args end
    local n = tonumber(args[1])
    if n then
        local e = zone_entries()[n]
        if e then return e, {unpack(args, 2)} end
    end
    for count = #args, 1, -1 do
        local candidate = table.concat(args, " ", 1, count):lower()
        for _, e in ipairs(entries) do
            if e.key:lower() == candidate or e.name:lower() == candidate then
                return e, {unpack(args, count + 1)}
            end
        end
    end
    return nil, args
end

local function kind_label(e)
    return e.kind == "lottery" and "lottery" or "timed"
end

local function cmd_list(all)
    local list = all and entries or zone_entries()
    if #list == 0 then
        chat(string.format("[NMTimer] No NMs are registered for %s (add one with //nmt add; all zones: //nmt list all)", zone_label(current_zone)))
        return
    end
    chat(string.format("[NMTimer] NMs in %s:", all and "all zones" or zone_label(current_zone)))
    for i, e in ipairs(list) do
        local wait = describe_wait(e) or "time unknown"
        local flag = tracked(e) and "" or " [not tracked]"
        local job = e.job and (" [" .. e.job .. "]") or ""
        chat(string.format("  %s%s %s%s %s %s%s", all and "" or (i .. ". "), e.name, job, "(" .. kind_label(e) .. ")", wait,
            e.hint and ("/ " .. e.hint) or "", flag))
        local m = state.measured[e.key]
        if m and #m > 0 then
            local parts = {}
            for _, s in ipairs(m) do parts[#parts + 1] = string.format("%d min", math.floor(s / 60 + 0.5)) end
            chat("      measured: " .. table.concat(parts, ", "))
        end
        if e.ph then
            local ph_minutes, source, n = ph_wait(e, current_zone)
            local label = ph_minutes and string.format("%.1f min", ph_minutes):gsub("%.0 min", " min") or "unknown"
            if source == "area" then label = label .. string.format(" (median of %d measurements)", n)
            elseif source == "user" then label = label .. " (set by you)" end
            local marked = user.ph_ids[e.key] and next(user.ph_ids[e.key]) and " / PH set" or ""
            chat(string.format("      PH: %s / respawn: %s%s", table.concat(e.ph, ", "), label, marked))
        end
    end
end

local function cmd_status()
    local now = os.time()
    local rows = build_rows(now)
    if #rows == 0 then chat("[NMTimer] No records") return end
    for _, row in ipairs(rows) do
        chat("  " .. (row.text:gsub("\\cs%(%d+,%d+,%d+%)", ""):gsub("\\cr", "")), 207)
    end
end

local function cmd_ph_list()
    local any = false
    local now = os.time()
    for _, e in ipairs(zone_entries()) do
        if e.ph then
            any = true
            local rk = rec_key(e, current_zone)
            chat(string.format("[NMTimer] %s / PH: %s", e.name, table.concat(e.ph, ", ")))
            local ids = {}
            for id in pairs(user.ph_ids[e.key] or {}) do ids[#ids + 1] = id end
            table.sort(ids)
            if #ids > 0 then
                chat("      PH set: ID " .. table.concat(id_tags(ids), ", ID ") .. string.format(" (%d)", #ids))
            else
                chat("      PH set: none (every same-named enemy killed nearby is counted; set one with //nmt ph)")
            end
            local slot_ids = {}
            for id in pairs(state.ph_slots[rk] or {}) do slot_ids[#slot_ids + 1] = id end
            table.sort(slot_ids)
            for _, id in ipairs(slot_ids) do
                chat(string.format("      recording: ID %s (killed %s ago)", id_tag(id), fmt_time(now - state.ph_slots[rk][id].at)))
            end
            local per_id = {}
            for _, smp in ipairs(state.ph_measured[rk] or {}) do
                if type(smp) == "table" and smp.id then
                    per_id[#per_id + 1] = string.format("ID %s = %s", id_tag(smp.id), fmt_time(smp.secs))
                end
            end
            if #per_id > 0 then chat("      measured: " .. table.concat(per_id, ", ")) end
        end
    end
    local excluded = {}
    for id in pairs(user.ph_excluded) do excluded[#excluded + 1] = id end
    table.sort(excluded)
    if #excluded > 0 then chat("[NMTimer] IDs removed from PHs: " .. table.concat(id_tags(excluded), ", ")) end
    if not any then chat(string.format("[NMTimer] No NM with a PH in %s.", zone_label(current_zone))) end
end

local function clear_for(e)
    for rk, rec in pairs(state.records) do if rec.key == e.key then state.records[rk] = nil end end
    for rk, slots in pairs(state.ph_slots) do
        for _, slot in pairs(slots) do
            if slot.key == e.key then state.ph_slots[rk] = nil break end
        end
    end
    recount_pending()
    return save_state(true)                    -- called from commands: a failure is reported at once
end

local function need_entry(args, usage)
    local e, rest = resolve(args)
    if not e then
        chat("[NMTimer] Unknown NM. " .. usage .. " (name, key or number from //nmt list)", 123)
        return nil
    end
    return e, rest
end

local function make_key(name)
    local base = name:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if base == "" or base:find("[\128-\255]") then base = "nm" end
    local key, n = "u_" .. base, 1
    while by_key[key] do n = n + 1; key = "u_" .. base .. n end
    return key
end

local function target_name()
    local t = windower.ffxi.get_mob_by_target("t")
    return t and t.name or nil
end

local function utf8_name(raw)
    -- English client: names are plain ASCII, nothing to convert
    return raw
end

-- //nmt scan : a research command that only reads the enemy list (windower.ffxi.get_mob_array).
-- Checks whether enemies that are not drawn (Abyssean NMs etc.) are in the list with a readable name and coordinates.
--   //nmt scan           : registered NMs of this zone whose name matches (even if invisible)
--   //nmt scan all        : every enemy that is not drawn (valid_target is false), including enemies with an empty name
--   //nmt scan near [y]   : every enemy within y yalms of you (visible or not, named or not; default 60)
--   //nmt scan <name>     : enemies whose name contains the text (case-insensitive)
-- Results are also appended to data/scan.log (for later study)
local SCAN_LIMIT = 25
local function cmd_scan(args)
    local text = args[1] and table.concat(args, " "):lower() or nil
    local mode = "nm"
    local near_sq
    if text == "all" then mode = "hidden"
    elseif args[1] and args[1]:lower() == "near" then
        mode = "near"
        local m = tonumber(args[2]) or 60
        near_sq = m * m
    elseif text then mode = "text" end
    local array = windower.ffxi.get_mob_array() or {}
    local me = windower.ffxi.get_mob_by_target("me") or {}
    local found, total, hidden, nameless = {}, 0, 0, 0
    for _, mob in pairs(array) do
        if type(mob) == "table" and mob.is_npc ~= false then
            total = total + 1
            if mob.valid_target == false then hidden = hidden + 1 end
            local has_name = mob.name and mob.name ~= ""
            if not has_name then nameless = nameless + 1 end
            local hit = false
            if mode == "hidden" then
                hit = mob.valid_target == false
            elseif mode == "near" then
                hit = (mob.distance or math.huge) <= near_sq
            elseif has_name then
                local l = mob.name:lower()
                if mode == "text" then
                    hit = l:find(text, 1, true) ~= nil
                else
                    for _, e in ipairs(name_index[l] or {}) do
                        if zone_sets[e.key][current_zone] then hit = true end
                    end
                end
            end
            if hit then found[#found + 1] = mob end
        end
    end
    table.sort(found, function(a, b) return (a.distance or math.huge) < (b.distance or math.huge) end)

    local lines = {}
    lines[#lines + 1] = string.format("[NMTimer scan] %s ID %d / %d enemies in the list (%d not drawn, %d without a name) / %d matched",
        zone_label(current_zone), current_zone, total, hidden, nameless, #found)
    if me.x then
        lines[#lines + 1] = string.format("  you: X %.1f Y %.1f Z %.1f heading %s", me.x, me.y or 0, me.z or 0, tostring(me.heading))
    end
    for i, mob in ipairs(found) do
        if i > SCAN_LIMIT then
            lines[#lines + 1] = string.format("  ...and %d more (omitted; narrow it down by name: //nmt scan <name>)", #found - SCAN_LIMIT)
            break
        end
        lines[#lines + 1] = string.format("  %s ID %s dist %s X %s Y %s Z %s valid_target=%s status=%s HP=%s%%",
            (mob.name and mob.name ~= "") and utf8_name(mob.name) or "(no name)", tostring(mob.id),
            mob.distance and string.format("%.1f yalms", math.sqrt(mob.distance)) or "?",
            mob.x and string.format("%.1f", mob.x) or "?", mob.y and string.format("%.1f", mob.y) or "?",
            mob.z and string.format("%.1f", mob.z) or "?",
            tostring(mob.valid_target), tostring(mob.status), tostring(mob.hpp))
    end
    if #found == 0 then
        lines[#lines + 1] = "  No matching enemy is in the enemy list."
        if mode == "nm" then lines[#lines + 1] = "  (an invisible NM may simply not be in the list. Try again near the direction the jade pointed)" end
    else
        -- print every readable field of the first one (to find out which fields are usable)
        local keys = {}
        for k, v in pairs(found[1]) do
            if type(v) ~= "table" and type(v) ~= "function" then keys[#keys + 1] = tostring(k) .. "=" .. tostring(v) end
        end
        table.sort(keys)
        lines[#lines + 1] = "  fields (first one): " .. table.concat(keys, ", ")
    end
    for _, line in ipairs(lines) do chat(line, 207) end
    ensure_dir()
    local f = io.open(DATA_DIR .. "scan.log", "a")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        for _, line in ipairs(lines) do f:write(line .. "\n") end
        f:write("\n")
        f:close()
    end
end

local function print_help()
    chat("[NMTimer] //nmt list [all]        : list the NMs of this zone (or all)")
    chat("[NMTimer] //nmt off/on <NM>       : stop / resume tracking (it disappears from the HUD)")
    chat("[NMTimer] //nmt tod <NM> [min ago] : record a kill time by hand (for kills you did not see)")
    chat("[NMTimer] //nmt time <NM> <min> [max] : set the respawn time (reset restores it)")
    chat("[NMTimer] //nmt add [name] [min]   : add the targeted enemy (or a name)")
    chat("[NMTimer] //nmt alias <NM>         : make the targeted enemy's name an alias of that NM")
    chat("[NMTimer] //nmt remove <NM>        : remove an NM you added")
    chat("[NMTimer] //nmt clear [NM]         : clear records")
    chat("[NMTimer] //nmt ph                 : add the targeted enemy as a PH (any number). ph list / ph del [ID] / ph clear <NM>")
    chat("[NMTimer] //nmt phtime <NM> <min>  : set the PH respawn time (reset goes back to measured)")
    chat("[NMTimer] //nmt scan [all|near [y]|name] : inspect the enemy list (is an invisible NM in it? read-only)")
    chat("[NMTimer] //nmt lead <min>         : notify this many minutes before it can spawn (0 = off)")
    chat("[NMTimer] //nmt sound|chat|hud|coord on|off, //nmt pos X Y, //nmt size N, //nmt expire <min>")
    chat("[NMTimer] //nmt status             : current records  /  //nmt debug : show the names of dead enemies")
end

local function on_off(arg, current)
    if arg == "on" then return true end
    if arg == "off" then return false end
    return not current
end

windower.register_event("addon command", function(cmd, ...)
    local ok, err = pcall(function(...)
        local args = {...}
        cmd = cmd and cmd:lower() or "help"

        if cmd == "list" then
            cmd_list(args[1] and args[1]:lower() == "all")

        elseif cmd == "status" or cmd == "s" then
            cmd_status()

        elseif cmd == "off" or cmd == "on" then
            local e = need_entry(args, "//nmt " .. cmd .. " <NM>")
            if not e then return end
            if cmd == "off" then
                user.ignored[e.key] = true
                clear_for(e)
                local saved = save_user()
                chat(string.format("[NMTimer] Stopped tracking %s. To resume: //nmt on %s%s", e.name, e.key, unsaved_note(saved)))
            else
                user.ignored[e.key] = nil
                local saved = save_user()
                chat(string.format("[NMTimer] Resumed tracking %s.%s", e.name, unsaved_note(saved)))
            end

        elseif cmd == "tod" then
            local e, rest = need_entry(args, "//nmt tod <NM> [min ago]")
            if not e then return end
            local ago = (tonumber(rest[1]) or 0) * 60
            if not finite(ago) or ago < 0 then        -- a negative / infinite value would put the kill time in the future
                chat("[NMTimer] Give the minutes ago as a number of 0 or more. //nmt tod <NM> [min ago]", 123)
                return
            end
            record_kill(e, current_zone, nil, nil, nil, os.time() - ago, true)

        elseif cmd == "time" then
            local e, rest = need_entry(args, "//nmt time <NM> <min> [max]")
            if not e then return end
            if rest[1] and rest[1]:lower() == "reset" then
                user.times[e.key] = nil
                local saved = save_user()
                chat(string.format("[NMTimer] Reset the respawn time of %s to the default.%s", e.name, unsaved_note(saved)))
                return
            end
            local min, max = tonumber(rest[1]), tonumber(rest[2])
            if not min or min <= 0 then
                chat("[NMTimer] //nmt time <NM> <min> [max]  (e.g. //nmt time shoggoth 60)", 123)
                return
            end
            user.times[e.key] = {min = min, max = max and max > min and max or nil}
            local saved = save_user()
            chat(string.format("[NMTimer] Set the respawn time of %s to %s.%s", e.name, describe_wait(e), unsaved_note(saved)))

        elseif cmd == "add" then
            local name = target_name()
            local nums, words = {}, {}
            for _, a in ipairs(args) do
                if tonumber(a) then nums[#nums + 1] = tonumber(a) else words[#words + 1] = a end
            end
            local raw = #words > 0 and table.concat(words, " ") or name
            if not raw or raw == "" then
                chat("[NMTimer] Target the enemy to add, or give a name. //nmt add [name] [min]", 123)
                return
            end
            local e = {key = make_key(utf8_name(raw)), name = utf8_name(raw), alias = {raw}, kind = "timed",
                zone_ids = {current_zone}, min = nums[1], max = nums[2], user = true}
            user.entries[#user.entries + 1] = e
            local saved = save_user()
            rebuild_index()
            chat(string.format("[NMTimer] Added %s (%s / %s). It will be recorded when it dies.%s", e.name, zone_label(current_zone), describe_wait(e) or "time unknown", unsaved_note(saved)))

        elseif cmd == "alias" then
            local e = need_entry(args, "//nmt alias <NM>  (target the enemy to use as the alias first)")
            if not e then return end
            local name = target_name()
            if not name then chat("[NMTimer] Target the enemy to use as an alias.", 123) return end
            user.alias[e.key] = user.alias[e.key] or {}
            table.insert(user.alias[e.key], name)
            local saved = save_user()
            rebuild_index()
            chat(string.format("[NMTimer] Added an alias to %s: '%s'.%s", e.name, utf8_name(name), unsaved_note(saved)))

        elseif cmd == "remove" then
            local e = need_entry(args, "//nmt remove <NM>")
            if not e then return end
            if not e.user then chat("[NMTimer] Bundled NMs cannot be removed. To stop tracking one, use //nmt off", 123) return end
            for i, ue in ipairs(user.entries) do
                if ue.key == e.key then table.remove(user.entries, i) break end
            end
            clear_for(e)
            local saved = save_user()
            rebuild_index()
            chat(string.format("[NMTimer] Removed %s.%s", e.name, unsaved_note(saved)))

        elseif cmd == "clear" then
            if #args == 0 then
                state.records, state.ph_slots = {}, {}
                recount_pending()
                local saved = save_state(true)
                chat("[NMTimer] Cleared all records." .. unsaved_note(saved))
            else
                local e = need_entry(args, "//nmt clear [NM]")
                if not e then return end
                local saved = clear_for(e)
                chat(string.format("[NMTimer] Cleared the records of %s.%s", e.name, unsaved_note(saved)))
            end

        elseif cmd == "ph" then
            -- //nmt ph [add] : add the targeted enemy as a PH (any number). //nmt ph del [ID] : remove a PH. //nmt ph list : list
            local sub = args[1] and args[1]:lower()
            local function target_mob()
                local t = windower.ffxi.get_mob_by_target("t")
                if t and t.name and t.id then return t end
            end
            if sub == "list" then
                cmd_ph_list()

            elseif sub == "clear" then
                local e = need_entry({unpack(args, 2)}, "//nmt ph clear <NM>")
                if not e then return end
                user.ph_ids[e.key] = nil
                local saved = save_user()
                chat(string.format("[NMTimer] Cleared all PH settings of %s. Same-named enemies killed nearby are counted.%s", e.name, unsaved_note(saved)))

            elseif sub == "del" or sub == "remove" then
                -- a dead enemy cannot be targeted, so an ID number also works (//nmt ph list and the record notice show the ID)
                local id = tonumber(args[2])
                if not id then
                    local t = target_mob()
                    id = t and t.id
                end
                if not id then
                    chat("[NMTimer] Target the enemy to remove, or give an ID. //nmt ph del [ID]", 123)
                    return
                end
                for _, marked in pairs(user.ph_ids) do marked[id] = nil end
                for rk, slots in pairs(state.ph_slots) do
                    slots[id] = nil
                    if next(slots) == nil then state.ph_slots[rk] = nil end
                end
                for _, list in pairs(state.ph_measured) do
                    for i = #list, 1, -1 do
                        if type(list[i]) == "table" and list[i].id == id then table.remove(list, i) end
                    end
                end
                user.ph_excluded[id] = true
                ph_pending[id] = nil
                local saved_user = save_user()
                local saved = save_state(true) and saved_user
                recount_pending()
                chat(string.format("[NMTimer] Removed ID %s from the PHs (its record and measurements were also deleted). To restore it, target the enemy and use //nmt ph%s", id_tag(id), unsaved_note(saved)))

            else
                local t = target_mob()
                if not t then
                    chat("[NMTimer] Target the lottery PH and type //nmt ph (any number can be registered).", 123)
                    return
                end
                local hit = {}
                for _, e in ipairs(ph_index[t.name:lower()] or {}) do
                    if zone_sets[e.key][current_zone] then hit[#hit + 1] = e end
                end
                if #hit == 0 then
                    chat(string.format("[NMTimer] '%s' is not registered as a PH of any NM in this zone.", utf8_name(t.name)), 123)
                    return
                end
                user.ph_excluded[t.id] = nil
                for _, e in ipairs(hit) do
                    user.ph_ids[e.key] = user.ph_ids[e.key] or {}
                    user.ph_ids[e.key][t.id] = true
                    local n = 0
                    for _ in pairs(user.ph_ids[e.key]) do n = n + 1 end
                    chat(string.format("[NMTimer] %s: added this %s (ID %s) as a PH (%d set). While any is set, only the set enemies are counted.",
                        e.name, utf8_name(t.name), id_tag(t.id), n))
                end
                if not save_user() then chat("[NMTimer]" .. unsaved_note(false), 123) end
            end

        elseif cmd == "scan" then
            cmd_scan(args)

        elseif cmd == "phtime" then
            local e, rest = need_entry(args, "//nmt phtime <NM> <min>")
            if not e then return end
            if rest[1] and rest[1]:lower() == "reset" then
                user.ph_times[e.key] = nil
                local saved = save_user()
                chat(string.format("[NMTimer] Restored the PH respawn time of %s (measurements are used if there are any).%s", e.name, unsaved_note(saved)))
                return
            end
            local minutes = tonumber(rest[1])
            if not minutes or minutes <= 0 then
                chat("[NMTimer] //nmt phtime <NM> <min>  (e.g. //nmt phtime golden_bat 5. reset restores it)", 123)
                return
            end
            user.ph_times[e.key] = minutes
            local saved = save_user()
            chat(string.format("[NMTimer] Set the PH respawn time of %s to %s min.%s", e.name, tostring(minutes), unsaved_note(saved)))

        elseif cmd == "lead" then
            local n = tonumber(args[1])
            if not n or n < 0 then chat(string.format("[NMTimer] Early notice: %d min before. Usage: //nmt lead <min>", settings.lead_min)) return end
            settings.lead_min = n
            if save_settings() then chat(string.format("[NMTimer] You will be notified %d min before it can spawn.", n)) end

        elseif cmd == "expire" then
            local n = tonumber(args[1])
            if not n or n < 0 then chat(string.format("[NMTimer] HUD entries stay %d min after the spawn window opens. Usage: //nmt expire <min>", settings.expire_min)) return end
            settings.expire_min = n
            if save_settings() then chat(string.format("[NMTimer] Entries are removed from the HUD %d min after they can spawn.", n)) end

        elseif cmd == "sound" or cmd == "chat" or cmd == "hud" or cmd == "coord" then
            local field = cmd == "hud" and "show" or cmd
            settings[field] = on_off(args[1] and args[1]:lower(), settings[field])
            if save_settings() then chat(string.format("[NMTimer] %s: %s", cmd, settings[field] and "on" or "off")) end
            last_hud_text = nil

        elseif cmd == "pos" and tonumber(args[1]) and tonumber(args[2]) then
            settings.pos.x, settings.pos.y = tonumber(args[1]), tonumber(args[2])
            hud:pos(settings.pos.x, settings.pos.y)
            save_settings()

        elseif cmd == "size" and tonumber(args[1]) then
            local size = math.max(6, math.min(40, tonumber(args[1])))
            settings.text.size = size
            hud:size(size)
            save_settings()

        elseif cmd == "debug" then
            settings.debug = on_off(args[1] and args[1]:lower(), settings.debug)
            if save_settings() then chat(string.format("[NMTimer] debug: %s (prints the names of dead enemies; use it when looking for aliases)", settings.debug and "on" or "off")) end

        elseif cmd == "watch" then
            local wid = tonumber(args[1])
            if wid then
                watch_ids[wid] = not watch_ids[wid] or nil
                chat(string.format("[NMTimer] %s updates for ID %s (shown while //nmt debug is on)", watch_ids[wid] and "Watching" or "Stopped watching", id_tag(wid)))
            else
                watch_ids = {}
                chat("[NMTimer] Stopped watching everything. Usage: //nmt watch <enemy ID> (for investigation, not saved)")
            end

        else
            print_help()
        end
    end, ...)
    if not ok then report_error("command error", err) end
end)

-- -----------------------------------------------------------------------------
-- Startup
-- -----------------------------------------------------------------------------
ensure_dir()
update_zone()
do
    local info = windower.ffxi.get_info()
    logged_in = info and info.logged_in and true or false
end
load_all()
mark_returned()                                -- we were not watching while the addon was unloaded or the game was closed
recount_pending()
