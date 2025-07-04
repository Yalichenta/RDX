﻿-- Assets.lua
-- VFL
-- (C)2007 Bill Johnson and the VFL Project.
--
-- Asset management for textures, fonts, backdrops and other reusable
-- UI types.

----------------------------------
-- FONT SYSTEM
----------------------------------
--- Font face database
local faces = {};
local sortedFaces = {};
function VFLUI.RegisterFontFace(path, name)
	if type(path) ~= "string" or type(name) ~= "string" then
		error("invalid arguments to RegisterFontFace");
	end
	if faces[path] then return; end -- dup reg
	faces[path] = name;
	-- Sorted faces list for menus.
	table.insert(sortedFaces, {path = path, name = name});
	table.sort(sortedFaces, function(x1,x2) return x1.name < x2.name; end);
end

function VFLUI._GetFontFaces() return sortedFaces; end
function VFLUI.GetFontFaceName(path) return faces[path]; end

function VFLUI.isFacePathExist(path)
	if (not path) or (not faces[path]) then return false; else return true end
end

--- Font descriptor database
Fonts = {};
FontObjects = {};
FontIndex = {};

function VFLUI.RegisterFont(tbl)
	if (type(tbl) ~= "table") or (type(tbl.name) ~= "string") then
		error("Invalid argument to RegisterFont");
	end
	if Fonts[tbl.name] then
		error("Duplicate font registration for " .. tbl.name);
	end
	if type(tbl.face) ~= "string" then tbl.face = sortedFaces[1].path; end
	if type(tbl.size) ~= "number" then tbl.size = 12; end
	--if type(tbl.justifyH) ~= "string" then tbl.justifyH = "LEFT"; end
	--if type(tbl.justifyV) ~= "string" then tbl.justifyV = "MIDDLE"; end
	Fonts[tbl.name] = tbl;

	-- Also create a font object for use with buttons.
	local fo = CreateFont("zzz_" .. tbl.name);
	fo:SetFont(tbl.face, tbl.size, tbl.flags or "");
	if tbl.color then
		fo:SetTextColor(VFL.explodeRGBA(tbl.color));
	elseif tbl.cr then
		fo:SetTextColor(tbl.cr, tbl.cg, tbl.cb, tbl.ca);
	end
	if tbl.justifyH then
		fo:SetJustifyH(tbl.justifyH);
	end
	FontObjects[tbl.name] = fo;
	table.insert(FontIndex, {text = "Fonts." .. tbl.name});
end

function VFLUI._GetFontIndex() return FontIndex; end

--- Apply a font descriptor to a FontInstance.
function VFLUI.SetFont(obj, descr, sz, justify, extra)
	if type(descr) ~= "table" then descr = Fonts.Default;	end
	if not VFLUI.isFacePathExist(descr.face) then descr.face = "Interface\\Addons\\VFL\\Fonts\\LiberationSans-Regular.ttf"; end
	obj:SetFont(descr.face, (sz or descr.size or 10), descr.flags or "");
	if descr.sx then
		obj:SetShadowOffset(descr.sx or 0, descr.sy or 0);
		obj:SetShadowColor(descr.sr or 0, descr.sg or 0, descr.sb or 0, descr.sa or 1);
	else
		obj:SetShadowOffset(0,0);
	end
	if descr.cr then
		obj:SetTextColor(descr.cr or 1, descr.cg or 1, descr.cb or 1, descr.ca or 1);
	end
	if justify then
		obj:SetJustifyH(descr.justifyH or "LEFT");
		local jv = justifyV
		if(jv == "BOTTOM" or jv == "TOP") then
			obj:SetJustifyV(jv);
		end
		obj:SetJustifyV("MIDDLE");
	end
end

--- Generate the code that will apply a font descriptor to a FontInstance.
function VFLUI.GenerateSetFontCode(obj, descr, sz, justify)
	if type(descr) ~= "table" then descr = Fonts.Default;	end
	if not VFLUI.isFacePathExist(descr.face) then descr.face = "Interface\\Addons\\VFL\\Fonts\\LiberationSans-Regular.ttf"; end
	local ret = [[
]] .. obj .. ":SetFont(" .. string.format("%q", descr.face) .. ", " .. (sz or descr.size or 10);
	if descr.flags then ret = ret .. ", " .. string.format("%q", descr.flags or ""); end
	ret = ret.. [[);
]];
	if descr.sx then
		ret = ret .. obj .. [[:SetShadowOffset(]] .. (descr.sx or 0) .. "," .. (descr.sy or 0) .. [[);
]] .. obj .. [[:SetShadowColor(]] .. (descr.sr or 0) .. "," .. (descr.sg or 0) .. "," .. (descr.sb or 0) .. "," .. (descr.sa or 1) .. [[);
]];
	else
		ret = ret .. obj .. [[:SetShadowOffset(0,0);
]];
	end
	if descr.cr and descr.cg and descr.cb and descr.ca then
		ret = ret .. obj .. [[:SetTextColor(]] .. (descr.cr or 1) .. "," .. (descr.cg or 1) .. "," .. (descr.cb or 1) .. "," .. (descr.ca or 1) .. [[);
]];
	end
	if justify then
		local jv = "MIDDLE"
		if(descr.justifyV == "TOP") then jv = "TOP" end
		if(descr.justifyV == "BOTTOM") then jv = "BOTTOM" end
		ret = ret .. obj .. [[:SetJustifyH("]] .. (descr.justifyH or "LEFT") .. [["); ]] .. obj .. [[:SetJustifyV("]] .. (jv) .. [[");
]];
	end
	return ret;
