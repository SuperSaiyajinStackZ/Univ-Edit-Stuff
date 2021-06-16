-- Keep them here.
local GBAIdent = { [0] = 0x53, [1] = 0x54, [2] = 0x57, [3] = 0x4E, [4] = 0x30, [5] = 0x32, [6] = 0x34 }; -- GBA Header Identifier.
local NDSIdent = { [0] = 0x64, [1] = 0x61, [2] = 0x74, [3] = 0x0, [4] = 0x20, [5] = 0x0, [6] = 0x0, [7] = 0x0 }; -- NDS Header Identifier.


--[[
	Check the file for GBA or NDS Saves.

	Returns -1 for invalid, 0 for GBA and 1 for NDS.
]]
local function CheckFile()
	local Count = 0;
	local FileSize = UniversalEdit.FileSize(); -- Get the filesize.
	local Res = -1;

	if (FileSize == 0x10000) or (FileSize == 0x20000) then -- 64 and 128 KB are GBA Save Sizes.
		local Buffer = UniversalEdit.Read(0x0, 0x7); -- Read 7 uint8_t's starting at offset 0x0.

		for Idx = 0, 6 do -- Go through the Idents.
			if (Buffer[Idx] == GBAIdent[Idx]) then
				Count = Count + 1; -- Increase count by 1.
			end
		end

		if (Count == 7) then
			Res = 0; -- It's a GBA SAV.
		end
	
	elseif (FileSize == 0x40000) or (FileSize == 0x80000) then -- 256 and 512 KB are NDS Save Sizes.
		for Slot = 0, 4 do -- Check for all 5 possible Save Slots.
			local Buffer = UniversalEdit.Read((Slot * 0x1000), 0x8); -- Read 8 uint8_t's starting at offset 0x0 of the slot.
			Count = 0; -- Reset Count here.
	
			for Idx = 0, 7 do -- Go through the Idents.
				if (Buffer[Idx] == NDSIdent[Idx]) then
					Count = Count + 1; -- Increase count by 1.
				end
			end
	
			if (Count == 8) then
				Res = 1; -- It's a NDS SAV.
				break;
			end
		end
	end

	return Res;
end

--[[
	Calculate the checksum.

	StartOffs: The offset where to start.
	Size: The size to calculate.
	AmountOfSkips: The amount of offsets to skip.
	SkipOffs: A table with the offsets to skip.

	Returns an uint16_t of the Checksum.
]]
local function Calc(StartOffs, Size, AmountOfSkips, SkipOffs)
	local Byte1 = 0;
	local Byte2 = 0;
	local Skip = false;
	local Buffer = UniversalEdit.Read(StartOffs, Size); -- Read directly to a buffer to make the operation faster.

	for Idx = 0, Size / 2 - 1 do -- / 2 since for loop with an uint16_t, - 1 cause LUA is different than C/C++ with for loops.
		if (AmountOfSkips > 0) then -- Only do this if larger than 0.
			for CurSkipIdx = 0, AmountOfSkips do
				-- (StartOffs / 2) since we do it in 2 byte steps.
				if ((StartOffs / 2) + Idx == SkipOffs[CurSkipIdx]) then -- If index is the same as the skip index -> Skip.
					Skip = true;
					break;
				end
			end
		end

		if (Skip == false) then -- If we don't skip -> Execute the action.
			Byte1 = (Byte1 + Buffer[Idx * 2]);

			if (Byte1 > 255) then -- 256+ -> Reset to 0 + increase of the second byte variable.
				Byte1 = Byte1 % 256;
				Byte2 = Byte2 + 1;
			end

			Byte2 = (Byte2 + Buffer[(Idx * 2) + 1]) % 256;
		end

		Skip = false;
	end

	Byte2 = Byte2 + 1; -- Increase.
	if (Byte2 > 255) then -- 256 -> 0.
		Byte2 = 0;
	end

	return (256 * (256 - Byte2)) + (256 - Byte1);
end

