o._stakeTime = 0
o._stakeTime = 0
o._zoom = 0
o._curFOV = Cfg.FOV
o._destFOV = Cfg.FOV
o._zoomdelay = 0
--============================================================================
function BoltGunHeater:OnCreateEntity()
	self:ReloadTextures()
    self._sndZoom = SOUND2D.Create(self:GetSndInfo("zoom_loop",true),false,true)
end
--============================================================================
function BoltGunHeater:OnPrecache()
    CloneTemplate("BoltGunHeater.CWeapon"):LoadHUDData()
	Cache:PrecacheItem("BoltStick.CItem")     
	Cache:PrecacheItem("HeaterBomb.CItem")             
    Cache:PrecacheTrail("trail_kolek")        
    Cache:PrecacheTrail("trail_kolek_combo")        
end
--============================================================================
function BoltGunHeater:OnChangeWeapon()
    self._stakeTime = 0 
    self._zoom = 0
    self._curFOV = Cfg.FOV
    self._destFOV = Cfg.FOV
    Hud.NoCrosshair = nil
    R3D.SetCameraFOV(Cfg.FOV)
    MOUSE.SetSensitivity(Cfg.MouseSensitivity)
    SOUND2D.Stop(self._sndZoom)
    WORLD.UseSwitchZones(true)
end
--============================================================================
function BoltGunHeater:OnReleaseEntity()
    if self._sndZoom then
        SOUND2D.Delete(self._sndZoom)
    end
    WORLD.UseSwitchZones(true)
end
--============================================================================
function BoltGunHeater:ReloadTextures()
	if not self._Entity then return end
    if Cfg.WeaponNormalMap == true then    
        if Cfg.WeaponSpecular == false then
            MATERIAL.Replace("models/kgr/kgr_pb","models/kgr/kgr_pb_no_specular")
        else
            MATERIAL.Replace("models/kgr/kgr_pb","models/kgr/kgr_pb")
        end
    end
	MDL.EnableNormalMaps(self._Entity,Cfg.WeaponNormalMap)
end
--============================================================================
function BoltGunHeater:LoadHUDData()
	self._matAmmoIcon1 = MATERIAL.Create("HUD/bolty", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matAmmoIcon2 = MATERIAL.Create("HUD/kulki", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matZoom = MATERIAL.Create("HUD/zoom", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
end
--============================================================================
function BoltGunHeater:DrawHUD(delta)
    local w,h = R3D.ScreenSize()
    local gray = R3D.RGB(120,120,70)
    local sizex, sizey = MATERIAL.Size(Hud._matHUDLeft)
    
    Hud.NoCrosshair = nil
    if self._zoom > 0 then
        HUD.DrawQuad(self._matZoom,0,0,w,h)
        Hud.NoCrosshair = true        
    end
    
    if not (INP.IsFireSwitched() or (not Game.SwitchFire[7] and Cfg.SwitchFire[7]) or (not Cfg.SwitchFire[7] and Game.SwitchFire[7])) then
		Hud:Quad(self._matAmmoIcon1,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*11)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoIcon2,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Bolt),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Bolt)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.HeaterBomb),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.HeaterBomb)
	else
		Hud:Quad(self._matAmmoIcon2,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*11)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoIcon1,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.HeaterBomb),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.HeaterBomb)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Bolt),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Bolt)
	end    