end

--- COMPAT: compatibility with oldschool font api.
function VFLUI.GetFont(base, sz)
	return base, sz;
end

------------------------------------------------
-- TEXTURE SYSTEM
------------------------------------------------
local textures = {};
local texCategories = {};
local tcSorted = {};
local texByPath = {};
function VFLUI.RegisterTexture(tbl, fast)
	if (type(tbl) ~= "table") or (type(tbl.name) ~= "string") then
		error("Invalid arguments to RegisterTexture()");
	end
	if not tbl.title then tbl.title = tbl.name; end
	if not tbl.category then tbl.category = "Uncategorized"; end
	if not tbl.dx then tbl.dx = 32; end
	if not tbl.dy then tbl.dy = 32; end
	if not tbl.blendMode then tbl.blendMode = "BLEND"; end
	if not texCategories[tbl.category] then
		texCategories[tbl.category] = true;
		table.insert(tcSorted, tbl.category); table.sort(tcSorted);
	end
	textures[tbl.name] = tbl;
	if tbl.path and (not fast) then texByPath[tbl.path] = tbl; end
end

function VFLUI.RegisterAbilIcon(class, title, path)
	VFLUI.RegisterTexture({
		name = string.gsub(title, "[^%w_]", "_");
		category = "Spells" .. ": " .. class;
		title = title;
		path = "Interface\\Icons\\" .. path;
		dx = 32; dy = 32;
	});
end

function VFLUI._AllTextures()
	return textures;
end

function VFLUI.GetTextureByPath(path)
	return texByPath[path];
end

function VFLUI.GetSortedTextureCategories()
	return tcSorted;
end

--- Copy only the UI-relevant portions of a texture object.
function VFLUI.CopyTexture(tex)
	local ret = {};
	if tex.color then ret.color = VFL.copy(tex.color); end
	if tex.path then ret.path = tex.path; end
	if tex.pathid then ret.pathid = tex.pathid; end
	ret.blendMode = tex.blendMode;
	ret.gradDir = tex.gradDir;
	if tex.vertexColor then ret.vertexColor = VFL.copy(tex.vertexColor); end
	if tex.grad1 then ret.grad1 = VFL.copy(tex.grad1); end
	if tex.grad2 then ret.grad2 = VFL.copy(tex.grad2); end
	if tex.coord then ret.coord = VFL.copy(tex.coord); end
	if tex.coord2 then ret.coord2 = VFL.copy(tex.coord2); end
	return ret;
end

--- Apply a texture descriptor to a Texture.
function VFLUI.SetTexture(obj, descr)
	if not descr then
		obj:SetTexture(nil);
		obj:SetColorTexture(0, 0, 0, 0);
	else
		if descr.color then
			obj:SetColorTexture(VFL.explodeRGBA(descr.color));
		elseif descr.path then
			obj:SetTexture(descr.path);
		elseif descr.pathid then
			obj:SetToFileData(descr.pathid);
		else
			return;
		end
		obj:SetBlendMode(descr.blendMode);
		if descr.vertexColor then
			obj:SetVertexColor(VFL.explodeRGBA(descr.vertexColor));
		elseif descr.gradDir then
			local c = descr.grad1
			-- bethan > SetGradientAlpha no longer exist so replace it with SetGradient
			--obj:SetGradientAlpha(descr.gradDir, c.r, c.g, c.b, c.a, VFL.explodeRGBA(descr.grad2));
			obj:SetGradient(descr.gradDir, CreateColor(c.r, c.g, c.b, c.a),CreateColor(VFL.explodeRGBA(descr.grad2)))
		else
			obj:SetVertexColor(1,1,1,1);
		end
		if descr.path then
			if descr.coord then
				local c = descr.coord;
				obj:SetTexCoord(c.l, c.r, c.b, c.t);
			elseif descr.coord2 then
				local c = descr.coord2;
				obj:SetTexCoord(c.ULx,c.ULy,c.LLx,c.LLy,c.URx,c.URy,c.LRx,c.LRy);
			else
				obj:SetTexCoord(0, 1, 0, 1);
			end
		end
	end
end

--- Generate the code that will apply a texture to a Texture object.
function VFLUI.GenerateSetTextureCode(obj, descr)
	local ret = "";
	if descr.color then
		local c = descr.color;
		ret = obj .. ":SetColorTexture(" .. c.r .. "," .. c.g .. "," .. c.b .. "," .. c.a .. "); ";
	elseif descr.path then
		ret = obj .. ":SetTexture(" .. string.format("%q", descr.path) .. "); ";
	elseif descr.pathid then
		ret = obj .. ":SetToFileData(" .. string.format("%q", descr.pathid) .. "); ";
	end
	ret = ret .. obj .. ":SetBlendMode(" .. string.format("%q", descr.blendMode) .. "); ";
	if descr.vertexColor then
		local c = descr.vertexColor;
		ret = ret .. obj .. ":SetVertexColor(" .. c.r .. "," .. c.g .. "," .. c.b .. "," .. c.a .. [[);
]];
	elseif descr.gradDir then
		local c,c2 = descr.grad1, descr.grad2;
		-- bethan > SetGradientAlpha no longer exist so replace it with SetGradient
		--ret = ret .. obj .. ":SetGradientAlpha('" .. descr.gradDir .. "'," .. c.r .. "," .. c.g .. "," .. c.b .. "," .. c.a .. "," .. c2.r .. "," .. c2.g .. "," .. c2.b .. "," .. c2.a .. [[);
		ret = ret .. obj .. ":SetGradient('" .. descr.gradDir .. "',CreateColor(" .. c.r .. "," .. c.g .. "," .. c.b .. "," .. c.a .. "),CreateColor(" .. c2.r .. "," .. c2.g .. "," .. c2.b .. "," .. c2.a .. [[));
]];

	else
		ret = ret .. obj .. [[:SetVertexColor(1,1,1,1);
]];
	end
	if descr.path then
		if descr.coord then
			local c = descr.coord;
			ret = ret .. obj .. ":SetTexCoord(" .. c.l .. "," .. c.b .. "," .. c.r .. "," .. c.t .. [[);
]];
		elseif descr.coord2 then
			local c = descr.coord2;
			ret = ret .. obj .. ":SetTexCoord(" .. c.ULx .. "," .. c.ULy .. "," .. c.LLx .. "," .. c.LLy .. "," .. c.URx .. "," .. c.URy .. "," .. c.LRx .. "," .. c.LRy ..[[);
]];
		else
			ret = ret .. obj .. [[:SetTexCoord(0,1,0,1);
]];
		end
	end
	return ret;
