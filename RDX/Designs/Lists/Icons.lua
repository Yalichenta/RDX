﻿-- Icons.lua
-- OpenRDX
--

local ShowAuraTooltip = RDXDAL.ShowAuraTooltip;
local GetSpellInfoName = VFLUI.GetSpellInfo_name;

function __AuraIconOnEnter(self)
	if self.meta then ShowAuraTooltip(self.meta, self, "RIGHT"); end
end
function __AuraIconOnLeave()
	GameTooltip:Hide();
end

function __AuraIconOnClick(self)
	if not InCombatLockdown() then
		CancelSpellByName(self.meta.name);
	end
end

local ShowCooldownTooltip = RDXCD.ShowCooldownTooltip;

function __CooldownIconOnEnter(self)
	if self.spellid then ShowCooldownTooltip(self.spellid, self, "RIGHT"); end
end
function __CooldownIconOnLeave()
	GameTooltip:Hide();
end

function __TotemIconOnClick(self)
	DestroyTotem(self.id);
end

-----------------------------
-- AURA ICONS
-----------------------------
RDX.RegisterFeature({
	name = "listicons";
	version = 1;
	title = VFLI.i18n("Icons");
	test = true;
	category = VFLI.i18n("Lists");
	multiple = true;
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if not RDXUI.DescriptorCheck(desc, state, errs) then return nil; end
		local flg = true;
		flg = flg and RDXUI.UFFrameCheck_Proto("Icons_", desc, state, errs);
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
		if desc.ftype == 1 or desc.ftype == 2 then
			if (not tonumber(desc.mindurationfilter)) then
				if (desc.mindurationfilter ~= "") then VFL.AddError(errs, VFLI.i18n("Min duration is not a number or empty")); flg = nil; end
			end
			if (not tonumber(desc.maxdurationfilter)) then
				if (desc.maxdurationfilter ~= "") then VFL.AddError(errs, VFLI.i18n("Max duration is not a number or empty")); flg = nil; end
			end
		end
		if desc.externalNameFilter and desc.externalNameFilter ~= "" then
			if not RDXDB.CheckObject(desc.externalNameFilter, "AuraFilter") then VFL.AddError(errs, VFLI.i18n("Invalid aurafilter")); flg = nil; end
		end
		if desc.ftype == 3 then
			if (not desc.number) or (not state:Slot("NumberVar_" .. desc.number)) then
				VFL.AddError(errs, VFLI.i18n("Invalid number object pointer")); return nil;
			end
		end
		if desc.ftype == 4 then
			desc.nIcons = 4;
		end

		if not desc.shader then desc.shader = 2; end

		if flg then state:AddSlot("Icons_" .. desc.name); end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "Icons_" .. desc.name;

		local driver = desc.driver or 1;
		local bs = desc.bs or VFLUI.defaultButtonSkin;
		local bkd = desc.bkd or VFLUI.defaultBackdrop;

		if not desc.nIcons then desc.nIcons = 3; end

		local os = 0;
		if driver == 2 then
			if desc.bs and desc.bs.insets then os = desc.bs.insets or 0; end
		elseif driver == 3 then
			if desc.bkd and desc.bkd.insets and desc.bkd.insets.left then os = desc.bkd.insets.left or 0; end
		end

		local r, g, b, a = 1, 1, 1, 1;
		if driver == 2 then
			r, g, b, a = bs.br or 1, bs.bg or 1, bs.bb or 1, bs.ba or 1;
		elseif driver == 3 then
			r, g, b, a = bkd.br or 1, bkd.bg or 1, bkd.bb or 1, bkd.ba or 1;
		end

		if not desc.drawLayer then desc.drawLayer = "ARTWORK"; end
		if not desc.sublevel then desc.sublevel = 3; end
		if not desc.cd then desc.cd = VFL.copy(VFLUI.defaultCooldown); end

		local loadCode = "";

		local mux, mask = nil, 0;

		if desc.ftype == 1 then
			loadCode = "LoadBuffFromUnit";
			-- Event hinting.
			local wstate = state:GetContainingWindowState();
			if wstate then
				mux, mask = wstate:GetSlotValue("Multiplexer"), 0;
				if desc.auraType == "DEBUFFS" then
					mask = mux:GetPaintMask("DEBUFFS");
					mux:Event_UnitMask("UNIT_DEBUFF_*", mask);
					loadCode = "LoadDebuffFromUnit";
				else
					mask = mux:GetPaintMask("BUFFS");
					mux:Event_UnitMask("UNIT_BUFF_*", mask);
				end
				mask = bit.bor(mask, 1);
			end

			-- If there's an external filter, add a quick menu to the window to edit it.
			if desc.externalNameFilter then
				local path = desc.externalNameFilter; local afname = desc.name;
				local wstate = state:GetContainingWindowState();
				if wstate then
					wstate:Attach("Menu", true, function(win, mnu)
						table.insert(mnu, {
							text = VFLI.i18n("Edit AuraFilter: ") .. afname;
							func = function()
								VFL.poptree:Release();
								RDXDB.OpenObject(path, "Edit", VFLDIALOG);
							end;
						});
					end);
				end
			end

			------------ Closure
			local closureCode = "";
			if desc.filterName then
				closureCode = closureCode ..[[
local ]] .. objname .. [[_fnames = ]];
				if desc.externalNameFilter then
					closureCode = closureCode .. [[
RDXDB.GetObjectInstance(]] .. string.format("%q", desc.externalNameFilter) .. [[);
]];
				else
					-- Internal filter
					closureCode = closureCode .. [[{};
]];
					if desc.filterNameList then
						local flag;
						for _,name in pairs(desc.filterNameList) do
							flag = nil;
							local test = string.sub(name, 1, 1);
							if test == "!" then
								flag = true;
								name = string.sub(name, 2);
							end
							local testnumber = tonumber(name);
							if testnumber then
								local auname = GetSpellInfoName(name);
								if not auname then auname = name; end
								if flag then
									auname = "!" .. auname;
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", auname) .. "] = true; ";
								else
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", auname) .. "] = true; ";
								end
							else
								if flag then
									name = "!" .. name;
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", name) .. "] = true; ";
								else
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", name) .. "] = true; ";
								end
							end
						end
					end
				end
			end
			state:Attach("EmitClosure", true, function(code) code:AppendCode(closureCode); end);
		elseif desc.ftype == 2 then
			-- Event hinting.
			local wstate = state:GetContainingWindowState();
			if wstate then
				mux, mask = wstate:GetSlotValue("Multiplexer"), 0;
				mask = mux:GetPaintMask("COOLDOWN");
				mux:Event_UnitMask("UNIT_COOLDOWN", mask);
				mask = bit.bor(mask, 1);
			end

			loadCode = "unit:GetUsedCooldownsById";
			-- Event hinting.
			if desc.cooldownType == "AVAIL" then
				loadCode = "unit:GetAvailCooldownsById";
			end

			-- If there's an external filter, add a quick menu to the window to edit it.
			if desc.externalNameFiltercd then
				local path = desc.externalNameFiltercd; local afname = desc.name;
				local wstate = state:GetContainingWindowState();
				if wstate then
					wstate:Attach("Menu", true, function(win, mnu)
						table.insert(mnu, {
							text = VFLI.i18n("Edit CooldownFilter: ") .. afname;
							func = function()
								VFL.poptree:Release();
								RDXDB.OpenObject(path, "Edit", VFLDIALOG);
							end;
						});
					end);
				end
			end

		------------ Closure
			if desc.filterNamecd then
				local closureCode = "";
				closureCode = closureCode ..[[
local ]] .. objname .. [[_fnames = ]];
				if desc.externalNameFiltercd then
					closureCode = closureCode .. [[
RDXDB.GetObjectInstance(]] .. string.format("%q", desc.externalNameFiltercd) .. [[);
]];
				else
					-- Internal filter
					closureCode = closureCode .. [[{};
]];
					if desc.filterNameListcd then
						local flag;
						for _,name in pairs(desc.filterNameListcd) do
							flag = nil;
							local test = string.sub(name, 1, 1);
							if test == "!" then
								flag = true;
								name = string.sub(name, 2);
							end
							local testnumber = tonumber(name);
							if testnumber then
								local auname = GetSpellInfoName(name);
								if flag then
									auname = "!" .. auname;
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", auname) .. "] = true; ";
								else
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", auname) .. "] = true; ";
								end
							else
								if flag then
									name = "!" .. name;
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", name) .. "] = true; ";
								else
									closureCode = closureCode .. objname .. "_fnames[" .. string.format("%q", name) .. "] = true; ";
								end
							end
						end
					end
				end
				state:Attach("EmitClosure", true, function(code) code:AppendCode(closureCode); end);
			end
		elseif desc.ftype == 3 then
			local closureCode = [[
local color]] .. objname .. [[ = {};
color]] .. objname .. [[[1] = ]] .. Serialize(desc.color1) .. [[;
color]] .. objname .. [[[2] = ]] .. Serialize(desc.color2) .. [[;
color]] .. objname .. [[[3] = ]] .. Serialize(desc.color3) .. [[;
color]] .. objname .. [[[4] = ]] .. Serialize(desc.color4) .. [[;
color]] .. objname .. [[[5] = ]] .. Serialize(desc.color5) .. [[;
]];
			state:Attach("EmitClosure", true, function(code) code:AppendCode(closureCode); end);
		elseif desc.ftype == 4 then
			local wstate = state:GetContainingWindowState();
			if wstate then
				mux = wstate:GetSlotValue("Multiplexer");
				smask = mux:GetPaintMask("TOTEM_UPDATE");
				umask = mux:GetPaintMask("ENTERING_WORLD");
				mux:Event_UnitMask("UNIT_TOTEM_UPDATE", smask);
				mux:Event_UnitMask("UNIT_ENTERING_WORLD", umask);
			end
		end

		----------------- Creation
		local createCode = [[
	frame.]] .. objname .. [[ = {};
	local btn, btnOwner = nil, ]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[;
	local h = VFLUI.AcquireFrame("Frame");
	VFLUI.StdSetParent(h, btnOwner);
	h:SetFrameLevel(btnOwner:GetFrameLevel() + 1);
	h:Show();
	frame.]] .. objname .. [[header = h;
	for i=1, ]] .. desc.nIcons .. [[ do
		btn = VFLUI.AcquireFrame("Button");
		btn:SetWidth(]] .. desc.w .. [[); btn:SetHeight(]] .. desc.h .. [[);
		btn:SetParent(h); btn:SetFrameLevel(h:GetFrameLevel());
]];
		if driver == 2 then
			createCode = createCode .. [[
		VFLUI.SetButtonSkin(btn, ]] .. Serialize(bs) .. [[);
]];
		elseif driver == 3 then
			createCode = createCode .. [[
		VFLUI.SetBackdrop(btn, ]] .. Serialize(bkd) .. [[);
]];
		end
		if desc.ftype == 1 and not desc.disableClick then createCode = createCode .. [[
		btn:RegisterForClicks("RightButtonUp");
		btn:SetScript("OnClick", __AuraIconOnClick);
]];
		end
		if desc.ftype == 4 and not desc.disableClick then createCode = createCode .. [[
		btn:RegisterForClicks("RightButtonUp");
		btn:SetScript("OnClick", __TotemIconOnClick);
]];
		end
		if desc.ftype == 4 then createCode = createCode .. [[
		btn.id = i;
]];
		end
		if desc.disableClick then createCode = createCode .. [[
		btn:Disable();
]];
		end
		if not desc.disableShowTooltip then
			if desc.ftype == 1 then
				createCode = createCode .. [[
		btn:SetScript("OnEnter", __AuraIconOnEnter);
		btn:SetScript("OnLeave", __AuraIconOnLeave);
]];
			elseif desc.ftype == 2 then
				createCode = createCode .. [[
		btn:SetScript("OnEnter", __CooldownIconOnEnter);
		btn:SetScript("OnLeave", __CooldownIconOnLeave);
]];
			end
		end
		createCode = createCode .. [[
		btn.tex = VFLUI.CreateTexture(btn);
		btn.tex:SetPoint("TOPLEFT", btn, "TOPLEFT", ]] .. os .. [[, -]] .. os .. [[);
		btn.tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -]] .. os .. [[, ]] .. os .. [[);
		if not RDXG.usecleanicons then
			btn.tex:SetTexCoord(0.05, 1-0.06, 0.05, 1-0.04);
		end
		btn.tex:SetDrawLayer("ARTWORK", 3);
		btn.tex:Show();
]];
		if desc.ftype == 3 then
			createCode = createCode .. VFLUI.GenerateSetTextureCode("btn.tex", desc.texture)
		end
		createCode = createCode .. [[
		btn.cd = VFLUI.CooldownCounter:new(btn, ]] .. Serialize(desc.cd) .. [[);
		btn.cd:SetAllPoints(btn.tex);
		btn.cd:Show();
]];
		createCode = createCode .. [[
		btn.frtxt = VFLUI.AcquireFrame("Frame");
		btn.frtxt:SetParent(btn);
		btn.frtxt:SetFrameLevel(btn:GetFrameLevel() + 2);
		btn.frtxt:SetAllPoints(btn);
		btn.frtxt:Show();
		btn.sttxt = VFLUI.CreateFontString(btn.frtxt);
		btn.sttxt:SetAllPoints(btn.frtxt);
		btn.sttxt:Show();
]];
		createCode = createCode .. VFLUI.GenerateSetFontCode("btn.sttxt", desc.fontst, nil, true);
		createCode = createCode .. [[
		frame.]] .. objname .. [[[i] = btn;
	end
]];
		createCode = createCode .. RDXUI.LayoutCodeMultiRows(objname, desc);
		createCode = createCode .. RDXUI.LayoutHeaderCodeMultiRows(objname, desc);
		state:Attach("EmitCreate", true, function(code) code:AppendCode(createCode); end);

		------------------- Destruction
		local destroyCode = [[
		for i=1,]] .. desc.nIcons .. [[ do
			btn = frame.]] .. objname .. [[[i]
			btn.meta = nil;
			VFLUI.ReleaseRegion(btn.sttxt); btn.sttxt = nil;
			btn.frtxt:Destroy(); btn.frtxt = nil;
			btn.cd:Destroy(); btn.cd = nil;
			VFLUI.ReleaseRegion(btn.tex); btn.tex = nil;
			btn:Destroy(); btn = nil;
		end
		frame.]] .. objname .. [[header:Destroy();
		frame.]] .. objname .. [[header = nil;
		frame.]] .. objname .. [[ = nil;
]];
		state:Attach("EmitDestroy", true, function(code) code:AppendCode(destroyCode); end);

		------------------- Paint
		--local winpath = state:GetContainingWindowState():GetSlotValue("Path");
		--local md = RDXDB.GetObjectData(winpath);
		local auracache = "false"; --if md and RDXDB.HasFeature(md.data, "AuraCache") then auracache = "true"; end
		local smooth = "nil"; if desc.smooth then smooth = "RDX.smooth"; end
		local raidfilter = "nil"; if desc.raidfilter then raidfilter = "true"; end

		local aurasfilter, afflag = " (", nil;
		if desc.playerauras then aurasfilter = aurasfilter .. " _caster == 'player'"; afflag = true; end
		if desc.othersauras then
			if afflag then
				aurasfilter = aurasfilter .. " or _caster ~= 'player'";
			else
				aurasfilter = aurasfilter .. " _caster ~= 'player'"; afflag = true;
			end
		end
		if desc.petauras then
			if afflag then
				aurasfilter = aurasfilter .. " or _caster == 'pet' or _caster == 'vehicle'";
			else
				aurasfilter = aurasfilter .. " _caster == 'pet' or _caster == 'vehicle'"; afflag = true;
			end

		end
		if desc.targetauras then
			if afflag then
				aurasfilter = aurasfilter .. " or _caster == 'target'";
			else
				aurasfilter = aurasfilter .. " _caster == 'target'"; afflag = true;
			end
		end
		if desc.focusauras then
			if afflag then
				aurasfilter = aurasfilter .. " or _caster == 'focus'";
			else
				aurasfilter = aurasfilter .. " _caster == 'focus'"; afflag = true;
			end
		end
		if not afflag then aurasfilter = aurasfilter .. " true"; end
		aurasfilter = aurasfilter .. " )";

		local isstealablefilter = "true"; if desc.isstealablefilter then isstealablefilter = "_isStealable"; end
		local curefilter = "true"; if desc.curefilter then curefilter = "(_dispelt and RDXSS.GetCategoryByName('CURE_'..string.upper(_dispelt)))"; end

		local timefilter = "true";
		if desc.timefilter then timefilter = "(_dur > 0";
			if (desc.mindurationfilter ~= "") then timefilter = timefilter .. " and _dur >= " .. desc.mindurationfilter; end
			if (desc.maxdurationfilter ~= "") then timefilter = timefilter .. " and _dur <= " .. desc.maxdurationfilter; end
			timefilter = timefilter ..")";
		elseif desc.notimefilter then
			timefilter = "(_dur == 0)";
		end
		local namefilter = "true"; if desc.filterName then
			namefilter = "(" .. objname .. "_fnames[_bn] or " .. objname .. "_fnames[_meta.category])";
			namefilter = namefilter .. " and (not (" .. objname .. "_fnames['!'.._bn] or " .. objname .. "_fnames['!'.._meta.category]))"
		end

		local number = 0;
		if desc.number then number = desc.number; end

		--local sorticons = " ";
		--desc.sort = nil;
		--if desc.sort then
		--	if desc.sortduration then sorticons = sorticons .. [[
		--	table.sort(sort_icons, function(x1,x2) return x1._dur < x2._dur; end); ]];
		--	end
		--	if desc.sortstack then sorticons = sorticons .. [[
		--	table.sort(sort_icons, function(x1,x2) return x1._apps < x2._apps; end); ]];
		--	end
		--	if desc.sorttimeleft then sorticons = sorticons .. [[
		--	table.sort(sort_icons, function(x1,x2) return x1._tl < x2._tl; end); ]];
		--	end
		--	if desc.sortname then sorticons = sorticons .. [[
		--	table.sort(sort_icons, function(x1,x2) return x1._bn < x2._bn; end); ]];
		--	end
		--end

		local paintCodeTest = [[
		_i, _j, _bn, _tex, _apps, _meta, _dur, _tl, _dispelt, _caster, _isStealable = 1,1,nil,nil,nil,nil,nil,nil,nil,nil;
		_icons = frame.]] .. objname .. [[;
		while true do
			if (_j > ]] .. desc.nIcons .. [[) then break; end
			_, _bn, _, _, _meta, _, _tex, _apps, _dispelt, _dur, _, _tl, _caster, _isStealable = nil, true, nil, nil, {}, nil, "Interface\\InventoryItems\\WoWUnknownItem01.blp", 6, nil, 60, nil, 50, true, true;
			btn = _icons[_j];
			if not btn:IsShown() then btn:Show(smooth); end
			btn.meta = _meta;
			btn.tex:SetTexture(_tex);
			if _dispelt and DebuffTypeColor[_dispelt] then
]];
		if desc.shader == 1 then
			paintCodeTest = paintCodeTest .. [[
]];
		elseif desc.shader == 2 then
			if desc.driver == 2 then
				paintCodeTest = paintCodeTest .. [[
						VFLUI.SetButtonSkinBorderColor(btn, explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						VFLUI.SetButtonSkinBorderColor(btn, ]] .. r .. [[, ]] .. g .. [[, ]] .. b .. [[, ]] .. a .. [[);
]];
			elseif desc.driver == 3 then
				paintCodeTest = paintCodeTest .. [[
						VFLUI.SetBackdropBorderColor(btn, explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						VFLUI.SetBackdropBorderColor(btn, ]] .. r .. [[, ]] .. g .. [[, ]] .. b .. [[, ]] .. a .. [[);
]];
			end
		elseif desc.shader == 3 then
			paintCodeTest = paintCodeTest .. [[
						btn.tex:SetVertexColor(explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						btn.tex:SetVertexColor(1, 1, 1, 1);
]];
		end
		paintCodeTest = paintCodeTest .. [[
			end
			-- Cooldown
			if _dur and _dur > 0 and btn.cd then
				btn.cd:SetCooldown(GetTime() + _tl - _dur , _dur);
			else
				btn.cd:SetCooldown(0, 0);
			end
			if _apps and (_apps > 1) then btn.sttxt:SetText(_apps); else btn.sttxt:SetText(""); end

			_j = _j + 1;

			--_i = _i + 1;
		end
		--while _j <= ]] .. desc.nIcons .. [[ do
			--btn = _icons[_j];
			--if btn:IsShown() then btn:Hide(]] .. smooth .. [[); end
			--_j = _j + 1;
		--end
]];

		local paintCodeAura = [[
		if band(paintmask, ]] .. mask .. [[) ~= 0 then
			_i, _j, _bn, _tex, _apps, _meta, _dur, _tl, _dispelt, _caster, _isStealable = 1,1,nil,nil,nil,nil,nil,nil,nil,nil;
			_icons = frame.]] .. objname .. [[;
			while true do
				if (_j > ]] .. desc.nIcons .. [[) then break; end
				_, _bn, _, _, _meta, _, _tex, _apps, _dispelt, _dur, _, _tl, _caster, _isStealable = ]] .. loadCode .. [[(uid, _i, ]] .. raidfilter .. [[, ]] .. auracache .. [[);
				if not _meta then break; end
				if (not _meta.isInvisible) and ]] .. aurasfilter .. [[ and ]] .. isstealablefilter .. [[ and ]] .. curefilter .. [[ and ]] .. timefilter .. [[ and ]] .. namefilter .. [[ then
					btn = _icons[_j];
					if not btn:IsShown() then btn:Show(smooth); end
					btn.meta = _meta;
					btn.tex:SetTexture(_tex);
					if _dispelt and DebuffTypeColor[_dispelt] then
]];
		if desc.shader == 1 then
			paintCodeAura = paintCodeAura .. [[
]];
		elseif desc.shader == 2 then
			if desc.driver == 2 then
				paintCodeAura = paintCodeAura .. [[
						VFLUI.SetButtonSkinBorderColor(btn, explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						VFLUI.SetButtonSkinBorderColor(btn, ]] .. r .. [[, ]] .. g .. [[, ]] .. b .. [[, ]] .. a .. [[);
]];
			elseif desc.driver == 3 then
				paintCodeAura = paintCodeAura .. [[
						VFLUI.SetBackdropBorderColor(btn, explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						VFLUI.SetBackdropBorderColor(btn, ]] .. r .. [[, ]] .. g .. [[, ]] .. b .. [[, ]] .. a .. [[);
]];
			end
		elseif desc.shader == 3 then
			paintCodeAura = paintCodeAura .. [[
						btn.tex:SetVertexColor(explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						btn.tex:SetVertexColor(1, 1, 1, 1);
]];
		end
		paintCodeAura = paintCodeAura .. [[
					end

					-- Cooldown
					if _dur and _dur > 0 and btn.cd then
						btn.cd:SetCooldown(GetTime() + _tl - _dur , _dur);
					else
						btn.cd:SetCooldown(0, 0);
					end
					if _apps and (_apps > 1) then btn.sttxt:SetText(_apps); else btn.sttxt:SetText(""); end

					_j = _j + 1;
				end
				_i = _i + 1;
			end
			while _j <= ]] .. desc.nIcons .. [[ do
				btn = _icons[_j];
				if btn:IsShown() then btn:Hide(]] .. smooth .. [[); end
				_j = _j + 1;
			end
		end
]];

		local paintCodeCd = [[
		if band(paintmask, ]] .. mask .. [[) ~= 0 then
			_i, _j, _avail, _bn, _meta, _tex, _dur, _start = 1, 1, nil, nil, nil, nil, nil;
			_icons = frame.]] .. objname .. [[;
			while true do
				if (_j > ]] .. desc.nIcons .. [[) then break; end
				_avail, _bn, _meta, _tex, _dur, _start = ]] .. loadCode .. [[(_i);
				if not _avail then break; end
				if ]] .. timefilter .. [[ and ]] .. namefilter .. [[ then
					btn = _icons[_j];
					if not btn:IsShown() then btn:Show(); end
					btn.spellid = _meta;
					btn.tex:SetTexture(_tex);
					if _dur and _dur > 0 and btn.cd then
						btn.cd:SetCooldown(_start, _dur);
					end
					_j = _j + 1;
				end
				_i = _i + 1;
			end
			while _j <= ]] .. desc.nIcons .. [[ do
				if _icons[_j]:IsShown() then _icons[_j]:Hide(); end
				_j = _j + 1;
			end
		end
]];
		local paintCodeCustom = [[
		_i = VFL.clamp(]] .. number .. [[, 0, ]] .. desc.nIcons .. [[);
		if _i and _i > 0 then
			for i=1, _i do
				frame.]] .. objname .. [[[i].tex:SetVertexColor(explodeRGBA(color]] .. objname .. [[[i]));
				frame.]] .. objname .. [[[i]:Show();
			end
			if _i < ]] .. desc.nIcons .. [[ then
				for i=(_i + 1), ]] .. desc.nIcons .. [[ do
					frame.]] .. objname .. [[[i]:Hide();
				end
			end
		else
			for i=1,]] .. desc.nIcons .. [[ do
				frame.]] .. objname .. [[[i]:Hide();
			end
		end
]];
		local paintCodeTotem = [[
		for i=1, 4 do
			_avail, _bn, _start, _dur, _tex = GetTotemInfo(i);
			if _avail then
				frame.]] .. objname .. [[[i].tex:SetTexture(_tex);
				frame.]] .. objname .. [[[i].cd:SetCooldown(_start, _dur);
				frame.]] .. objname .. [[[i]:Show();
			else
				frame.]] .. objname .. [[[i]:Hide();
			end
		end
]];
		if desc.test then
			state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCodeTest); end);
		elseif desc.ftype == 1 then
			state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCodeAura); end);
		elseif desc.ftype == 2 then
			state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCodeCd); end);
		elseif desc.ftype == 3 then
			state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCodeCustom); end);
		elseif desc.ftype == 4 then
			state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCodeTotem); end);
		end
		------------------- Cleanup
		local cleanupCode = [[
	local btn = nil;
	for i=1,]] .. desc.nIcons .. [[ do
		btn = frame.]] .. objname .. [[[i];
		btn:Hide(); btn.meta = nil;
	end
]];
		state:Attach("EmitCleanup", true, function(code) code:AppendCode(cleanupCode); end);

		return true;
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);

		------------- Core
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Core Parameters")));

		local ed_name = VFLUI.LabeledEdit:new(ui, 100); ed_name:Show();
		ed_name:SetText(VFLI.i18n("Name"));
		ed_name.editBox:SetText(desc.name);
		ui:InsertFrame(ed_name);

		------------- Layout
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Layout parameters")));

		local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, {"Frame_", "Button_", "Cooldown_", });
		if desc and desc.owner then owner:SetSelection(desc.owner); end

		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);

		local ed_nicon = VFLUI.LabeledEdit:new(ui, 50); ed_nicon:Show();
		ed_nicon:SetText(VFLI.i18n("Max icons"));
		if desc and desc.nIcons then ed_nicon.editBox:SetText(desc.nIcons); end
		ui:InsertFrame(ed_nicon);

		local ed_rows = VFLUI.LabeledEdit:new(ui, 50); ed_rows:Show();
		ed_rows:SetText(VFLI.i18n("Row number"));
		if desc and desc.rows then ed_rows.editBox:SetText(desc.rows); end
		ui:InsertFrame(ed_rows);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Orientation"));
		local dd_orientation = VFLUI.Dropdown:new(er, RDXUI.OrientationDropdownFunction);
		dd_orientation:SetWidth(75); dd_orientation:Show();
		if desc and desc.orientation then
			dd_orientation:SetSelection(desc.orientation);
		else
			dd_orientation:SetSelection("RIGHT");
		end
		er:EmbedChild(dd_orientation); er:Show();
		ui:InsertFrame(er);

		local ed_iconspx = VFLUI.LabeledEdit:new(ui, 50); ed_iconspx:Show();
		ed_iconspx:SetText(VFLI.i18n("Width spacing"));
		if desc and desc.iconspx then ed_iconspx.editBox:SetText(desc.iconspx); else ed_iconspx.editBox:SetText("0"); end
		ui:InsertFrame(ed_iconspx);

		local ed_iconspy = VFLUI.LabeledEdit:new(ui, 50); ed_iconspy:Show();
		ed_iconspy:SetText(VFLI.i18n("Height spacing"));
		if desc and desc.iconspy then ed_iconspy.editBox:SetText(desc.iconspy); else ed_iconspy.editBox:SetText("0"); end
		ui:InsertFrame(ed_iconspy);

		local ed_width = VFLUI.LabeledEdit:new(ui, 50); ed_width:Show();
		ed_width:SetText(VFLI.i18n("Width"));
		if desc and desc.w then ed_width.editBox:SetText(desc.w); else ed_width.editBox:SetText("20"); end
		ui:InsertFrame(ed_width);

		local ed_height = VFLUI.LabeledEdit:new(ui, 50); ed_height:Show();
		ed_height:SetText(VFLI.i18n("Height"));
		if desc and desc.h then ed_height.editBox:SetText(desc.h); else ed_height.editBox:SetText("20"); end
		ui:InsertFrame(ed_height);


		-- to be replace by h and w ?

		-------------- Display
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Skin parameters")));

		local driver = VFLUI.DisjointRadioGroup:new();

		local driver_NS = driver:CreateRadioButton(ui);
		driver_NS:SetText(VFLI.i18n("No Skin"));
		local driver_BS = driver:CreateRadioButton(ui);
		driver_BS:SetText(VFLI.i18n("Use Button Skin"));
		local driver_BD = driver:CreateRadioButton(ui);
		driver_BD:SetText(VFLI.i18n("Use Backdrop"));
		driver:SetValue(desc.driver or 1);

		ui:InsertFrame(driver_NS);

		ui:InsertFrame(driver_BS);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("ButtonSkin"));
		local dd_buttonskin = VFLUI.MakeButtonSkinSelectButton(er, desc.bs);
		dd_buttonskin:Show();
		er:EmbedChild(dd_buttonskin); er:Show();
		ui:InsertFrame(er);

		ui:InsertFrame(driver_BD);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Backdrop"));
		local dd_backdrop = VFLUI.MakeBackdropSelectButton(er, desc.bkd);
		dd_backdrop:Show();
		er:EmbedChild(dd_backdrop); er:Show();
		ui:InsertFrame(er);

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Shader parameters")));

		--local chk_hidebs = VFLUI.Checkbox:new(ui); chk_hidebs:Show();
		--chk_hidebs:SetText(VFLI.i18n("Hide empty button"));
		--if desc and desc.hidebs then chk_hidebs:SetChecked(true); else chk_hidebs:SetChecked(); end
		--ui:InsertFrame(chk_hidebs);

		-- Shader stuff

		local shader = VFLUI.DisjointRadioGroup:new();

		local shader_key = shader:CreateRadioButton(ui);
		shader_key:SetText(VFLI.i18n("No Shader (dispell)"));
		local shader_border = shader:CreateRadioButton(ui);
		shader_border:SetText(VFLI.i18n("Use Border Shader"));
		local shader_icon = shader:CreateRadioButton(ui);
		shader_icon:SetText(VFLI.i18n("Use Icon Shader"));
		shader:SetValue(desc.shader or 2);

		ui:InsertFrame(shader_key);

		ui:InsertFrame(shader_border);

		ui:InsertFrame(shader_icon);

		-------------- Interraction
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Interaction parameters")));

		local chk_disableClick = VFLUI.Checkbox:new(ui); chk_disableClick:Show();
		chk_disableClick:SetText(VFLI.i18n("Disable button"));
		if desc and desc.disableClick then chk_disableClick:SetChecked(true); else chk_disableClick:SetChecked(); end
		ui:InsertFrame(chk_disableClick);

		local chk_disableShowTooltip = VFLUI.Checkbox:new(ui); chk_disableShowTooltip:Show();
		chk_disableShowTooltip:SetText(VFLI.i18n("Disable tooltip"));
		if desc and desc.disableShowTooltip then chk_disableShowTooltip:SetChecked(true); else chk_disableShowTooltip:SetChecked(); end
		ui:InsertFrame(chk_disableShowTooltip);

		-------------- Texture
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Texture parameters")));

		-- Drawlayer
		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Draw layer"));
		local drawLayer = VFLUI.Dropdown:new(er, RDXUI.DrawLayerDropdownFunction);
		drawLayer:SetWidth(150); drawLayer:Show();
		if desc and desc.drawLayer then drawLayer:SetSelection(desc.drawLayer); else drawLayer:SetSelection("ARTWORK"); end
		er:EmbedChild(drawLayer); er:Show();
		ui:InsertFrame(er);

		-- SubLevel
		local ed_sublevel = VFLUI.LabeledEdit:new(ui, 50); ed_sublevel:Show();
		ed_sublevel:SetText(VFLI.i18n("TextureLevel offset"));
		if desc and desc.sublevel then ed_sublevel.editBox:SetText(desc.sublevel); end
		ui:InsertFrame(ed_sublevel);

		-------------- CooldownDisplay
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Cooldown parameters")));
		local ercd = VFLUI.EmbedRight(ui, VFLI.i18n("Cooldown"));
		local cd = VFLUI.MakeCooldownSelectButton(ercd, desc.cd); cd:Show();
		ercd:EmbedChild(cd); ercd:Show();
		ui:InsertFrame(ercd);

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Font parameters")));

		local er_st = VFLUI.EmbedRight(ui, VFLI.i18n("Font stack"));
		local fontsel2 = VFLUI.MakeFontSelectButton(er_st, desc.fontst); fontsel2:Show();
		er_st:EmbedChild(fontsel2); er_st:Show();
		ui:InsertFrame(er_st);

		--ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Smooth show hide")));
		--local chk_smooth = VFLUI.Checkbox:new(ui); chk_smooth:Show();
		--chk_smooth:SetText(VFLI.i18n("Use smooth on show and hide"));
		--if desc and desc.smooth then chk_smooth:SetChecked(true); else chk_smooth:SetChecked(); end
		--ui:InsertFrame(chk_smooth);

		------------ Sort
		--[[ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Sort")));

		local chk_sort = VFLUI.Checkbox:new(ui); chk_sort:Show();
		chk_sort:SetText(VFLI.i18n("Activate Sort"));
		if desc and desc.sort then chk_sort:SetChecked(true); else chk_sort:SetChecked(); end
		ui:InsertFrame(chk_sort);

		local chk_sortstack = VFLUI.Checkbox:new(ui); chk_sortstack:Show();
		chk_sortstack:SetText(VFLI.i18n("Sort by stack"));
		if desc and desc.sortstack then chk_sortstack:SetChecked(true); else chk_sortstack:SetChecked(); end
		ui:InsertFrame(chk_sortstack);

		local chk_sortduration = VFLUI.Checkbox:new(ui); chk_sortduration:Show();
		chk_sortduration:SetText(VFLI.i18n("Sort by duration"));
		if desc and desc.sortduration then chk_sortduration:SetChecked(true); else chk_sortduration:SetChecked(); end
		ui:InsertFrame(chk_sortduration);

		local chk_sorttimeleft = VFLUI.Checkbox:new(ui); chk_sorttimeleft:Show();
		chk_sorttimeleft:SetText(VFLI.i18n("Sort by timeleft"));
		if desc and desc.sorttimeleft then chk_sorttimeleft:SetChecked(true); else chk_sorttimeleft:SetChecked(); end
		ui:InsertFrame(chk_sorttimeleft);

		local chk_sortname = VFLUI.Checkbox:new(ui); chk_sortname:Show();
		chk_sortname:SetText(VFLI.i18n("Sort by name"));
		if desc and desc.sortname then chk_sortname:SetChecked(true); else chk_sortname:SetChecked(); end
		ui:InsertFrame(chk_sortname);]]

		------------ Filter
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Filtering parameters")));

		local chk_notimefilter = VFLUI.Checkbox:new(ui); chk_notimefilter:Show();
		chk_notimefilter:SetText(VFLI.i18n("Show only icons with no timer"));
		if desc and desc.notimefilter then chk_notimefilter:SetChecked(true); else chk_notimefilter:SetChecked(); end
		ui:InsertFrame(chk_notimefilter);

		local chk_timefilter = VFLUI.Checkbox:new(ui); chk_timefilter:Show();
		chk_timefilter:SetText(VFLI.i18n("Show only icons with timer"));
		if desc and desc.timefilter then chk_timefilter:SetChecked(true); else chk_timefilter:SetChecked(); end
		ui:InsertFrame(chk_timefilter);

		local ed_maxduration = VFLUI.LabeledEdit:new(ui, 50); ed_maxduration:Show();
		ed_maxduration:SetText(VFLI.i18n("Filter by Max duration (sec)"));
		if desc and desc.maxdurationfilter then ed_maxduration.editBox:SetText(desc.maxdurationfilter); else ed_maxduration.editBox:SetText(""); end
		ui:InsertFrame(ed_maxduration);

		local ed_minduration = VFLUI.LabeledEdit:new(ui, 50); ed_minduration:Show();
		ed_minduration:SetText(VFLI.i18n("Filter by min duration (sec)"));
		if desc and desc.mindurationfilter then ed_minduration.editBox:SetText(desc.mindurationfilter); else ed_minduration.editBox:SetText(""); end
		ui:InsertFrame(ed_minduration);

		-- Feature type
		local ftype = VFLUI.DisjointRadioGroup:new();
		local ftype_1 = ftype:CreateRadioButton(ui);
		ftype_1:SetText(VFLI.i18n("Use Aura Icons"));
		local ftype_2 = ftype:CreateRadioButton(ui);
		ftype_2:SetText(VFLI.i18n("Use Coodown Icons"));
		local ftype_3 = ftype:CreateRadioButton(ui);
		ftype_3:SetText(VFLI.i18n("Use Custom Icons"));
		local ftype_4 = ftype:CreateRadioButton(ui);
		ftype_4:SetText(VFLI.i18n("Use Totems Icons"));
		ftype:SetValue(desc.ftype or 1);

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Aura Icons")));
		ui:InsertFrame(ftype_1);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Aura Type"));
		local dd_auraType = VFLUI.Dropdown:new(er, RDXUI.AurasTypesDropdownFunction);
		dd_auraType:SetWidth(150); dd_auraType:Show();
		if desc and desc.auraType then
			dd_auraType:SetSelection(desc.auraType);
		else
			dd_auraType:SetSelection("BUFFS");
		end
		er:EmbedChild(dd_auraType); er:Show();
		ui:InsertFrame(er);

		local chk_raidfilter = VFLUI.Checkbox:new(ui); chk_raidfilter:Show();
		chk_raidfilter:SetText(VFLI.i18n("Use Blizzard raid filter"));
		if desc and desc.raidfilter then chk_raidfilter:SetChecked(true); else chk_raidfilter:SetChecked(); end
		ui:InsertFrame(chk_raidfilter);

		local chk_playerauras = VFLUI.Checkbox:new(ui); chk_playerauras:Show();
		chk_playerauras:SetText(VFLI.i18n("Filter auras by player"));
		if desc and desc.playerauras then chk_playerauras:SetChecked(true); else chk_playerauras:SetChecked(); end
		ui:InsertFrame(chk_playerauras);

		local chk_othersauras = VFLUI.Checkbox:new(ui); chk_othersauras:Show();
		chk_othersauras:SetText(VFLI.i18n("Filter auras by other players"));
		if desc and desc.othersauras then chk_othersauras:SetChecked(true); else chk_othersauras:SetChecked(); end
		ui:InsertFrame(chk_othersauras);

		local chk_petauras = VFLUI.Checkbox:new(ui); chk_petauras:Show();
		chk_petauras:SetText(VFLI.i18n("Filter auras by pet/vehicle"));
		if desc and desc.petauras then chk_petauras:SetChecked(true); else chk_petauras:SetChecked(); end
		ui:InsertFrame(chk_petauras);

		local chk_targetauras = VFLUI.Checkbox:new(ui); chk_targetauras:Show();
		chk_targetauras:SetText(VFLI.i18n("Filter auras by target"));
		if desc and desc.targetauras then chk_targetauras:SetChecked(true); else chk_targetauras:SetChecked(); end
		ui:InsertFrame(chk_targetauras);

		local chk_focusauras = VFLUI.Checkbox:new(ui); chk_focusauras:Show();
		chk_focusauras:SetText(VFLI.i18n("Filter auras by focus"));
		if desc and desc.focusauras then chk_focusauras:SetChecked(true); else chk_focusauras:SetChecked(); end
		ui:InsertFrame(chk_focusauras);

		local chk_nameauras = VFLUI.Checkbox:new(ui); chk_nameauras:Show();
		chk_nameauras:SetText(VFLI.i18n("Filter auras by name"));
		if desc and desc.nameauras then chk_nameauras:SetChecked(true); else chk_nameauras:SetChecked(); end
		ui:InsertFrame(chk_nameauras);

		local ed_unitfilter = VFLUI.LabeledEdit:new(ui, 200); ed_unitfilter:Show();
		ed_unitfilter:SetText(VFLI.i18n("Name of the unit"));
		if desc and desc.unitfilter then ed_unitfilter.editBox:SetText(desc.unitfilter); else ed_unitfilter.editBox:SetText(""); end
		ui:InsertFrame(ed_unitfilter);

		local chk_isStealable = VFLUI.Checkbox:new(ui); chk_isStealable:Show();
		chk_isStealable:SetText(VFLI.i18n("Show only Stealable auras"));
		if desc and desc.isstealablefilter then chk_isStealable:SetChecked(true); else chk_isStealable:SetChecked(); end
		ui:InsertFrame(chk_isStealable);

		local chk_curefilter = VFLUI.Checkbox:new(ui); chk_curefilter:Show();
		chk_curefilter:SetText(VFLI.i18n("Show only auras that I can cure"));
		if desc and desc.curefilter then chk_curefilter:SetChecked(true); else chk_curefilter:SetChecked(); end
		ui:InsertFrame(chk_curefilter);

		local chk_filterName = VFLUI.Checkbox:new(ui); chk_filterName:Show();
		chk_filterName:SetText(VFLI.i18n("Filter by aura name"));
		if desc and desc.filterName then chk_filterName:SetChecked(true); else chk_filterName:SetChecked(); end
		ui:InsertFrame(chk_filterName);

		local chk_external = VFLUI.CheckEmbedRight(ui, VFLI.i18n("Use external aura list"));
		local file_external = RDXDB.ObjectFinder:new(chk_external, function(d,p,f,md) return (md and type(md) == "table" and md.ty and string.find(md.ty, "AuraFilter$")); end);
		file_external:SetWidth(200); file_external:Show();
		chk_external:EmbedChild(file_external); chk_external:Show();
		ui:InsertFrame(chk_external);
		if desc.externalNameFilter then
			chk_external:SetChecked(true); file_external:SetPath(desc.externalNameFilter);
		else
			chk_external:SetChecked();
		end

		local le_names = VFLUI.ListEditor:new(ui, desc.filterNameList or {}, function(cell,data)
			if type(data) == "number" then
				local name = GetSpellInfoName(data);
				cell.text:SetText(name);
			else
				local test = string.sub(data, 1, 1);
				if test == "!" then
					local uname = string.sub(data, 2);
					local vname = GetSpellInfoName(uname);
					if vname then
						cell.text:SetText("!" .. vname);
					else
						cell.text:SetText(data);
					end
				else
					cell.text:SetText(data);
				end
			end
		end);
		le_names:SetHeight(183); le_names:Show();
		ui:InsertFrame(le_names);

		ui:InsertFrame(VFLUI.EmptySeparator:new(ui, 30));

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Cooldown Icons")));
		ui:InsertFrame(ftype_2);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Cooldown Type"));
		local dd_cooldownType = VFLUI.Dropdown:new(er, RDXUI.CooldownsTypesDropdownFunction);
		dd_cooldownType:SetWidth(150); dd_cooldownType:Show();
		if desc and desc.cooldownType then
			dd_cooldownType:SetSelection(desc.cooldownType);
		else
			dd_cooldownType:SetSelection("USED");
		end
		er:EmbedChild(dd_cooldownType); er:Show();
		ui:InsertFrame(er);

		local chk_filterNamecd = VFLUI.Checkbox:new(ui); chk_filterNamecd:Show();
		chk_filterNamecd:SetText(VFLI.i18n("Filter by cooldown name"));
		if desc and desc.filterNamecd then chk_filterNamecd:SetChecked(true); else chk_filterNamecd:SetChecked(); end
		ui:InsertFrame(chk_filterNamecd);

		local chk_externalcd = VFLUI.CheckEmbedRight(ui, VFLI.i18n("Use external cooldown list"));
		local file_externalcd = RDXDB.ObjectFinder:new(chk_externalcd, function(d,p,f,md) return (md and type(md) == "table" and md.ty and string.find(md.ty, "CooldownFilter$")); end);
		file_externalcd:SetWidth(200); file_externalcd:Show();
		chk_externalcd:EmbedChild(file_externalcd); chk_externalcd:Show();
		ui:InsertFrame(chk_externalcd);
		if desc.externalNameFiltercd then
			chk_externalcd:SetChecked(true); file_externalcd:SetPath(desc.externalNameFiltercd);
		else
			chk_externalcd:SetChecked();
		end

		local le_namescd = VFLUI.ListEditor:new(ui, desc.filterNameListcd or {}, function(cell,data)
			if type(data) == "number" then
				local name = GetSpellInfoName(data);
				cell.text:SetText(name);
			else
				local test = string.sub(data, 1, 1);
				if test == "!" then
					local uname = string.sub(data, 2);
					local vname = GetSpellInfoName(uname);
					if vname then
						cell.text:SetText("!" .. vname);
					else
						cell.text:SetText(data);
					end
				else
					cell.text:SetText(data);
				end
			end
		end);
		le_namescd:SetHeight(183); le_namescd:Show();
		ui:InsertFrame(le_namescd);

		ui:InsertFrame(VFLUI.EmptySeparator:new(ui, 30));

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Custom Icons")));

		ui:InsertFrame(ftype_3);

		local number = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Number"), state, "NumberVar_");
		if desc and desc.number then number:SetSelection(desc.number); end

		-- Texture
		local er = VFLUI.EmbedRight(ui, "Texture");
		local tsel = VFLUI.MakeTextureSelectButton(er, desc.texture); tsel:Show();
		er:EmbedChild(tsel); er:Show();
		ui:InsertFrame(er);

		-- color
		local color1 = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Texture 1 color"));
		if desc and desc.color1 then color1:SetColor(VFL.explodeRGBA(desc.color1)); end
		local color2 = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Texture 2 color"));
		if desc and desc.color2 then color2:SetColor(VFL.explodeRGBA(desc.color2)); end
		local color3 = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Texture 3 color"));
		if desc and desc.color3 then color3:SetColor(VFL.explodeRGBA(desc.color3)); end
		local color4 = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Texture 4 color"));
		if desc and desc.color4 then color4:SetColor(VFL.explodeRGBA(desc.color4)); end
		local color5 = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Texture 5 color"));
		if desc and desc.color5 then color5:SetColor(VFL.explodeRGBA(desc.color5)); end

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Totems Icons")));

		ui:InsertFrame(ftype_4);


		function ui:GetDescriptor()
			local filterName, filterNameList, filternl, ext, filterNamecd, filterNameListcd, filternlcd, extcd, unitfi, maxdurfil, mindurfil = nil, nil, {}, nil, nil, nil, {}, nil, "", "", "";
			if chk_nameauras:GetChecked() then
				unitfi = string.lower(ed_unitfilter.editBox:GetText());
			end
			if chk_timefilter:GetChecked() then
				maxdurfil = ed_maxduration.editBox:GetText();
				mindurfil = ed_minduration.editBox:GetText();
				chk_notimefilter:SetChecked();
			end
			if chk_filterName:GetChecked() then
				filterNameList = le_names:GetList();
				local flag;
				for k,v in pairs(filterNameList) do
					flag = nil;
					local test = string.sub(v, 1, 1);
					if test == "!" then
						flag = true;
						v = string.sub(v, 2);
					end
					local testnumber = tonumber(v);
					if testnumber then
						if flag then
							filternl[k] = "!" .. testnumber;
						else
							filternl[k] = testnumber;
						end
					else
						if flag then
							local spellid = RDXSS.GetSpellIdByLocalName(v);
							if spellid then
								filternl[k] = "!" .. spellid;
							else
								filternl[k] = "!" .. v;
							end
						else
							filternl[k] = RDXSS.GetSpellIdByLocalName(v) or v;
						end
					end
				end
				if chk_external:GetChecked() then ext = file_external:GetPath(); end
			end
			if chk_filterNamecd:GetChecked() then
				filterNameListcd = le_namescd:GetList();
				local flag;
				for k,v in pairs(filterNameListcd) do
					flag = nil;
					local test = string.sub(v, 1, 1);
					if test == "!" then
						flag = true;
						v = string.sub(v, 2);
					end
					local testnumber = tonumber(v);
					if testnumber then
						if flag then
							filternlcd[k] = "!" .. testnumber;
						else
							filternlcd[k] = testnumber;
						end
					else
						if flag then
							local spellid = RDXSS.GetSpellIdByLocalName(v);
							if spellid then
								filternlcd[k] = "!" .. spellid;
							else
								filternlcd[k] = "!" .. v;
							end
						else
							filternlcd[k] = RDXSS.GetSpellIdByLocalName(v) or v;
						end
					end
				end
				if chk_externalcd:GetChecked() then extcd = file_externalcd:GetPath(); end
			end
			--if  not chk_sort:GetChecked() then
			--	chk_sortstack:SetChecked();
			--	chk_sortduration:SetChecked();
			--	chk_sorttimeleft:SetChecked();
			--	chk_sortname:SetChecked();
			--end
			return {
				feature = "listicons"; version = 1;
				name = ed_name.editBox:GetText();
				-- layout
				owner = owner:GetSelection();
				anchor = anchor:GetAnchorInfo();
				nIcons = VFL.clamp(ed_nicon.editBox:GetNumber(), 1, 40);
				rows = VFL.clamp(ed_rows.editBox:GetNumber(), 1, 40);
				orientation = dd_orientation:GetSelection();
				iconspx = VFL.clamp(ed_iconspx.editBox:GetNumber(), -200, 200);
				iconspy = VFL.clamp(ed_iconspy.editBox:GetNumber(), -200, 200);
				w = VFL.clamp(ed_width.editBox:GetNumber(), 1, 100);
				h = VFL.clamp(ed_height.editBox:GetNumber(), 1, 100);
				-- display
				driver = driver:GetValue();
				bs = dd_buttonskin:GetSelectedButtonSkin();
				bkd = dd_backdrop:GetSelectedBackdrop();
				-- shader
				shader = shader:GetValue();
				-- interaction
				disableClick = chk_disableClick:GetChecked();
				disableShowTooltip = chk_disableShowTooltip:GetChecked();
				-- texture
				drawLayer = drawLayer:GetSelection();
				sublevel = VFL.clamp(ed_sublevel.editBox:GetNumber(), 1, 20);
				-- cooldown
				cd = cd:GetSelectedCooldown();
				-- other
				fontst = fontsel2:GetSelectedFont();
				-- smooth
				--smooth = chk_smooth:GetChecked();
				-- filter
				notimefilter = chk_notimefilter:GetChecked();
				timefilter = chk_timefilter:GetChecked();
				maxdurationfilter = maxdurfil;
				mindurationfilter = mindurfil;
				-- sort
				--sort = chk_sort:GetChecked();
				--sortstack = chk_sortstack:GetChecked();
				--sortduration = chk_sortduration:GetChecked();
				--sorttimeleft = chk_sorttimeleft:GetChecked();
				--sortname = chk_sortname:GetChecked();
				ftype = ftype:GetValue();
				auraType = dd_auraType:GetSelection();
				raidfilter = chk_raidfilter:GetChecked();
				playerauras = chk_playerauras:GetChecked();
				othersauras = chk_othersauras:GetChecked();
				petauras = chk_petauras:GetChecked();
				targetauras = chk_targetauras:GetChecked();
				focusauras = chk_focusauras:GetChecked();
				nameauras = chk_nameauras:GetChecked();
				unitfilter = unitfi;
				isstealablefilter = chk_isStealable:GetChecked();
				curefilter = chk_curefilter:GetChecked();
				filterName = chk_filterName:GetChecked();
				externalNameFilter = ext;
				filterNameList = filternl;
				--
				cooldownType = dd_cooldownType:GetSelection();
				filterNamecd = chk_filterNamecd:GetChecked();
				externalNameFiltercd = extcd;
				filterNameListcd = filternlcd;
				--
				number = number.editBox:GetText();
				texture = tsel:GetSelectedTexture();
				color1 = color1:GetColor();
				color2 = color2:GetColor();
				color3 = color3:GetColor();
				color4 = color4:GetColor();
				color5 = color5:GetColor();
			};
		end

		ui.Destroy = VFL.hook(function(s)
			ftype:Destroy(); ftype = nil;
			driver:Destroy(); driver = nil;
			shader:Destroy(); shader = nil;
		end, ui.Destroy);

		return ui;
	end;
	CreateDescriptor = function()
		local font = VFL.copy(Fonts.Default); font.size = 8; font.justifyV = "MIDDLE"; font.justifyH = "CENTER";
		return {
			feature = "listicons";
			version = 1;
			name = "li1";
			owner = "Frame_decor";
			anchor = { lp = "TOPLEFT", af = "Frame_decor", rp = "TOPLEFT", dx = 0, dy = 0};
			nIcons = 12; rows = 1; orientation = "RIGHT"; iconspx = 5; iconspy = 0;
			w = 30; h = 30;
			driver = 1;
			bkd = VFL.copy(VFLUI.defaultBackdrop);
			drawLayer = "ARTWORK"; sublevel = 1;
			cd = VFL.copy(VFLUI.defaultCooldown);
			fontst = font;
			mindurationfilter = 0;
			maxdurationfilter = 3000;
			ftype = 1;
			auraType = "BUFFS";
			cooldownType = "USED";
		};
	end;
});

RDX.RegisterFeature({
	name = "aura_icons";
	version = 31338;
	invisible = true;
	IsPossible = VFL.Nil;
	VersionMismatch = function(desc)
		desc.feature = "listicons";
		desc.ftype = 1;
		desc.h = desc.size;
		desc.w = desc.size;
	end;
});

RDX.RegisterFeature({
	name = "cd_icons";
	version = 31338;
	invisible = true;
	IsPossible = VFL.Nil;
	VersionMismatch = function(desc)
		desc.feature = "listicons";
		desc.ftype = 2;
		desc.h = desc.size;
		desc.w = desc.size;
	end;
});

RDX.RegisterFeature({
	name = "custom_icons";
	version = 31338;
	invisible = true;
	IsPossible = VFL.Nil;
	VersionMismatch = function(desc)
		desc.feature = "listicons";
		desc.ftype = 3;
	end;
});
