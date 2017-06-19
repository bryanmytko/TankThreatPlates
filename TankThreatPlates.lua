local playerRole, tanks = _, {}

local frame, events = CreateFrame("frame"), {}

local color_default = {
  r = 1.0,
  b = 0.0,
  g = 0.0
}

local color_tanking_low = {
  r = 1.0,
  b = 1.0,
  g = 0.0
}

local color_tanking_mid = {
  r = 0.0,
  b = 0.0,
  g = 0.0
}

local color_tanking_high = {
  r = 0.0,
  b = 0.0,
  g = 1.0
}

local color_offtanking = {
  r = 0.5,
  b = 1.0,
  g = 0.5
}

local function updatePlayerRole()
  playerRole = GetSpecializationRole(GetSpecialization())
  print('Player Role Changed: ' .. playerRole)
end

local function findTanks()
end

local function isOffTanking(unit)
  return true
end

local function isValidThreatSituation(frame)
  local reaction = UnitReaction("player", frame.unit)

  if reaction
    and reaction < 4
    and (reaction < 5 or CompactUnitFrame_IsOnThreatListWithPlayer(frame.displayedUnit))
    and not UnitIsPlayer(frame.unit)
    and not CompactUnitFrame_IsTapDenied(frame) then

    return true
  end
end

local function resetThreat(frame)
  if frame.threat then
      frame.threat = nil
      frame.healthBar:SetStatusBarColor(
        0.9,
        0.6,
        0.0
      )
  end
end

-- 0 - Unit has less than 100% raw threat (default UI shows no indicator)
-- 1 - Unit has 100% or higher raw threat but isn't mobUnit's primary target (default UI shows yellow indicator)
-- 2 - Unit is mobUnit's primary target, and another unit has 100% or higher raw threat (default UI shows orange indicator)
-- 3 - Unit is mobUnit's primary target, and no other unit has 100% or higher raw threat (default UI shows red indicator)

local function determineThreatLevel(frame)
  local threat = UnitThreatSituation("player", unit) or 0

  if isOffTanking(unit) then threat = 4 end

  local threat_color = (({
    color_default,
    color_tanking_low,
    color_tanking_mid,
    color_tanking_high,
    color_offtanking
  })[threat + 1] or color_default)

  return threat_color
end

local function updateStatusBarColor(frame)
  local threat_color
  if isValidThreatSituation(frame) then
    threat_color = determineThreatLevel(frame)

    frame.healthBar:SetStatusBarColor(
      threat_color.r,
      threat_color.g,
      threat_color.b
    )
  end
end

frame:SetScript('OnEvent', function(self, event, ...)
  events[event](self, ...)
end)

function events:UNIT_THREAT_SITUATION_UPDATE(self, event, ...)
  if not playerRole then
    updatePlayerRole()
  end

  if playerRole == "TANK" then
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
      updateStatusBarColor(nameplate.UnitFrame)
    end
  end
end

function events:PLAYER_SPECIALIZATION_CHANGED(self, events, ...)
  updatePlayerRole()
end

function events:PLAYER_ROLES_ASSIGNED(self, event, ...)
  findTanks()
end

function events:RAID_ROSTER_UPDATE(self, events, ...)
  findTanks()
end

function events:NAME_PLATE_UNIT_REMOVED(self, events, ...)
  local nameplate = C_NamePlate.GetNamePlateForUnit(self)
  resetThreat(nameplate.UnitFrame)
end

for key, _ in pairs(events) do
   -- Register all events for which handlers have been defined
  frame:RegisterEvent(key)
end