end

--------------------------------
-- BUTTON SKINS
--------------------------------
local buttonskins = {};
local buttonskinsList = {};

function VFLUI.RegisterButtonSkin(tbl)
	if (type(tbl) ~= "table") or (type(tbl.name) ~= "string") then
		error("Invalid arguments to RegisterButtonSkin()");
	end
	if not tbl.title then tbl.title = tbl.name; end
	-- Value and text fields for dropdowns
	tbl.value = tbl.name; tbl.text = tbl.name;
	buttonskins[tbl.name] = tbl;
	table.insert(buttonskinsList, tbl);
end

function VFLUI._AllButtonSkins()
	return buttonskins;
end

function VFLUI.GetButtonSkin(name)
	return buttonskins[name];
end

function VFLUI.GetButtonSkinList() return buttonskinsList; end
VFLUI.RegisterButtonSkin({ name = "bs_default"; title = "None"; });

function VFLUI.SetButtonSkin(frame, bsp)
	if (type(frame) ~= "table") then return; end

	if frame.framesup and not bsp then
		VFLUI.SetTexture(frame._texBackdrop, nil);
		frame._texBackdrop:Hide();
		VFLUI.SetTexture(frame._texBorder, nil);
		frame._texBorder:Hide();
		VFLUI.SetTexture(frame._texFlash, nil);
		frame._texFlash:Hide();
		VFLUI.SetTexture(frame._texNormal, nil);
		frame:SetNormalTexture(frame._texNormal);
		VFLUI.SetTexture(frame._texPushed, nil);
		frame:SetPushedTexture(frame._texPushed);
		VFLUI.SetTexture(frame._texDisabled, nil);
		frame:SetDisabledTexture(frame._texDisabled);
		VFLUI.SetTexture(frame._texHighlight, nil);
		frame:SetHighlightTexture(frame._texHighlight);
		VFLUI.SetTexture(frame._texGloss, nil);
		frame._texGloss:Hide();

		frame.framesup:Hide();
	end

	if (type(bsp) == "table") then
		if not frame.framesup then
			local framesup = VFLUI.AcquireFrame("Frame");
			framesup:SetParent(frame);
			framesup:SetFrameStrata(frame:GetFrameStrata());
			framesup:SetFrameLevel(frame:GetFrameLevel() + 2);
			framesup:SetAllPoints(frame);
			framesup:Show();
			frame.framesup = framesup;

			local _texBackdrop = VFLUI.CreateTexture(frame);
			_texBackdrop:SetAllPoints(frame);
			_texBackdrop:Hide();
			frame._texBackdrop = _texBackdrop;

			local _texBorder = VFLUI.CreateTexture(framesup);
			_texBorder:SetAllPoints(framesup);
			_texBorder:Hide();
			frame._texBorder = _texBorder;

			local _texFlash = VFLUI.CreateTexture(framesup);
			_texFlash:SetAllPoints(framesup);
			_texFlash:Hide();
			frame._texFlash = _texFlash;

			-- normal
			local _texNormal = VFLUI.CreateTexture(frame);
			_texNormal:SetAllPoints(frame);
			frame._texNormal = _texNormal;

			-- pushed
			local _texPushed = VFLUI.CreateTexture(frame);
			_texPushed:SetAllPoints(frame);
			frame._texPushed = _texPushed;

			-- disabled
			local _texDisabled = VFLUI.CreateTexture(frame);
			_texDisabled:SetAllPoints(frame);
			frame._texDisabled = _texDisabled;

			-- checked
			local _texChecked = VFLUI.CreateTexture(frame);
			_texChecked:SetAllPoints(frame);
			frame._texChecked = _texChecked;

			-- highlights
			local _texHighlight = VFLUI.CreateTexture(frame);
			_texHighlight:SetAllPoints(frame);
			frame._texHighlight = _texHighlight;

			-- gloss
			local _texGloss = VFLUI.CreateTexture(frame);
			_texGloss:SetAllPoints(frame);
			frame._texGloss = _texGloss;

			frame.Destroy = VFL.hook(function(s)
				VFLUI.ReleaseRegion(s._texBackdrop); s._texBackdrop = nil;
				VFLUI.ReleaseRegion(s._texBorder); s._texBorder = nil;
				VFLUI.ReleaseRegion(s._texFlash); s._texFlash = nil;
				VFLUI.ReleaseRegion(s._texNormal); s._texNormal = nil;
				VFLUI.ReleaseRegion(s._texPushed); s._texPushed = nil;
				VFLUI.ReleaseRegion(s._texDisabled); s._texDisabled = nil;
				VFLUI.ReleaseRegion(s._texChecked); s._texChecked = nil;
				VFLUI.ReleaseRegion(s._texHighlight); s._texHighlight = nil;
				VFLUI.ReleaseRegion(s._texGloss); s._texGloss = nil;
				s.framesup:Destroy(); s.framesup = nil;
			end, frame.Destroy);
		end

		local desc = VFLUI.GetButtonSkin(bsp.name);
		if not desc then return; end
		if desc.backdrop then
			VFLUI.SetTexture(frame._texBackdrop, desc.backdrop);
			frame._texBackdrop:SetDrawLayer("ARTWORK", 1);
			frame._texBackdrop:Show();
		end
		if desc.border then
			VFLUI.SetTexture(frame._texBorder, desc.border);
			frame._texBorder:SetDrawLayer("ARTWORK", 6);
			frame._texBorder:Show();
		end
		if desc.flash then
			VFLUI.SetTexture(frame._texFlash, desc.flash);
			frame._texFlash:SetDrawLayer("ARTWORK", 7);
			frame._texFlash:Show();
		end
		if desc.normal then
			VFLUI.SetTexture(frame._texNormal, desc.normal);
			frame._texNormal:SetDrawLayer("ARTWORK", 3);
			frame:SetNormalTexture(frame._texNormal);
		end
		if desc.pushed then
			VFLUI.SetTexture(frame._texPushed, desc.pushed);
			frame._texPushed:SetDrawLayer("ARTWORK", 3);
			frame:SetPushedTexture(frame._texPushed);
		end
		if desc.disabled then
			VFLUI.SetTexture(frame._texDisabled, desc.disabled);
			frame._texDisabled:SetDrawLayer("ARTWORK", 3);
			frame:SetDisabledTexture(frame._texDisabled);
		end
		if desc.checked and frame:GetObjectType() == "CheckButton" then
		--	VFLUI.SetTexture(frame:GetCheckedTexture(), desc.checked);
		--	frame:GetCheckedTexture():SetDrawLayer("ARTWORK", 3);
		--	frame:GetCheckedTexture():Show();
		--	frame.ctex = desc.checked;
		end
		if desc.highlight then
			VFLUI.SetTexture(frame._texHighlight, desc.highlight);
			frame._texHighlight:SetDrawLayer("ARTWORK", 3);
			frame:SetHighlightTexture(frame._texHighlight);
		end
		if desc.gloss then
			VFLUI.SetTexture(frame._texGloss, desc.gloss);
			frame._texGloss:SetDrawLayer("ARTWORK", 4);
			frame._texGloss:Show();
		end

		if not bsp.showflash then
			VFLUI.SetTexture(frame._texFlash, nil);
		end

		if not bsp.showgloss then
			VFLUI.SetTexture(frame._texGloss, nil);
		end

		if bsp.br then
			frame._texBorder:SetVertexColor(bsp.br or 1, bsp.bg or 1, bsp.bb or 1, bsp.ba or 1);
			frame._texGloss:SetVertexColor(bsp.br or 1, bsp.bg or 1, bsp.bb or 1, bsp.ba or 1);
		end
	end
