o._shotNr = 0
o._fxMode = 1
--============================================================================
function RifleFlameThrower:OnReleaseEntity()
    self:OnChangeWeapon()
    if self._sndLoop then
        SOUND2D.Delete(self._sndLoop)
    end
    self._sndLoop = nil
    --self._fireFX:Delete()
end
--============================================================================
function RifleFlameThrower:OnCreateEntity(entity)
    self._sndLoop = SOUND2D.Create(self:GetSndInfo("flame_loop",true))
    self:ReloadTextures()
end
--============================================================================
function RifleFlameThrower:OnPrecache()
    CloneTemplate("RifleFlameThrower.CWeapon"):LoadHUDData()
	Cache:PrecacheParticleFX("RFT_smallflame")
	Cache:PrecacheParticleFX("RFT_flame")
    Cache:PrecacheParticleFX("RFT_flameWarp")
    Cache:PrecacheParticleFX("RifleHitWall")
	Cache:PrecacheItem("Kamyk.CItem")
    Cache:PrecacheDecal("bullethole")
    Cache:PrecacheItem("FlameThrowerGas.CItem")     
    Cache:PrecacheSounds("impacts/barrel-wood-fire-loop")
end
--============================================================================
function RifleFlameThrower:MuzzleFlashFX()
    -- protection for multiply lights simultaneously
    if not self._LightName or getfenv()[self._LightName] == nil then
        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
        local fv = self.ObjOwner.ForwardVector
        local a = AddAction({{"Light:a[1],a[2],a[3],200,200,150, 5, 8 , 1, 0,0.05,0.05"}},nil,nil,x+fv.X*1.5,y+1.5,z+fv.Z*1.5)
        self._LightName = a._Name
        self:MuzzleFlash("joint17",0,0,0,0.5,"particles/rm",FRand(0,6.28))
    end        
end
--============================================================================
function RifleFlameThrower:EnableFX(mode)
    if self._oldmode == mode then return end

    --ENTITY.Release(self._light)
    ENTITY.Release(self._fxStart)
    PARTICLE.Die(self._fxEnd)
    PARTICLE.Die(self._fxEnd2)
    self._fxStart = nil
    self._fxEnd = nil
    self._fxEnd2 = nil
    --self._light = nil

    if mode == 1 then -- normal
        self._fxStart = BindFX(self._Entity,"RFT_smallflame",0.08,"joint17",0,0,0)
        ENTITY.EnableGunPass(self._fxStart,true)
    end

    if mode == 2 then -- attack
        --self._light = CreateLight(0,0,0,255,255,255,2,5,1)
        local scale = 1
        if self.ObjOwner.HasWeaponModifier then scale = 1.25 end
        self._fxStart = BindFX(self._Entity,"RFT_smallflame",0.08*scale,"joint17",0,0,0)
        self._fxEnd = BindFX(self._Entity,"RFT_flame",0.25*scale,"joint17",0,0,0,nil,nil,nil,0,1.57,0)        
        self._fxEnd2 = BindFX(self._Entity,"RFT_flameWarp",0.25*scale,"joint17",0,0,0,nil,nil,nil,0,1.57,0)        
    end

    self._oldmode = mode
    self._fxMode = mode
end
--============================================================================
function RifleFlameThrower:OnChangeWeapon()
    SOUND2D.Stop(self._sndLoop)
    self:EnableFX(0)
    --ENTITY.EnableDraw(self._fireFX._Entity,false)    
    self._fxMode = 1
end
--============================================================================
function RifleFlameThrower:ReloadTextures()
	if not self._Entity then return end
    if Cfg.WeaponNormalMap == true then
        if Cfg.WeaponSpecular == false then
            MATERIAL.Replace("models/esl/esl_tex2pb","models/esl/esl_tex2pb_no_specular")
        else
            MATERIAL.Replace("models/esl/esl_tex2pb","models/esl/esl_tex2pb")
        end
    end
	MDL.EnableNormalMaps(self._Entity,Cfg.WeaponNormalMap)
