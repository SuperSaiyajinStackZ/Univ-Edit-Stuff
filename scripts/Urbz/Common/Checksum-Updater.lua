--[[
	The Urbz: Sims in the City Game Boy Advance and Nintendo DS Checksum-Updater for Universal-Edit-Hex.

	This is a small The Urbz: Sims in the City Game Boy Advance and Nintendo DS Checksum-Updater, which can fix your Savefile, if it's bad / invalid.
	What it includes should actually be pretty self-explanatory.

	History:
	v0.1.0: Added initial implementation of the Checksum-Updater.


	Copyright (C) by SuperSaiyajinStackZ 2021.
]]


local GBAIdent = { [0] = 0x55, [1] = 0x52, [2] = 0x42, [3] = 0x5A, [4] = 0x30, [5] = 0x30, [6] = 0x31, [7] = 0x31 }; -- GBA Header Identifier.

local NDSIdentJPN = { [0] = 0x55, [1] = 0x52, [2] = 0x42, [3] = 0x5A, [4] = 0x4A, [5] = 0x30, [6] = 0x30, [7] = 0x32 }; -- NDS JPN Header Identifier.
local NDSIdentPAL = { [0] = 0x55, [1] = 0x52, [2] = 0x42, [3] = 0x5A, [4] = 0x30, [5] = 0x30, [6] = 0x37, [7] = 0x30 }; -- NDS PAL Header Identifier.
local NDSIdentNA  = { [0] = 0x55, [1] = 0x52, [2] = 0x42, [3] = 0x5A, [4] = 0x30, [5] = 0x30, [6] = 0x31, [7] = 0x30 }; -- NDS  NA Header Identifier.