end
--============================================================================
function BoltGunHeater:StickShot(nr,player,ox,oy,oz)
    local s = self:GetSubClass()
    -- create rocket object
    local obj = GObjects:Add(TempObjName(),CloneTemplate("BoltStick.CItem"))        
    local x,y,z = ENTITY.PO_GetPawnHeadPos(player._Entity)                
    local fv = player.ForwardVector
    --y = y - 0.05
    
    local orientation = ENTITY.GetOrientation(player._Entity)
    
    local tv = Vector:New(ox,oy,oz)
    tv:Rotate(-math.atan(fv.Y),orientation,0)    
    obj.Pos:Set(x+fv.X*0.4+tv.X,y+fv.Y*0.4+tv.Y,z+fv.Z*0.4+tv.Z)
    obj.Rot:FromNormalZ(fv.X,fv.Y,fv.Z)         
    
    obj._lastTraceStartPoint =  obj.Pos:Copy()
    obj.ObjOwner = player
    obj:Apply()
    obj.Damage = s.BoltStickDamage
    if player.HasQuad then            
        obj.Damage = math.floor(obj.Damage * 4)
    end
    obj.EnemyThrowBack = s.BoltStickEnemyThrowBack
    obj.EnemyThrowUp   = s.BoltStickEnemyThrowUp

    local speed = s.BoltStickSpeed
    if player.HasWeaponModifier then 
        speed = speed * 1.2 
        obj.Damage = obj.Damage * 1.5
    end
    
    ENTITY.SetVelocity(obj._Entity,fv.X*speed,fv.Y*speed,fv.Z*speed)
    ENTITY.PO_EnableGravity(obj._Entity,false)
    
    MDL.SetMeshVisibility(self._Entity,"stickShape"..nr,false)
end
--============================================================================
function BoltGunHeater:Fire(prevstate,combo) -- Stake
    if not combo then combo = 0 end
    local s = self:GetSubClass()
    if self.ObjOwner.Ammo.Bolt > 0 then                
        local action = {
            
            {"L:p:StickShot(1,p.ObjOwner,0,0,0)"},
            {"Wait:0.1"},
            {"L:p:StickShot(2,p.ObjOwner,-0.25,-0.12,0)"},
            {"L:p:StickShot(4,p.ObjOwner,0.25,-0.12,0)"},
            {"Wait:0.1"},
            {"L:p:StickShot(3,p.ObjOwner,-0.5,-0.24,0)"},
            {"L:p:StickShot(5,p.ObjOwner,0.5,-0.24,0)"},
            
        }
        AddAction(action,self)
        self.FireSFX(self.ObjOwner._Entity)
    else
        self.OutOfAmmoFX(self.ObjOwner._Entity,1)
        self.ShotTimeOut = s.AltFireTimeout
    end

    PlayLogicSound("FIRE",PX,PY,PZ,12,24,Player)   
end
--============================================================================
function BoltGunHeater:OnFinishFire(oldstate)
end
--============================================================================
function BoltGunHeater:BombShot(nr,player,ox,oy,oz)
    -- create grenade object
    local obj = GObjects:Add(TempObjName(),CloneTemplate("HeaterBomb.CItem"))
    obj.ObjOwner = player		
    
    local s = self:GetSubClass()
   
    local x,y,z = ENTITY.PO_GetPawnHeadPos(player._Entity)                
    y = y --.5
    local fv = Clone(player.ForwardVector)
        
    local orientation = ENTITY.GetOrientation(player._Entity)   
    
    --Game:Print(math.atan(fv.Y))
    local tv = Vector:New(ox,oy,oz)
    local forward = math.sqrt(fv.X*fv.X + fv.Z*fv.Z)
    tv:Rotate(-math.atan2(fv.Y,forward),orientation,0)
    obj.Pos:Set(x+tv.X+fv.X*0.3+FRand(-0.2,0.2),y+tv.Y+fv.Y*0.3+FRand(-0.1,0.1),z+tv.Z+fv.Z*0.3+FRand(-0.2,0.2))
    
    obj.Rot:FromNormalY(fv.X,fv.Y,fv.Z)     
    obj:Apply()
    obj.ExplosionStrength = s.HeaterBombExplosionStrength
    obj.ExplosionRange    = s.HeaterBombExplosionRange        
    obj.Damage            = s.HeaterBombDamage        
    if player.HasQuad then            
        obj.Damage = math.floor(obj.Damage * 4)
    end
    
    local gvf = s.HeaterBombSpeed
    local tv = Vector:New(0,0,1)
    tv:Rotate(0,(nr-5.5)*0.02,0)
    tv:Rotate(-math.atan2(fv.Y,forward),orientation,0)    
    tv:Normalize()
    
    MDL.SetMeshVisibility(self._Entity,"ballShape"..nr,false)
    ENTITY.SetVelocity(obj._Entity,tv.X*gvf+FRand(-2,2), tv.Y*gvf+FRand(-1,1), tv.Z*gvf+FRand(-2,2))       
