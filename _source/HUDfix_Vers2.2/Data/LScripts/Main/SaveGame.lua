--============================================================================
-- SAVE GAME
--============================================================================
SaveGameVersion = 5
SaveGame = 
{
    -- attributes
    Level = "Name",    
    LevelDir = "",
    Type  = "Normal", -- CheckPoint, NewLevel, Normal, Quick, AutoNewLevel, StartLevel
    Date  = "DD-MM-YYYY",
    Time  = "HH:MM:SS",
    Difficulty = 0,
    LevelTime = "HH:MM:SS",
    CheckPoint = 0,
    Version = SaveGameVersion, -- savegame version (for patches)
}
--============================================================================
function SaveGame:RestorePointers(t)
    if t.____restored then return end
    if not table.isconstant(t) then
        t.____restored = true
    end
    local i, v = next(t, nil)
    while i do
        if type(v)=="table" then 
            self:RestorePointers(v) 
        else       
            if type(v)=="string" and string.find(v,"ref:",1,true) then
                local str = string.sub(v,5)
                local ptr = getfenv()[str]
                rawset(t,i,ptr)
            end
        end
        i, v = next(t, i) 
    end
    if not table.isconstant(t) then
        t.____restored = nil
    end
end
--============================================================================
function SaveGame:RestoreTimers(obj)
    if obj.____restored then return end
    if not table.isconstant(obj) then
        obj.____restored = true
    end
    if obj._Timers then
        for i,o in obj._Timers do
            o[4] = obj[o[1]]           
        end 
    end
    for i,o in obj do
        if type(o) == "table" then
            self:RestoreTimers(o)
        end
    end
    if not table.isconstant(obj) then
        obj.____restored = nil
    end
end
--============================================================================
-- uzupelnianie od funkcje i tablice statyczne z BaseObj i Class
function SaveGame:RestoreBaseObjectAndClass(obj)
    if obj.____restored then return end
    if not table.isconstant(obj) then
        obj.____restored = true
    end
	if obj.BaseObj then
		local o
		if obj.BaseName then
			o = FindObj(obj.BaseName)
		else
			o = FindObj(obj.BaseObj)
		end
		if o then
			InheritFunctionsAndStatics(obj,o)
		end
	end

    if obj._Class then
        local o = FindObj(obj._Class)
        if o then
			InheritFunctionsAndStatics(obj,o)
		end
    end
    for i,o in obj do
        if type(o) == "table" then
            self:RestoreBaseObjectAndClass(o)
        end
    end
    if not table.isconstant(obj) then
        obj.____restored = nil
    end
end
--============================================================================
function SaveGame:SaveOtherData(slot,demo)
	local path
	if not demo then
		path = string.format("../SaveGames/%03d/",slot)
	else
		path = "../Recordings/"..slot.."/"
	end

    local f = FS.File_Open(path.."OtherData.State","w")
    if f then
        FS.File_Write(f,"EntityToObject = {}\n")
        for i,o in EntityToObject do
            if o then
                FS.File_Write(f,"EntityToObject["..i.."] = '"..o._Name.."'\n")
            end
        end
    end
    FS.File_Close(f)

    Game.con = {}
    local f = FS.File_Open(path.."Game.State","w")
    if f then
        SaveFullTable(f,Game,"Game") 
    end
    FS.File_Close(f)
end
--============================================================================
function SaveGame:LoadOtherData(slot,demo)
   	local path
	if not demo then
		path = string.format("../SaveGames/%03d/",slot)
	else
		path = "../Recordings/"..slot.."/"
	end

    DoFile(path.."OtherData.State")
    for i,o in EntityToObject do
        local ptr = getfenv()[o]
        rawset(EntityToObject,i,ptr)
    end
    DoFile(path.."Game.State")
    self:RestorePointers(Game)
    self:RestoreBaseObjectAndClass(Game)
