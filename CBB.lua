--[[
* ReaScript Name: CBB
* Description: A script for REAPER ReaScript.
* Instructions: Run script to display cues, bars and beats
* Screenshot:
* Author: dovgjm
* Repository: 
* Repository URI: 
* File URI:
* License: 
* Forum Thread:
* Forum Thread URI:
* REAPER: 7.x
* Extensions: None
* Version: 1.0
--]]

--[[ ----- INSTRUCTIONS ====>

Run script to display cues, bars and beats

--]]






-- Setup: Paths, item files, functions
os = reaper.GetOS();
if(os == "Win32" or os == "Win64") then
  pathSep = "\\"
else
  pathSep = "/"
end

_,ScriptPath = reaper.get_action_context()
ScriptPath = ScriptPath:gsub("[^" .. pathSep .. "]+$", "") -- remove filename
dataPath = ScriptPath .. "data" .. pathSep






-- Track name defaults
CUES = "Cues"
BARS = "Bars"
BEATS = "Beats"

------------------


cuesTrack = nil
barsTrack = nil
beatsTrack = nil

function remove_tracks()

local t=0
local bucket, bucket_index = {}, 0
local CT = reaper.CountTracks(0)

for t=0, CT-1 do

local track = reaper.GetTrack(0, t)
local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)

  if trackName == BARS then 
      bucket[bucket_index] = track
      bucket_index = bucket_index + 1
  elseif trackName == BEATS then
      bucket[bucket_index] = track
      bucket_index = bucket_index + 1
  elseif trackName == CUES then
      bucket[bucket_index] = track
      bucket_index = bucket_index + 1
  end

  t = t + 1
end


if bucket_index > 0 then
  local dialog_btn = reaper.ShowMessageBox(
    string.format("Delete and remake Beats, Bars & Cues tracks?"),
    "Confirmation", 1
  )

  if dialog_btn == 1 then
    local track_index = 0

    while track_index < bucket_index do
      reaper.DeleteTrack(bucket[track_index])
      track_index = track_index + 1
    end
  end
end

if cuesTrack == nil then
  reaper.InsertTrackAtIndex(0, true)
  cuesTrack = reaper.GetTrack(0, 0)
  reaper.GetSetMediaTrackInfo_String(cuesTrack, "P_NAME", CUES, true)
end
    
if barsTrack == nil then
  reaper.InsertTrackAtIndex(0, true)
  barsTrack = reaper.GetTrack(0, 0)
  reaper.GetSetMediaTrackInfo_String(barsTrack, "P_NAME", BARS, true)
end
    
if beatsTrack == nil then
  reaper.InsertTrackAtIndex(0, true)
  beatsTrack = reaper.GetTrack(0, 0)   
  reaper.GetSetMediaTrackInfo_String(beatsTrack, "P_NAME", BEATS, true)
end

end

--------------------


function CBB_main(q,w)

remove_tracks()


--local dialog_btn = reaper.ShowMessageBox(
--    string.format("What bar is 1? How many bars in?"),
--    "Setup", 1
--  )


local retval, csv = reaper.GetUserInputs("CBB Setup", 3, "Free Bars (default: 1),Free Into Count Up(2) Down(1),Start Bar (default: 9)", "1,2,9")
if retval then
	local tokens = {}
	for token in csv:gmatch("([^,]*),?") do
		table.insert(tokens, token)
	end
	
    freeInto = math.ceil(tokens[1])
    countDirection = math.ceil(tokens[2])
    cueStart = math.ceil(tokens[3] - 1)
    freePos = cueStart - freeInto
end    
-- cueStart = 9 - 1
-- freeInto = 2
-- freePos = cueStart - freeInto


_, _, _, timesig_num, _, _ = reaper.TimeMap_GetMeasureInfo(0 , freePos)
freeBeats = timesig_num * freeInto


retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )

--reaper.ShowConsoleMsg(retval .. " " .. num_markers .. " " .. num_regions .. "\n")


for p=0, retval-1 do

local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0 , p )

if isrgn then -- Cue Title 

--reaper.ShowConsoleMsg(p .. " " .. pos .. " " .. rgnend .. " ")

