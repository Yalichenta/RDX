﻿-- HeaderAuraIconList.lua
-- OpenRDX - Sigg - Rashgarroth FR
--

RDX.RegisterFeature({
	name = "sec_aura_icons";
	version = 1;
	title = VFLI.i18n("Icons Aura Secured");
	category = VFLI.i18n("Lists");
	multiple = true;
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if not RDXUI.DescriptorCheck(desc, state, errs) then return nil; end
		desc.owner = "Base";
		if not desc.usebkd then desc.usebs = true; end
		if not desc.xoffset then desc.xoffset = "0"; end
		if not desc.yoffset then desc.yoffset = "0"; end
		local flg = true;
		flg = flg and RDXUI.UFFrameCheck_Proto("SIcons_", desc, state, errs);
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		--flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs, true);
		if not desc.shader then desc.shader = 2; end
		if flg then state:AddSlot("SIcons_" .. desc.name); end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "SIcons_" .. desc.name;

		local driver = desc.driver or 1;
		local bs = desc.bs or VFLUI.defaultButtonSkin;
		local bkd = desc.bkd or VFLUI.defaultBackdrop;

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

		local showweapons = "false";
		if desc.showweapons then showweapons = "true"; end
		local sortdir = "+";
		if desc.sortdir then sortdir = "-"; end
		local separateown = "0";
		if desc.separateown == "BEFORE" then sortdir = "1"; end
		if desc.separateown == "AFTER" then sortdir = "-1"; end

		-- Event hinting.
		--local mux, mask = state:GetContainingWindowState():GetSlotValue("Multiplexer"), 0;
		local filter;
		if desc.auraType == "DEBUFFS" then
		--	mask = mux:GetPaintMask("DEBUFFS");
		--	mux:Event_UnitMask("DELAYED_UNIT_DEBUFF_*", mask);
			filter = "HARMFUL";
		else
		--	mask = mux:GetPaintMask("BUFFS");
		--	mux:Event_UnitMask("DELAYED_UNIT_BUFF_*", mask);
			filter = "HELPFUL";
		end

		--local smask = mux:GetPaintMask("UNIT_BUFFWEAPON");
		--mux:Event_UnitMask("UNIT_BUFFWEAPON_UPDATE", smask);

		--mask = bit.bor(mask, 1);

		----------------- Creation
		local createCode = [[
	local h = RDX.SmartHeaderAura:new();
	h:SetParent(]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[);
	h:SetPoint(]] .. RDXUI.AnchorCodeFromDescriptor(desc.anchor) .. [[);
	h:SetAttribute("useparent-unit", true);
	h:SetAttribute("useparent-unitsuffix", true);
	h:SetAttribute("filter", "]] .. filter .. [[");
	h:SetAttribute("template", "]] .. desc.template .. [[");
	if ]] .. showweapons .. [[ then
		h:SetAttribute("includeWeapons", 1);
		h:SetAttribute("weaponTemplate", "]] .. desc.template .. [[");
	end
	h:SetAttribute("minWidth", 1);
	h:SetAttribute("minHeight", 1);
	h:SetAttribute("point", "]] .. desc.point .. [[");
	h:SetOrientation("]] .. desc.template .. [[", "]] .. desc.orientation .. [[", ]] .. desc.wrapafter .. [[, ]] .. desc.maxwraps .. [[, ]] .. desc.xoffset .. [[, ]] .. desc.yoffset .. [[);
	h:SetAttribute("sortMethod", "]] .. desc.sortmethod .. [[");
	h:SetAttribute("sortDir", "]] .. sortdir .. [[");
	h:SetAttribute("separateOwn", ]] .. separateown .. [[);
	h:Show();

	h.updateFunc = function(self)
		for _,child in self:ActiveChildren() do
			if not child.btn then
				local btn = VFLUI.AcquireFrame("Frame");
				btn:SetParent(child); btn:SetFrameLevel(child:GetFrameLevel());
				btn:SetAllPoints(child);
				btn:Show();
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

		createCode = createCode .. [[
				btn.tex = VFLUI.CreateTexture(btn);
				btn.tex:SetPoint("TOPLEFT", btn, "TOPLEFT", ]] .. os .. [[, -]] .. os .. [[);
				btn.tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -]] .. os .. [[, ]] .. os .. [[);
				if not RDXG.usecleanicons then
					btn.tex:SetTexCoord(0.05, 1-0.06, 0.05, 1-0.04);
				end
				btn.tex:SetDrawLayer("ARTWORK", 2);
				btn.tex:Show();

				btn.cd = VFLUI.CooldownCounter:new(btn, ]] .. Serialize(desc.cd) .. [[);
				btn.cd:SetAllPoints(btn.tex);
				btn.cd:Show();

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
				btn.filter = "]] .. filter .. [[";
				child.btn = btn;
			end
			_bn, _tex, _apps, _dispelt, _dur, _et = AuraUtil.FindAuraByName(child:GetID(), SecureButton_GetModifiedUnit(frame) or "player", "]] .. filter .. [[");
			if _bn then
				child.btn.tex:SetTexture(_tex);
				if _dispelt and DebuffTypeColor[_dispelt] then
]];
		if desc.shader == 1 then
			createCode = createCode .. [[
]];
		elseif desc.shader == 2 then
			if desc.driver == 2 then
				createCode = createCode .. [[
						VFLUI.SetButtonSkinBorderColor(child.btn, explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						VFLUI.SetButtonSkinBorderColor(child.btn, ]] .. r .. [[, ]] .. g .. [[, ]] .. b .. [[, ]] .. a .. [[);
]];
			elseif desc.driver == 3 then
				createCode = createCode .. [[
						VFLUI.SetBackdropBorderColor(child.btn, explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						VFLUI.SetBackdropBorderColor(child.btn, ]] .. r .. [[, ]] .. g .. [[, ]] .. b .. [[, ]] .. a .. [[);
]];
			end
		elseif desc.shader == 3 then
			createCode = createCode .. [[
						child.btn.tex:SetVertexColor(explodeRGBA(DebuffTypeColor[_dispelt]));
					else
						child.btn.tex:SetVertexColor(1, 1, 1, 1);
]];
		end
		createCode = createCode .. [[
				end
				child.btn.cd:SetCooldown(_et - _dur, _dur);
				if _apps > 1 then child.btn.sttxt:SetText(_apps); else child.btn.sttxt:SetText("");end
				child.btn:Show();
			else
				child.btn:Hide();
			end
		end
		local hasMainHandEnchant, mainHandBuffName, mainHandBuffRank, mainHandCharges, mainHandBuffStart, mainHandBuffDur, mainHandTex, mainHandBuffTex, mainHandSlot, hasOffHandEnchant, offHandBuffName, offHandBuffRank, offHandCharges, offHandBuffStart, offHandBuffDur, offHandTex, offHandBuffTex, offHandSlot;
		local tempEnchant1 = self:GetAttribute("tempEnchant1");
		local tempEnchant2 = self:GetAttribute("tempEnchant2");
		if tempEnchant1 or tempEnchant2 then
			hasMainHandEnchant, mainHandBuffName, mainHandBuffRank, mainHandCharges, mainHandBuffStart, mainHandBuffDur, mainHandTex, mainHandBuffTex, mainHandSlot, hasOffHandEnchant, offHandBuffName, offHandBuffRank, offHandCharges, offHandBuffStart, offHandBuffDur, offHandTex, offHandBuffTex, offHandSlot = RDXDAL.LoadWeaponsBuff();
		end
		if tempEnchant1 then
			if not tempEnchant1.btn then
				local btn = VFLUI.AcquireFrame("Frame");
				btn:SetParent(tempEnchant1); btn:SetFrameLevel(tempEnchant1:GetFrameLevel());
				btn:SetAllPoints(tempEnchant1);
				btn:Show();
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

		createCode = createCode .. [[
				btn.tex = VFLUI.CreateTexture(btn);
				btn.tex:SetPoint("TOPLEFT", btn, "TOPLEFT", ]] .. os .. [[, -]] .. os .. [[);
				btn.tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -]] .. os .. [[, ]] .. os .. [[);
				if not RDXG.usecleanicons then
					btn.tex:SetTexCoord(0.05, 1-0.06, 0.05, 1-0.04);
				end
				btn.tex:SetDrawLayer("ARTWORK", 2);
				btn.tex:Show();

				btn.cd = VFLUI.CooldownCounter:new(btn, ]] .. Serialize(desc.cd) .. [[);
				btn.cd:SetAllPoints(btn.tex);
				btn.cd:Show();

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
				tempEnchant1.btn = btn;
			end
			if hasMainHandEnchant then
				tempEnchant1.btn.tex:SetTexture(mainHandTex);
				tempEnchant1.btn.cd:SetCooldown(mainHandBuffStart, mainHandBuffDur);
				if mainHandCharges > 1 then tempEnchant1.btn.sttxt:SetText(mainHandCharges); else tempEnchant1.btn.sttxt:SetText("");end
				tempEnchant1.btn:Show();
			else
				tempEnchant1.btn:Hide();
			end
		end
		local tempEnchant2 = self:GetAttribute("tempEnchant2");
		if tempEnchant2 then
			if not tempEnchant2.btn then
				local btn = VFLUI.AcquireFrame("Frame");
				btn:SetParent(tempEnchant2); btn:SetFrameLevel(tempEnchant2:GetFrameLevel());
				btn:SetAllPoints(tempEnchant2);
				btn:Show();
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

		createCode = createCode .. [[
				btn.tex = VFLUI.CreateTexture(btn);
				btn.tex:SetPoint("TOPLEFT", btn, "TOPLEFT", ]] .. os .. [[, -]] .. os .. [[);
				btn.tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -]] .. os .. [[, ]] .. os .. [[);
				if not RDXG.usecleanicons then
					btn.tex:SetTexCoord(0.05, 1-0.06, 0.05, 1-0.04);
				end
				btn.tex:SetDrawLayer("ARTWORK", 2);
				btn.tex:Show();

				btn.cd = VFLUI.CooldownCounter:new(btn, ]] .. Serialize(desc.cd) .. [[);
				btn.cd:SetAllPoints(btn.tex);
				btn.cd:Show();

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
				tempEnchant2.btn = btn;
			end
			if hasOffHandEnchant then
				tempEnchant2.btn.tex:SetTexture(offHandTex);
				tempEnchant2.btn.cd:SetCooldown(offHandBuffStart, offHandBuffDur);
				if offHandCharges > 1 then tempEnchant2.btn.sttxt:SetText(offHandCharges); else tempEnchant2.btn.sttxt:SetText("");end
				tempEnchant2.btn:Show();
			else
				tempEnchant2.btn:Hide();
			end
		end
	end
	h:updateFunc();
	frame.]] .. objname .. [[ = h;
]];
		state:Attach("EmitCreate", true, function(code) code:AppendCode(createCode); end);

		------------------- Destruction
		local destroyCode = [[
		for _,child in frame.]] .. objname .. [[:AllChildren() do
			local btn = child.btn;
			if btn then
				VFLUI.ReleaseRegion(btn.sttxt); btn.sttxt = nil;
				btn.frtxt:Destroy(); btn.frtxt = nil;
				btn.cd:Destroy(); btn.cd = nil;
				VFLUI.ReleaseRegion(btn.tex); btn.tex = nil;
				btn:Destroy(); btn = nil;
			end
			child.btn = nil;
		end
		local tempEnchant1 = frame.]] .. objname .. [[:GetAttribute("tempEnchant1");
		if tempEnchant1 then
			local btn = tempEnchant1.btn;
			if btn then
				VFLUI.ReleaseRegion(btn.sttxt); btn.sttxt = nil;
				btn.frtxt:Destroy(); btn.frtxt = nil;
				btn.cd:Destroy(); btn.cd = nil;
				VFLUI.ReleaseRegion(btn.tex); btn.tex = nil;
				btn:Destroy(); btn = nil;
			end
			tempEnchant1.btn = nil;
		end
		local tempEnchant2 = frame.]] .. objname .. [[:GetAttribute("tempEnchant2");
		if tempEnchant2 then
			local btn = tempEnchant2.btn;
			if btn then
				VFLUI.ReleaseRegion(btn.sttxt); btn.sttxt = nil;
				btn.frtxt:Destroy(); btn.frtxt = nil;
				btn.cd:Destroy(); btn.cd = nil;
				VFLUI.ReleaseRegion(btn.tex); btn.tex = nil;
				btn:Destroy(); btn = nil;
			end
			tempEnchant2.btn = nil;
		end
		frame.]] .. objname .. [[:Destroy();
		frame.]] .. objname .. [[ = nil;
]];
		state:Attach("EmitDestroy", true, function(code) code:AppendCode(destroyCode); end);

		------------------- Paint
--		local paintCode = [[

--]];
--		state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCode); end);

		------------------- Cleanup
--		local cleanupCode = [[

--]];
--		state:Attach("EmitCleanup", true, function(code) code:AppendCode(cleanupCode); end);

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

		local chk_showweapons = VFLUI.Checkbox:new(ui); chk_showweapons:Show();
		chk_showweapons:SetText(VFLI.i18n("Show Weapons Enchant"));
		if desc and desc.showweapons then chk_showweapons:SetChecked(true); else chk_showweapons:SetChecked(); end
		ui:InsertFrame(chk_showweapons);

		------------- Layout
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Layout parameters")));

		--local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, {"Frame_", "Button_", "Cooldown_", }, true);
		--if desc and desc.owner then owner:SetSelection(desc.owner); end

		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Template"));
		local dd_template = VFLUI.Dropdown:new(er, RDX.IconTemplatesFunc);
		dd_template:SetWidth(250); dd_template:Show();
		if desc and desc.template then
			dd_template:SetSelection(desc.template);
		else
			dd_template:SetSelection("RDXAB30x30Template");
		end
		er:EmbedChild(dd_template); er:Show();
		ui:InsertFrame(er);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Point"));
		local dd_point = VFLUI.Dropdown:new(er, RDXUI.AnchorPointSelectionFunc);
		dd_point:SetWidth(150); dd_point:Show();
		if desc and desc.point then
			dd_point:SetSelection(desc.point);
		else
			dd_point:SetSelection("TOPLEFT");
		end
		er:EmbedChild(dd_point); er:Show();
		ui:InsertFrame(er);

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

		local ed_wrapafter = VFLUI.LabeledEdit:new(ui, 50); ed_wrapafter:Show();
		ed_wrapafter:SetText(VFLI.i18n("Wrap After"));
		if desc and desc.wrapafter then ed_wrapafter.editBox:SetText(desc.wrapafter); else ed_wrapafter.editBox:SetText("10"); end
		ui:InsertFrame(ed_wrapafter);

		local ed_maxwraps = VFLUI.LabeledEdit:new(ui, 50); ed_maxwraps:Show();
		ed_maxwraps:SetText(VFLI.i18n("Max Wraps"));
		if desc and desc.maxwraps then ed_maxwraps.editBox:SetText(desc.maxwraps); else ed_maxwraps.editBox:SetText("1"); end
		ui:InsertFrame(ed_maxwraps);

		local ed_xoffset = VFLUI.LabeledEdit:new(ui, 50); ed_xoffset:Show();
		ed_xoffset:SetText(VFLI.i18n("Offset x"));
		if desc and desc.xoffset then ed_xoffset.editBox:SetText(desc.xoffset); else ed_xoffset.editBox:SetText("0"); end
		ui:InsertFrame(ed_xoffset);

		local ed_yoffset = VFLUI.LabeledEdit:new(ui, 50); ed_yoffset:Show();
		ed_yoffset:SetText(VFLI.i18n("Offset y"));
		if desc and desc.yoffset then ed_yoffset.editBox:SetText(desc.yoffset); else ed_yoffset.editBox:SetText("0"); end
		ui:InsertFrame(ed_yoffset);

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
		shader_key:SetText(VFLI.i18n("Use Key Shader"));
		local shader_border = shader:CreateRadioButton(ui);
		shader_border:SetText(VFLI.i18n("Use Border Shader"));
		local shader_icon = shader:CreateRadioButton(ui);
		shader_icon:SetText(VFLI.i18n("Use Icon Shader"));
		shader:SetValue(desc.shader or 2);

		ui:InsertFrame(shader_key);

		ui:InsertFrame(shader_border);

		ui:InsertFrame(shader_icon);

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

		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Smooth show hide")));
		local chk_smooth = VFLUI.Checkbox:new(ui); chk_smooth:Show();
		chk_smooth:SetText(VFLI.i18n("Use smooth on show and hide"));
		if desc and desc.smooth then chk_smooth:SetChecked(true); else chk_smooth:SetChecked(); end
		ui:InsertFrame(chk_smooth);

		------------ Sort
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Sort parameters")));

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Sort Method:"));
		local dd_sortMethod = VFLUI.Dropdown:new(er, RDX.SortMethodFunc);
		dd_sortMethod:SetWidth(75); dd_sortMethod:Show();
		if desc and desc.sortmethod then
			dd_sortMethod:SetSelection(desc.sortmethod);
		else
			dd_sortMethod:SetSelection("INDEX");
		end
		er:EmbedChild(dd_sortMethod); er:Show();
		ui:InsertFrame(er);

		local chk_sortDir = VFLUI.Checkbox:new(ui); chk_sortDir:Show();
		chk_sortDir:SetText(VFLI.i18n("Sort Direction -"));
		if desc and desc.sortdir then chk_sortDir:SetChecked(true); else chk_sortDir:SetChecked(); end
		ui:InsertFrame(chk_sortDir);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Separate Own:"));
		local dd_separateOwn = VFLUI.Dropdown:new(er, RDX.SeparateOwnFunc);
		dd_separateOwn:SetWidth(75); dd_separateOwn:Show();
		if desc and desc.separateown then
			dd_separateOwn:SetSelection(desc.separateown);
		else
			dd_separateOwn:SetSelection("NONE");
		end
		er:EmbedChild(dd_separateOwn); er:Show();
		ui:InsertFrame(er);

		function ui:GetDescriptor()
			return {
				feature = "sec_aura_icons"; version = 1;
				name = ed_name.editBox:GetText();
				auraType = dd_auraType:GetSelection();
				showweapons = chk_showweapons:GetChecked();
				-- layout
				owner = "Base";
				anchor = anchor:GetAnchorInfo();
				template = dd_template:GetSelection();
				point = dd_point:GetSelection();
				orientation = dd_orientation:GetSelection();
				wrapafter = VFL.clamp(ed_wrapafter.editBox:GetNumber(), 1, 40);
				maxwraps = VFL.clamp(ed_maxwraps.editBox:GetNumber(), 1, 40);
				xoffset = VFL.clamp(ed_xoffset.editBox:GetNumber(), -10, 10);
				yoffset = VFL.clamp(ed_yoffset.editBox:GetNumber(), -10, 10);
				-- display
				driver = driver:GetValue();
				bs = dd_buttonskin:GetSelectedButtonSkin();
				bkd = dd_backdrop:GetSelectedBackdrop();
				-- shader
				shader = shader:GetValue();
				-- cooldown
				cd = cd:GetSelectedCooldown();
				fontst = fontsel2:GetSelectedFont();
				smooth = chk_smooth:GetChecked();
				-- sort
				sortmethod = dd_sortMethod:GetSelection();
				sortdir = chk_sortDir:GetChecked();
				separateown = dd_separateOwn:GetSelection();
			};
		end

		ui.Destroy = VFL.hook(function(s)
			driver:Destroy(); driver = nil;
			shader:Destroy(); shader = nil;
		end, ui.Destroy);

		return ui;
	end;
	CreateDescriptor = function()
		local font = VFL.copy(Fonts.Default); font.size = 8; font.justifyV = "MIDDLE"; font.justifyH = "CENTER";
		return {
			feature = "sec_aura_icons";
			version = 1;
			name = "sai1";
			auraType = "BUFFS";
			owner = "Base";
			anchor = { lp = "TOPLEFT", af = "Frame_decor", rp = "TOPLEFT", dx = 0, dy = 0};
			template = "RDXAB30x30Template"; orientation = "LEFT"; wrapafter = 10; maxwraps = 2; xoffset = 0; yoffset = 0; point = "TOPLEFT";
			externalButtonSkin = "bs_default";
			ButtonSkinOffset = 0;
			bkd = VFL.copy(VFLUI.defaultBackdrop);
			drawLayer = "ARTWORK";
			cd = VFL.copy(VFLUI.defaultCooldown);
			fontst = font;
			sortmethod = "INDEX";
			separateown = "NONE";
		};
	end;
});


