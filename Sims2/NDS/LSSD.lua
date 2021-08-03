--[[
	The Sims 2 Nintendo DS Last Saved Slot Detector (LSSD) for Universal-Edit-Hex.

	This is a small The Sims 2 Nintendo DS Last Saved Slot Detector Tool which tells you the Offsets of the 3 active Save Slots that you see in-game.

	Copyright (C) by SuperSaiyajinStackZ 2021.
]]


local SlotIdent = { [0] = 0x64, [1] = 0x61, [2] = 0x74, [3] = 0x0, [4] = 0x1F, [5] = 0x0, [6] = 0x0, [7] = 0x0 }; -- NDS Slot Identifier.
local SLOT_OFFS = 0xC; -- The Slot (0x0: 1, 0x1: 2, 0x2: 3). Additional Note: 0xD seems to be related to the Slot offset too, but the Game handles it on 0xC only?
local SAV_COUNT_OFFS = 0x8; -- The SAV Count offset. It is 4 byte long (0xFFFFFFFF).


--[[
	Check the active file, if it's a The Sims 2 Nintendo DS Savefile.

	Returns -1 for invalid, and 1 for Nintendo DS USA, 2 for Nintendo DS EUR, 3 for Nintendo DS JPN.
]]
local function CheckFile()
	local Count = 0;
	local FileSize = UniversalEdit.FileSize(); -- Get the Filesize.
	local Res = -1;

	if (FileSize == 0x40000) or (FileSize == 0x80000) then -- 256 and 512 KB is valid for a The Sims 2 Nintendo DS Savefile.
		for Slot = 0, 4 do -- Check for all 5 possible Save Slots.
			local Buffer = UniversalEdit.Read((Slot * 0x1000), 0x8); -- Read 8 uint8_t's starting at offset 0x0 of the slot.

			for Reg = 0, 2 do -- Go through all regions.
				Count = 0; -- Reset Count here.
	
				for Idx = 0, 7 do -- Go through the Identifiers.

					if (Idx == 0x4) then -- 0x4 --> region specific uint8_t.
						if (Buffer[Idx] == SlotIdent[Idx] + Reg) then
							Count = Count + 1; -- Increase count by 1.
						end

					else
						if (Buffer[Idx] == SlotIdent[Idx]) then
							Count = Count + 1; -- Increase count by 1.
						end
					end
				end
	
				if (Count == 8) then
					Res = 1 + Reg;
					break;
				end
			end
		end
	end

	return Res;
end


--[[
	The Last Saved Slot Detector Action.

	SavSlot: The Slot to check. ( 0 - 2 ).
	Region: The region which got detected before, that saves us the whole region loops.

	Returns the index of the specified Save Slot.
]]
local function LSSD(SavSlot, Region)
	local IDCount = 0;
	local SavCount = { [0] = 0x00000000, [1] = 0x00000000, [2] = 0x00000000, [3] = 0x00000000, [4] = 0x00000000 };
	local SavSlotExist = { [0] = false, [1] = false, [2] = false, [3] = false, [4] = false };

	-- Looping 5 times.
	for Slot = 0, 4 do
		IDCount = 0; -- First reset here to 0.

		-- Check for Identifier.
		for ID = 0, 7 do -- Go through the Identifiers.
			if (ID == 0x4) then
				if (UniversalEdit.Read((Slot * 0x1000) + ID, 1)[0] == SlotIdent[ID] + (Region - 1)) then
					IDCount = IDCount + 1;
				end

			else
				if (UniversalEdit.Read((Slot * 0x1000) + ID, 1)[0] == SlotIdent[ID]) then
					IDCount = IDCount + 1;
				end
			end
		end

		-- If 8, then it passed the header.
		if (IDCount == 8) then
			-- Check, if current slot is also the actual Save Slot. It seems 0xC and 0xD added is the Slot, however 0xD seems never be touched from the game and hence like all the time 0x0?
			if (UniversalEdit.Read((Slot * 0x1000) + SLOT_OFFS, 1)[0] + UniversalEdit.Read((Slot * 0x1000) + SLOT_OFFS + 1, 1)[0] == SavSlot) then
				-- Now get the Save Count.
				SavCount[Slot] = UniversalEdit.Read((Slot * 0x1000) + SAV_COUNT_OFFS, 1, "uint32_t")[0];
				SavSlotExist[Slot] = true;
			end
		end
	end

	-- Here we check and return the proper last saved Slot. The highest Save Count is what will be checked for, as the higher the Save Count -- The more recently it got used.
	local HighestCount = 0;
	local LSS = -1;

	for Slot = 0, 4 do
		if (SavSlotExist[Slot]) then -- Ensure the Slot existed before.
			if (SavCount[Slot] > HighestCount) then -- Ensure count is higher.
				HighestCount = SavCount[Slot];
				LSS = Slot;
			end
		end
	end

	return LSS;
end


--[[
	Displays the detected Savefile and returns, if it's a valid Savefile or not.
]]
local function DisplayDetected()
	local Res = CheckFile(); -- Check the file for a valid save.

	if (Res == -1) then
		UniversalEdit.StatusMSG("The current file is not a valid The Sims 2 Nintendo DS Savefile.", -1);

	elseif (Res == 1) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 Nintendo DS USA Savefile.", 0);

	elseif (Res == 2) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 Nintendo DS EUR Savefile.", 0);

	elseif (Res == 3) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 Nintendo DS JPN Savefile.", 0);
	end

	return Res;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("Display the offsets of the 3 active Save Slots from your Savefile of The Sims 2 Nintendo DS.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.3.0.", 0);
	local Region = DisplayDetected(); -- Displays the detected Savefile and return if it's a valid save.
	local Running = (Region > -1);

	while(Running) do
		local SelectedOption = UniversalEdit.SelectList("Select the Slot you want to check.", { "Slot 1", "Slot 2", "Slot 3", "Exit" });

		if ((SelectedOption > -1) and (SelectedOption < 3)) then -- 0 - 2 --> Slot Options.
			local Res = LSSD(SelectedOption, Region);

			if (Res == -1) then -- Save Slot does not.
				UniversalEdit.StatusMSG("Slot " .. tostring(SelectedOption + 1) .. " does not exist inside the Savefile.", -1);
			
			else -- Save Slot exists.
				UniversalEdit.StatusMSG("Slot " .. tostring(SelectedOption + 1) .. " does exist!\nIt can be found at offset: 0x" .. string.format("%04x", Res * 0x1000) .. ".", 0);
			end
	
		else -- Else just stop running.
			Running = false;
		end
	end
end


-- Main function.
Main();