local cueItem = reaper.CreateNewMIDIItemInProj( cuesTrack, pos, rgnend)
local cueTake = reaper.GetActiveTake(cueItem)

name = name
reaper.GetSetMediaItemTakeInfo_String(cueTake , "P_NAME", name , 1) 

  -- Item Chunk ----------------------------------
  ret, Chunk  = reaper.GetItemStateChunk(cueItem,"",false)
  if Chunk:find("TAKEFX") then  return end
  -- New Chunk  ----------------------------------
  Chunk = Chunk:sub(1,-3)
  FXID =  reaper.genGuid("") -- Gen FXID
  -- Video_processor --------------
  TAKEFX = 
  [[<TAKEFX
  WNDRECT 261 91 870 502
  SHOW 0
  LASTSEL 0
  DOCKED 0
  BYPASS 0 0 0
  <VIDEO_EFFECT "Video processor" ""
  <CODE
    |// Text
    | font="Arial";
    |
    | size = 0.1;
    | ypos = 1;
    | xpos = 0.5;
    | border = 0;
    | fgc = 1;
    | fga = 1;
    | bgc = 0;
    | bga = 1;
    | bgfit = 1;
    |
    |
    | project_wh_valid===0 ? input_info(input,project_w,project_h);
    | gfx_a2=0;
    | gfx_blit(input,1);
    | gfx_setfont(size*project_h,font);
    |
    | input_get_name(-1,#text);
    |
    | gfx_str_measure(#text,txtw,txth);
    | b = (border*txth)|0;
    | yt = ((project_h - txth - b*2)*ypos)|0;
    | xp = (xpos * (project_w-txtw))|0;
    | gfx_set(bgc,bgc,bgc,bga);
    | bga>0?gfx_fillrect(bgfit?xp-b:0, yt, bgfit?txtw+b*2:project_w, txth+b*2);
    | gfx_set(fgc,fgc,fgc,fga);
    | gfx_str_draw(#text,xp,yt+b);
    |
  >
  CODEPARM 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000
  >
  FLOATPOS 0 0 0 0
  FXID ]]..FXID.. -- Insert FXID  
  [[WAK 0
  >
  >]]
  ---------------
  Chunk = Chunk..TAKEFX
  --reaper.ShowConsoleMsg("====Chunk====".."\n"..Chunk)
  reaper.SetItemStateChunk(cueItem , Chunk, true)
  reaper.UpdateItemInProject(cueItem)
  
  

-- Free into Count In ------------------
--for i=freePos, cueStart-1 do -- bars to process


           
            
_, qn_start, _, _, _, _ = reaper.TimeMap_GetMeasureInfo(0 , 0)
_, _, qn_end, _, _, _ = reaper.TimeMap_GetMeasureInfo(0 , 7)

            
--reaper.ShowConsoleMsg("retval " .. retval .. " qn start " .. qn_start .. " qn end " .. qn_end .. " time sig num " .. timesig_num .. " time sig denom " .. timesig_denom .. " tempo " .. tempo .. "\n")

barItem = reaper.CreateNewMIDIItemInProj( barsTrack, qn_start, qn_end, 1)
--local barTake = reaper.AddTakeToMediaItem(barItem)
barTake = reaper.GetActiveTake(barItem)

--name = "Bar " .. i+1-mPos .. " "
name = freeBeats .. " Free"
reaper.GetSetMediaItemTakeInfo_String(barTake , "P_NAME", name , 1) 

  -- Item Chunk ----------------------------------
  ret, Chunk  = reaper.GetItemStateChunk(barItem,"",false)
  if Chunk:find("TAKEFX") then  return end
  -- New Chunk  ----------------------------------
  Chunk = Chunk:sub(1,-3)
  FXID =  reaper.genGuid("") -- Gen FXID
  -- Video_processor --------------
  TAKEFX = 
  [[<TAKEFX
  WNDRECT 261 91 870 502
  SHOW 0
  LASTSEL 0
  DOCKED 0
  BYPASS 0 0 0
  <VIDEO_EFFECT "Video processor" ""
  <CODE
    |// Text
    | font="Arial";
    |
    | size = 0.14;
    | ypos = 0.01;
    | xpos = 0.5;
    | border = 0.1;
    | fgc = 0;
    | fga = 1;
    | bgc = 0;
    | bga = 1;
    | bgfit = 1;
    |
    |
    | project_wh_valid===0 ? input_info(input,project_w,project_h);
    | gfx_a2=0;
    | gfx_blit(input,1);
    | gfx_setfont(size*project_h,font);
    |
    | input_get_name(-1,#text);
    |
    | gfx_str_measure(#text,txtw,txth);
    | b = (border*txth)|0;
    | yt = ((project_h - txth - b*2)*ypos)|0;
    | xp = (xpos * (project_w-txtw))|0;
    | gfx_set(1,1,bgc,bga);
    | bga>0?gfx_fillrect(bgfit?xp-b:0, yt, bgfit?txtw+b*2:project_w, txth+b*2);
    | gfx_set(fgc,fgc,fgc,fga);
    | gfx_str_draw(#text,xp,yt+b);
    |
  >
  CODEPARM 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000
  >
  FLOATPOS 0 0 0 0
  FXID ]]..FXID.. -- Insert FXID  
  [[WAK 0
  >
  >]]
  ---------------
  Chunk = Chunk..TAKEFX
  --reaper.ShowConsoleMsg("====Chunk====".."\n"..Chunk)
  reaper.SetItemStateChunk(barItem , Chunk, true)
  reaper.UpdateItemInProject(barItem)












retval, qn_start, qn_end, timesig_num, timesig_denom, tempo = reaper.TimeMap_GetMeasureInfo(0 , freePos)
-- reaper.ShowConsoleMsg("retval " .. retval .. " qn start " .. qn_start .. " qn end " .. qn_end .. " time sig num " .. timesig_num .. " time sig denom " .. timesig_denom .. " tempo " .. tempo .. "\n")

freeBeats = timesig_num * freeInto
--reaper.ShowConsoleMsg("freeBeats " .. freeBeats ) 

beat_pos = {}
if timesig_denom == 16 then
  ts = 0.25              
  elseif timesig_denom == 8 then
  ts = 0.5
  elseif timesig_denom == 2 then
  ts = 2
  else
  ts = 1
  end --if timesig_denom 
  
qn_pos = qn_start

 for j=0, freeBeats do -- beat items
 
  bp = reaper.TimeMap2_QNToTime(0, qn_pos)
 
  beat_pos[j] = bp
  
--  reaper.ShowConsoleMsg("" .. qn_pos .. "  " .. bp .. "  " .. retval .. "\n")
  
  qn_pos = qn_pos + ts


 end -- close for loop, beat items
 
 countDown = freeBeats
 countUp = 1
 
 for b=0, freeBeats-1 do
--   reaper.ShowConsoleMsg(beat_pos[b] .. " " .. beat_pos[b+1] .. "\n")
   beatItem = reaper.CreateNewMIDIItemInProj( beatsTrack, beat_pos[b], beat_pos[b+1], 0)
   beatTake = reaper.GetActiveTake(beatItem)
--   beatName = b+1 .. " - " .. timesig_num..'/'..timesig_denom
   if countDirection == 1 then beatName = countDown end
   if countDirection == 2 then beatName = countUp end
   reaper.GetSetMediaItemTakeInfo_String(beatTake , "P_NAME", beatName , 1)
   ----------------
   -- Item Chunk ----------------------------------
   ret, Chunk  = reaper.GetItemStateChunk(beatItem,"",false)
   if Chunk:find("TAKEFX") then  return end
   -- New Chunk  ----------------------------------
   Chunk = Chunk:sub(1,-3)
   FXID =  reaper.genGuid("") -- Gen FXID
   -- Video_processor --------------
   TAKEFX = 
   [[<TAKEFX
   WNDRECT 261 91 870 502
   SHOW 0
   LASTSEL 0
   DOCKED 0
   BYPASS 0 0 0
   <VIDEO_EFFECT "Video processor" ""
   <CODE
     |// Text
     | font="Arial";
     |
     | size = 0.14;
     | ypos = 0.01;
     | xpos = 0.96;
     | border = 0.1;
     | fgc = 0;
     | fga = 1;
     | bgc = 0;
     | bga = 1;
     | bgfit = 1;
     |
     |
     | project_wh_valid===0 ? input_info(input,project_w,project_h);
     | gfx_a2=0;
     | gfx_blit(input,1);
     | gfx_setfont(size*project_h,font);
     |
     | input_get_name(-1,#text);
     |
     | gfx_str_measure(#text,txtw,txth);
     | b = (border*txth)|0;
     | yt = ((project_h - txth - b*2)*ypos)|0;
     | xp = (xpos * (project_w-txtw))|0;
     | gfx_set(1,1,bgc,bga);
     | bga>0?gfx_fillrect(bgfit?xp-b:0, yt, bgfit?txtw+b*2:project_w, txth+b*2);
     | gfx_set(fgc,fgc,fgc,fga);
     | gfx_str_draw(#text,xp,yt+b);
     |
   >
   CODEPARM 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000
   >
   FLOATPOS 0 0 0 0
   FXID ]]..FXID.. -- Insert FXID  
   [[WAK 0
   >
   >]]
   ---------------
   Chunk = Chunk..TAKEFX
   --reaper.ShowConsoleMsg("====Chunk====".."\n"..Chunk)
   reaper.SetItemStateChunk(beatItem , Chunk, true)
   reaper.UpdateItemInProject(beatItem)
   ----------------
   countDown = countDown - 1
   countUp = countUp + 1
 end



-- end -- Free into Count In --


-- Main cue Bars & Beats -------
local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, pos)

local mPos = measures

local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, rgnend)

local mDur = measures

-- reaper.ShowConsoleMsg("mPos " .. mPos .. " mDur " .. mDur .. "\n")

-- get_track()

--for i=mPos, mDur-1 do -- bars to process
for i=cueStart, mDur-11 do -- bars to process

retval, qn_start, qn_end, timesig_num, timesig_denom, tempo = reaper.TimeMap_GetMeasureInfo(0 , i)
-- reaper.ShowConsoleMsg("retval " .. retval .. " qn start " .. qn_start .. " qn end " .. qn_end .. " time sig num " .. timesig_num .. " time sig denom " .. timesig_denom .. " tempo " .. tempo .. "\n")

barItem = reaper.CreateNewMIDIItemInProj( barsTrack, qn_start, qn_end, 1)
--local barTake = reaper.AddTakeToMediaItem(barItem)
barTake = reaper.GetActiveTake(barItem)

--name = "Bar " .. i+1-mPos .. " "
name = i+1-cueStart.. "|"
reaper.GetSetMediaItemTakeInfo_String(barTake , "P_NAME", name , 1) 

  -- Item Chunk ----------------------------------
  ret, Chunk  = reaper.GetItemStateChunk(barItem,"",false)
  if Chunk:find("TAKEFX") then  return end
  -- New Chunk  ----------------------------------
  Chunk = Chunk:sub(1,-3)
  FXID =  reaper.genGuid("") -- Gen FXID
  -- Video_processor --------------
  TAKEFX = 
  [[<TAKEFX
  WNDRECT 261 91 870 502
  SHOW 0
  LASTSEL 0
  DOCKED 0
  BYPASS 0 0 0
  <VIDEO_EFFECT "Video processor" ""
  <CODE
    |// Text
    | font="Arial";
    |
    | size = 0.16;
    | ypos = 0.01;
    | xpos = 0.87;
    | border = 0;
    | fgc = 1;
    | fga = 1;
    | bgc = 0;
    | bga = 1;
    | bgfit = 1;
    |
    |
    | project_wh_valid===0 ? input_info(input,project_w,project_h);
    | gfx_a2=0;
    | gfx_blit(input,1);
    | gfx_setfont(size*project_h,font);
    |
    | input_get_name(-1,#text);
    |
    | gfx_str_measure(#text,txtw,txth);
    | b = (border*txth)|0;
    | yt = ((project_h - txth - b*2)*ypos)|0;
    | xp = ((xpos * project_w)-txtw)|0;
    | gfx_set(bgc,bgc,bgc,bga);
    | bga>0?gfx_fillrect(bgfit?xp-b:0, yt, bgfit?txtw+b*2:project_w, txth+b*2);
    | gfx_set(fgc,fgc,fgc,fga);
    | gfx_str_draw(#text,xp,yt+b);
    |
  >
  CODEPARM 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000
  >
  FLOATPOS 0 0 0 0
  FXID ]]..FXID.. -- Insert FXID  
  [[WAK 0
  >
  >]]
  ---------------
  Chunk = Chunk..TAKEFX
  --reaper.ShowConsoleMsg("====Chunk====".."\n"..Chunk)
  reaper.SetItemStateChunk(barItem , Chunk, true)
  reaper.UpdateItemInProject(barItem)


beat_pos = {}
if timesig_denom == 16 then
  ts = 0.25
  elseif timesig_denom == 8 then
  ts = 0.5
  elseif timesig_denom == 2 then
  ts = 2
  else
  ts = 1
  end --if timesig_denom 
  
qn_pos = qn_start

 for j=0, timesig_num do -- beat items
 
  bp = reaper.TimeMap2_QNToTime(0, qn_pos)
 
  beat_pos[j] = bp
  
--  reaper.ShowConsoleMsg("" .. qn_pos .. "  " .. bp .. "  " .. retval .. "\n")
  
  qn_pos = qn_pos + ts


 end -- close for loop, beat items
 
 for b=0, timesig_num-1 do
--   reaper.ShowConsoleMsg(beat_pos[b] .. " " .. beat_pos[b+1] .. "\n")
   beatItem = reaper.CreateNewMIDIItemInProj( beatsTrack, beat_pos[b], beat_pos[b+1], 0)
   beatTake = reaper.GetActiveTake(beatItem)
--   beatName = b+1 .. " - " .. timesig_num..'/'..timesig_denom
   beatName = b+1
   reaper.GetSetMediaItemTakeInfo_String(beatTake , "P_NAME", beatName , 1)
   ----------------
   -- Item Chunk ----------------------------------
   ret, Chunk  = reaper.GetItemStateChunk(beatItem,"",false)
   if Chunk:find("TAKEFX") then  return end
   -- New Chunk  ----------------------------------
   Chunk = Chunk:sub(1,-3)
   FXID =  reaper.genGuid("") -- Gen FXID
   -- Video_processor --------------
   TAKEFX = 
   [[<TAKEFX
   WNDRECT 261 91 870 502
   SHOW 0
   LASTSEL 0
   DOCKED 0
   BYPASS 0 0 0
   <VIDEO_EFFECT "Video processor" ""
   <CODE
     |// Text
     | font="Arial";
     |
     | size = 0.16;
     | ypos = 0.01;
     | xpos = 0.97;
     | border = 0;
     | fgc = 1;
     | fga = 1;
     | bgc = 0;
     | bga = 1;
     | bgfit = 1;
     |
     |
     | project_wh_valid===0 ? input_info(input,project_w,project_h);
     | gfx_a2=0;
     | gfx_blit(input,1);
     | gfx_setfont(size*project_h,font);
     |
     | input_get_name(-1,#text);
     |
     | gfx_str_measure(#text,txtw,txth);
     | b = (border*txth)|0;
     | yt = ((project_h - txth - b*2)*ypos)|0;
     | xp = ((xpos * project_w) - txtw)|0;
     | gfx_set(bgc,bgc,bgc,bga);
     | bga>0?gfx_fillrect(bgfit?xp-b:0, yt, bgfit?txtw+b*2:project_w, txth+b*2);
     | gfx_set(fgc,fgc,fgc,fga);
     | gfx_str_draw(#text,xp,yt+b);
     |
   >
   CODEPARM 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000 0.0000000000
   >
   FLOATPOS 0 0 0 0
   FXID ]]..FXID.. -- Insert FXID  
   [[WAK 0
   >
   >]]
   ---------------
   Chunk = Chunk..TAKEFX
   --reaper.ShowConsoleMsg("====Chunk====".."\n"..Chunk)
   reaper.SetItemStateChunk(beatItem , Chunk, true)
   reaper.UpdateItemInProject(beatItem)
   ----------------
                    
    end


end -- close for loop, create bar items

end -- closes region IF statement

end -- close for loop, create cue items

end -- close function main


CBB_main()


