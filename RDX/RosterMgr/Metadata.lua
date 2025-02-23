--
-- METADATA
-- 

RDXMD = RegisterVFLModule({
	name = "RDXMD";
	title = "RDX METADATA";
	description = "RDX METADATA";
	version = {1,0,0};
	parent = RDX;
});

local idToClass = { 
	"PRIEST", "DRUID", "PALADIN", 
	"SHAMAN", "WARRIOR", "WARLOCK", 
	"MAGE", "ROGUE", "HUNTER", "DEATHKNIGHT", "MONK", "DEMONHUNTER","EVOKER"
};
local classToID = VFL.invert(idToClass);

local idToLocalName = { 
	VFLI.i18n("Priest"), VFLI.i18n("Druid"), VFLI.i18n("Paladin"), 
	VFLI.i18n("Shaman"), VFLI.i18n("Warrior"), VFLI.i18n("Warlock"), 
	VFLI.i18n("Mage"), VFLI.i18n("Rogue"), VFLI.i18n("Hunter"), 
	VFLI.i18n("DeathKnight"), VFLI.i18n("Monk"), VFLI.i18n("DemonHunter"), VFLI.i18n("Evoker"),
};
local localNameToID = VFL.invert(idToLocalName);

local idToClassColor = {};
for i=1,11 do
	idToClassColor[i] = RAID_CLASS_COLORS[idToClass[i]];
end
local nameToClassColor = RAID_CLASS_COLORS;

local _grey = { r=.5, g=.5, b=.5};

