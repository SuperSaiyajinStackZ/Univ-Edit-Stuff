--[[
	The Sims 2 Game Boy Advance Cast Member Editor for Universal-Edit-Hex.

	This is a small The Sims 2 Game Boy Advance Cast Member Editor, including...
		- Editing the Friendly Interaction Level.
		- Editing the Romance Interaction Level.
		- Editing the Intimidate Interaction Level.
		- (Un)lock the Secret from a Cast Member.
		- Change a Cast Members Feeling.

	Copyright (C) by SuperSaiyajinStackZ 2021.
]]


local GBAIdent = { [0] = 0x53, [1] = 0x54, [2] = 0x57, [3] = 0x4E, [4] = 0x30, [5] = 0x32, [6] = 0x34 }; -- GBA Header Identifier.
local ChangesMade = false;


--[[
	Check the file for an The Sims 2 Game Boy Advance Savefile.

	Returns true if it's a The Sims 2 Game Boy Advance Savefile, false if not.
]]
local function CheckFile()
	local Count = 0;
	local FileSize = UniversalEdit.FileSize(); -- Get the Filesize.
	local Good = false;

	if (FileSize == 0x10000) or (FileSize == 0x20000) then -- 64 and 128 KB are The Sims 2 Game Boy Advance Save Sizes.
		local Buffer = UniversalEdit.Read(0x0, 0x7); -- Read 7 uint8_t's starting at offset 0x0.

		for Idx = 0, 6 do -- Go through the Identifiers.
			if (Buffer[Idx] == GBAIdent[Idx]) then
				Count = Count + 1; -- Increase count by 1.
			end
		end

		if (Count == 7) then
			Good = true; -- It's a The Sims 2 Game Boy Advance Savefile.
		end
	end

	return Good;
end


--[[
	Displays the detected Savefile and returns, if it's a valid Savefile or not.
]]
local function DisplayDetected()
	local Res = CheckFile(); -- Check the file for a valid Savefile.

	if (Res == true) then
		UniversalEdit.StatusMSG("Detected a The Sims 2 Game Boy Advance Savefile.", 0);
	
	else
		UniversalEdit.StatusMSG("The current file is not a valid The Sims 2 Game Boy Advance Savefile.", -1);
	end

	return Res;
end


--[[
	Get the amount of items from your House.

	Slot: The Slot to check.
]]
local function GetHouseCount(Slot)
	return UniversalEdit.Read((Slot * 0x1000) + 0xD6, 1)[0]; -- Contains the House Item Count.
end


--[[
	Set the Friendly Interaction Level of a Cast Member.

	Slot: The Slot to set to.
	Cast: The Cast Member to set to.
	HouseCount: The count of the items inside the house.
]]
local function SetFriendly(Slot, Cast, HouseCount)
	local Level = UniversalEdit.SelectList("Select the Level of the Friendly Interaction.", { "Level 0", "Level 1", "Level 2", "Level 3" });

	if (Level > -1) then
		local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Cast * 0xA);
		UniversalEdit.Write(Offs, { Level });

		ChangesMade = true;
	end
end

local function SetFriendlyMass(Slot, HouseCount)
	local Level = UniversalEdit.SelectList("Select the Level of the Friendly Interaction.", { "Level 0", "Level 1", "Level 2", "Level 3" });

	if (Level > -1) then
		for Idx = 0, 25 do
			local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Idx * 0xA);
			UniversalEdit.Write(Offs, { Level });
		end

		ChangesMade = true;
	end
end


--[[
	Set the Romance Interaction Level of a Cast Member.

	Slot: The Slot to set to.
	Cast: The Cast Member to set to.
	HouseCount: The count of the items inside the house.
]]
local function SetRomance(Slot, Cast, HouseCount)
	local Level = UniversalEdit.SelectList("Select the Level of the Romance Interaction.", { "Level 0", "Level 1", "Level 2", "Level 3" });

	if (Level > -1) then
		local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Cast * 0xA) + 0x1;
		UniversalEdit.Write(Offs, { Level });

		ChangesMade = true;
	end
end

