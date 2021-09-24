--[[
	The Sims 2 Game Boy Advance Episode Editor for Universal-Edit-Hex.

	This is a small The Sims 2 Game Boy Advance Episode Editor, including...
		- Editing the Rating of all 4 Categories from a Episode.
		- (Un)lock Episodes.

	Copyright (C) by SuperSaiyajinStackZ 2021.
]]


local GBAIdent = { [0] = 0x53, [1] = 0x54, [2] = 0x57, [3] = 0x4E, [4] = 0x30, [5] = 0x32, [6] = 0x34 }; -- GBA Header Identifier.
local EPOffs = {
	[0] = 0x104, [1] = 0x10E, [2] = 0x122, [3] = 0x11D, [4] = 0x131, [5] = 0x127,
	[6] = 0x14A, [7] = 0x140, [8] = 0x118, [9] = 0x16D, [10] = 0x168
}; -- All 11 Episode Offsets.

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
	Get the final offset of an Episode.

	Slot: The Slot from which to get the final Episode offset.
	Episode: The Episode from which to get the final Episode offset.
]]
local function GetEPOffs(Slot, Episode)
	return ((Slot * 0x1000) + EPOffs[Episode] + (UniversalEdit.Read((Slot * 0x1000) + 0xD6, 1)[0] * 0x6));
end


--[[
	Set the Rating points from an episode from a Slot to a specific Rating category.

	Slot: The Slot to set the rating points to.
	Episode: The Episode to set the rating points to.
	Category: The Category to set the rating points to.
]]
local function SetRatingPoints(Slot, Episode, Category)
	local OldVal = UniversalEdit.Read(GetEPOffs(Slot, Episode) + Category, 1)[0]; -- Get old value as a restore.
	local Points = UniversalEdit.Numpad("Enter the rating points.\n0 - 25 are valid options.\n\nYour current value is: " .. tostring(OldVal) .. ".", OldVal, 0, 25, 2);

	if (OldVal ~= Points) then
		UniversalEdit.Write(GetEPOffs(Slot, Episode) + Category, { Points });
		ChangesMade = true;
	end
end

local function SetRatingPointsMass(Slot, Category)
	local Points = UniversalEdit.Numpad("Enter the rating points.\n0 - 25 are valid options.", 0, 0, 25, 2);

	for Idx = 0, 10 do
		UniversalEdit.Write(GetEPOffs(Slot, Idx) + Category, { Points });
	end

	ChangesMade = true;
end


--[[
	Same as above, but for all categories.

	Slot: The Slot to set the rating points to.
	Episode: The Episode to set the rating points to.
]]
local function SetRatingPointsAll(Slot, Episode)
	local Points = UniversalEdit.Numpad("Enter the rating points you want to set to all ratings of the selected Episode.\n0 - 25 are valid options.", 0, 0, 25, 2);

	UniversalEdit.Write(GetEPOffs(Slot, Episode), { Points, Points, Points, Points });
	ChangesMade = true;
end

local function SetRatingPointsAllMass(Slot)
	local Points = UniversalEdit.Numpad("Enter the rating points yoiu want to set to all ratings for all Episodes.\n0 - 25 are valid options.", 0, 0, 25, 2);

	for Idx = 0, 10 do
		UniversalEdit.Write(GetEPOffs(Slot, Idx), { Points, Points, Points, Points });
	end

	ChangesMade = true;
end


--[[
	Set the Episode Unlocked State.

	Slot: The Slot to set the state to.
	Episode: The episode to set the state to.
]]
local function SetEPState(Slot, Episode)
	local CurState = UniversalEdit.Read(GetEPOffs(Slot, Episode) + 0x4, 1)[0];
	local Unlocked = CurState;

	if (CurState == 0) then
		Unlocked = UniversalEdit.Prompt("Do you want to unlock the Episode?");

	else
		Unlocked = not UniversalEdit.Prompt("Do you want to lock the Episode?");
	end

	if (CurState ~= Unlocked) then
		if (Unlocked) then
			UniversalEdit.Write(GetEPOffs(Slot, Episode) + 0x4, { 1 });

		else
			UniversalEdit.Write(GetEPOffs(Slot, Episode) + 0x4, { 0 });
		end

		ChangesMade = true;
	end
end

local function SetEPStateMass(Slot)
	local Unlocked = UniversalEdit.Prompt("Do you want to unlock all the Episode?");

	for Idx = 0, 10 do
		if (Unlocked) then
			UniversalEdit.Write(GetEPOffs(Slot, Idx) + 0x4, { 1 });

		else
			UniversalEdit.Write(GetEPOffs(Slot, Idx) + 0x4, { 0 });
		end
	end

	ChangesMade = true;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("A small The Sims 2 Game Boy Advance Episode Save Editor Tool.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.5.0.", 0);
	local Detected = DisplayDetected(); -- Displays the detected Savefile and return if it's a valid Savefile.
	local Running = Detected;
	local EpisodeSelectorRunning = false;
	local EpisodeEditorRunning = false;

	if Detected then
		Running = UniversalEdit.Prompt("This Tool expects a \"Episode.json\" and \"Rating.json\" inside the \"Scripts/Sims2/GBA/Strings/\" directory.\n\nDo you have both placed inside it?");
	end

	while(Running) do
		local Slot = UniversalEdit.SelectList("Select the Slot you want to edit.", { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Exit" });

		if ((Slot > -1) and (Slot < 4)) then -- 0 - 3.
			EpisodeSelectorRunning = true;

			while(EpisodeSelectorRunning) do
				local Episode = UniversalEdit.SelectJSONList("Select the Episode you want to edit.", UniversalEdit.BasePath() .. "Scripts/Sims2/GBA/Strings/Episode.json");

				if (Episode > -1) then
					EpisodeEditorRunning = true;

					while(EpisodeEditorRunning) do
						local SelectedOption = UniversalEdit.SelectList("What do you want to do?", { "Edit Episode Ratings", "Edit Episode State", "Exit" });

						if (SelectedOption == 0) then -- Edit Episode Rating.
							local SelectedRating = UniversalEdit.SelectJSONList("Select the rating category you want to edit.", UniversalEdit.BasePath() .. "Scripts/Sims2/GBA/Strings/Rating.json");

							if (SelectedRating > -1) then
								if (SelectedRating < 4) then -- Single episode editing.
									if (Episode < 11) then SetRatingPoints(Slot + 1, Episode, SelectedRating);
									else SetRatingPointsMass(Slot + 1, SelectedRating);
									end

								else -- All episode editing.
									if (Episode < 11) then SetRatingPointsAll(Slot + 1, Episode);
									else SetRatingPointsAllMass(Slot + 1);
									end
								end
							end

						elseif (SelectedOption == 1) then -- Edit Episode State.
							if (Episode < 11) then SetEPState(Slot + 1, Episode);
							else SetEPStateMass(Slot + 1);
							end

						else -- Exit Episode Editor.
							EpisodeEditorRunning = false;
						end
					end
				
				else -- Exit Episode Selector.
					EpisodeSelectorRunning = false;
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