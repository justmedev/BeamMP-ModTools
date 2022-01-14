local json = require("json")

-- Settings
local admins = {"117326"}
local notFoundEnabled = true
local logToConsole = true
local prefix = "/"
local banlistName = "banlist.json"
local banMessage = "You are banned: "
-- END Settings

local commands = {
  {
    ["name"]="help",
    ["description"]="Shows this",
  },
  {
    ["name"]="list",
    ["description"]="List all players on this server with their id",
  },
  {
    ["name"]="kick",
    ["description"]="Kick the specified player",
    ["usage"]="player_name [reason]",
  },
  {
    ["name"]="ban",
    ["description"]="Ban the specified player",
    ["usage"]="player_name [reason]",
  },
  {
    ["name"]="unban",
    ["description"]="Unban the specified player",
    ["usage"]="player_name",
  },
}

function LoadBanListFile ()
  local jsonFile = io.open("banlist.json", "rb")

  if jsonFile == nil then
    print(banlistName .. " is missing. Creating one for you...")
    io.open(banlistName, "w"):write("{ banned: [] }"):close()
    jsonFile = io.open(banlistName, "rb")
  end

  local content = jsonFile:read("a")
  jsonFile:close()

  return json.parse(content)
end

local banlist = LoadBanListFile()

-- Registering events
MP.RegisterEvent("onChatMessage", "HandleChatMessage")
MP.RegisterEvent("onPlayerJoin", "OnPlayerJoin")

-- Events
function OnPlayerJoin (player_id)
  local payer_name = MP.GetPlayerName(player_id)

  if ArrayContains(banlist.banned, payer_name) then
    print("Banned player '" ..  MP.GetPlayerName(player_id) .. "' Just tried to join.")
    MP.DropPlayer(player_id, "You are banned from this server.")
  end
end

function HandleChatMessage(sender_id, sender_name, message)
  -- split string at $prefix then split it at " " and put the first el of the new table in the var cmd
  if message:sub(1,1) ~= prefix then return 0 end
  local split = SplitString(message:sub(2), " ")
  local cmd = split[1]

  local args = {}
  if #split > 1 then
    table.remove(split, 1)
    args = split
  end

  local id = MP.GetPlayerIdentifiers(sender_id)
  if logToConsole then print("Player " .. sender_name .. "(" .. sender_id .. ";" .. id.beammp .. ") Just executed the command '" .. prefix .. cmd .. "'.") end

  -- check if player has rights to execute the command; if not: show help
  if ArrayContains(admins, id.beammp) == false then
    CommandNotFound(sender_id, cmd)
    return 1
  end

  if cmd == "kick" then
    local reason = "No reason specified"
    if #args < 1 then
      MP.SendChatMessage(sender_id, "Required argument player_name missing!")
      return 1
    end

    if #args > 1 then reason = table.concat(args:sub(2), " ") end

    local playerId = FindPlayerByName(args[1])

    if playerId == -1 then
      MP.SendChatMessage(sender_id, "Player '" .. args[1] .. "' not found!")
      return 1
    end

    MP.DropPlayer(playerId, reason)
    return 1

  elseif cmd == "ban" then
    local reason = "No reason specified."
    if #args < 1 then
      MP.SendChatMessage(sender_id, "Required argument player_name missing!")
      return 1
    end

    if #args > 1 then reason = table.concat(args:sub(2), " ") end

    local playerId = FindPlayerByName(args[1])

    if playerId == nil then
      MP.SendChatMessage(sender_id, "Player '" .. args[1] .. "' not found!")
      return 1
    end

    MP.DropPlayer(playerId, banMessage .. reason)

    table.insert(banlist.banned, args[1])
    SaveBanListFile()
    return 1

  elseif cmd == "unban" then
    if #args < 1 then
      MP.SendChatMessage(sender_id, "Required argument player_name missing!")
      return 1
    end

    for i, n in ipairs(banlist.banned) do
      if args[1] == n then table.remove(banlist, i) end
    end

    SaveBanListFile()
    MP.SendChatMessage("Unbanned player '" .. args[1] .. "'.")
    return 1

  elseif cmd == "list" then
    MP.SendChatMessage(sender_id, "------ [Online Players] ------")

    for id, name in pairs(MP.GetPlayers()) do
      MP.SendChatMessage(sender_id, id .. ": " .. name)
    end

    return 1

  elseif cmd == "help" then
    MP.SendChatMessage(sender_id, "------ [ModTools Help] ------")
    MP.SendChatMessage(sender_id, "Note: [...] is optional")

    for _, command in ipairs(commands) do
      local usage = ""
      if command.usage then usage = " " .. command.usage end

      local msg = prefix .. command.name .. usage .. ": " .. command.description
      MP.SendChatMessage(sender_id, msg)
    end
    return 1

  else
    -- no command found
    CommandNotFound(sender_id, cmd)
    return 1
  end
end

-- #region Helper functions
function CommandNotFound (plr, cmd) if notFoundEnabled then MP.SendChatMessage(plr, "Command '" .. cmd .. "' not found. Type " .. prefix .. "help for help!") end end

function FindPlayerByName (name)
  local players = MP.GetPlayers()
  for i, n in pairs(players) do
    if name == n then
      return i
    end
  end

  return nil
end

function SaveBanListFile ()
  local f = io.open(banlistName, "w")
  local stringified = json.stringify(banlist)
  print(stringified)
  f:write(stringified)
  f:close()
end

function SplitString (str, char)
  local res = {};
  for i in string.gmatch(str, "[^" .. char .. "]+") do
    table.insert(res, i)
  end
  return res
end

function ArrayContains (tab, val)
  for _, v in ipairs(tab) do
    if val == v then return true end
  end
  return false
end
-- #endregion