end
--============================================================================
function SaveGame:LoadObjectsDirectory(path) 
    --local dirs = FS.FindFiles(path.."C*",0,1)
    --for i=1,table.getn(dirs) do            
    --    self:LoadObjectsDirectory(path..dirs[i].."/")
    --end    
            
    local files = FS.FindFiles(path.."*.C*",1,0)
    PMENU.SetLoadingScreenOverall( table.getn(files), 20 )
    for i=1,table.getn(files) do            
        local fname, ext = ParseFileName(files[i])        
        if string.len(fname) <= 2 then MsgBox("Warning!!! Object's name is too short: "..files[i]) end
        if ext ~= "CLevel" then             
            local obj = {}
            o = obj
            getfenv()[fname] = obj
            DoFile(path..files[i])                
            DoFile("../Data/Levels/"..Lev._Name.."/"..ext.."/"..fname..".lua",false)
            if not o then 
                MsgBox("Cannot Create Object:\n" .. path..files[i]) 
            else
                GObjects:Add(fname,o)
            end
            PMENU.LoadingProgress()
        end
    end
end
--============================================================================
-- called from C++
function SaveGame:AfterLoadEntities()
    self:RestorePointers(Lev)
    self:RestorePointers(GObjects.Elements)
    
    self:RestoreBaseObjectAndClass(Lev)
    self:RestoreBaseObjectAndClass(GObjects.Elements)
    
    self:RestoreTimers(Lev)
    self:RestoreTimers(GObjects.Elements)    
    Lev:RestoreReplacedFunctions()
    
    for i,o in GObjects.Elements do
        if o.RestoreFromSave then o:RestoreFromSave() end
        o:RestoreReplacedFunctions()
        GObjects:AddToTables(o)
    end    
end
--============================================================================
function SaveGame:LoadRequest(slot,loadOnly,demo)
    LoadRequest = 
    {   Slot = slot,
        LoadOnly = loadOnly,
        Demo = demo
    }
