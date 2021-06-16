local SlotIdent = { [0] = 0x64, [1] = 0x61, [2] = 0x74, [3] = 0x0, [4] = 0x20, [5] = 0x0, [6] = 0x0, [7] = 0x0 }; -- NDS Slot Identifier.
local SLOT_OFFS = 0xC; -- The Slot (0x0: 1, 0x1: 2, 0x2: 3). Additional Note: 0xD seems to be related to the Slot offset too, but the Game handles it on 0xC only?
local SAV_COUNT_OFFS = 0x8; -- The SAV Count offset. It is 4 byte long (0xFFFFFFFF).


--[[
	Check the active file, if it's a The Sims 2 NDS Sav.

	Returns true if it's a valid The Sims 2 NDS Savefile, false if not.
]]
local function CheckFile()
	local Count = 0;
	local FileSize = UniversalEdit.FileSize(); -- Get the filesize.
	local Good = false;

	if (FileSize == 0x40000) or (FileSize == 0x80000) then -- 256 and 512 KB is valid for the NDS SAV.
		for Slot = 0, 4 do -- Check for all 5 possible Save Slots.
			local Buffer = UniversalEdit.Read((Slot * 0x1000), 0x8); -- Read 8 uint8_t's starting at offset 0x0 of the slot.
			Count = 0; -- Reset Count here.
	
			for Idx = 0, 7 do -- Go through the Idents.
				if (Buffer[Idx] == SlotIdent[Idx]) then
					Count = Count + 1; -- Increase count by 1.
				end
			end
	
			if (Count == 8) then
				Good = true;
				break;
			end
		end
	end

	return Good;
end

--[[
	The Last Saved Slot Detector Action.

	SavSlot: The Slot to check. ( 0 - 2 ).

	Returns the index of the specified SavSlot.
]]
local function LSSD(SavSlot)
	local IDCount = 0;
	local SavCount = { [0] = 0x00000000, [1] = 0x00000000, [2] = 0x00000000, [3] = 0x00000000, [4] = 0x00000000 };
	local SavSlotExist = { [0] = false, [1] = false, [2] = false, [3] = false, [4] = false };

	-- Looping 5 times.
	for Slot = 0, 4 do
		IDCount = 0; -- First reset here to 0.

		-- Check for Identifier.
		for ID = 0, 7 do -- Go through the Idents.
			if (UniversalEdit.Read((Slot * 0x1000) + ID, 1)[0] == SlotIdent[ID]) then
				IDCount = IDCount + 1;
			end
		end

		-- If 8, then it passed the header.
		if (IDCount == 8) then
			-- Check, if current slot is also the actual SavSlot. It seems 0xC and 0xD added is the Slot, however 0xD seems never be touched from the game and hence like all the time 0x0?
			if (UniversalEdit.Read((Slot * 0x1000) + SLOT_OFFS, 1)[0] + UniversalEdit.Read((Slot * 0x1000) + SLOT_OFFS + 1, 1)[0] == SavSlot) then
				-- Now get the SAVCount.
				SavCount[Slot] = UniversalEdit.Read((Slot * 0x1000) + SAV_COUNT_OFFS, 1, "uint32_t")[0];
				SavSlotExist[Slot] = true;
			end
		end
	end

	-- Here we check and return the proper last saved Slot.
	local HighestCount = 0;
	local LSS = -1;

	for Slot = 0, 4 do
		if (SavSlotExist[Slot] == true) then -- Ensure the Slot existed before.
			if (SavCount[Slot] > HighestCount) then -- Ensure count is higher.
				HighestCount = SavCount[Slot];
				LSS = Slot;
			end
		end
	end

	return LSS;
end

--[[
	Displays the detected Save and returns, if it's a valid save or not.
]]
local function DisplayDetected()
	local Res = CheckFile(); -- Check the file for a valid save.

	if (Res == true) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 NDS Savefile.", 0);
	
	else
		UniversalEdit.StatusMSG("The current file is not a valid The Sims 2 NDS Savefile.", -1);
	end

	return Res;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("Display the offsets of the 3 active Save Slots from your Sav of The Sims 2 NDS.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.1.0.", 0);
	local Detected = DisplayDetected(); -- Displays the detected Savefile and return if it's a valid save.
	local Running = Detected;

	while(Running) do
		local SelectedOption = UniversalEdit.SelectList("Select the Slot you want to check.", { "Slot 1", "Slot 2", "Slot 3", "Exit" });

		if ((SelectedOption > -1) and (SelectedOption < 3)) then -- 0 - 2 --> Slot Options.
			local Res = LSSD(SelectedOption);

			if (Res == -1) then -- SavSlot Does not.
				UniversalEdit.StatusMSG("Slot " .. tostring(SelectedOption + 1) .. " does not exist inside the Savefile.", -1);
			
			else -- SavSlot Exist.
				UniversalEdit.StatusMSG("Slot " .. tostring(SelectedOption + 1) .. " does exist!\nIt can be found at offset: 0x" .. string.format("%04x", Res * 0x1000) .. ".", 0);
			end
	
		else -- Else just stop running.
			Running = false;
		end
	end
end

-- Main function.
Main();