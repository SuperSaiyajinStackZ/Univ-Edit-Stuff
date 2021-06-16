local GameCodes = {
	[0] = 0xC5, -- EUR.
	[1] = 0x8A, -- USA.
	[2] = 0x32, -- JPN.
	[3] = 0x32  -- KOR.
}; -- The Gamecodes from byte 0x0 - 0x1.

local SavCopyOffsets = {
	[0] = 0x15FE0, -- EUR.
	[1] = 0x15FE0, -- USA.
	[2] = 0x12224, -- JPN.
	[3] = 0x173FC  -- KOR.
}; -- The Savcopy offsets. Also used for the SavCopy size.

local ChecksumOffset = {
	[0] = 0x15FDC, -- EUR.
	[1] = 0x15FDC, -- USA.
	[2] = 0x12220, -- JPN.
	[3] = 0x173F8  -- KOR.
}; -- The Checksum Offset.


--[[
	Detect the Savtype of an AC:WW Save.

	Returns -1 for not match, 0 for EUR, 1 for USA, 2 for JPN and 3 for KOR.
]]
local function DetectACWWSav()
	local SavSize = UniversalEdit.FileSize();
	local Region = -1;

	-- The sizes below are valid AC:WW Savesizes.
	if ((SavSize == 0x40000) or (SavSize == 0x4007A) or (SavSize == 0x80000) or (SavSize == 0x8007A)) then
		for Idx = 0, 3 do -- Go through all 4 regions.
			if ((UniversalEdit.Read(0x0, 0x1)[0] == GameCodes[Idx]) and (UniversalEdit.Read(SavCopyOffsets[Idx], 0x1)[0] == GameCodes[Idx])) then
				Region = Idx;
				break;
			end
		end
	end

	return Region;
end

-- Displays the detected Region as a Status Message and return the index.
local function DisplayDetected()
	local Region = DetectACWWSav();

	if (Region > -1) then
		local Regions = {
			[0] = "Detected Region: Europe.",
			[1] = "Detected Region: USA.",
			[2] = "Detected Region: JPN.",
			[3] = "Detected Region: KOR."
		};

		UniversalEdit.StatusMSG(Regions[Region], 0);

	else
		UniversalEdit.StatusMSG("Not a valid AC:WW Save.", -1);
	end

	return Region;
end

--[[
	Calculates the checksum for the Savefile.

	Region: The Region which got detected.
	
	Returns it as an uint16_t.
]]
local function CalculateChecksum(Region)
	local ChecksVar = 0;
	local Buffer = UniversalEdit.Read(0x0, (SavCopyOffsets[Region] / 2), "uint16_t"); -- Init the buffer, to make the process faster.

	for Idx = 0, SavCopyOffsets[Region] / 2 - 1 do
		if (Idx ~= ChecksumOffset[Region] / 2) then
			ChecksVar = (ChecksVar + Buffer[Idx]) % 0x10000;
		end
	end

	return 0x10000 - ChecksVar;
end

--[[
	Returns if the checksum is valid.

	Region: The Region which got detected.

	Returns -1 if already good, or the new calculated result.
]]
local function ChecksumValid(Region)
	local Calced = CalculateChecksum(Region);
	local Res = -1;

	if (Calced ~= UniversalEdit.Read(ChecksumOffset[Region], 1, "uint16_t")[0]) then
		Res = Calced; -- Set the result to calced.
	end

	return Res;
end


local function Main() -- Main function call.
	UniversalEdit.StatusMSG("Fix the checksum of your Animal Crossing: Wild World Savefile with this Tool.\n\nTool created by SuperSaiyajinStackZ.\nVersion of this Tool: v0.1.0.", 0);

	local Region = DisplayDetected(); -- Displays the detected Savefile and return the region.
	
	if (Region > -1) then
		local Res = ChecksumValid(Region);

		if (Res ~= -1) then
			local DoAction = UniversalEdit.Prompt("The checksum is invalid.\n\nWould you like to fix it?");

			if (DoAction) then
				-- Fix the checksum.
				UniversalEdit.ProgressMessage("Fixing the checksum...");
				UniversalEdit.Write(ChecksumOffset[Region], { Res }, "uint16_t");

				-- Copy first Savcopy to the second one.
				local MainCopy = UniversalEdit.Read(0x0, SavCopyOffsets[Region]);
				UniversalEdit.ProgressMessage("Copying to second Savcopy...");
				UniversalEdit.Write(SavCopyOffsets[Region], MainCopy);
			end
		
		else
			UniversalEdit.StatusMSG("The savefile has a valid checksum already.", 0);
		end
	end
end

-- Main function.
Main();