end

function VFLUI.SetButtonSkinBorderColor(frame, r, g, b, a)
	if frame._texBorder then
		frame._texBorder:SetVertexColor(r or 1, g or 1, b or 1, a or 1);
		frame._texGloss:SetVertexColor(r or 1, g or 1, b or 1, a or 1);
	end
end

-------------------------------------------------
-- COOLDOWN SYSTEM
-------------------------------------------------

local titadd = {
	{ text = "COOLDOWN&TEXT" },
	{ text = "COOLDOWN" },
	{ text = "TEXT" },
	{ text = "NONE" },
};
function VFLUI.TimerTypesDropdownFunction() return titadd; end

local tetadd = {
	{ text = "Largest" },
	{ text = "MinSec" },
	{ text = "Seconds" },
	{ text = "Tenths" },
	{ text = "Hundredths" },
};
function VFLUI.TextTypesDropdownFunction() return tetadd; end

local mapNTT = {
	["Largest"] = VFLT.Emm,
	["MinSec"] = VFLT.FormatMinSec,
	["Seconds"] = VFL.NumberFloor,
	["Tenths"] = VFL.Tenths,
	["Hundredths"] = VFL.Hundredths,
}
function VFLUI.GetTextTimerTypesFunction(name) return mapNTT[name] or VFLT.FormatMinSec; end

local mapNTS = {
	["Largest"] = "VFLT.Emm",
	["MinSec"] = "VFLT.FormatMinSec",
	["Seconds"] = "VFL.NumberFloor",
	["Tenths"] = "VFL.Tenths",
	["Hundredths"] = "VFL.Hundredths",
}
function VFLUI.GetTextTimerTypesString(name) return mapNTS[name] or "VFLT.FormatMinSec"; end

-------------------------------------------------
-- MINIMAP BLIP Texture
-------------------------------------------------
local blipTexture = {};

function VFLUI.RegisterBlipTexture(name, path)
	if blipTexture[name] then error("Duplicate BlipTexture registration " .. name); end
	blipTexture[name] = path;
	return true;
end;

function VFLUI.GetBlipTexture(name)
	return blipTexture[name];
end;

function VFLUI.GetListBlipTexture()
	local t = {};
	for k,_ in pairs(blipTexture) do
		table.insert(t, {text = k});
	end
	return t;