end
--============================================================================
function SaveGame:Load(slot,loadOnly,demo)

    LoadRequest = nil
    
    WORLD.SwitchToState(2)    
    
    local path
	if not demo then
		path = string.format("../SaveGames/%03d/",slot)
	else
		path = "../Recordings/"..slot.."/"
	end

    o = {}
    DoFile(path.."SaveGame.Info",false)
    if not o.Type then return end    
	local saveData = Clone(o)
    
    local pack = FS.RegisterPack(path.."Save.dat",path)

	o = {}
	DoFile(path.."LevelStart.Info",false)
	if not o.Difficulty then 
        FS.UnregisterPack(pack)
        return 
    end
	LevelStartState = {}
	LevelStartState = Clone(o)
	Game:Print( "LevelStartState.Difficulty = "..LevelStartState.Difficulty )
	
	o = {}
	DoFile(path.."CurrState.Info",false)
	if o.Difficulty then
		Game:SetCurrentLevelState(o)
	else
		Game:SetCurrentLevelState(LevelStartState)
	end

	if saveData.Type == "NewLevel" or saveData.Type == "AutoNewLevel" or saveData.Type == "StartLevel" then
        CONSOLE.AddMessage(TXT.Menu.GameLoaded)
        if not loadOnly then
			Game:NewLevel("NoName","","",0.3,true) 
			Lev:Apply()
			PMENU.MapSetCurrLevel(Game.CurrLevel, Game.CurrChapter)
			PMENU.SwitchToMap()
			PMENU.MapNextLevel()
		else
			Game:Clear()
            WORLD.Release(true)
            Game:LoadLevel(saveData.LevelDir)
            Game:OnPlay(true)
            Game:SwitchPlayerToPhysics(true)
            MOUSE.Lock()
        end
        FS.UnregisterPack(pack)
        return
    end

	local currLevel, currChapter = Levels_GetLevelByDir(saveData.LevelDir)
	if currLevel then
		Game.CurrLevel = currLevel
		Game.CurrChapter = currChapter
	else
		Game.CurrLevel = 0
		Game.CurrChapter = 0
	end

    PMENU.ActivateLoadingScreen( true, Game.CurrLevel, Levels_GetSketchByDir(saveData.LevelDir) )

    PMENU.ActivateLoadingScreen( true )    
    local files = FS.FindFiles(path.."*.CLevel",1,0)
    if table.getn(files)>0 then
        -- create and load level object
        local fname, ext = ParseFileName(files[1])        
        Game:NewLevel(fname,"","",3)
        o = Lev        
        DoFile(path..files[1])
        DoFile("../Data/Levels/"..Lev._Name.."/"..Lev._Name..".lua",false)
        --PMENU.LoadingProgress()
        getfenv()[fname] = Lev        
        -- load level templates
        PreloadTemplates("../Data/Levels/"..Lev._Name.."/Templates",true)                
        -- load objects
        self:LoadObjectsDirectory(path,true)
    end
    
    WORLD.Release(true,Lev.Map) -- full world release with current map
    
    WORLD.LateVBsBegin()

    WORLD.LoadMap("../Data/Maps/"..Lev.Map,Lev._Name,Lev.Scale,Lev.Overbright,Lev.RTCubeMap)        
    local p = Lev.Physics     
    WORLD.Init(p.ActiveMeshesMassScale,p.DefaultMeshFriction,p.DefaultMeshRestitution,p.Deactivator.Delay,p.Deactivator.MaxPosDiff,true)
    Lev:SetupMap()        
    
    WORLD.LoadGame(path..Lev._Name..".World")
    Game:SetupMapEntities("../Data/Levels/"..Lev._Name.."/")            
    self:LoadOtherData(slot,demo)
    
    -- dopiero po LoadGame poniewaz indeksy musza isc od zera
    Cache:PrecacheLevel(name)    

    Player = Game.Players[1]
    for i,o in Player.Weapons do
        if o.LoadHUDData then o:LoadHUDData() end
        o:RestoreFromSave()
    end
    
    if Lev.RestoreFromSave then Lev:RestoreFromSave() end    
    
    for i,o in GObjects.Elements do
        if o.PostRestoreFromSave then o:PostRestoreFromSave() end
    end    

    WORLD.LateVBsEnd()
    WORLD.UpdateAllEntities()

    CAM.SetAng(Lev.Ang.X,Lev.Ang.Y,Lev.Ang.Z)
    CAM.SetPos(Lev.Pos.X,Lev.Pos.Y,Lev.Pos.Z)
    
    if not Game.IsDemon then R3D.SetCameraFOV(Cfg.FOV) end

	Game:RestoreGoldenIcons(true)

    Game.Active = true
    Game._BlockedPlay = true
    MOUSE.Lock(true)
    PX,PY,PZ = Player.Pos:Get()
    
    --debug = 1
    --debugMarek = true    
	SaveGame:Save(0,"StartLevel",LevelStartState.Timestamp)

    PMENU.ActivateLoadingScreen( false )
    INP.ResetTimer()
    CONSOLE.AddMessage(TXT.Menu.GameLoaded)
    PMENU.Activate(false)
    PMENU.ResumeSounds()
    Game.PlayerEnabledWeapons = nil
    MOUSE.Lock()
    FS.UnregisterPack(pack)
    
    SOUND.SaveGame_ResumeSounds()
    
    SOUND.ApplySoundSettings( Cfg.MasterVolume, 100, Cfg.SfxVolume, Cfg.SpeakersSetup, Cfg.SoundPan, Cfg.ReverseStereo, Cfg.SoundProvider3D )
	SOUND.StreamSetVolume(0,Cfg.AmbientVolume)
	SOUND.StreamSetVolume(1,Cfg.MusicVolume)
	CSound.EnableAmbients(Cfg.AmbientSounds)
end
--============================================================================
function SaveGame:FindFreeSlot()
    
    local slot = 0
    local files = FS.FindFiles("../SaveGames/*.*",0,1)
    table.sort(files,function (a,b) return a < b end)    
    
    if files[1] == "001" or files[1] == "000" then    
        for i,o in files do
            slot = tonumber(o)
            if not slot or (files[i+1] and tonumber(files[i+1]) and tonumber(files[i+1]) > slot+1) then break end
        end
    end
    
    if not slot then 
        slot = 0
    end
    
    return slot + 1
end
--============================================================================
function SaveGame:SaveRequest(slot,stype,demo)
    SaveRequest = 
    {   Slot = slot,
        SType = stype,
        Demo = demo
    }