end
--============================================================================
-- ALT FIRE - GRENADE (Server Side)
--============================================================================
function BoltGunHeater:AltFire() -- bomb
    
    --if Game.GMode ~= GModes.SingleGame then 
    --    self._ActionState = "Idle"
    --    self._altfire = false
    --    return 
    --end
    
    local s = self:GetSubClass()
    if self.ObjOwner.Ammo.HeaterBomb > 0  then       
        if Player then Player.ExplosiveFired = true end       
        if Game.GMode == GModes.SingleGame then 
            self:BombShot(1,self.ObjOwner,-0.5/2,0,0)       
            self:BombShot(2,self.ObjOwner,-0.4/2,0,0)       
            self:BombShot(3,self.ObjOwner,-0.3/2,0,0)       
            self:BombShot(4,self.ObjOwner,-0.2/2,0,0)       
            self:BombShot(5,self.ObjOwner,-0.1/2,0,0)       
            
            self:BombShot(6,self.ObjOwner,0.1/2,0,0)       
            self:BombShot(7,self.ObjOwner,0.2/2,0,0)       
            self:BombShot(8,self.ObjOwner,0.3/2,0,0)       
            self:BombShot(9,self.ObjOwner,0.4/2,0,0)       
            self:BombShot(10,self.ObjOwner,0.5/2,0,0)       
        else
            self:BombShot(1,self.ObjOwner,-0.5/2,0,0)       
            self:BombShot(2,self.ObjOwner,-0.3/2,0,0)                   
            self:BombShot(3,self.ObjOwner,0.3/2,0,0)       
            self:BombShot(4,self.ObjOwner,0.5/2,0,0)       
        end
        -- launch SpecialFX on all clients
        self.AltFireSFX(self.ObjOwner._Entity)
    else
        self.OutOfAmmoFX(self.ObjOwner._Entity,2)
        self.ShotTimeOut = s.AltFireTimeout
    end

    PlayLogicSound("FIRE",PX,PY,PZ,26,52,Player)
end
--============================================================================
function BoltGunHeater:OnTick(delta)
    if self._stakeTime > 0 then 
        self._stakeTime = self._stakeTime - delta         
    else
        if self._stakeTime < 0 then
            self._stakeTime = 0
        end
        if self.ObjOwner.Ammo.Bolt > 0  then                     
            for i=1,5 do 
                MDL.SetMeshVisibility(self._Entity,"stickShape"..i,true)
            end
        end
        if self.ObjOwner.Ammo.HeaterBomb > 0  then                     
            for i=1,10 do 
                MDL.SetMeshVisibility(self._Entity,"ballShape"..i,true)
            end
        end
    end
    
    if self._zoomdelay and self._zoomdelay > 0 then
        self._zoomdelay = self._zoomdelay - delta
    end
    
    if INP.UIAction(UIActions.Zoom) and self._zoomdelay <= 0 then
        self._zoomdelay = 0.3
        self._zoom = self._zoom + 1
        if self._zoom > 1 then self._zoom = 0 end
        if self._zoom == 1 then
            self:SndEnt("zoom_in",self.ObjOwner._Entity)
            self._destFOV = 50
            if Cfg.ZoomFOV then
                self._destFOV =Cfg.ZoomFOV
            end            
            SOUND2D.Play(self._sndZoom)            
            SOUND2D.SetLoopCount(self._sndZoom,0)
        end
               
        if self._zoom == 0 then
            Cfg.ZoomFOV = self._destFOV
            self._destFOV = Cfg.FOV
            --R3D.SetCameraFOV(Cfg.FOV)
            MOUSE.SetSensitivity(Cfg.MouseSensitivity)            
            --SOUND2D.SetLoopCount(self._sndZoom,10)
        end        
    end
    
    if self._zoom == 1 then
        if INP.Key(Keys.MouseWheelBack) == 1 or INP.Action(Actions.PrevWeapon) then
            self._destFOV = self._destFOV + 7
            if self._destFOV > 50 then self._destFOV = 50 end
            --Game:Print("back")
        end  
    
        if INP.Key(Keys.MouseWheelForward) == 1 or INP.Action(Actions.NextWeapon) then
            self._destFOV = self._destFOV - 7
            if self._destFOV < 3 then self._destFOV = 3 end
            --Game:Print("forward")
        end  
    end

    MOUSE.SetSensitivity(Cfg.MouseSensitivity * (self._destFOV/Cfg.FOV))
    --Game:Print(Cfg.MouseSensitivity * (Cfg.FOV/self._destFOV))
    self._curFOV = self._curFOV + (self._destFOV - self._curFOV) * delta * 12        
    R3D.SetCameraFOV(self._curFOV)
    
    if self._curFOV < 50 then
        WORLD.UseSwitchZones(false)
    else
        WORLD.UseSwitchZones(true)
    end
    
    local vol = math.abs(self._destFOV - self._curFOV) * 100
    SOUND2D.SetVolume(self._sndZoom,vol)
    --if math.abs(self._destFOV - self._curFOV) < 0.5 then
    --    SOUND2D.SetVolume(self._sndZoom,0)
    --else
    --    SOUND2D.SetVolume(self._sndZoom,100)
    --end
    
    --Game:Print(vol)