end;

-------------------------------------------------
-- MINIMAP MASK Texture
-------------------------------------------------
local maskTexture = {};

function VFLUI.RegisterMaskTexture(name, path)
	if maskTexture[name] then error("Duplicate MaskTexture registration " .. name); end
	maskTexture[name] = path;
	return true;
end;

function VFLUI.GetMaskTexture(name)
	return maskTexture[name];
end;

function VFLUI.GetListMaskTexture()
	local t = {};
	for k,_ in pairs(maskTexture) do
		table.insert(t, {text = k});
	end
	return t;
end;

-------------------------------------------------
-- BACKDROP SYSTEM
-------------------------------------------------
--------------- Registration for borders and backdrops
local backdropBorders = {};
local backdropBorderList = {};
function VFLUI.GetBackdropBorderTitle(name)
	local x = backdropBorders[name or "none"]; if not x then return "None"; end
	return x.title;
end
function VFLUI.GetBackdropBorderList() return backdropBorderList; end
function VFLUI.RegisterBackdropBorder(tbl)
	if (type(tbl) ~= "table") or (type(tbl.name) ~= "string") then
		error("Invalid arguments to RegisterBackdropBorder()");
	end
	if not tbl.title then tbl.title = tbl.name; end
	-- Value and text fields for dropdowns
	tbl.value = tbl.name; tbl.text = tbl.title;

	backdropBorders[tbl.name] = tbl;
	table.insert(backdropBorderList, tbl);
end

local backdrops = {};
local backdropList = {};
function VFLUI.GetBackdropTitle(name)
	local x = backdrops[name or "none"]; if not x then return "None"; end
	return x.title;
end
function VFLUI.GetBackdropList() return backdropList; end
function VFLUI.RegisterBackdrop(tbl)
	if (type(tbl) ~= "table") or (type(tbl.name) ~= "string") then
		error("Invalid arguments to RegisterBackdrop()");
	end
	if not tbl.title then tbl.title = tbl.name; end
	-- Value and text fields for dropdowns
	tbl.value = tbl.name; tbl.text = tbl.title;

	backdrops[tbl.name] = tbl;
	table.insert(backdropList, tbl);
end

-------------- The empty "None" backdrops
VFLUI.RegisterBackdropBorder({ name = "none"; title = "None"; });
VFLUI.RegisterBackdrop({ name = "none"; title = "None"; });

-------------- Application
local function applyBorder(bkdp, border)
	bkdp.edgeFile = border.edgeFile;
	bkdp.edgeSize = border.edgeSize;
	if type(border.insets) == "table" then bkdp.insets = VFL.copy(border.insets); else bkdp.insets = nil; end
end

local function applyBackdrop(bkdp, bkmeta)
	bkdp.bgFile = bkmeta.bgFile; bkdp.tile = bkmeta.tile;
	if bkdp.tile then bkdp.tileSize = tonumber(bkmeta.tileSize) or 16; else bkdp.tileSize = nil; end
end

function VFLUI.ApplyBaseBackdrop(bkdp, border, backdrop)
	if border then
		bkdp._border = border or "none";
		border = backdropBorders[bkdp._border] or backdropBorders["none"];
		applyBorder(bkdp, border);
	end
	if backdrop then
		bkdp._backdrop = backdrop or "none";
		backdrop = backdrops[bkdp._backdrop] or backdrops["none"];
		applyBackdrop(bkdp, backdrop);
	end
end