end
--============================================================================
function RifleFlameThrower:LoadHUDData()
	self._matAmmoIcon = MATERIAL.Create("HUD/rifle", TextureFlags.NoLOD)
	self._matAmmoElectroIcon = MATERIAL.Create("HUD/ikona_flamer", TextureFlags.NoLOD)
end
--============================================================================
function RifleFlameThrower:DrawHUD(delta)
    local w,h = R3D.ScreenSize()
    local gray = R3D.RGB(120,120,70)
    local sizex, sizey = MATERIAL.Size(Hud._matHUDLeft)

    if not (INP.IsFireSwitched() or (not Game.SwitchFire[6] and Cfg.SwitchFire[6]) or (not Cfg.SwitchFire[6] and Game.SwitchFire[6])) then
		Hud:Quad(self._matAmmoIcon,(1024-56*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*12)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoElectroIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*47)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Rifle),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Rifle)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.FlameThrower),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.FlameThrower)
	else
		Hud:Quad(self._matAmmoElectroIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*13)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoIcon,(1024-56*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.FlameThrower),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.FlameThrower)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Rifle),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Rifle)
	end
end
--============================================================================
function RifleFlameThrower:Fire()
    local s = self:GetSubClass()
    if self.ObjOwner.Ammo.Rifle > 0 then
        self.StartFireFX(self.ObjOwner._Entity, self.ObjOwner.Ammo.Rifle)
    else    
        self.OutOfAmmoFX(self.ObjOwner._Entity,1)
        self.ShotTimeOut = s.FireTimeout * 5
        self._ActionState = "Idle"
        self._fire = false
    end
end
--============================================================================
function RifleFlameThrower:OnFinishFire(oldstate)
    self.OnReloadFX(self.ObjOwner.ClientID,self.ObjOwner._Entity, self.ObjOwner.Ammo.Rifle)
end
--============================================================================
function RifleFlameThrower:StartFireFX(pe,ammo)
    local player = EntityToObject[pe]
    local t = Templates["RifleFlameThrower.CWeapon"]
    local s = t:GetSubClass()

    if player then
        player.Ammo.Rifle = ammo
        local cw = player:GetCurWeapon()
        cw._ShotInterval = 0
        cw._ActionState = "Fire"
    end
    QuadSound(pe)
end
Network:RegisterMethod("RifleFlameThrower.StartFireFX", NCallOn.ServerAndAllClients, NMode.Reliable, "eu")
--============================================================================
--============================================================================
function RifleFlameThrower:OnReloadFX(pe,ammo)
    local t = Templates["RifleFlameThrower.CWeapon"]
    local s = t:GetSubClass()
    local player = EntityToObject[pe]    
    if player then
        player.Ammo.Rifle = ammo
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut = s.ReloadTimeout
        cw._ActionState = "Idle"
        cw._fire = false
        cw._shotNr = 0
        if player == Player then
            cw:SetAnim("shot4",false)            
        end
        --t:SndEnt("rifle_reload",pe)
    end
end
Network:RegisterMethod("RifleFlameThrower.OnReloadFX", NCallOn.ServerAndSingleClient, NMode.Reliable, "eu")
--============================================================================
-- ALT FIRE -
--============================================================================
function RifleFlameThrower:AltFire()

    if Game.GMode ~= GModes.SingleGame then 
        self._ActionState = "Idle"
        self._altfire = false
        return 
    end

    if self.ObjOwner.Ammo.FlameThrower > 0 then
        self.StartAltFireFX(self.ObjOwner._Entity, self.ObjOwner.Ammo.FlameThrower)
    else
        local s = self:GetSubClass()
        self.OutOfAmmoFX(self.ObjOwner._Entity,2)
        self.ShotTimeOut = s.AltFireTimeout * 4
        -- to jakos inaczej rozwiazac, zeby outofammo od razu ustawialo idle'a
        self._ActionState = "Idle"
        self._altfire = false
    end