--[[
	Check the active file for a The Urbz: Sims in the City Game Boy Advance or Nintendo DS Savefile.

	Returns -1 for invalid, 0 for Game Boy Advance and 1 for Nintendo DS JPN, 2 for Nintendo DS PAL, 3 for Nintendo DS NA.
]]
local function CheckFile()
	local Count = 0;
	local FileSize = UniversalEdit.FileSize(); -- Get the Filesize.
	local Res = -1;

	if (FileSize == 0x10000) or (FileSize == 0x20000) then -- 64 and 128 KB are The Urbz: Sims in the City Game Boy Advance Save Sizes.
		local Buffer = UniversalEdit.Read(0x0, 0x7); -- Read 7 uint8_t's starting at offset 0x0.

		for Idx = 0, 6 do -- Go through the Identifiers.
			if (Buffer[Idx] == GBAIdent[Idx]) then
				Count = Count + 1; -- Increase count by 1.
			end
		end

		if (Count == 7) then
			Res = 0; -- It's a The Urbz: Sims in the City Game Boy Advance Savefile.
		end

	--[[
		8 KB OR 256 KB (in case of no$gba) are The Urbz: Sims in the City Nintendo DS Save Sizes.
	]]
	elseif (FileSize == 0x2000) or (FileSize == 0x40000) then
		local Buffer = UniversalEdit.Read(0x0, 0x8); -- Read 8 uint8_t's starting at offset 0x0.

		--[[ First check for JPN's Header. ]]
		for Idx = 0, 7 do -- Go through the Identifiers.
			if (Buffer[Idx] == NDSIdentJPN[Idx]) then
				Count = Count + 1; -- Increase count by 1.
			end
		end

		if (Count == 8) then
			Res = 1; -- It's a The Urbz: Sims in the City Nintendo DS JPN Savefile.


		--[[Doesn't match, so check the PAL version. ]]
		else
			Count = 0;

			for Idx = 0, 7 do -- Go through the Identifiers.
				if (Buffer[Idx] == NDSIdentPAL[Idx]) then
					Count = Count + 1; -- Increase count by 1.
				end
			end
	
			if (Count == 8) then
				Res = 2; -- It's a The Urbz: Sims in the City Nintendo DS PAL Savefile.


			--[[ Doesn't match, so check the NA version. ]]
			else
				Count = 0;

				for Idx = 0, 7 do -- Go through the Identifiers.
					if (Buffer[Idx] == NDSIdentNA[Idx]) then
						Count = Count + 1; -- Increase count by 1.
					end
				end
		
				if (Count == 8) then
					Res = 3; -- It's a The Urbz: Sims in the City Nintendo DS NA Savefile.
				end
			end
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
	Handle the Game Boy Advance Slot Checksum Action.
]]
local function CalcGBASlot(Slot)
	local Exist = UniversalEdit.Read((Slot * 0x1000) + 0xE, 1, "uint8_t")[0] ~= 0x0; -- It only exist, if 0xE of the Save Slot is NOT 0x0.

	if (Exist) then
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

	else
		UniversalEdit.StatusMSG("Slot " .. tostring(Slot) .. " doesn't exist.\n\nPossible Reason: 0xE of the Slot is 0x0, which is the first character of the Urbz Name. It MUST be larger as 0x0 to be detected.", -2);
	end
end


--[[
	Handle the Nintendo DS Slot Checksum Action.
]]
local function CalcNDSSlot(Slot)
	local Exist = UniversalEdit.Read(0x20 + (Slot * 0xFE0) + 0xE, 1, "uint8_t")[0] ~= 0x0; -- It only exist, if 0xE of the Save Slot is NOT 0x0.

	if (Exist) then
		local CurCHKS = UniversalEdit.Read(0x20 + (Slot * 0xFE0) + 0xFDE, 1, "uint16_t")[0]; -- Read the current checksum of the slot.
		local Calced = Calc(0x20 + (Slot * 0xFE0), 0xFDE, 0, { 0 });

		if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
			local ShouldFix = UniversalEdit.Prompt("Slot " .. tostring(Slot + 1) .. " doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

			if (ShouldFix) then
				UniversalEdit.Write(0x20 + (Slot * 0xFE0) + 0xFDE, { Calced }, "uint16_t");
				UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot + 1) .. " fixed.", 0);
			end

		else
			UniversalEdit.StatusMSG("Checksum of Slot " .. tostring(Slot + 1) .. " is already valid.", 0);
		end

	else
		UniversalEdit.StatusMSG("Slot " .. tostring(Slot + 1) .. " doesn't exist.\n\nPossible Reason: 0xE of the Slot is 0x0, which is the first character of the Urbz Name. It MUST be larger as 0x0 to be detected.", -2);
	end
end


--[[
	Handle the Game Boy Advance Settings Checksum Action.
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
	Handle the Nintendo DS Settings Checksum Action.
]]
local function CalcNDSSettings()
	local CurCHKS = UniversalEdit.Read(0x1E, 1, "uint16_t")[0];
	local Calced = Calc(0x0, 0x1E, 0, { 0x0 });

	if (CurCHKS ~= Calced) then -- At this point, the checksum and the calculated result is NOT identical and invalid.
		local ShouldFix = UniversalEdit.Prompt("The Settings Checksum doesn't match the calculated checksum!\n\nDo you want to fix it's Checksum?");

		if (ShouldFix) then
			UniversalEdit.Write(0x1E, { Calced }, "uint16_t");
			UniversalEdit.StatusMSG("Settings Checksum fixed.", 0);
		end

	else
		UniversalEdit.StatusMSG("Settings Checksum is already valid.", 0);
	end
end


--[[
	Detect and display the detected Savefile.

	Returns -1 for invalid, 0 for Game Boy Advance and 1 for Nintendo DS.
]]
local function DisplayDetected()
	local Res = CheckFile(); -- Check the file for a valid Savefile.

	if (Res == -1) then
		UniversalEdit.StatusMSG("The current file is not a valid The Urbz: Sims in the City Game Boy Advance or Nintendo DS Savefile.", -1);

	elseif (Res == 0) then
		UniversalEdit.StatusMSG("Detected a The Urbz: Sims in the City Game Boy Advance Savefile.", 0);

	elseif (Res == 1) then
		UniversalEdit.StatusMSG("Detected a The Urbz: Sims in the City Nintendo DS (JPN) Savefile.", 0);

	elseif (Res == 2) then
		UniversalEdit.StatusMSG("Detected a The Urbz: Sims in the City Nintendo DS (PAL) Savefile.", 0);

	elseif (Res == 3) then
		UniversalEdit.StatusMSG("Detected a The Urbz: Sims in the City Nintendo DS (NA) Savefile.", 0);
	end

	return Res;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("Update the Checksum of a Save Slot or the Settings of an The Urbz: Sims in the City Game Boy Advance or Nintendo DS Savefile with this Tool.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.1.0.", 0);

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
		
		elseif (Detected >= 1) and (Detected <= 3) then -- Handle NDS things.
			local SelectedOption = UniversalEdit.SelectList("What do you want to do?", { "Check Slot Checksum", "Check Settings Checksum", "Exit" });

			if (SelectedOption == 0) then -- Check Slot Checksum.
				local Slot = UniversalEdit.SelectList("Which Slot do you want to check?", { "Slot 1", "Slot 2" });
					
				if (Slot > -1) then -- If larger than -1, then do the action.
					CalcNDSSlot(Slot);
				end
				
			elseif (SelectedOption == 1) then -- Check Settings Checksum.
				CalcNDSSettings();
				
			else
				Running = false; -- break the loop.
			end
		end
	end
end


-- Main function.
Main();