end
--============================================================================
function BoltGunHeater:OnFinishAnim(anim)
    if anim == "stickshot" then
        self:SetAnim("stick_reload",false) 
        self:SndEnt("bolt_reload",self.ObjOwner._Entity)
    end
end
--============================================================================
-- NET EVENTS
--============================================================================
function BoltGunHeater:FireSFX(pe)
    local player = EntityToObject[pe]   
    
    local t = Templates["BoltGunHeater.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)
    
    if player and player._Class ~= "CPlayer" then MsgBox("Bad player object: "..player._Class) end

    -- update ammo on proper client and server
    if player then
        if not Game.NoAmmoLoss then player.Ammo.Bolt = player.Ammo.Bolt - 5 end
        if player.Ammo.Bolt < 0 then player.Ammo.Bolt = 0 end
        -- set next shot timeout
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut =  s.FireTimeout
        cw._ActionState = "Idle"
        cw:ForceAnim("stickshot",false)                           
        cw._stakeTime = 1.1         
        
        local action = {            
            {"L:p:SndEnt('bolt_shot',"..pe..")"},
            {"Wait:0.1"},
            {"L:p:SndEnt('bolt_shot',"..pe..")"},
            {"Wait:0.1"},
            {"L:p:SndEnt('bolt_shot',"..pe..")"},
            
        }
        AddAction(action,t)
    end

    QuadSound(pe)                
end
Network:RegisterMethod("BoltGunHeater.FireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "e") 
-- potwierdzony poniewaz i tak doklei sie do komunikatu stworzenia nowego entity kolka
--============================================================================
function BoltGunHeater:AltFireSFX(pe)
    local player = EntityToObject[pe]

    local t = Templates["BoltGunHeater.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)
    
    -- update ammo on proper client and server
    if player then 
        if not Game.NoAmmoLoss then player.Ammo.HeaterBomb = player.Ammo.HeaterBomb -10 end
        -- set next shot timeout
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut   =  s.AltFireTimeout
        cw._ActionState = "Idle" -- bo korzystamy z timeout'a        
        Game._EarthQuakeProc:Add(x,y,z, 2, 4, s.ShotCamMove, s.ShotCamRotate, false)        
        if player == Player then
            cw:ForceAnim("ballshot",false)                
        end        
        cw._stakeTime = 0.4
    end
          
    t:SndEnt("heater_shot",pe)
    QuadSound(pe)           
end
Network:RegisterMethod("BoltGunHeater.AltFireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "e") 
--============================================================================
function BoltGunHeater:OutOfAmmoFX(entity,fire)
    Templates["BoltGunHeater.CWeapon"]:SndEnt("out_of_ammo",entity)
end
Network:RegisterMethod("BoltGunHeater.OutOfAmmoFX", NCallOn.AllClients, NMode.Reliable, "eb") 
--============================================================================
