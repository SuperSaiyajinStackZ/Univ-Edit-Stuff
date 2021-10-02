--[[
	The Sims Bustin' Out Game Boy Advance Checksum-Updater for Universal-Edit-Hex.

	This is a small The Sims Bustin' Out Game Boy Advance Checksum-Updater, which can fix your Savefile, if it's bad / invalid.
	What it includes should actually be pretty self-explanatory.

	History:
	v0.1.0: Added initial implementation of the Checksum-Updater.


	Copyright (C) by SuperSaiyajinStackZ 2021.
]]


local Ident = { [0] = 0x30, [1] = 0x30, [2] = 0x30, [3] = 0x30, [4] = 0x45, [5] = 0x49, [6] = 0x53, [7] = 0x41 }; -- Header Identifier.


--[[
	Check the active file for a The Sims Bustin' Out Game Boy Advance Savefile.

	Returns -1 for invalid, 0 for valid.
]]
local function CheckFile()
	local Count = 0;
	local FileSize = UniversalEdit.FileSize(); -- Get the Filesize.
	local Res = -1;

	--[[
		8 KB OR 128 KB (in case of no$gba) are The Sims Bustin' Out Game Boy Advance Save Sizes.
	]]
	if (FileSize == 0x2000) or (FileSize == 0x20000) then
		local Buffer = UniversalEdit.Read(0x0, 0x8); -- Read 8 uint8_t's starting at offset 0x0.

		--[[ Check for the Header to ensure it is a valid Savefile. ]]
		for Idx = 0, 7 do -- Go through the Identifiers.
			if (Buffer[Idx] == Ident[Idx]) then
				Count = Count + 1; -- Increase count by 1.
			end
		end

		if (Count == 8) then
			Res = 0; -- It's a The Sims Bustin' Out Game Boy Advance Savefile.
		end
	end

	return Res;
end


--[[
	Calculate the Checksum.

	StartOffs: The Offset where to start.
	Size: The size to Calculate.
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
			Byte2 = (Byte2 + Buffer[((Idx * 2) + 1)]);

			if (Byte2 > 255) then -- 256+ -> Reset to 0 + increase of the second byte variable.
				Byte2 = Byte2 % 256;
				Byte1 = Byte1 + 1;
			end

			Byte1 = (Byte1 + Buffer[Idx * 2]) % 256;
		end

		Skip = false;
	end

	Byte1 = Byte1 + 1; -- Increase.
	if (Byte1 > 255) then -- 256 -> 0.
		Byte1 = 0;
	end

	return (256 * (256 - Byte2)) + (256 - Byte1);
end


--[[
	Handle the Game Boy Advance Slot Checksum Action.
]]
local function CalcSlot(Slot)
	local CurCHKS = UniversalEdit.Read(0x10 + (Slot * 0x7F8) + 0x7F0, 1, "uint16_t")[0]; -- Read the current checksum of the slot.
	local Calced = Calc(0x10 + (Slot * 0x7F8), 0x7F8, 1, { (0x10 + (Slot * 0x7F8) + 0x7F0) / 2 });

	if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
		local ShouldFix = UniversalEdit.Prompt("Slot " .. tostring(Slot + 1) .. " doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

		if (ShouldFix) then
			UniversalEdit.Write(0x10 + (Slot * 0x7F8) + 0x7F0, { Calced }, "uint16_t");
			UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot + 1) .. " fixed.", 0);
		end

	else
		UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot + 1) .. " is already valid.", 0);
	end
end


--[[
	Handle the Game Boy Advance Settings Checksum Action.
]]
local function CalcSettings()
	local CurCHKS = UniversalEdit.Read(0x8, 1, "uint16_t")[0];
	local Calced = Calc(0x0, 0x10, 1, { 0x8 / 2 });

	if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
		local ShouldFix = UniversalEdit.Prompt("The Settings Checksum doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

		if (ShouldFix) then
			UniversalEdit.Write(0x8, { Calced }, "uint16_t");
			UniversalEdit.StatusMSG("Settings Checksum fixed.", 0);
		end

	else
		UniversalEdit.StatusMSG("Settings Checksum is already valid.", 0);
	end
end


--[[
	Detect and display the detected Savefile.

	Returns -1 for invalid, 0 valid.
]]
local function DisplayDetected()
	local Res = CheckFile(); -- Check the file for a valid Savefile.

	if (Res == -1) then
		UniversalEdit.StatusMSG("The current file is not a valid The Sims Bustin' Out Game Boy Advance Savefile.", -1);

	elseif (Res == 0) then
		UniversalEdit.StatusMSG("Detected a The Sims Bustin' Out Game Boy Advance Savefile.", 0);
	end

	return Res;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("Update the Checksum of a Save Slot or the Settings of an The Sims Bustin' Out Game Boy Advance Savefile with this Tool.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.1.0.", 0);

	local Detected = DisplayDetected(); -- Displays the detected Savefile and decide, if the action will run.
	local Running = (Detected ~= -1);

	while(Running) do
		if (Detected == 0) then -- Handle GBA things.
			local SelectedOption = UniversalEdit.SelectList("What do you want to do?", { "Check Slot Checksum", "Check Settings Checksum", "Exit" });

			if (SelectedOption == 0) then -- Check Slot Checksum.
				local Slot = UniversalEdit.SelectList("Which Slot do you want to check?", { "Slot 1", "Slot 2", "Slot 3" });
				
				if (Slot > -1) then -- If larger than -1, then do the action.
					CalcSlot(Slot);
				end
			
			elseif (SelectedOption == 1) then -- Check Settings Checksum.
				CalcSettings();
			
			else
				Running = false; -- break the loop.
			end
		end
	end
end


-- Main function.
Main();