end
--============================================================================
function RifleFlameThrower:OnFinishAltFire()
    self.FinishAltFireFX(self.ObjOwner.ClientID, self.ObjOwner._Entity,self.ObjOwner.Ammo.FlameThrower)
end
--============================================================================
function RifleFlameThrower:StartAltFireFX(pe,ammo)
    local player = EntityToObject[pe]
    local t = Templates["RifleFlameThrower.CWeapon"]
    local s = t:GetSubClass()

    if player then
        local cw = player:GetCurWeapon()
        cw._lastLockedEntity = nil
        cw._lockedEntity = nil
        local x,y,z = ENTITY.PO_GetPawnHeadPos(player._Entity)
        local fv = player.ForwardVector
        player.Ammo.FlameThrower = ammo
        cw._ShotInterval = 0
        cw.ShotTimeOut = s.AltFireTimeout

        if player == Player then
            SOUND2D.SetLoopCount(cw._sndLoop,0)
            SOUND2D.Play(cw._sndLoop)
             -- to musimy recznie ustawic na kliencie
            cw:SetAnim("flame")
            cw._ActionState = "AltFire"            
        end
    end
    QuadSound(pe)
    t:SndEnt("flame_start",pe)
end
Network:RegisterMethod("RifleFlameThrower.StartAltFireFX", NCallOn.ServerAndAllClients, NMode.Reliable, "eu")
--============================================================================
function RifleFlameThrower:FinishAltFireFX(pe,ammo)
    local player = EntityToObject[pe]
    if not player then return end

    player.Ammo.FlameThrower = ammo
    local cw = player:GetCurWeapon()
    cw._lockedEntity = nil
    cw._ActionState = "Idle"
    cw._altfire = false
    if player == Player then
        cw:EnableFX(1)
        cw:Snd2D("flame_stop",pe)
        SOUND2D.Stop(cw._sndLoop)
    end
end
Network:RegisterMethod("RifleFlameThrower.FinishAltFireFX", NCallOn.ServerAndSingleClient, NMode.Reliable, "eu")
RifleFlameThrower.time = 0
--============================================================================
function RifleFlameThrower:OnTick(delta)
    if self.ObjOwner ~= Player then return end
end
--============================================================================
function RifleFlameThrower:OnUpdate() -- COMMON: CLIENT & SERVER
    local s = Templates["RifleFlameThrower.CWeapon"]:GetSubClass()
    self.ObjOwner.State = 6    
        
    if self._ActionState == "Fire" then
        if self.ObjOwner.Ammo.Rifle > 0 then            
            self._ShotInterval = self._ShotInterval - 1
            if self._ShotInterval <= 0 then
                PlayLogicSound("FIRE",self.ObjOwner.Pos.X,self.ObjOwner.Pos.Y,self.ObjOwner.Pos.Z,12,26,self.ObjOwner)            
                self:FireSFX(self.ObjOwner._Entity)
                if Game.GMode ~= GModes.MultiplayerClient then
                    self:HitTest()            
                    self._shotNr = self._shotNr + 1
                    if self._shotNr >= s.RifleBurst then
                        if self.ObjOwner.HasWeaponModifier then
                            self._shotNr = 0
                        else
                            self.OnReloadFX(self.ObjOwner.ClientID,self.ObjOwner._Entity,self.ObjOwner.Ammo.Rifle)
                        end
                    end
                    if self.ObjOwner.Ammo.Rifle <= 0 then
                        self.OnReloadFX(self.ObjOwner.ClientID,self.ObjOwner._Entity,self.ObjOwner.Ammo.Rifle)
                    end
                end
            end
        end
                
        self.ObjOwner.State = 61
        return
    end

    if self._ActionState == "AltFire" and self.ObjOwner.Ammo.FlameThrower > 0 then
        self._ShotInterval = self._ShotInterval - 1
        if self._ShotInterval <= 0 then
            if not Game.NoAmmoLoss then self.ObjOwner.Ammo.FlameThrower = self.ObjOwner.Ammo.FlameThrower - 1 end
            self._ShotInterval = s.AltFireTimeout

            -- logika strzalu nie dziala na kliencie
            if Game.GMode ~= GModes.MultiplayerClient then
                -- ammo check
                if self.ObjOwner.Ammo.FlameThrower <= 0 then
                    self.ObjOwner.Ammo.FlameThrower = 0
                    self:OnFinishAltFire()
                else
                    self:FlameThrowerTest()
                end
            end
            --self:FlameThrowerSP()
        end
        self.ObjOwner.State = 62
    else
        self:EnableFX(1)
    end
