local playerRole, tanks = _, {}

local frame, events = CreateFrame("frame"), {}

local color_default = { 1.0, 1.0, 0.0 }

local color_tanking_low = { 0.0, 0.0, 0.0 }

local color_tanking_mid = { 0.0, 0.0, 0.0 }

local color_tanking_high  = { 0.3, 0.5, 1.0 }

local color_offtanking = { 0.0, 0.0, 1.0 }

local function updatePlayerRole()
  playerRole = GetSpecializationRole(GetSpecialization())
end

local function findTanks()
end

local function isOffTanking(unit)
  return false
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
      frame.healthBar:SetStatusBarColor(unpack(default_color))
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

    frame.healthBar:SetStatusBarColor(unpack(color_default))
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

----------------------------- Menu -------------------------------------

function showColorPicker(r, g, b, a, changedCallback)
 ColorPickerFrame:SetColorRGB(r,g,b, 1.0);
 ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
 ColorPickerFrame.previousValues = {r,g,b,a};
 ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc =
  colorSelectCallback, colorSelectCallback, colorSelectCallback;
 ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
 ColorPickerFrame:Show();
end

TankThreatPlatesMenu = {}
TankThreatPlatesMenu.panel = CreateFrame( "Frame", "TankThreatPlatesMenu", UIParent )
TankThreatPlatesMenu.panel.name = "Tank Threat Plates"
InterfaceOptions_AddCategory(TankThreatPlatesMenu.panel)

local title = TankThreatPlatesMenu.panel:CreateFontString(
                nil,
                "ARTWORK",
                "GameFontNormalLarge"
              )

title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Tank Threat Plates")

-- local sometext = TankThreatPlatesMenu.panel:CreateFontString(
--                    nil,
--                    "ARTWORK",
--                    "GameFontHighlightSmall"
--                  )
--
-- sometext:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
-- sometext:SetText("Default Color:")

myCheckButton = CreateFrame(
  "Button",
  "myCheckButton_GlobalName",
  TankThreatPlatesMenu.panel,
  "ChatConfigCheckButtonTemplate"
)

myCheckButton:SetPoint("TOPLEFT", 20, -60)
myCheckButton_GlobalNameText:SetText("Default Plate Color")
myCheckButton.tooltip = "Click to select default color"

myCheckButton.texture = myCheckButton:CreateTexture()
myCheckButton.texture:SetAllPoints(myCheckButton)
myCheckButton.texture:SetColorTexture(1.0, 0.0, 0.0, 0.5)


myCheckButton:SetScript("OnClick", function()
  showColorPicker(_, _, _, _, colorSelectCallback)
end);

function colorSelectCallback()
  local r, g, b = ColorPickerFrame:GetColorRGB()

  color_default = { r, g, b }
  myCheckButton.texture = myCheckButton:CreateTexture()
  myCheckButton.texture:SetAllPoints(myCheckButton)
  myCheckButton.texture:SetColorTexture(r, g, b)
end

SLASH_TANKTHREATPLATES1 = "/ttp"
SlashCmdList["TANKTHREATPLATES"] = function(msg, editBox)
  -- Yes, this is a workaround to a known Blizz bug
  InterfaceOptionsFrame_OpenToCategory(TankThreatPlatesMenu.panel.name)
  InterfaceOptionsFrame_OpenToCategory(TankThreatPlatesMenu.panel.name)
end