end
--============================================================================
function SaveGame:Save(slot,stype,forcetime,demo)

    SaveRequest = nil
    if Game.GMode ~= GModes.SingleGame and not demo then return end

    if not slot then
        slot = self:FindFreeSlot()
	end
    
	if stype == "Quick" then
		local qs_cnt = self:CountSaves("Quick")
		if qs_cnt == 25 then
			self:DeleteOldestSave("Quick")
			slot = self:FindFreeSlot()
		else
			slot = self:FindFreeSlot()
		end
	elseif stype == "CheckPoint" then
		local qs_cnt = self:CountSaves("CheckPoint")
		if qs_cnt == 24 then
			self:DeleteOldestSave("CheckPoint")
			slot = self:FindFreeSlot()
		else
			slot = self:FindFreeSlot()
		end
	elseif stype == "AutoNewLevel" and slot ~= 0 then
		local qs_cnt = self:CountSaves("AutoNewLevel")
		if qs_cnt == 50 then
			self:DeleteOldestSave("AutoNewLevel")
			slot = self:FindFreeSlot()
		else
			slot = self:FindFreeSlot()
		end
    end

    local path
	if not demo then
		FS.CreateDirectory("../SaveGames")
		path = string.format("../SaveGames/%03d/",slot)
	else
		FS.CreateDirectory("../Recordings")
		path = "../Recordings/"..slot.."/"
	end
    FS.CreateDirectory(path)
    FS.DeleteFiles(path)
    
    SaveGame.Type = stype
    SaveGame.LevelDir = Lev._Name
    SaveGame.Level = Lev._Name
    SaveGame.CheckPoint = Game.CheckPoint
    SaveGame.Difficulty = Game.Difficulty
    SaveGame.Date = os.date("%d-%m-%Y")
    SaveGame.Time = os.date("%H:%M:%S")
    SaveGame.LevelTime = os.date("!%H:%M:%S",Game.LevelTime)
    SaveGame.Timestamp = os.date("%Y%m%d%H%M%S")
    if forcetime then SaveGame.Timestamp = forcetime end

    if Player then
        Game.PlayerEnabledWeapons = Player.EnabledWeapons
        if stype ~= "Normal" and stype ~= "Quick" then        
			Game.PlayerEnabledWeapons[10] = nil -- mogl skonczyc poprzedni level w demonie
		end
    end

	if string.find(Lev._Name,"C6L",1,true) == 1 then
		Levels = LevelsAddOn
	else
		Levels = LevelsMain
	end

    if stype == "NewLevel" or stype == "AutoNewLevel" or stype == "StartLevel" then 
        
		if Game.CurrChapter > 0 and Game.CurrLevel > 0 then
			SaveGame.LevelDir = Levels[Game.CurrChapter][Game.CurrLevel][1]
		end
		if stype ~= "StartLevel" then
			SaveGame.LevelDir = Levels_GetNextLevel(SaveGame.LevelDir)
		end
        SaveGame.CheckPoint = 0
        SaveGame.LevelTime = "00:00:00"
        if not SaveGame.LevelDir then 
            FS.RemoveDirectory(path)
            FS.ClosePAK()
            return             
        end -- last level        
    end

	local currState = Game:GetCurrentLevelState()

    local levelname = Levels_GetLevelName(SaveGame.LevelDir)
    if levelname then
		SaveGame.Level = levelname
	end

	if stype == "CheckPoint" then
		SaveGame.Level = TXT.Menu.CheckptPrefix.." "..SaveGame.Level
	elseif stype == "AutoNewLevel" then
		SaveGame.Level = TXT.Menu.AutoPrefix.." "..SaveGame.Level
	end
    
    if LevelStartState then            
		SaveFullObj(path.."SaveGame.Info",SaveGame)
        FS.CreatePAK(path.."Save.dat")
		SaveFullObj(path.."LevelStart.Info",LevelStartState)
		
        if stype ~= "StartLevel" then 
			SaveFullObj(path.."CurrState.Info",currState)
		end
        
		if stype == "NewLevel" or stype == "AutoNewLevel" or stype == "StartLevel" then 
			if slot ~= 0 then CONSOLE.AddMessage(TXT.Menu.GameSaved) end
            FS.ClosePAK()
			return 
		end
	else
		FS.RemoveDirectory(path)
		Game:Print( "ERROR: Cannot create savegame" )
        FS.ClosePAK()
		return
	end

    SaveFullObj(path..Lev._Name.."."..Lev._Class,Lev)
    for i,o in GObjects.Elements do 
        SaveFullObj(path..o._Name.."."..o._Class,o)            
    end        
    self:SaveOtherData(slot,demo)
    WORLD.SaveGame(path..Lev._Name..".World")
    CONSOLE.AddMessage(TXT.Menu.GameSaved)
    INP.ResetTimer()
    FS.ClosePAK()
