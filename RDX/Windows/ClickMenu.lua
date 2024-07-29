-- ClickMenu.lua
-- OpenRDX
-- Taelnia Perenolde US

-- I cleaned up all the repetetive code into this function that can be called from anywhere to add a button to the unitpopup menu

local buttonList = {};

RDX.AddPopupButton = function(label, _func)
	local button = {};

	button.text = label;
	button.func = _func

	table.insert(buttonList, button);
end

local function _RDX_OnMenuClick_wrapper(button)
	return (function(contextData) button.func(contextData.unit, contextData.name) end)
end

-- add all buttons in buttonList in a RDX submenu for the given menu
local function _RDX_ModifyMenu_Unit(menu)
	Menu.ModifyMenu(menu, function(owner, rootDescription, contextData)
		rootDescription:CreateDivider();
		local submenu = rootDescription:CreateButton("RDX");
		for k, button in pairs(buttonList) do
			submenu:CreateButton(button.text,_RDX_OnMenuClick_wrapper(button) , contextData);
		end
	end);
end

_RDX_ModifyMenu_Unit("MENU_UNIT_SELF")
_RDX_ModifyMenu_Unit("MENU_UNIT_PARTY")
_RDX_ModifyMenu_Unit("MENU_UNIT_RAID_PLAYER")
-- old code was not modifying those two dropdown, but in case one wish to add them just uncomment them
--_RDX_ModifyMenu_Unit("MENU_UNIT_TARGET")
--_RDX_ModifyMenu_Unit("MENU_UNIT_FOCUS")

-- note : I'm not sure any of these actually do anything, but adding them should work as expected
RDX.AddPopupButton(VFLI.i18n("RDX: Add to Assists"), function(unit, name) Logistics.AddAssist(name); end);
RDX.AddPopupButton(VFLI.i18n("RDX: Remove from Assists"), function(unit, name) Logistics.DropAssist(name); end);
RDX.AddPopupButton(VFLI.i18n("RDX: Add to Auto-Promote"), function(unit, name) Logistics.AddPromote(name); end);
RDX.AddPopupButton(VFLI.i18n("RDX: Remove from Auto-Promote"), function(unit, name) Logistics.DropPromote(name); end);
RDX.AddPopupButton(VFLI.i18n("RDX: View Character Sheet"), function(unit, name) Omni.CS_Ask(name); end);
RDX.AddPopupButton(VFLI.i18n("RDX: Request CombatLogs"), function(unit, name) Omni.PredefinedQuery(string.lower(name)); end);
RDX.AddPopupButton(VFLI.i18n("RDX: Request Packages"), function(unit, name) RDXDB.RAU_SeeAddons_Ask(name); end);

--[[
----------------------------------------
-- GLUE
-- ASSISTS
-- By Taelnia
----------------------------------------
local RDX_PopupButton_AddAssist = { text = "RDX: Add to Assists", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end Logistics.AddAssist(name); end, arg1 = "", arg2 = "", notCheckable = true };
local RDX_PopupButton_RemoveAssist = { text = "RDX: Remove from Assists", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end Logistics.DropAssist(name); end, arg1 = "", arg2 = "", notCheckable = true };
local function _MA_UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	if(dropdownMenu.which == "RAID" or dropdownMenu.which == "SELF" or dropdownMenu.which == "PLAYER" or dropdownMenu.which == "PARTY") then
		UIDropDownMenu_AddButton(RDX_PopupButton_AddAssist);
		UIDropDownMenu_AddButton(RDX_PopupButton_RemoveAssist);
	end
end
hooksecurefunc("UnitPopup_ShowMenu", _MA_UnitPopup_ShowMenu);

-----------------------------
-- RAIDINVITES
-----------------------------
local RDX_PopupButton_AddPromote = { text = "RDX: Add to Auto-Promote", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end Logistics.AddPromote(name); end, arg1 = "", arg2 = "", notCheckable = true };
local RDX_PopupButton_RemovePromote = { text = "RDX: Remove from Auto-Promote", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end Logistics.DropPromote(name); end, arg1 = "", arg2 = "", notCheckable = true };
local function _promote_UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	if(dropdownMenu.which == "RAID" or dropdownMenu.which == "SELF" or dropdownMenu.which == "PLAYER" or dropdownMenu.which == "PARTY") then
		UIDropDownMenu_AddButton(RDX_PopupButton_AddPromote);
		UIDropDownMenu_AddButton(RDX_PopupButton_RemovePromote);
	end
end
hooksecurefunc("UnitPopup_ShowMenu", _promote_UnitPopup_ShowMenu);

-----------------------------
-- CHARACTER SHEET
-----------------------------
local RDX_PopupButton_CharacterSheet = { text = "RDX: Character Sheet", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end CS_Ask(name); end , arg1 = "", arg2 = "", notCheckable = true };
local function _CHAR_UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	if(dropdownMenu.which == "RAID" or dropdownMenu.which == "SELF" or dropdownMenu.which == "PLAYER" or dropdownMenu.which == "PARTY") then
		UIDropDownMenu_AddButton(RDX_PopupButton_CharacterSheet);
	end
end
hooksecurefunc("UnitPopup_ShowMenu", _CHAR_UnitPopup_ShowMenu);

-----------------------------
-- Omniscience
-----------------------------
local RDX_PopupButton_Omni = { text = "RDX: Omniscience", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end name = string.lower(name); Omni.PredefinedQuery(name); end , arg1 = "", arg2 = "", notCheckable = true };
local function _OMNI_UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	if(dropdownMenu.which == "RAID" or dropdownMenu.which == "SELF" or dropdownMenu.which == "PLAYER" or dropdownMenu.which == "PARTY") then
		UIDropDownMenu_AddButton(RDX_PopupButton_Omni);
	end
end
hooksecurefunc("UnitPopup_ShowMenu", _OMNI_UnitPopup_ShowMenu);

-----------------------------
-- PackageUpdater
-----------------------------
local RDX_PopupButton_RAUSearchSheet = { text = "RDX: See Addons", dist = 0, func = function() local dropdownFrame = UIDropDownMenu_GetCurrentDropDown(); local unit = dropdownFrame.unit; local name = dropdownFrame.name; if UnitExists(unit) then name = UnitName(unit); end RDXDB.RAU_SeeAddons_Ask(name); end , arg1 = "", arg2 = "", notCheckable = true };
local function _RAUSearch_UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	if(dropdownMenu.which == "RAID" or dropdownMenu.which == "SELF" or dropdownMenu.which == "PLAYER" or dropdownMenu.which == "PARTY") then
		UIDropDownMenu_AddButton(RDX_PopupButton_RAUSearchSheet);
	end
end
hooksecurefunc("UnitPopup_ShowMenu", _RAUSearch_UnitPopup_ShowMenu);

]]--