end

--============================================================================
function RifleFlameThrower:FlameThrowerSP()
    
    local fv = self.ObjOwner.ForwardVector
    local cx,cy,cz = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
    
    for i = 1, 1 do
        local ke = AddItem("FlamePart.CItem",1,Vector:New(cx+fv.X*0.7,cy-0.1+fv.Y*0.7,cz+fv.Z*0.7),true)
        local mx = 1 --FRand(0.9,1.1)
        local mz = 1 --FRand(0.9,1.1)
        ENTITY.SetVelocity(ke,fv.X*125,fv.Y*125,fv.Z*125)
    end
end
--============================================================================
function RifleFlameThrower:FlameThrowerTest()
    local s = Templates["RifleFlameThrower.CWeapon"]:GetSubClass()
    -- havok's trace from player

    local fv = self.ObjOwner.ForwardVector
    local cx,cy,cz = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
    local rot = Quaternion:New_FromNormalZ(fv.X,fv.Y,fv.Z) 
    local b,d,tx,ty,tz,nx,ny,nz,he,e
    local scale = 1
    if self.ObjOwner.HasWeaponModifier then scale = 1.25 end
    for i,o in s.FlameRangePoints do
        local sx,sy,sz = rot:TransformVector(o[1]*scale,o[2]*scale,o[3]*scale)
        b,d,tx,ty,tz,nx,ny,nz,he,e = self.ObjOwner:TraceToPoint(cx+sx,cy+sy,cz+sz)
        if b then break end
    end
    if b and e then
        local damage = s.FlameDamage        
        local obj = EntityToObject[e] -- LUA gameobject
        if obj then
            if obj.OnDamage then obj:OnDamage(damage,self.ObjOwner,AttackTypes.FlameThrower,x,y,z,nx,ny,nz,he) end
            BurnObject(obj)        
        else
            for i=1, 1 do
                local ob = GObjects:Add(TempObjName(),CloneTemplate("FlameThrowerGas.CItem"))
                ob.Pos.X = tx - fv.X
                ob.Pos.Y = ty - fv.Y
                ob.Pos.Z = tz - fv.Z
                ob.sound = "impacts/barrel-wood-fire-loop"
                ob.TimeToLive = FRand(ob.TimeToLive * 0.8, ob.TimeToLive * 1.2)			
                ob:Apply()
                ob:Synchronize()
                ENTITY.SetVelocity(ob._Entity, fv.X*10, fv.Y*10, fv.Z*10)
            end
        end
    end