local function SetRomanceMass(Slot, HouseCount)
	local Level = UniversalEdit.SelectList("Select the Level of the Romance Interaction.", { "Level 0", "Level 1", "Level 2", "Level 3" });

	if (Level > -1) then
		for Idx = 0, 25 do
			local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Idx * 0xA) + 0x1;
			UniversalEdit.Write(Offs, { Level });
		end

		ChangesMade = true;
	end
end


--[[
	Set the Intimidate Interaction Level of a Cast Member.

	Slot: The Slot to set to.
	Cast: The Cast Member to set to.
	HouseCount: The count of the items inside the house.
]]
local function SetIntimidate(Slot, Cast, HouseCount)
	local Level = UniversalEdit.SelectList("Select the Level of the Intimidate Interaction.", { "Level 0", "Level 1", "Level 2", "Level 3" });

	if (Level > -1) then
		local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Cast * 0xA) + 0x2;
		UniversalEdit.Write(Offs, { Level });

		ChangesMade = true;
	end
end

local function SetIntimidateMass(Slot, HouseCount)
	local Level = UniversalEdit.SelectList("Select the Level of the Intimidate Interaction.", { "Level 0", "Level 1", "Level 2", "Level 3" });

	if (Level > -1) then
		for Idx = 0, 25 do
			local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Idx * 0xA) + 0x2;
			UniversalEdit.Write(Offs, { Level });
		end

		ChangesMade = true;
	end
end


--[[
	Set the picture from the Cast list of a Cast Member.

	Slot: The Slot to set to.
	Cast: The Cast Member to set to.
	HouseCount: The count of the items inside the house.
]]
local function SetFeeling(Slot, Cast, HouseCount)
	local Feeling = UniversalEdit.SelectList("What should be the feeling of the Cast Member?", { "Neutral", "Friendly", "Annoyed", "Romantic" });

	if (Feeling > -1) then
		local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Cast * 0xA) + 0x3;
		UniversalEdit.Write(Offs, { Feeling });

		ChangesMade = true;
	end
end

local function SetFeelingMass(Slot, HouseCount)
	local Feeling = UniversalEdit.SelectList("What should be the feeling of the Cast Members?", { "Neutral", "Friendly", "Annoyed", "Romantic" });

	if (Feeling > -1) then
		for Idx = 0, 25 do
			local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Idx * 0xA) + 0x3;
			UniversalEdit.Write(Offs, { Feeling });
		end

		ChangesMade = true;
	end
end


--[[
	Toggle the Secret of a Cast Member.

	Slot: The Slot to toggle to.
	Cast: The Cast Member to toggle to.
	HouseCount: The count of the items inside the house.
]]
local function SetSecret(Slot, Cast, HouseCount)
	local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Cast * 0xA) + 0x8;
	local CurState = UniversalEdit.Read(Offs, 1)[0];
	local Unlocked = CurState;

	if (CurState == 0) then
		Unlocked = UniversalEdit.Prompt("Do you want to unlock the Secret?");

	else
		Unlocked = not UniversalEdit.Prompt("Do you want to lock the Secret?");
	end

	if (CurState ~= Unlocked) then
		if (Unlocked) then
			UniversalEdit.Write(Offs, { 1 });

		else
			UniversalEdit.Write(Offs, { 0 });
		end

		ChangesMade = true;
	end
end

local function SetSecretMass(Slot, HouseCount)
	local Unlocked = UniversalEdit.Prompt("Do you want to unlock the Secrets?");

	for Idx = 0, 25 do
		local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Idx * 0xA) + 0x8;

		if (Unlocked) then
			UniversalEdit.Write(Offs, { 1 });

		else
			UniversalEdit.Write(Offs, { 0 });
		end

		ChangesMade = true;
	end
end


--[[
	Unlock everything from a Cast Member.

	Slot: The Slot to unlock everything.
	Cast: The Cast Member to unlock everything.
	HouseCount: The count of the items inside the house.
]]
local function UnlockAll(Slot, Cast, HouseCount)
	local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Cast * 0xA);
		
	-- Start with the Interactions.
	UniversalEdit.Write(Offs, { 0x3, 0x3, 0x3 });

	-- Now the Secret.
	UniversalEdit.Write(Offs + 0x8, { 1 }); -- Unlock Secret.

	ChangesMade = true;