--[[
	Handle the GBA Slot Checksum Action.
]]
local function CalcGBASlot(Slot)
	local CurCHKS = UniversalEdit.Read(Slot * 0x1000 + 0xFFE, 1, "uint16_t")[0]; -- Read the current checksum of the slot.
	local Calced = Calc(Slot * 0x1000, 0xFFE, 0, { 0 });

	if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
		local ShouldFix = UniversalEdit.Prompt("Slot " .. tostring(Slot) .. " doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

		if (ShouldFix) then
			UniversalEdit.Write(Slot * 0x1000 + 0xFFE, { Calced }, "uint16_t");
			UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot) .. " fixed.", 0);
		end

	else
		UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot) .. " is already valid.", 0);
	end
end

--[[
	Handle the NDS Slot Checksum Action.
]]
local function CalcNDSSlot(Slot)
	local CurCHKS = UniversalEdit.Read((Slot * 0x1000) + 0x28, 1, "uint16_t")[0];
	local SkipOffs = { (((Slot * 0x1000) + 0x12) / 2), (((Slot * 0x1000) + 0x28) / 2) }; -- Skip those offsets, since they need to be skipped on calculation.

	local Calced = Calc(((Slot * 0x1000) + 0x10), 0x1000 - 0x10, 2, SkipOffs);

	if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
		local ShouldFix = UniversalEdit.Prompt("Slot " .. tostring(Slot + 1) .. " doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

		if (ShouldFix) then
			UniversalEdit.Write(Slot * 0x1000 + 0x28, { Calced }, "uint16_t");
			UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot + 1) .. " fixed.", 0);
		end

	else
		UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot + 1) .. " is already valid.", 0);
	end
end

--[[
	Handle the GBA Settings Checksum Action.
]]
local function CalcGBASettings()
	local CurCHKS = UniversalEdit.Read(0xE, 1, "uint16_t")[0];
	local Calced = Calc(0x0, 0x18, 1, { 0xE / 2 });

	if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
		local ShouldFix = UniversalEdit.Prompt("The Settings Checksum doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

		if (ShouldFix) then
			UniversalEdit.Write(0xE, { Calced }, "uint16_t");
			UniversalEdit.StatusMSG("Settings Checksum fixed.", 0);
		end

	else
		UniversalEdit.StatusMSG("Settings Checksum is already valid.", 0);
	end
end

--[[
	Detect and display the detected Save.

	Returns -1 for invalid, 0 for GBA and 1 for NDS.
]]
local function DisplayDetected()
	local Res = CheckFile(); -- Check the file for a valid save.

	if (Res == -1) then
		UniversalEdit.StatusMSG("The current file is not a valid The Sims 2 GBA or The Sims 2 NDS Savefile.", -1);

	elseif (Res == 0) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 GBA Savefile.", 0);

	elseif (Res == 1) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 NDS Savefile.", 0);
	end

	return Res;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("Update the Checksum of a Save Slot or the Settings of an The Sims 2 GBA or NDS Savefile with this Tool.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.1.0.", 0);

	local Detected = DisplayDetected(); -- Displays the detected Savefile and decide, if the action will run.
	local Running = (Detected ~= -1);

	while(Running) do
		if (Detected == 0) then -- Handle GBA things.
			local SelectedOption = UniversalEdit.SelectList("What do you want to do?", { "Check Slot Checksum", "Check Settings Checksum", "Exit" });

			if (SelectedOption == 0) then -- Check Slot Checksum.
				local Slot = UniversalEdit.SelectList("Which Slot do you want to check?", { "Slot 1", "Slot 2", "Slot 3", "Slot 4" });
				
				if (Slot > -1) then -- If larger than -1, then do the action.
					CalcGBASlot(Slot + 1);
				end
			
			elseif (SelectedOption == 1) then -- Check Settings Checksum.
				CalcGBASettings();
			
			else
				Running = false; -- break the loop.
			end

		elseif (Detected == 1) then -- Handle NDS things.
			local SelectedOption = UniversalEdit.SelectList("What do you want to do?", { "Check Slot Checksum", "Exit" });

			if (SelectedOption == 0) then -- Check Slot Checksum.
				local Slot = UniversalEdit.SelectList("Which Slot do you want to check?", { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5" });

				if (Slot > -1) then -- If larger than -1, then do the action.
					CalcNDSSlot(Slot);
				end

			else
				Running = false; -- break the loop.
			end
		end
	end
end

-- Main function.
Main();