local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function CreateFrames(parent_frame, array, num, template)
    while (#parent_frame[array] < num) do
		local frame = CreateFrame("Frame", nil, parent_frame, template);
	end

    for i = num + 1, #parent_frame[array] do
		parent_frame[array][i]:Hide();
	end
end

local function ReanchorFrames(frames, anchorPoint, anchor, relativePoint, width, spacing, distance)
    local num = #frames;
    local numButtons = math.min(MAX_PER_ROW, num);
    local fullWidth = (width * numButtons) + (spacing * (numButtons - 1));
    local halfWidth = fullWidth / 2;

    local numRows = math.floor((num + MAX_PER_ROW - 1) / MAX_PER_ROW) - 1;
    local fullDistance = numRows * frames[1]:GetHeight() + (numRows + 1) * distance;

    -- First frame
    frames[1]:ClearAllPoints();
    frames[1]:SetPoint(anchorPoint, anchor, relativePoint, -halfWidth, fullDistance);

    -- first row
    for i = 2, math.min(MAX_PER_ROW, #frames) do
        frames[i]:SetPoint("LEFT", frames[i-1], "RIGHT", spacing, 0);
    end

    -- n-rows after
    if (num > MAX_PER_ROW) then
        local currentExtraRow = 0;
        local finished = false;
        repeat
            local setFirst = false;
            for i = (MAX_PER_ROW + (MAX_PER_ROW * currentExtraRow)) + 1, (MAX_PER_ROW + (MAX_PER_ROW * currentExtraRow)) + MAX_PER_ROW do
                if (not frames[i]) then
                    finished = true;
                    break;
                end
                if (not setFirst) then
                    frames[i]:SetPoint("TOPLEFT", frames[i - (MAX_PER_ROW + (MAX_PER_ROW * currentExtraRow))], "BOTTOMLEFT", 0, -distance);
                    setFirst = true;
                else
                    frames[i]:SetPoint("LEFT", frames[i-1], "RIGHT", spacing, 0);
                end
            end
            currentExtraRow = currentExtraRow + 1;
        until finished;
    end
end

local function LineUpFrames(frames, anchorPoint, anchor, relativePoint, width)
    local num = #frames;

	local distanceBetween = 2;
	local spacingWidth = distanceBetween * num;
	local widthRemaining = width - spacingWidth;

    local halfWidth = width / 2;

	local calculateWidth = widthRemaining / num;

    -- First frame
    frames[1]:ClearAllPoints();
	if(frames[1].Icon) then
		frames[1].Icon:SetSize(calculateWidth, calculateWidth);
	end
	frames[1]:SetSize(calculateWidth, calculateWidth);
    frames[1]:SetPoint(anchorPoint, anchor, relativePoint, -halfWidth, 5);

	for i = 2, #frames do
		if(frames[i].Icon) then
			frames[i].Icon:SetSize(calculateWidth, calculateWidth);
		end
		frames[i].Icon:SetSize(calculateWidth, calculateWidth);
		frames[i]:SetSize(calculateWidth, calculateWidth);
		frames[i]:SetPoint("LEFT", frames[i-1], "RIGHT", distanceBetween, 0);
	end
end

function UpdateKeys()
     local sortedMaps = {};
     local weekAffixes = C_MythicPlus.GetCurrentAffixes();

     for i = 1, #ChallengesFrame.maps do
 		local inTimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(ChallengesFrame.maps[i]);
 		local affixScores, overAllScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(ChallengesFrame.maps[i]);
 		local level = 0; -- TODO delete
 		local thisLevel = 0;
 		local otherLevel = 0;
 		local dungeonScore = 0;
 		local week = "Tyrannical"
 		if (weekAffixes[1].id == 10) then
 		  week = "Fortified"
 		end

 		if (affixScores) then
            for i, affixScore in ipairs(affixScores) do
                if affixScore.name == week then
                  thisLevel = affixScore.level
                else
                  otherLevel = affixScore.level
                end
            end
 		end

 		if(inTimeInfo and overtimeInfo) then
 			local inTimeScoreIsBetter = inTimeInfo.dungeonScore > overtimeInfo.dungeonScore;
 			dungeonScore = inTimeScoreIsBetter and inTimeInfo.dungeonScore or overtimeInfo.dungeonScore;
         elseif(inTimeInfo or overtimeInfo) then
 			dungeonScore = inTimeInfo and inTimeInfo.dungeonScore or overtimeInfo.dungeonScore;
 		end
 		local name = C_ChallengeMode.GetMapUIInfo(ChallengesFrame.maps[i]);
 		tinsert(sortedMaps, { id = ChallengesFrame.maps[i], level = thisLevel, otherLevel = otherLevel, dungeonScore = dungeonScore, name = name}); -- TODO add fort/tyr level
     end

     table.sort(sortedMaps,
 	function(a, b)
 		if(b.level ~= a.level) then
 			return a.level > b.level;
 		else
 			return strcmputf8i(a.name, b.name) > 0;
 		end
 	end);

 	local hasWeeklyRun = false;
 	local weeklySortedMaps = {};
 	 for i = 1, #ChallengesFrame.maps do
 		local _, weeklyLevel = C_MythicPlus.GetWeeklyBestForMap(ChallengesFrame.maps[i])
         if (not weeklyLevel) then
             weeklyLevel = 0;
         else
             hasWeeklyRun = true;
         end
         tinsert(weeklySortedMaps, { id = ChallengesFrame.maps[i], weeklyLevel = weeklyLevel});
      end

     table.sort(weeklySortedMaps, function(a, b) return a.weeklyLevel > b.weeklyLevel end);

     local frameWidth = ChallengesFrame.WeeklyInfo:GetWidth()

     local num = #sortedMaps;

     CreateFrames(ChallengesFrame, "DungeonIcons", num, "ChallengesDungeonIconFrameTemplate");
     LineUpFrames(ChallengesFrame.DungeonIcons, "BOTTOMLEFT", ChallengesFrame, "BOTTOM", frameWidth);

     for i = 1, #sortedMaps do
         local frame = ChallengesFrame.DungeonIcons[i];
         frame:SetUp(sortedMaps[i], i == 1);
         frame:Show();

 		if (i == 1) then
 			ChallengesFrame.WeeklyInfo.Child.SeasonBest:ClearAllPoints();
 			ChallengesFrame.WeeklyInfo.Child.SeasonBest:SetPoint("TOPLEFT", ChallengesFrame.DungeonIcons[i], "TOPLEFT", 5, 15);
 		end
     end
end

local function load()
  if IsAddOnLoaded("Blizzard_ChallengesUI") then
    hooksecurefunc(ChallengesFrame, "Update", UpdateKeys)
    UpdateKeys()
  else
    C_Timer.After(3, function()
        load()
    end)
  end

end

load()