end
--============================================================================
function RifleFlameThrower:HitTest()
    local s = Templates["RifleFlameThrower.CWeapon"]:GetSubClass()
    -- havok's trace from player
    local b,d,x,y,z,nx,ny,nz,he,e = self.ObjOwner:Trace(s.RifleRange)
    if b and e then
        local fv = self.ObjOwner.ForwardVector
        if Game.GMode == GModes.SingleGame and ENTITY.IsWater(e) then
            Templates["MiniGunRL.CWeapon"]:HitWaterSFX(x,y,z,nx,ny,nz,fv.X,fv.Y,fv.Z,e)
        else
            local damage = s.RifleDamage
            if self.ObjOwner.HasWeaponModifier then
                damage = math.floor(damage * 1.5)
            end
            if self.ObjOwner.HasQuad then            
                damage = math.floor(damage * 4)
            end
            local obj = EntityToObject[e] -- LUA gameobject
            if obj and damage > 0 and obj.OnDamage then
                obj:OnDamage(damage,self.ObjOwner,AttackTypes.Rifle,x,y,z,nx,ny,nz,he)
            end
    
            if obj and (obj._Class == "CActor" or obj._Class == "CPlayer" )then
                local ib =  s.EnemyThrowBack
                local iu =  s.EnemyThrowUp
                if self.ObjOwner.HasWeaponModifier then
                    ib = ib * 1.5
                end
                -- hit spherical body
                if (not obj.NeverMove and not obj._disableHits) or obj.Health <= damage then
                    ENTITY.PO_Hit(e,x,y,z,fv.X*ib,fv.Y*ib+iu,fv.Z*ib)
                end
                -- hit ragdoll body
                WORLD.HitPhysicObject(he,x,y,z,fv.X*150,fv.Y*150,fv.Z*150)
                if not CanBurning(obj) then 
                    self:HitWallSFX(e,x,y,z,nx,ny,nz)
                end
            else
                -- hit havok body
                WORLD.HitPhysicObject(he,x,y,z,fv.X*150,fv.Y*150,fv.Z*150)
                if Game.GMode == GModes.SingleGame then
                    self:HitWallSFX(e,x,y,z,nx,ny,nz)
                end
            end
            CheckStartGlass(he,x,y,z,0.1,fv.X*50,fv.Y*50,fv.Z*50)
        end
        PlayLogicSound("RICOCHET",x,y,z,8,16,nil)
    end
end
--============================================================================
function RifleFlameThrower:HitWallSFX(entity,x,y,z,nx,ny,nz)

    local t = Templates["RifleFlameThrower.CWeapon"]

    if entity then ENTITY.SpawnDecal(entity,'bullethole',x,y,z,nx,ny,nz) end
    -- launch sparks and decals
    local r = Quaternion:New(1,0,0,0)
    local ay = math.atan2(nx,-nz) + 1.57
    r:FromEuler(0,ay,-1.57 + ny*1.57)    
	AddPFX("RifleHitWall",0.2,Vector:New(x,y,z),r)    
    if nx>=ny and nx>=nz then nx=nx+0.5; ny=ny+0.5*math.random(-1,1); nz=nz+0.5*math.random(-1,1) end
    if ny>=nx and ny>=nz then ny=ny+0.5; nx=nx+0.5*math.random(-1,1); nz=nz+0.5*math.random(-1,1) end
    if nz>=nx and nz>=ny then nz=nz+0.5; nx=nx+0.5*math.random(-1,1); ny=ny+0.5*math.random(-1,1) end
    local n = math.random(1,1)
    for i = 1, n do
        local sizes = {0.3,0.5,0.8}
        local ke = AddItem("Kamyk.CItem",sizes[math.random(1,3)],Vector:New(x+FRand(-0.2,0.2),y+FRand(-0.2,0.2),z+FRand(-0.2,0.2)))
        local vx = nx*FRand(10,15)
        local vy = ny*FRand(10,15)
        local vz = nz*FRand(10,15)
        ENTITY.SetVelocity(ke,vx,vy,vz)
        ENTITY.SetTimeToDie(ke,FRand(1,2))
    end
    
    local obj = EntityToObject[entity]
    if obj and obj.s_SubClass and obj.s_SubClass.SoundsDefinitions and obj.s_SubClass.SoundsDefinitions.SoundHitByBullet and math.random(100) < 50 then
        obj:PlaySound("SoundHitByBullet",nil,nil,nil,nil,tx,ty,tz)
    else
        if math.random(100) < 50 then  t:Snd3D("bullet_hit_wall",x,y,z) end
    end

