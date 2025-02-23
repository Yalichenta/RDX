﻿-- MenuBar.lua
-- OpenRDX
-- Sigg Rashgarroth EU

-- DEPRECATED

-- taille normal : 58 28 25 18  6, 6
-- taille petit  : 36 19 15 11  4, 4

--table.insert(MICRO_BUTTONS, "FriendsMicroButton");

RDXUpdateMicroButtonsParent = UpdateMicroButtonsParent
RDXMoveMicroButtons = MoveMicroButtons
--RDXUpdateMicroButtonsParent(UIParent)
--RDXMoveMicroButtons("TOP", UIParent, "TOP", 0, 22)

UpdateMicroButtonsParent = VFL.Noop;
MoveMicroButtons = VFL.Noop;

local function _EmitCreateCode(objname, desc)
	local createCode = [[
	local btn, btnOwner = nil, ]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[;
	--RDXUpdateMicroButtonsParent(btnOwner)
	--RDXMoveMicroButtons("TOPLEFT", btnOwner, "TOPLEFT", 0, 22)
	RDXUpdateMicroButtonsParent(btnOwner)
	RDXMoveMicroButtons(]] .. RDXUI.AnchorCodeFromDescriptor(desc.anchor) .. [[)
]];
	return createCode;
end

local _orientations = {
	{ text = "LEFT"},
	{ text = "RIGHT"},
	{ text = "DOWN"},
	{ text = "UP"},
};
local function _dd_orientations() return _orientations; end

RDX.RegisterFeature({
	name = "menubar"; 
	version = 1; 
	title = VFLI.i18n("Blizzard Main Menu"); 
	category = VFLI.i18n("Complexes");
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if not RDXUI.DescriptorCheck(desc, state, errs) then return nil; end
		local flg = true;
		flg = flg and RDXUI.UFFrameCheck_Proto("Frame_", desc, state, errs);
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
		if flg then state:AddSlot("Frame_" .. desc.name); end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "Icons_" .. desc.name;
		------------------ On frame creation

		local createCode = _EmitCreateCode(objname, desc);
		state:Attach("EmitCreate", true, function(code) code:AppendCode(createCode); end);
		
		------------------ On frame destruction.
		local destroyCode = [[
		RDXUpdateMicroButtonsParent(UIParent)
		RDXMoveMicroButtons("TOP", UIParent, "TOP", 0, 22)
]];
		state:Attach(state:Slot("EmitDestroy"), true, function(code) code:AppendCode(destroyCode); end);

		return true;
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);

		------------- Layout
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Layout parameters")));
		
		local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, {"Frame_", "Button_", "Cooldown_", });
		if desc and desc.owner then owner:SetSelection(desc.owner); end

		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);

		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Orientation"));
		local dd_orientation = VFLUI.Dropdown:new(er, _dd_orientations);
		dd_orientation:SetWidth(75); dd_orientation:Show();
		if desc and desc.orientation then 
			dd_orientation:SetSelection(desc.orientation); 
		else
			dd_orientation:SetSelection("RIGHT");
		end
		er:EmbedChild(dd_orientation); er:Show();
		ui:InsertFrame(er);
		
		local ed_rows = VFLUI.LabeledEdit:new(ui, 50); ed_rows:Show();
		ed_rows:SetText(VFLI.i18n("Row number"));
		if desc and desc.rows then ed_rows.editBox:SetText(desc.rows); end
		ui:InsertFrame(ed_rows);
		
		local ed_iconspx = VFLUI.LabeledEdit:new(ui, 50); ed_iconspx:Show();
		ed_iconspx:SetText(VFLI.i18n("Width spacing"));
		if desc and desc.iconspx then ed_iconspx.editBox:SetText(desc.iconspx); else ed_iconspx.editBox:SetText("0"); end
		ui:InsertFrame(ed_iconspx);
		
		local ed_iconspy = VFLUI.LabeledEdit:new(ui, 50); ed_iconspy:Show();
		ed_iconspy:SetText(VFLI.i18n("Height spacing"));
		if desc and desc.iconspy then ed_iconspy.editBox:SetText(desc.iconspy); else ed_iconspy.editBox:SetText("0"); end
		ui:InsertFrame(ed_iconspy);
		
		
		function ui:GetDescriptor()
			return { 
				feature = "menubar"; version = 1;
				name = "mbar";
				owner = owner:GetSelection();
				anchor = anchor:GetAnchorInfo();
				rows = VFL.clamp(ed_rows.editBox:GetNumber(), 1, 40);
				orientation = dd_orientation:GetSelection();
				iconspx = VFL.clamp(ed_iconspx.editBox:GetNumber(), -10, 200);
				iconspy = VFL.clamp(ed_iconspy.editBox:GetNumber(), -25, 200);
			};
		end

		return ui;
	end;
	CreateDescriptor = function()
		return { 
			feature = "menubar"; version = 1; 
			name = "mbar"; owner = "Frame_decor";
			anchor = { lp = "TOPLEFT", af = "Frame_decor", rp = "TOPLEFT", dx = 0, dy = 0};
			rows = 1; orientation = "RIGHT"; iconspx = -2; iconspy = 0;
		};
	end;
});