end
--============================================================================
function SaveGame:Delete(slot,demo)
	if not slot then return end
    local path
	if not demo then
		path = string.format("../SaveGames/%03d/",slot)
	else
		path = "../Recordings/"..slot.."/"
	end
    FS.DeleteFiles(path)    
    FS.RemoveDirectory(path)
end
--============================================================================
function SaveGame:FindLastSave(stype,level)
	if not stype then return nil end

	local dirs = FS.FindFiles("../SaveGames/*",0,1)

	local lastSlot = nil
	local lastTime = "0"
	for i=1,table.getn(dirs) do
		o = {}
		DoFile("../SaveGames/"..dirs[i].."/SaveGame.Info",false)
		if o.Type then
			if o.Type == stype and o.Timestamp and (o.Type == "AutoNewLevel" or SaveGameVersion == o.Version) then
				if o.Timestamp > lastTime and (not level or level == o.LevelDir) then
					lastSlot = dirs[i]
					lastTime = o.Timestamp
				end
			end
		end
	end

	return lastSlot
end
--============================================================================
function SaveGame:CountSaves(stype)
	if not stype then return nil end

	local dirs = FS.FindFiles("../SaveGames/*",0,1)

	local count = 0
	for i=1,table.getn(dirs) do
		o = {}
		DoFile("../SaveGames/"..dirs[i].."/SaveGame.Info",false)
		if o.Type then
			if o.Type == stype and o.Timestamp and (o.Type == "AutoNewLevel" or SaveGameVersion == o.Version) then
				count = count + 1
			end
		end
	end

	return count
end
--============================================================================
function SaveGame:DeleteOldestSave(stype)
	if not stype then return nil end
	local dirs = FS.FindFiles("../SaveGames/*",0,1)

	local lastSlot = nil
	local lastTime = "9"
	for i=1,table.getn(dirs) do
		o = {}
		DoFile("../SaveGames/"..dirs[i].."/SaveGame.Info",false)
		if o.Type then
			if o.Type == stype and o.Timestamp and (o.Type == "AutoNewLevel" or SaveGameVersion == o.Version) then
				if o.Timestamp < lastTime then
					lastSlot = dirs[i]
					lastTime = o.Timestamp
				end
			end
		end
	end

	if lastSlot then
		self:Delete(lastSlot)
	end
end
--============================================================================
--[[
 + nie ladowac obiektow przez LoadObj tylko przez dofile
 + zaladowac templaty z zapisanego levelu
 + zrobic dopelnienie obiektow z BaseObj i Class funkcjami i tablicami statycznymi s_
 + zapisywac czy testuje death zony
 + zapisywac powiazania miedzy dziecmi i rodzicami
    (nr indeksu rodzica i inne dane)
 + zapisywac mesh visibility modeli - dla lepperow i broni
 + savowanie decali i traili
 + savowanie i restorowanie skompilowanych akcji
 + zaladowac pliki z kodem lua do istniejacych jeszcze obiektow z katalogu levelu
 + przywracanie environmentow
 + savowanie billboardow
 + savowanie szyb
 + savowanie dzwiekow
 + generowanie antyportali ze slabow
 + savewoanie stanow death zones
 + ustawianie mapentities
 + giby
 + savowanie particli i swiatel
 + zapis i odczyt game'a
 + proces trzesienia ziemi w gamie
 + kontrolowac jakos przypisanie funkcji do class ... zrobic jawny mechanizm do zamiany i nilowania funkcji
 + demon
 + zamrazanie
 + swamp
 + alastor
 + efekty atmosferyczne
 - tekstury
 - uodpornic save'a na ladowanie poprzednich wersji - szczegolnie entities - zrobic wersjonowanie lub zapis opisu pol
 - pakowanie savow zipem
--]]
--============================================================================