local classIcons = {
	["WARRIOR"]		= {0, 0.25, 0, 0.25},
	["MAGE"]		= {0.25, 0.49609375, 0, 0.25},
	["ROGUE"]		= {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"]		= {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"]		= {0, 0.25, 0.25, 0.5},
	["SHAMAN"]	 	= {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"]		= {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"]		= {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"]		= {0, 0.25, 0.5, 0.75},
	["DEATHKNIGHT"]	= {0.25, .5, 0.5, .75},
	["MONK"]		= {0.5, 0.73828125, 0.5, .75},
	["DEMONHUNTER"]	= {0.7421875, 0.98828125, 0.5, 0.75},
	["EVOKER"]	= {0.5, 0.5, 0.5, 0.75},
	["PETS"] = {0, 1, 0, 1},
	["MAINTANK"] = {0, 1, 0, 1},
	["MAINASSIST"] = {0, 1, 0, 1}
};
local class_un = {0, 0, 0, 0};

--[[
["WARRIOR"] = {0, 0.25, 0, 0.25},
	["MAGE"] = {0.25, 0.5, 0, 0.25},
	["ROGUE"] = {0.5, 0.75, 0, 0.25},
	["DRUID"] = {0.74, 1, 0, 0.25},
	["HUNTER"] = {0, 0.25, 0.25, 0.5},
	["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
	["PRIEST"] = {0.5, 0.75, 0.25, 0.5},
	["WARLOCK"] = {0.75, 1, 0.25, 0.5},
	["PALADIN"] = {0, 0.25, 0.5, 0.75},
	["DEATHKNIGHT"]	= {0.25, .5, 0.5, .75},
	["MONK"]	= {0.5, .75, 0.5, .75},
	["DEMONHUNTER"]	= {0.7421875, 0.98828125, 0.5, 0.75},
]]

--- Retrieve the class ID for the class with the given proper name.
-- The proper name is the SECOND parameter returned from UnitClass(), and is
-- the fully capitalized English name of the class (e.g. "WARRIOR", "PALADIN")
function RDXMD.GetClassID(cn) return classToID[cn] or 0; end

-- Given the class ID, retrieve the proper classname
function RDXMD.GetClassMnemonic(cid) return idToClass[cid] or "UNKNOWN"; end

--- Given the class ID, retrieve the localized name for the class.
function RDXMD.GetClassName(cid) return idToLocalName[cid] or VFLI.i18n("Unknown"); end

--- Given the class ID, retrieve the class color as an RGB table.
function RDXMD.GetClassColor(cid) return idToClassColor[cid] or _grey; end
function RDXMD.GetClassColorFromEn(en) return nameToClassColor[en] or _grey; end

--- Given a *VALID* unit ID, get its class color.
function RDXMD.GetUnitClassColor(uid)
	local _,cn = UnitClass(uid);
	local id = classToID[cn];
	if not id then return _grey; end
	return idToClassColor[id] or _grey;
end

-- need find the points
function RDXMD.GetClassIcon(cn)
	return classIcons[cn] or class_un;
end

---------------------------------------------------------
-- metadata about role
--
local idToRole = { 
	"MAINTANK", "MAINASSIST", "TANK", "HEALER", "DAMAGER", "NONE",
};
local roleToId = VFL.invert(idToRole);

function RDXMD.GetRoleName(cid) return idToRole[cid] or VFLI.i18n("Unknown"); end

local idToRoleColor = {};
idToRoleColor[1] = _blue;
idToRoleColor[2] = _red;
idToRoleColor[3] = _blue;
idToRoleColor[4] = _green;
idToRoleColor[5] = _red;
idToRoleColor[6] = _yellow;

function RDXMD.GetRoleColor(cid) return idToRoleColor[cid] or _grey; end

--
-- Metadata about talent
--

local idToLocalsubclass = { 
	"Discipline", "Holy", "Shadow",
	"Balance", "Feral", "Guardian", "Restoration",
	"Holy", "Protection", "Retribution",
	"Elemental", "Enhancement", "Restoration",
	"Arms", "Fury", "Protection",
	"Affliction", "Demonology", "Destruction",
	"Arcane", "Fire", "Frost",
	"Assassination","Combat", "Subtlety",
	"Beast Mastery", "Marksmanship", "Survival",
	"Blood", "Frost", "Unholy",
	"DH1", "DH2", "DH3",
};
local localsubclassToID = VFL.invert(idToLocalsubclass);
local _unsubclass = "Unknown";

local talentIndex = {};
talentIndex["PRIEST"] = 1;
talentIndex["DRUID"] = 4;
talentIndex["PALADIN"] = 8;
talentIndex["SHAMAN"] = 11;
talentIndex["WARRIOR"] = 14;
talentIndex["WARLOCK"] = 17;
talentIndex["MAGE"] = 20;
talentIndex["ROGUE"] = 23;
talentIndex["HUNTER"] = 26;
talentIndex["DEATHKNIGHT"] = 29;
talentIndex["MONK"] = 32;
talentIndex["DEMONHUNTER"] = 35;
talentIndex["EVOKER"] = 37;

local idToSubClassColor = { 
	RAID_CLASS_COLORS["PRIEST"], RAID_CLASS_COLORS["PRIEST"], RAID_CLASS_COLORS["PRIEST"],
	RAID_CLASS_COLORS["DRUID"], RAID_CLASS_COLORS["DRUID"], RAID_CLASS_COLORS["DRUID"], RAID_CLASS_COLORS["DRUID"],
	RAID_CLASS_COLORS["PALADIN"], RAID_CLASS_COLORS["PALADIN"], RAID_CLASS_COLORS["PALADIN"],
	RAID_CLASS_COLORS["SHAMAN"], RAID_CLASS_COLORS["SHAMAN"], RAID_CLASS_COLORS["SHAMAN"],
	RAID_CLASS_COLORS["WARRIOR"], RAID_CLASS_COLORS["WARRIOR"], RAID_CLASS_COLORS["WARRIOR"],
	RAID_CLASS_COLORS["WARLOCK"], RAID_CLASS_COLORS["WARLOCK"], RAID_CLASS_COLORS["WARLOCK"],
	RAID_CLASS_COLORS["MAGE"], RAID_CLASS_COLORS["MAGE"], RAID_CLASS_COLORS["MAGE"],
	RAID_CLASS_COLORS["ROGUE"], RAID_CLASS_COLORS["ROGUE"], RAID_CLASS_COLORS["ROGUE"],
	RAID_CLASS_COLORS["HUNTER"], RAID_CLASS_COLORS["HUNTER"], RAID_CLASS_COLORS["HUNTER"],
	RAID_CLASS_COLORS["DEATHKNIGHT"], RAID_CLASS_COLORS["DEATHKNIGHT"], RAID_CLASS_COLORS["DEATHKNIGHT"],
	RAID_CLASS_COLORS["MONK"], RAID_CLASS_COLORS["MONK"], RAID_CLASS_COLORS["MONK"],
	RAID_CLASS_COLORS["DEMONHUNTER"], RAID_CLASS_COLORS["DEMONHUNTER"], RAID_CLASS_COLORS["DEMONHUNTER"],
	RAID_CLASS_COLORS["EVOKER"], RAID_CLASS_COLORS["EVOKER"], RAID_CLASS_COLORS["EVOKER"],
};
local localSubClassColorToID = VFL.invert(idToSubClassColor);
local _unsbColor = { r=.5, g=.5, b=.5};




local idToTexture = {};
idToTexture[1] = "Interface\\Icons\\Spell_Holy_PowerInfusion";
idToTexture[2] = "Interface\\Icons\\Spell_Holy_HolyBolt";
idToTexture[3] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain";
idToTexture[4] = "Interface\\Icons\\Spell_Nature_Preservation";
idToTexture[5] = "Interface\\Icons\\Ability_Druid_CatForm";
idToTexture[6] = "Interface\\Icons\\Ability_Racial_BearForm";
idToTexture[7] = "Interface\\Icons\\Spell_Nature_HealingTouch";
idToTexture[8] = "Interface\\Icons\\Spell_Holy_HolyGuidance";
idToTexture[9] = "Interface\\Icons\\SPELL_HOLY_DEVOTIONAURA";
idToTexture[10] = "Interface\\Icons\\Spell_Holy_AuraOfLight";
idToTexture[11] = "Interface\\Icons\\Spell_Nature_Lightning";
idToTexture[12] = "Interface\\Icons\\Spell_Nature_LightningShield";
idToTexture[13] = "Interface\\Icons\\Spell_Nature_MagicImmunity";
idToTexture[14] = "Interface\\Icons\\Ability_MeleeDamage";
idToTexture[15] = "Interface\\Icons\\Ability_Warrior_InnerRage";
idToTexture[16] = "Interface\\Icons\\Ability_Warrior_DefensiveStance";
idToTexture[17] = "Interface\\Icons\\Spell_Shadow_DeathCoil";
idToTexture[18] = "Interface\\Icons\\Spell_Shadow_Metamorphosis";
idToTexture[19] = "Interface\\Icons\\Spell_Shadow_RainOfFire";
idToTexture[20] = "Interface\\Icons\\Spell_Arcane_Blast";
idToTexture[21] = "Interface\\Icons\\Spell_Fire_FlameBolt";
idToTexture[22] = "Interface\\Icons\\Spell_Frost_FrostBolt02";
idToTexture[23] = "Interface\\Icons\\Ability_Rogue_Eviscerate";
idToTexture[24] = "Interface\\Icons\\Ability_BackStab";
idToTexture[25] = "Interface\\Icons\\Ability_Rogue_MasterOfSubtlety";
idToTexture[26] = "Interface\\Icons\\Ability_Hunter_BeastTaming";
idToTexture[27] = "Interface\\Icons\\Ability_Marksmanship";
idToTexture[28] = "Interface\\Icons\\Ability_Hunter_SwiftStrike";
idToTexture[29] = "Interface\\Icons\\Spell_Deathknight_BloodPresence";
idToTexture[30] = "Interface\\Icons\\Spell_Deathknight_FrostPresence";
idToTexture[31] = "Interface\\Icons\\Spell_Deathknight_UnholyPresence";
idToTexture[32] = "Interface\\Icons\\Spell_Monk_Brewmaster_Spec";
idToTexture[33] = "Interface\\Icons\\Spell_Monk_MistWeaver_Spec";
idToTexture[34] = "Interface\\Icons\\Spell_Monk_WindWalker_Spec";
idToTexture[35] = "Interface\\Icons\\Spell_Monk_Brewmaster_Spec";
idToTexture[36] = "Interface\\Icons\\Spell_Monk_MistWeaver_Spec";
idToTexture[37] = "Interface\\Icons\\Spell_Monk_WindWalker_Spec";
idToTexture[38] = "Interface\\Icons\\Spell_Monk_MistWeaver_Spec";
idToTexture[39] = "Interface\\Icons\\Spell_Monk_WindWalker_Spec";

local _unsbTex = "Interface\\InventoryItems\\WoWUnknownItem01.blp";

function RDXMD.GetIdSubClassByLocal(scn)
	return localsubclassToID[scn] or 0;
end

function RDXMD.GetLocalSubclassById(scid)
	return idToLocalsubclass[scid] or _unsubclass;
end

function RDXMD.GetColorSubClassByLocal(scn)
	local idn = localsubclassToID[scn];
	if not idn then return _unsbColor; end
	return idToSubClassColor[idn] or _unsbColor;
end

function RDXMD.GetColorSubClassById(id)
	return idToSubClassColor[id] or _unsbColor;
end

function RDXMD.GetTextureSubClassByLocal(scn)
	local idn = localsubclassToID[scn];
	if not idn then return _unsbTex; end
	return idToTexture[idn] or _unsbTex;
end

function RDXMD.GetTextureSubClassById(id)
	return idToTexture[id] or _unsbTex;
end

function RDXMD.GetSelfTextureTalent()
	local currentSpec = GetSpecialization();
	local currentSpecTexture = currentSpec and select(4, GetSpecializationInfo(currentSpec)) or 0;
	return currentSpecTexture;
end

local tblnoindex = {};
tblnoindex[250] = 1;
tblnoindex[251] = 2;
tblnoindex[252] = 3;

tblnoindex[102] = 1;
tblnoindex[103] = 2;
tblnoindex[104] = 3;
tblnoindex[105] = 4;

tblnoindex[253] = 1;
tblnoindex[254] = 2;
tblnoindex[255] = 3;

tblnoindex[62] = 1;
tblnoindex[63] = 2;
tblnoindex[64] = 3;

tblnoindex[268] = 1;
tblnoindex[269] = 2;
tblnoindex[270] = 3;

tblnoindex[65] = 1;
tblnoindex[66] = 2;
tblnoindex[67] = 3;

tblnoindex[256] = 1;
tblnoindex[257] = 2;
tblnoindex[258] = 3;

tblnoindex[259] = 1;
tblnoindex[260] = 2;
tblnoindex[261] = 3;

tblnoindex[262] = 1;
tblnoindex[263] = 2;
tblnoindex[264] = 3;

tblnoindex[265] = 1;
tblnoindex[266] = 2;
tblnoindex[267] = 3;

tblnoindex[71] = 1;
tblnoindex[72] = 2;
tblnoindex[70] = 3;

tblnoindex[0] = 1;

function RDXMD.GetSelfTalentNoIndex()
	local currentSpec = GetSpecialization();
	local currentSpecid = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or 0;
	if not tblnoindex[currentSpecid] then VFL.print("RDXMD.GetSelfTalentNoIndex"); VFL.print(currentSpec); VFL.print(currentSpecid); end
	return tblnoindex[currentSpecid] or 1;
end

function RDXMD.GetSelfTalentIndex()
	local currentSpec = GetSpecialization();
	local currentSpecid = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or 0;
	return currentSpecid or 1;
end
--[[
Death Knight
250 = Blood
251 = Frost
252 = Unholy

Druid
102 = Balance
103 = Feral
104 = Guardian
105 = Restoration

Hunter
253 = Beast Mastery
254 = Marksmanship
255 = Survival

Mage
62 = Arcane
63 = Fire
64 = Frost

Monk
268 = Brewmaster
270 = Mistweaver
269 = Windwalker

Paladin
65 = Holy
66 = Protection
67 = Retribution

Priest
256 = Discipline
257 = Holy
258 = Shadow

Rogue
259 = Assassination
260 = Combat
261 = Subtlety

Shaman
262 = Elemental
263 = Enhancement
264 = Restoration

Warlock
265 = Affliction
266 = Demonology
267 = Destruction

Warrior
71 = Arms
72 = Fury
73 = Protection
]]

-- /script RDXMD.GetSelfTalentNoIndex()

--local function UpdateTalent()
--	local myunit = RDXDAL.GetMyUnit();
--	if not myunit then return; end
--	local t = myunit:GetNField("sync");
--	t.mt = RDXMD.GetSelfTalent();
--end;

--RDXEvents:Bind("INIT_DEFERRED", nil, UpdateTalent);
--WoWEvents:Bind("PLAYER_TALENT_UPDATE", nil, UpdateTalent);

--
-- Metadata about PVP
--
local pvpIcons = {
	["Horde"] = {0.08, 0.58, 0.045, 0.545},
	["Alliance"] = {0.07, 0.58, 0.06, 0.57},
	["FFA"] = {0.05, 0.605, 0.015, 0.57},
}

function RDXMD.GetPVPIcon(cl)
	return pvpIcons[cl];
end

-----------------------
-- Runes
-----------------------
local RUNETYPE_BLOOD = 1;
local RUNETYPE_UNHOLY = 2;
local RUNETYPE_FROST = 3;
local RUNETYPE_DEATH = 4;

local iconTextures = {
	[RUNETYPE_BLOOD] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
	[RUNETYPE_UNHOLY] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy",
	[RUNETYPE_FROST] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost",
	[RUNETYPE_DEATH] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death",
}
function RDXMD.GetRuneIconTexturesNormal(id)
	return iconTextures[id];
end

local iconTexturesOn = {
	[RUNETYPE_BLOOD] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood-On",
	[RUNETYPE_UNHOLY] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death-On",
	[RUNETYPE_FROST] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost-On",
	[RUNETYPE_DEATH] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Chromatic-On",
}
function RDXMD.GetRuneIconTexturesOn(id)
	return iconTexturesOn[id];
end

local runeTexturesOff = {
	[RUNETYPE_BLOOD] = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-Blood-Off",
	[RUNETYPE_UNHOLY] = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-Death-Off",
	[RUNETYPE_FROST] = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-Frost-Off",
	[RUNETYPE_DEATH] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Chromatic-Off",
}
function RDXMD.GetRuneIconTexturesOff(id)
	return runeTexturesOff[id];
end

local runeTexturesList = {
	{ text = "Normal" },
	{ text = "On" },
	{ text = "Off" },
};
function RDXMD.RuneTextureTypeDropdownFunction() return runeTexturesList; end

local runeColors = {
	[RUNETYPE_BLOOD] = {1, 0, 0},
	[RUNETYPE_UNHOLY] = {0, 0.5, 0},
	[RUNETYPE_FROST] = {0, 1, 1},
	[RUNETYPE_DEATH] = {0.8, 0.1, 1},
}
function RDXMD.GetRuneColors(id)
	return runeColors[id];
end   

local runeMapping = {
	[1] = VFLI.i18n("BLOOD"),
	[2] = VFLI.i18n("UNHOLY"),
	[3] = VFLI.i18n("FROST"),
	[4] = VFLI.i18n("DEATH"),
}

function RDXMD.GetRuneMapping(id)
	return runeMapping[id];
end

-------------------------------------------
-- Pet Hapiness
-------------------------------------------
local pethapIcons = {
	[1] = {0.375, 0.5625, 0, 0.359375},
	[2] = {0.1875, 0.375, 0, 0.359375},
	[3] = {0, 0.1875, 0, 0.359375},
}

function RDXMD.GetPethapIcon(cl)
	return pethapIcons[cl];
end