local function ASetBackdrop(frame, bkdp)
	if (type(frame) ~= "table") then return; end

	if frame._fbd then
		frame._fbd:SetBackdrop(nil);
		frame._fbb:SetBackdrop(nil);
		frame._fbd:Hide();
		frame._fbb:Hide();
	end
	if frame._rdxbf then
		frame._bg:Hide();
		frame._rdxbf:SetScript("OnSizeChanged", nil);
		frame._rdxbf:Hide();
	end
	if(frame.SetBackdrop) then frame:SetBackdrop(nil) end

	if (type(bkdp) == "table") then

		if not bkdp._bkdtype or bkdp._bkdtype == 1 then
			-- default backdrop
			Mixin(frame,BackdropTemplateMixin)
			frame:SetBackdrop(bkdp);
			if bkdp.br then
				frame:SetBackdropBorderColor(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
			else
				frame:SetBackdropBorderColor(1,1,1,1);
			end
			if bkdp.kr then
				frame:SetBackdropColor(bkdp.kr or 1, bkdp.kg or 1, bkdp.kb or 1, bkdp.ka or 1);
			else
				frame:SetBackdropColor(1,1,1,1);
			end
		elseif bkdp._bkdtype == 2 then
			-- double frame backdrop (one background, one sup)
			if not frame._fbd and not frame._fbb then
				local fbd = VFLUI.AcquireFrame("Frame");
				Mixin(fbd,BackdropTemplateMixin)
				fbd:SetParent(frame);
				fbd:Show();
				frame._fbd = fbd;
				local fbb = VFLUI.AcquireFrame("Frame");
				Mixin(fbb,BackdropTemplateMixin)
				fbb:SetParent(frame);
				fbb:Show();
				frame._fbb = fbb;
				frame.Destroy = VFL.hook(function(s)
					s._fbb:Destroy();
					s._fbb = nil;
					s._fbd:Destroy();
					s._fbd = nil;
				end, frame.Destroy);
			end

			if not bkdp.boff then bkdp.boff = 1; end
			if not bkdp.borl then bkdp.borl = 2; end

			frame._fbd:ClearAllPoints();
			frame._fbd:SetPoint("CENTER", frame, "CENTER");
			frame._fbd:SetWidth(frame:GetWidth() + bkdp.boff);
			frame._fbd:SetHeight(frame:GetHeight() + bkdp.boff);
			frame._fbd:SetFrameLevel(frame:GetFrameLevel());
			frame._fbd:Show();

			frame._fbb:ClearAllPoints();
			frame._fbb:SetPoint("CENTER", frame, "CENTER");
			frame._fbb:SetWidth(frame:GetWidth() + bkdp.boff);
			frame._fbb:SetHeight(frame:GetHeight() + bkdp.boff);
			frame._fbb:SetFrameLevel(frame:GetFrameLevel() + bkdp.borl);
			frame._fbb:Show();

			local bkdp_bd = VFL.copy(bkdp);
			bkdp_bd.edgeFile = nil;
			bkdp_bd.edgeSize = nil;
			--bkdp_bd.insets = nil;
			frame._fbd:SetBackdrop(bkdp_bd);

			local bkdp_bb = VFL.copy(bkdp);
			bkdp_bb.bgFile = nil;
			bkdp_bb.tile = nil;
			bkdp_bb.tileSize = nil;
			frame._fbb:SetBackdrop(bkdp_bb);

			if bkdp.br then
				frame._fbb:SetBackdropBorderColor(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
			else
				frame._fbb:SetBackdropBorderColor(1,1,1,1);
			end
			if bkdp.kr then
				frame._fbd:SetBackdropColor(bkdp.kr or 1, bkdp.kg or 1, bkdp.kb or 1, bkdp.ka or 1);
			else
				frame._fbd:SetBackdropColor(1,1,1,1);
			end
		elseif bkdp._bkdtype == 3 then
			-- Texture backdrop
			if not frame._rdxbf then
				local _f = VFLUI.AcquireFrame("Frame");
				_f:SetParent(frame);
				_f:SetAllPoints(frame);
				_f:Show();
				local _l = VFLUI.CreateTexture(_f);
				local _t = VFLUI.CreateTexture(_f);
				local _r = VFLUI.CreateTexture(_f);
				local _b = VFLUI.CreateTexture(_f);
				_l:Show();
				_t:Show();
				_r:Show();
				_b:Show();

				_f._l = _l;
				_f._t = _t;
				_f._r = _r;
				_f._b = _b;

				local _bg = VFLUI.CreateTexture(frame);
				_bg:Show();
				frame._bg = _bg;

				frame._rdxbf = _f;

				frame.Destroy = VFL.hook(function(s)
					s._rdxbf.rsize = nil;
					s._rdxbf.bors = nil;
					s._rdxbf._l:Destroy();
					s._rdxbf._l = nil;
					s._rdxbf._t:Destroy();
					s._rdxbf._t = nil;
					s._rdxbf._r:Destroy();
					s._rdxbf._r = nil;
					s._rdxbf._b:Destroy();
					s._rdxbf._b = nil;
					s._bg:Destroy();
					s._bg = nil;
					s._rdxbf:Destroy();
					s._rdxbf = nil;
				end, frame.Destroy);
			end

			frame._rdxbf:Show();
			frame._rdxbf:SetFrameLevel(frame:GetFrameLevel() + bkdp.borl);

			-- store the border sise
			frame._rdxbf.bors = bkdp.bors;

			local function rsize(self)
				self._l:ClearAllPoints();
				self._t:ClearAllPoints();
				self._r:ClearAllPoints();
				self._b:ClearAllPoints();
				self._l:SetPoint("LEFT", self, "LEFT");
				self._t:SetPoint("TOP", self, "TOP");
				self._r:SetPoint("RIGHT", self, "RIGHT");
				self._b:SetPoint("BOTTOM", self, "BOTTOM");
				self._l:SetWidth(self.bors or 1); self._l:SetHeight(self:GetHeight());
				self._t:SetWidth(self:GetWidth()); self._t:SetHeight(self.bors or 1);
				self._r:SetWidth(self.bors or 1); self._r:SetHeight(self:GetHeight());
				self._b:SetWidth(self:GetWidth()); self._b:SetHeight(self.bors or 1);
			end

			frame._rdxbf.rsize = rsize;
			frame._rdxbf:SetScript("OnSizeChanged", rsize);
			frame._rdxbf:rsize();

			if bkdp.br then
				frame._rdxbf._l:SetColorTexture(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
				frame._rdxbf._t:SetColorTexture(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
				frame._rdxbf._r:SetColorTexture(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
				frame._rdxbf._b:SetColorTexture(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
			else
				frame._rdxbf._l:SetColorTexture(1,1,1,1);
				frame._rdxbf._t:SetColorTexture(1,1,1,1);
				frame._rdxbf._r:SetColorTexture(1,1,1,1);
				frame._rdxbf._b:SetColorTexture(1,1,1,1);
			end
			frame._rdxbf._l:SetDrawLayer(bkdp.dl, bkdp.borl);
			frame._rdxbf._t:SetDrawLayer(bkdp.dl, bkdp.borl);
			frame._rdxbf._r:SetDrawLayer(bkdp.dl, bkdp.borl);
			frame._rdxbf._b:SetDrawLayer(bkdp.dl, bkdp.borl);
			--frame._rdxbf._l:SetVertexColor(1,1,1,1);
			--frame._rdxbf._t:SetVertexColor(1,1,1,1);
			--frame._rdxbf._r:SetVertexColor(1,1,1,1);
			--frame._rdxbf._b:SetVertexColor(1,1,1,1);

			if bkdp.kr then
				frame._bg:SetColorTexture(bkdp.kr or 1, bkdp.kg or 1, bkdp.kb or 1, bkdp.ka or 1);
			else
				frame._bg:SetTexture(nil);
				frame._bg:SetColorTexture(0, 0, 0, 0);
			end

			frame._bg:SetDrawLayer(bkdp.dl, bkdp.bgl or 1);
			--frame._bg:SetVertexColor(1,1,1,1);
			frame._bg:SetAllPoints(frame);
			frame._bg:Show();
		end
	end
end

function VFLUI.SetBackdrop(frame, bkdp)
	VFLT.NextFrame(math.random(100000000), function()
		ASetBackdrop(frame, bkdp)
	end);
end

function VFLUI.SetBackdropColor(frame, r, g, b, a)
	if frame._fbd then
		frame._fbd:SetBackdropColor(r or 1, g or 1, b or 1, a or 1);
	elseif frame._rdxbf then
		frame._bg:SetColorTexture(r or 1, g or 1, b or 1, a or 1);
	else
		frame:SetBackdropColor(r or 1, g or 1, b or 1, a or 1);
	end
end

function VFLUI.SetBackdropBorderColor(frame, r, g, b, a)
	if frame._fbd then
		frame._fbb:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1);
	elseif frame._rdxbf then
		frame._rdxbf._l:SetColorTexture(r or 1, g or 1, b or 1, a or 1);
		frame._rdxbf._t:SetColorTexture(r or 1, g or 1, b or 1, a or 1);
		frame._rdxbf._r:SetColorTexture(r or 1, g or 1, b or 1, a or 1);
		frame._rdxbf._b:SetColorTexture(r or 1, g or 1, b or 1, a or 1);
	else
		frame:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1);
	end
end





--Two backdrop, create two frames -- deprecated !!!!
function VFLUI.SetBackdropRDX(frame, bkdp, offset, borderlevel)
	if (type(frame) ~= "table") or (type(bkdp) ~= "table") then return; end
	if not offset then offset = 0; end
	if not borderlevel then borderlevel = 1; end

	if not frame._fbd then
		local fbd = VFLUI.AcquireFrame("Frame");
		fbd:SetParent(frame);
		fbd:Show();
		frame._fbd = fbd;
	end
	frame._fbd:ClearAllPoints();
	frame._fbd:SetPoint("CENTER", frame, "CENTER");
	frame._fbd:SetWidth(frame:GetWidth() + offset);
	frame._fbd:SetHeight(frame:GetHeight() + offset);
	frame._fbd:SetFrameLevel(frame:GetFrameLevel() - 1);

	if not frame._fbb then
		local fbb = VFLUI.AcquireFrame("Frame");
		fbb:SetParent(frame);
		fbb:Show();
		frame._fbb = fbb;
	end
	frame._fbb:ClearAllPoints();
	frame._fbb:SetPoint("CENTER", frame, "CENTER");
	frame._fbb:SetWidth(frame:GetWidth() + offset);
	frame._fbb:SetHeight(frame:GetHeight() + offset);
	frame._fbb:SetFrameLevel(frame:GetFrameLevel() + borderlevel);

	local bkdp_bd = VFL.copy(bkdp);
	bkdp_bd.edgeFile = nil;
	bkdp_bd.edgeSize = nil;
	bkdp_bd.insets = nil;
	frame._fbd:SetBackdrop(bkdp_bd);

	local bkdp_bb = VFL.copy(bkdp);
	bkdp_bb.bgFile = nil;
	bkdp_bb.tile = nil;
	bkdp_bb.tileSize = nil;
	frame._fbb:SetBackdrop(bkdp_bb);

	if bkdp.br then
		frame._fbb:SetBackdropBorderColor(bkdp.br or 1, bkdp.bg or 1, bkdp.bb or 1, bkdp.ba or 1);
	else
		frame._fbb:SetBackdropBorderColor(1,1,1,1);
	end
	if bkdp.kr then
		frame._fbd:SetBackdropColor(bkdp.kr or 1, bkdp.kg or 1, bkdp.kb or 1, bkdp.ka or 1);
	else
		frame._fbd:SetBackdropColor(1,1,1,1);
	end
	frame.Destroy = VFL.hook(function(s)
		s._fbb:Destroy();
		s._fbb = nil;
		s._fbd:Destroy();
		s._fbd = nil;
	end, frame.Destroy);
end

function VFLUI.ResizeBackdropRDX(frame, offset)
	if (type(frame) ~= "table") then return; end
	if not frame._fbd then error("Owner frame does not have a backdrop RDX"); end
	if not offset then offset = 0; end
	frame._fbd:ClearAllPoints();
	frame._fbd:SetPoint("CENTER", frame, "CENTER");
	frame._fbd:SetWidth(frame:GetWidth() + offset);
	frame._fbd:SetHeight(frame:GetHeight() + offset);
	frame._fbb:ClearAllPoints();
	frame._fbb:SetPoint("CENTER", frame, "CENTER");
	frame._fbb:SetWidth(frame:GetWidth() + offset);
	frame._fbb:SetHeight(frame:GetHeight() + offset);
end
-- deprecated
function VFLUI.SetBorderLevelBackdropRDX(frame, borderlevel)
	if (type(frame) ~= "table") then return; end
	if not frame._fbd then error("Owner frame does not have a backdrop RDX"); end
	if not borderlevel then borderlevel = 1; end
	frame._fbb:SetFrameLevel(frame:GetFrameLevel() + borderlevel);
end
-- deprecated
function VFLUI.ApplyColorBDBackdropRDX(frame, color)
	if (type(frame) ~= "table") or (type(color) ~= "table") then return; end
	if not frame._fbd then error("Owner frame does not have a backdrop RDX"); end
	frame._fbd:SetBackdropColor(VFL.explodeRGBA(color));
end
-- deprecated
function VFLUI.ApplyColorBBBackdropRDX(frame, color)
	if (type(frame) ~= "table") or (type(color) ~= "table") then return; end
	if not frame._fbd then error("Owner frame does not have a backdrop RDX"); end
	frame._fbb:SetBackdropBorderColor(VFL.explodeRGBA(color));
end

-- Border Texture -- deprecated
function VFLUI.SetBackdropBorderRDX(frame, color, drawlayer, sublevel, size, bgcolor)
	if (type(frame) ~= "table") or (type(color) ~= "table") then return; end
	if frame._rdxbl then error("Owner frame already has a backdrop border RDX"); end
	local _l = VFLUI.CreateTexture(frame);
	local _t = VFLUI.CreateTexture(frame);
	local _r = VFLUI.CreateTexture(frame);
	local _b = VFLUI.CreateTexture(frame);
	_l:SetColorTexture(VFL.explodeRGBA(color));
	_t:SetColorTexture(VFL.explodeRGBA(color));
	_r:SetColorTexture(VFL.explodeRGBA(color));
	_b:SetColorTexture(VFL.explodeRGBA(color));
	_l:SetDrawLayer(drawlayer, sublevel);
	_t:SetDrawLayer(drawlayer, sublevel);
	_r:SetDrawLayer(drawlayer, sublevel);
	_b:SetDrawLayer(drawlayer, sublevel);
	_l:SetVertexColor(1,1,1,1);
	_t:SetVertexColor(1,1,1,1);
	_r:SetVertexColor(1,1,1,1);
	_b:SetVertexColor(1,1,1,1);
	_l:SetPoint("LEFT", frame, "LEFT");
	_t:SetPoint("TOP", frame, "TOP");
	_r:SetPoint("RIGHT", frame, "RIGHT");
	_b:SetPoint("BOTTOM", frame, "BOTTOM");
	_l:SetWidth(size or 1); _l:SetHeight(frame:GetHeight());
	_t:SetWidth(frame:GetWidth()); _t:SetHeight(size or 1);
	_r:SetWidth(size or 1); _r:SetHeight(frame:GetHeight());
	_b:SetWidth(frame:GetWidth()); _b:SetHeight(size or 1);

	_l:Show();
	_t:Show();
	_r:Show();
	_b:Show();

	frame._rdxbl = _l;
	frame._rdxbt = _t;
	frame._rdxbr = _r;
	frame._rdxbb = _b;

	if bgcolor then
		local _bg = VFLUI.CreateTexture(frame);
		_bg:SetColorTexture(VFL.explodeRGBA(bgcolor));
		_bg:SetDrawLayer("BACKGROUND", 0);
		_bg:SetVertexColor(1,1,1,1);
		_bg:SetAllPoints(frame);
		_bg:Show();
		frame._rdxbbg = _bg;
	end

	frame.Destroy = VFL.hook(function(s)
		if s._rdxbbg then
			s._rdxbbg:Destroy();
			s._rdxbbg = nil;
		end
		s._rdxbl:Destroy();
		s._rdxbl = nil;
		s._rdxbt:Destroy();
		s._rdxbt = nil;
		s._rdxbr:Destroy();
		s._rdxbr = nil;
		s._rdxbb:Destroy();
		s._rdxbb = nil;
	end, frame.Destroy);
end
-- deprecated
function VFLUI.ResizeBackdropBorderRDX(frame, size)
	if (type(frame) ~= "table") then return; end
	if not frame._rdxbl then error("Owner frame does not have a backdrop border RDX"); end
	frame._rdxbl:SetWidth(size or 1); frame._rdxbl:SetHeight(frame:GetHeight());
	frame._rdxbt:SetWidth(frame:GetWidth()); frame._rdxbt:SetHeight(size or 1);
	frame._rdxbr:SetWidth(size or 1); frame._rdxbr:SetHeight(frame:GetHeight());
	frame._rdxbb:SetWidth(frame:GetWidth()); frame._rdxbb:SetHeight(size or 1);
end
-- deprecated
function VFLUI.ApplyColorBackdropBorderRDX(frame, color)
	if (type(frame) ~= "table") or (type(color) ~= "table") then return; end
	if not frame._rdxbl then error("Owner frame does not have a backdrop border RDX"); end
	frame._rdxbl:SetColorTexture(VFL.explodeRGBA(color));
	frame._rdxbt:SetColorTexture(VFL.explodeRGBA(color));
	frame._rdxbr:SetColorTexture(VFL.explodeRGBA(color));
	frame._rdxbb:SetColorTexture(VFL.explodeRGBA(color));
end

-------------------------------
-- SOUND SYSTEM
-------------------------------
local sounds = {};
local soundList = {};
local function slsf(a,b) return a.title < b.title; end
function VFLUI.RegisterSound(name, title)
	if sounds[name] then return; end -- Prevent duplicate sound registration
	local x = { name = name, title = title };
	sounds[name] = x;
	table.insert(soundList, x);
	table.sort(soundList, slsf);
end

function VFLUI.GetSoundList() return soundList; end