end
--============================================================================
-- NET EVENTS
--============================================================================
--============================================================================
-- COMMON: CLIENT & SERVER
function RifleFlameThrower:FireSFX(pe)
    local player = EntityToObject[pe]

    local t = Templates["RifleFlameThrower.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)

    -- update ammo on proper client and server
    if player then
        if not Game.NoAmmoLoss then player.Ammo.Rifle = player.Ammo.Rifle - 1 end
        if player.Ammo.Rifle < 0 then player.Ammo.Rifle = 0 end        
        local cw = player:GetCurWeapon()
        cw._ShotInterval = s.FireTimeout        
        if player == Player then
            cw:SetAnim("shot1",true)            
            cw:MuzzleFlashFX()
            Game._EarthQuakeProc:Add(x,y,z, 2, 4, 0.1, 0.1, false)
        end
    end

    t:SndEnt("rifle_shot",pe)
    t:SndEnt("rifle_shell",pe)
end
--============================================================================
function RifleFlameThrower:OutOfAmmoFX(entity,fire)
    Templates["RifleFlameThrower.CWeapon"]:SndEnt("out_of_ammo",entity)
end
Network:RegisterMethod("RifleFlameThrower.OutOfAmmoFX", NCallOn.AllClients, NMode.Reliable, "eb")
--============================================================================
function RifleFlameThrower:Render(delta)

    if Player ~= self.ObjOwner then return end
    if Game.TPP then return end

    if not (self._ActionState == "AltFire" and self.ObjOwner.Ammo.FlameThrower > 0) then
        return
    end

    self:EnableFX(2)
end
--============================================================================
function RifleFlameThrower:ClientTick(delta)
    if self._fxMode == 1 then
        --ENTITY.EnableDraw(self._fireFX._Entity,false)
    else
        --ENTITY.EnableDraw(self._fireFX._Entity,false) -- aby widziec efekt to trzeba zakomentowac
        --ENTITY.EnableDraw(self._fireFX._Entity,true)  -- a to odkomentowac
    end
end
--============================================================================
function RifleFlameThrower:ComboCheck()

    if self._ActionState ~= "AltFire" or Game.GMode ~= GModes.SingleGame then return end

    local s = self:GetSubClass()
    if ENTITY.PO_IsActionState(self.ObjOwner._Entity,Actions.Fire) then
        local s = self:GetSubClass()
        self:OnFinishAltFire()
        if self.ObjOwner.Ammo.FlameThrower < 50 then
            self.OutOfAmmoFX(self.ObjOwner._Entity,2)
            return
        end

        -- create grenade object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("RFTGasContainer.CItem"))
        obj.ObjOwner = self.ObjOwner

        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
        local fv = self.ObjOwner.ForwardVector
        y = y - 0.2

        local b = self.ObjOwner:Trace(1.3)
        if not b then
            x,y,z = x + fv.X*1.3, y + fv.Y*1.3, z + fv.Z*1.3
        end

        obj.Pos:Set(x,y,z)
        local orientation = ENTITY.GetOrientation(self.ObjOwner._Entity)
        obj.Rot:FromEulerZYX(-fv.Y,-orientation+1.57,0)
        obj:Apply()
        BurnObject(obj)

        ENTITY.SetVelocity(obj._Entity, fv.X*20, fv.Y*20+5, fv.Z*20)
        local ax,ay,az = obj.Rot:TransformVector(0,0,FRand(-20,-10))
        ENTITY.SetAngularVelocity(obj._Entity,ax,ay,az)

        -- launch SpecialFX on all clients
        self.ComboFX(self.ObjOwner._Entity)
        PlayLogicSound("FIRE",x,y,z,26,52,player)
    end
end
--============================================================================
function RifleFlameThrower:ComboFX(pe)
    local player = EntityToObject[pe]
    local t = Templates["DriverElectro.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)

    -- update ammo on proper client and server
    if player then
        if not Game.NoAmmoLoss then player.Ammo.FlameThrower = player.Ammo.FlameThrower - 50 end
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut   =  s.AltFireTimeout * 15
        cw._ActionState = "Idle"
        -- launch weapon's particle and sounds
        if player == Player then
            cw:ForceAnim("DISCshot",false)
        end
    end
    t:SndEnt("electrodisk_shot",pe)
    QuadSound(pe)
end
Network:RegisterMethod("RifleFlameThrower.ComboFX", NCallOn.ServerAndAllClients, NMode.Reliable, "e")
--============================================================================