end

local function UnlockAllMass(Slot, HouseCount)
	for Idx = 0, 25 do
		local Offs = (Slot * 0x1000) + (0x466 + (HouseCount * 0x6)) + (Idx * 0xA);
		
		-- Start with the Interactions.
		UniversalEdit.Write(Offs, { 0x3, 0x3, 0x3 });

		-- Now the Secrets.
		UniversalEdit.Write(Offs + 0x8, { 1 }); -- Unlock Secrets.
	end

	ChangesMade = true;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("A small The Sims 2 Game Boy Advance Cast Member Save Editor Tool.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.4.0.", 0);
	local Detected = DisplayDetected(); -- Displays the detected Savefile and return if it's a valid Savefile.
	local Running = Detected;
	local CastSelectorRunning = false;
	local CastEditorRunning = false;

	Running = UniversalEdit.Prompt("This Tool expects a \"Cast.json\" inside the \"Scripts/Sims2/GBA/Strings/\" directory.\n\nDo you have one placed inside it?");

	while(Running) do
		local Slot = UniversalEdit.SelectList("Select the Slot you want to edit.", { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Exit" });

		if ((Slot > -1) and (Slot < 4)) then -- 0 - 3.
			local HouseCount = GetHouseCount(Slot + 1);
			CastSelectorRunning = true;

			while(CastSelectorRunning) do
				local Cast = UniversalEdit.SelectJSONList("Select the Cast Member you want to edit.", UniversalEdit.BasePath() .. "Scripts/Sims2/GBA/Strings/Cast.json");

				if (Cast > -1) then
					CastEditorRunning = true;

					while(CastEditorRunning) do
						local SelectedOption = UniversalEdit.SelectList("What do you want to do?", { "Edit Friendly Interaction Level", "Edit Romance Interaction Level", "Edit Intimidate Interaction Level", "Edit Cast Feeling", "Edit Secret Unlocked State", "Unlock everything", "Exit" });

						if (SelectedOption == 0) then -- Edit Friendly Interaction Level.
							if (Cast < 26) then SetFriendly(Slot + 1, Cast, HouseCount);
							else SetFriendlyMass(Slot + 1, HouseCount);
							end

						elseif (SelectedOption == 1) then -- Edit Romance Interaction Level.
							if (Cast < 26) then SetRomance(Slot + 1, Cast, HouseCount);
							else SetRomanceMass(Slot + 1, HouseCount);
							end

						elseif (SelectedOption == 2) then -- Edit Intimidate Interaction Level.
							if (Cast < 26) then SetIntimidate(Slot + 1, Cast, HouseCount);
							else SetIntimidateMass(Slot + 1, HouseCount);
							end
								
						elseif (SelectedOption == 3) then -- Edit Cast Feeling.
							if (Cast < 26) then SetFeeling(Slot + 1, Cast, HouseCount);
							else SetFeelingMass(Slot + 1, HouseCount);
							end

						elseif (SelectedOption == 4) then -- Edit Secret Unlocked State.
							if (Cast < 26) then SetSecret(Slot + 1, Cast, HouseCount);
							else SetSecretMass(Slot + 1, HouseCount);
							end

						elseif (SelectedOption == 5) then -- Unlock everything. 
							if (Cast < 26) then UnlockAll(Slot + 1, Cast, HouseCount);
							else UnlockAllMass(Slot + 1, HouseCount);
							end

						else -- Exit Cast Editor.
							CastEditorRunning = false;
						end
					end
				
				else -- Exit Cast Selector.
					CastSelectorRunning = false;
				end
			end

		else -- Exit the script and display an info message that you have to run the Checksum-Updater now.
			if (ChangesMade) then
				UniversalEdit.StatusMSG("Now don't forget to run the Checksum-Updater and you are good to go.", 0);
			end

			Running = false;
		end
	end
end

-- Main function.
Main();