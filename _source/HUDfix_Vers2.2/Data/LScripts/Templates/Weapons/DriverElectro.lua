o._showDiskTime = -1
o.TipPoint = Vector:New(0,0,0)
o._wallFryTimeOut = 0.03
--o._particles = {}
--============================================================================
function DriverElectro:OnReleaseEntity()
    self:OnChangeWeapon()
    if self._sndLoop then
        SOUND2D.Delete(self._sndLoop)
        SOUND2D.Delete(self._sndLock)
        SOUND2D.Delete(self._sndFry)
        SOUND2D.Delete(self._sndGeoFry)
    end
    self._sndLoop = nil
    self._sndLock = nil
    self._sndFry = nil
    self._sndGeoFry = nil
end
--============================================================================
function DriverElectro:OnCreateEntity(entity)
    self._sndLoop = SOUND2D.Create(self:GetSndInfo("electro_loop",true))
    self._sndLock = SOUND2D.Create(self:GetSndInfo("electro_lock",true))
    self._sndFry  = SOUND2D.Create(self:GetSndInfo("electro_monsters_fry",true))
    self._sndGeoFry  = SOUND2D.Create(self:GetSndInfo("electro_geometry_fry",true))
    self:ReloadTextures()
end
--============================================================================
function DriverElectro:OnPrecache()
    CloneTemplate("DriverElectro.CWeapon"):LoadHUDData()
	Cache:PrecacheParticleFX("electro_end")
	Cache:PrecacheParticleFX("electro_start1")
	Cache:PrecacheParticleFX("electro_start2")
	Cache:PrecacheParticleFX("electro_hit_wall")
	Cache:PrecacheParticleFX("electro_hit")
	Cache:PrecacheItem("ShurikenW.CItem")
    Cache:PrecacheItem("ElectroDisk.CItem")
    Cache:PrecacheDecal("electro")
    MATERIAL.Create("particles/spaw")
end
--============================================================================
function DriverElectro:EnableFX(mode)
    if self._oldmode == mode then return end
    --Game:Print(mode)

    ENTITY.Release(self._light)
    ENTITY.Release(self._fxStart)
    ENTITY.Release(self._fxEnd)
    self._fxStart = nil
    self._fxEnd = nil
    self._light = nil

    --for i,o in self._particles do
    --    ENTITY.Release(o)
    --end
    --self._particles = {}

    if mode == 1 then -- normal
        self._fxStart = BindFX(self._Entity,"electro_start1",0.04,"joint2",0.18,0.075,0.065)
    end

    if mode == 2 then -- attack
        self._light = CreateLight(0,0,0,255,255,255,2,5,1)
        self._fxStart = BindFX(self._Entity,"electro_start2",0.04,"joint2",0.18,0.075,0.065)
        self._fxEnd = AddPFX("electro_end",0.8)
        --for i=1, 15 do
        --    self._particles[i] = AddPFX("electro",0.04)
        --end
    end

    if mode == 3 then -- wall
        self._light = CreateLight(0,0,0,255,255,255,2,5,1)
        self._fxStart = BindFX(self._Entity,"electro_start2",0.04,"joint2",0.18,0.075,0.065)
        -- self._fxEnd = AddPFX("electro_hit_wall",0.8)
    end

    ENTITY.SetPosition(self._fxEnd,self.TipPoint.X,self.TipPoint.Y,self.TipPoint.Z)
    ENTITY.SetPosition(self._light,self.TipPoint.X,self.TipPoint.Y+0.5,self.TipPoint.Z)

    self._oldmode = mode
end
--============================================================================
function DriverElectro:OnChangeWeapon()
    self._lockedEntity = nil
    self._nearObj = nil
    SOUND2D.Stop(self._sndLoop)
    SOUND2D.Stop(self._sndLock)
    SOUND2D.Stop(self._sndFry)
    SOUND2D.Stop(self._sndGeoFry)
    self:EnableFX(0)
end
--============================================================================
function DriverElectro:ReloadTextures()
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
function DriverElectro:LoadHUDData()
	self._matAmmoIcon = MATERIAL.Create("HUD/ikona_szuriken", TextureFlags.NoLOD)
	self._matAmmoElectroIcon = MATERIAL.Create("HUD/ikona_electro", TextureFlags.NoLOD)
end
--============================================================================
function DriverElectro:DrawHUD(delta)
    local w,h = R3D.ScreenSize()
    local gray = R3D.RGB(120,120,70)
    local sizex, sizey = MATERIAL.Size(Hud._matHUDLeft)

    if not (INP.IsFireSwitched() or (not Game.SwitchFire[5] and Cfg.SwitchFire[5]) or (not Cfg.SwitchFire[5] and Game.SwitchFire[5])) then
		Hud:Quad(self._matAmmoIcon,(1024-56*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*11)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoElectroIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*42)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Shurikens),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Shurikens)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Electro),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Electro)
	else
		Hud:Quad(self._matAmmoElectroIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*10)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoIcon,(1024-56*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*47)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Electro),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Electro)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Shurikens),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Shurikens)
	end
end
--============================================================================
function DriverElectro:Fire()
    local s = self:GetSubClass()
    if self.ObjOwner.Ammo.Shurikens > 0 then

        -- create rocket object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("ShurikenW.CItem"))
        -- set position
        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
        local fv = self.ObjOwner.ForwardVector
        y = y - 0.2

        local b = self.ObjOwner:Trace(1)
        if not b then
            x,y,z = x + fv.X*1, y + fv.Y*1, z + fv.Z*1
        end

        obj.Pos:Set(x,y,z)
        local orientation = ENTITY.GetOrientation(self.ObjOwner._Entity)
        obj.Rot:FromEulerZYX(-fv.Y,-orientation+1.57,0)
        obj:Apply()
        obj.ObjOwner = self.ObjOwner

        ENTITY.SetVelocity(obj._Entity,fv.X*s.ShurikenSpeed,fv.Y*s.ShurikenSpeed,fv.Z*s.ShurikenSpeed)
        local ax,ay,az = obj.Rot:TransformVector(0,120,0)
        ENTITY.SetAngularVelocity(obj._Entity,ax,ay,az)
        ENTITY.PO_EnableGravity(obj._Entity,false)
        obj.ExplosionStrength = s.ShurikenExplosionStrength
        obj.ExplosionRange    = s.ShurikenExplosionRange
        obj.ExplosionDamage   = s.ShurikenExplosionDamage
        if self.ObjOwner.HasQuad then            
            obj.ExplosionDamage = math.floor(obj.ExplosionDamage * 4)
        end

        obj._ExplodeTimer   = s.ShurikenExplodeAfterTime
        obj.Damage            = s.ShurikenDamage
        if self.ObjOwner.HasQuad then            
            obj.Damage = math.floor(obj.Damage * 4)
        end



        PlayLogicSound("FIRE",self.ObjOwner.Pos.X,self.ObjOwner.Pos.Y,self.ObjOwner.Pos.Z,12,26,self.ObjOwner)
        self.FireSFX(self.ObjOwner._Entity,obj._Entity)
    else
        self.OutOfAmmoFX(self.ObjOwner._Entity,1)
        self.ShotTimeOut = s.FireTimeout
    end
end
--============================================================================
function DriverElectro:OnFinishFire(oldstate)
end
--============================================================================
-- ALT FIRE -
--============================================================================
function DriverElectro:AltFire()

    if self.ObjOwner.Ammo.Electro > 0 then
        self.StartAltFireFX(self.ObjOwner._Entity, self.ObjOwner.Ammo.Electro)
    else
        local s = self:GetSubClass()
        self.OutOfAmmoFX(self.ObjOwner._Entity,2)
        self.ShotTimeOut = s.AltFireTimeout * 10
        -- to jakos inaczej rozwiazac, zeby outofammo od razu ustawialo idle'a
        self._ActionState = "Idle"
        self._altfire = false
    end
end
--============================================================================
function DriverElectro:ComboCheck()

    if self._ActionState ~= "AltFire" or Game.GMode ~= GModes.SingleGame then return end

    local s = self:GetSubClass()
    if ENTITY.PO_IsActionState(self.ObjOwner._Entity,Actions.Fire) then
        local s = self:GetSubClass()
        self:OnFinishAltFire()
        if self.ObjOwner.Ammo.Electro < s.ElectroDiskCost or (MPCfg.GameMode == "Voosh" and ENTITY.Exist(self._lastEDisk)) then
            self.OutOfAmmoFX(self.ObjOwner._Entity,2)
            return
        end

        -- create grenade object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("ElectroDisk.CItem"))
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
        obj.ExplosionStrength         = s.ElectroDiskExplosionStrength
        obj.ExplosionRange            = s.ElectroDiskExplosionRange
        obj.ExplosionDamage           = s.ElectroDiskExplosionDamage
        if self.ObjOwner.HasQuad then            
            obj.ExplosionDamage = math.floor(obj.ExplosionDamage * 4)
        end
        obj.Damage                    = s.ElectroDiskDamage
        if self.ObjOwner.HasQuad then            
            obj.Damage = math.floor(obj.Damage * 4)
        end
        obj.Timeout                   = s.ElectroDiskLifeTime * 30
        obj.ElectroDiskPinnedLifeTime = s.ElectroDiskPinnedLifeTime

        self._lastEDisk = obj._Entity

        ENTITY.SetVelocity(obj._Entity, fv.X*100, fv.Y*100, fv.Z*100)
        -- local ax,ay,az = obj.Rot:TransformVector(0,40,0)
        -- ENTITY.SetAngularVelocity(obj._Entity,ax,ay,az)

        -- launch SpecialFX on all clients
        self.ComboFX(self.ObjOwner._Entity)
        PlayLogicSound("FIRE",x,y,z,26,52,player)
    end
end
--============================================================================
function DriverElectro:OnFinishAltFire()
    Game:Print("OnFinishFire")
    self.FinishAltFireFX(self.ObjOwner.ClientID, self.ObjOwner._Entity,self.ObjOwner.Ammo.Electro)
end
--============================================================================
function DriverElectro:StartAltFireFX(pe,ammo)
    Game:Print("StartAltFireFX")
    local player = EntityToObject[pe]
    local t = Templates["DriverElectro.CWeapon"]
    local s = t:GetSubClass()

    if player then
        local cw = player:GetCurWeapon()
        cw._lastLockedEntity = nil
        cw._lockedEntity = nil
        local x,y,z = ENTITY.PO_GetPawnHeadPos(player._Entity)
        local fv = player.ForwardVector
        cw.TipPoint:Set(x+fv.X*s.ElectroLength, y+fv.Y*s.ElectroLength, z+fv.Z*s.ElectroLength)
        player.Ammo.Electro = ammo
        cw._ShotInterval = 0
        cw.ShotTimeOut = s.AltFireTimeout * (s.MinBurst-1) -- min ilosc naboi

        if player == Player then
            SOUND2D.SetLoopCount(cw._sndLoop,0)
            SOUND2D.Play(cw._sndLoop)
             -- to musimy recznie ustawic na kliencie
            cw:SetAnim("ELshot")
            cw._ActionState = "AltFire"
        end
    end
    QuadSound(pe)
    t:SndEnt("electro_start",pe)
end
Network:RegisterMethod("DriverElectro.StartAltFireFX", NCallOn.ServerAndAllClients, NMode.Reliable, "eu")
--============================================================================
function DriverElectro:ComboFX(pe)
    local player = EntityToObject[pe]
    local t = Templates["DriverElectro.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)

    -- update ammo on proper client and server
    if player then
        if not Game.NoAmmoLoss then player.Ammo.Electro = player.Ammo.Electro - s.ElectroDiskCost end
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut   =  s.AltFireTimeout * 15
        cw._ActionState = "Idle"
        -- launch weapon's particle and sounds
        if player == Player then
            cw:ForceAnim("DISCshot",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape509",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape510",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape511",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape512",false)
            cw._showDiskTime = 0.5
        end
    end
    t:SndEnt("electrodisk_shot",pe)
    QuadSound(pe)
end
Network:RegisterMethod("DriverElectro.ComboFX", NCallOn.ServerAndAllClients, NMode.Reliable, "e")
--============================================================================
function DriverElectro:FinishAltFireFX(pe,ammo)
    Game:Print("FinishAltFireFX")
    local player = EntityToObject[pe]
    if not player then return end

    player.Ammo.Electro = ammo
    local cw = player:GetCurWeapon()
    cw._lockedEntity = nil
    cw._ActionState = "Idle"
    cw._altfire = false
    if player == Player then
        cw:EnableFX(1)
        cw:Snd2D("electro_stop",pe)
        SOUND2D.Stop(cw._sndLoop)
        SOUND2D.Stop(cw._sndLock)
        SOUND2D.Stop(cw._sndFry)
        SOUND2D.Stop(cw._sndGeoFry)
    end
end
Network:RegisterMethod("DriverElectro.FinishAltFireFX", NCallOn.ServerAndSingleClient, NMode.Reliable, "eu")
DriverElectro.time = 0
--============================================================================
function DriverElectro:GetLockedObjPos()
    if not self._lockedEntity then return 0,0,0 end

    local dx,dy,dz = ENTITY.GetPosition(self._lockedEntity)
    if ENTITY.GetType(self._lockedEntity) ==  ETypes.Model then
        local idx = MDL.GetJointIndex(self._lockedEntity,"root")
        if idx > -1 then
            dx,dy,dz = MDL.GetJointPos(self._lockedEntity,idx)
            local fv = self.ObjOwner.ForwardVector
            dx,dy,dz = dx-fv.X*0.3,dy-fv.Y*0.3,dz-fv.Z*0.3
        end
    end

    return dx,dy,dz
end
--============================================================================
function DriverElectro:OnTick(delta)

    if self.ObjOwner ~= Player then return end

    if self._showDiskTime > 0 then
        self._showDiskTime = self._showDiskTime - delta
    else
        if self._showDiskTime < 0 then
            self._showDiskTime = 0
        end
        MDL.SetMeshVisibility(self._Entity,"polySurfaceShape509",true)
        MDL.SetMeshVisibility(self._Entity,"polySurfaceShape510",true)
        MDL.SetMeshVisibility(self._Entity,"polySurfaceShape511",true)
        MDL.SetMeshVisibility(self._Entity,"polySurfaceShape512",true)
    end

end
--============================================================================
function DriverElectro:OnUpdate() -- COMMON: CLIENT & SERVER
    local s = Templates["DriverElectro.CWeapon"]:GetSubClass()

    if self._ActionState == "AltFire" and self.ObjOwner.Ammo.Electro > 0 then
        self._ShotInterval = self._ShotInterval - 1
        if self._ShotInterval <= 0 then
            if not Game.NoAmmoLoss then self.ObjOwner.Ammo.Electro = self.ObjOwner.Ammo.Electro - 1 end
            self._ShotInterval = s.AltFireTimeout

            -- logika strzalu nie dziala na kliencie
            if Game.GMode ~= GModes.MultiplayerClient then
                self:HitTest()
                -- ammo check
                if self.ObjOwner.Ammo.Electro <= 0 then
                    self.ObjOwner.Ammo.Electro = 0
                    self:OnFinishAltFire()
                end
            end
        end
        self.ObjOwner.State = 51
    else
        self:EnableFX(1)
        self.ObjOwner.State = 5
    end
    --Game:Print(self._ActionState)
end
--============================================================================
function DriverElectro:HitTest()
    local s = Templates["DriverElectro.CWeapon"]:GetSubClass()

    local prevLockedEntity = self._lockedEntity

    if Game.GMode ~= GModes.SingleGame then
        self._lockedEntity = nil -- w MP namierzam zawsze od nowa
    end

    -- searching for any object
    local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
    local b,d,tx,ty,tz,nx,ny,nz,he,e = self.ObjOwner:Trace(s.ElectroLength)
    local fv = self.ObjOwner.ForwardVector

    if not self._lockedEntity and b and e then
        local obj = EntityToObject[e] -- LUA gameobject
        if Game.GMode == GModes.SingleGame then
            if obj and obj._died and obj.Electrize then
                obj:Electrize()
            end
        end
        if obj and obj.OnDamage and obj.Health > 0 and not obj.Immortal then
            self._lockedEntity = obj._Entity
        end
    end

    local obj
    if self._lockedEntity then
        obj = EntityToObject[self._lockedEntity]
    end

    -- check health
    if not obj or obj and obj.Health <= 0 then
        self._lockedEntity = nil
        self._nearObj = nil
        obj = nil
    end

    -- verify tolerance
    if Game.GMode == GModes.SingleGame and obj then
        local v1 = Vector:New(self.TipPoint.X-x, self.TipPoint.Y-y, self.TipPoint.Z-z):Normalize()
        local d = v1:Dot(fv)
        if d < s.ElectroAutoLockTolerance then
            self._lockedEntity = nil
            self._nearObj = nil
            obj = nil
        end
    end

    -- damage
    if obj and obj.OnDamage then
        local damage = s.ElectroDamage
        if self.ObjOwner.HasQuad then            
            damage = math.floor(damage * 4)
        end
        
        if Game.GMode ~= GModes.SingleGame and obj._Class == "CPlayer" then
            if prevLockedEntity ~= self._lockedEntity then
                self._damage = damage
            else
                self._damage = self._damage + 2
            end
            damage = self._damage
            if damage > 255 then damage = 255 end
            local h = math.floor(damage/4)
            if self.ObjOwner.HasWeaponModifier then h = damage end
            if h > 0 then
                if not (MPCfg.GameMode == "Team Deathmatch" and not MPCfg.TeamDamage and obj.Team == self.ObjOwner.Team) and MPCfg.GameState == GameStates.Playing then
                    CPlayer.AddHealth(self.ObjOwner.ClientID, self.ObjOwner._Entity, h)
                end
            end
            --Game:Print(damage)
        else
            self._damage = damage
        end

        obj:OnDamage(damage,self.ObjOwner,AttackTypes.Electro,self.TipPoint.X,self.TipPoint.Y,self.TipPoint.Z)

        AddPFX("electro_hit",0.8,self.TipPoint)
        if Game.GMode == GModes.SingleGame and self.ObjOwner.HasWeaponModifier then
            local d = Templates["ElectroDisk.CItem"]
            self._nearObj = d.FindAndDamageEnemy(self,self.TipPoint.X,self.TipPoint.Y,self.TipPoint.Z,obj)
        end
    end

    if obj and obj._Class == "CPlayer" then
        local ib =  s.EnemyThrowBack
        local iu =  s.EnemyThrowUp
        -- hit spherical body
        ENTITY.PO_Hit(e,x,y,z,fv.X*ib,fv.Y*ib+iu,fv.Z*ib)
        if obj._Class == "CPlayer" then
            ENTITY.PO_SetPlayerShocked(e)
        end
    end

    if prevLockedEntity ~= self._lockedEntity then
        --Game:Print("zmiana")
        self.OnChangeLockedEntity(self.ObjOwner.ClientID,self.ObjOwner._Entity,self._lockedEntity)
    end
end
--============================================================================
-- NET EVENTS
--============================================================================

--============================================================================
-- CLIENT
function DriverElectro:OnChangeLockedEntity(pe,e)
    --Game:Print("OnChangeLockedEntity")
    local player = EntityToObject[pe]
    if player then
        --Game:Print("OnChangeLockedEntity 1")
        local cw = player:GetCurWeapon()
        if cw then
            cw._lockedEntity = e
            --Game:Print(cw._lockedEntity)
            --Game:Print("OnChangeLockedEntity 2")
        end
    end
end
Network:RegisterMethod("DriverElectro.OnChangeLockedEntity", NCallOn.SingleClient, NMode.Reliable, "ee")
--============================================================================
-- COMMON: CLIENT & SERVER
function DriverElectro:FireSFX(pe,se,combo)
    local player = EntityToObject[pe]

    local t = Templates["DriverElectro.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)

    -- update ammo on proper client and server
    if player then
        if not Game.NoAmmoLoss then player.Ammo.Shurikens = player.Ammo.Shurikens - 1 end
        if player.Ammo.Shurikens < 0 then player.Ammo.Shurikens = 0 end
        -- set next shot timeout
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut =  s.FireTimeout
        cw._ActionState = "Idle"
        cw:SetAnim("SHshot",true)
    end

    t:SndEnt("shuriken_shot",pe)
    QuadSound(pe)
end
Network:RegisterMethod("DriverElectro.FireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "eeb")
--============================================================================
function DriverElectro:OutOfAmmoFX(entity,fire)
    Templates["DriverElectro.CWeapon"]:SndEnt("out_of_ammo",entity)
end
Network:RegisterMethod("DriverElectro.OutOfAmmoFX", NCallOn.AllClients, NMode.Reliable, "eb")
--============================================================================
function DriverElectro:DrawBezierLine(points,parts,mode,size,color,rnd)

    local va = VARRAY.Create()
    for i,o in points do
        VARRAY.AddPoint(va,o.X,o.Y,o.Z)
    end
    local spr = R3D.Spr_Create(size,color,"particles/spaw",mode)
    if not rnd then rnd = 0.05 end
    local px,py,pz
    for i=0,parts do
        px,py,pz = VARRAY.GetBezierPoint(va,i/(parts-1))
        if i ~= 0 then
            px = FRand(px-rnd, px+rnd)
            py = FRand(py-rnd, py+rnd)
            pz = FRand(pz-rnd, pz+rnd)
        end
        R3D.Spr_AddPoint(spr,px,py,pz)
    end
    R3D.Spr_Render(spr)
    VARRAY.Delete(va)
end
--============================================================================
function DriverElectro:Render(delta)

    if Player ~= self.ObjOwner then return end
    if Game.TPP then return end

    if not (self._ActionState == "AltFire" and self.ObjOwner.Ammo.Electro > 0) then
        return
    end

    local s = self:GetSubClass()
    local cx,cy,cz = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)                
    local fx,fy,fz = self.ObjOwner.ForwardVector.X,self.ObjOwner.ForwardVector.Y,self.ObjOwner.ForwardVector.Z
    local dx,dy,dz = cx+fx*s.ElectroLength, cy+fy*s.ElectroLength, cz+fz*s.ElectroLength

    -- disable/enable fx
    if self._lastLockedEntity ~= self._lockedEntity then
        if self._lockedEntity then
            local isActor = false
            if Game.GMode == GModes.SingleGame then
                local obj = EntityToObject[self._lockedEntity]
                if obj and obj._Class == "CActor" then isActor = true end
            else
                if ENTITY.GetType(self._lockedEntity) ==  ETypes.Model then isActor = true end
            end

            if isActor then
                SOUND2D.SetLoopCount(self._sndFry,0)
                SOUND2D.Play(self._sndFry)
            else
                SOUND2D.SetLoopCount(self._sndLock,0)
                SOUND2D.Play(self._sndLock)
            end
        else
            SOUND2D.Stop(self._sndLock)
            SOUND2D.Stop(self._sndFry)
        end
    end
    self._lastLockedEntity = self._lockedEntity

    local sfx = 2
    local b,d,tx,ty,tz,nx,ny,nz,he,e = self.ObjOwner:TraceToPoint(dx,dy,dz)
    if not self._lockedEntity then
        if b and e then
            if not SOUND2D.IsPlaying(self._sndGeoFry) then
                SOUND2D.SetLoopCount(self._sndGeoFry,0)
                SOUND2D.Play(self._sndGeoFry)
            end
            self.TipPoint:Set(tx-fx*0.1,ty-fy*0.1,tz-fz*0.1)
            self._wallFryTimeOut = self._wallFryTimeOut - delta
            if self._wallFryTimeOut <= 0 and not ENTITY.IsWater(e) then
                ENTITY.SpawnDecal(e,'electro',tx,ty,tz,nx,ny,nz)
                local r = Quaternion:New_FromNormal(nx,ny,nz)
                AddPFX("electro_hit_wall",0.5,self.TipPoint,r)
                self._wallFryTimeOut = 0.03
            end
            sfx = 3
        else
            if Game.GMode ~= GModes.SingleGame then
                self.TipPoint:Set(dx,dy,dz)
            end
            SOUND2D.Stop(self._sndGeoFry)
        end
    else
        if Game.GMode ~= GModes.SingleGame then
            self.TipPoint:Set(dx,dy,dz)
        end
        SOUND2D.Stop(self._sndGeoFry)
    end

    -- random spark sound
    if self.ObjOwner == Player then
        --local x,y,z = ENTITY.PO_GetPawnHeadPos(Player._Entity)
        if math.random(1,30) == 15 then
            --local p = Vector:New(x,y,z):Interpolate(self.TipPoint,FRand(0,1))
            self:Snd2D("electro_spark",math.random(30,80))
            --Game:Print("spark")
        end
    end

    if Game.GMode == GModes.SingleGame and self._lockedEntity then
        local dx,dy,dz = self:GetLockedObjPos()
        self.TipPoint:Set(dx,dy,dz)
    end

    -- tip point interpolation
    self.time = self.time + delta * 6
    if not self._lockedEntity and sfx == 2 then
        local i = s.ElectroCenterSpeed * delta
        if i > 1 then i = 1 end
        local a = 0.8

        if Game.GMode == GModes.SingleGame then
            self.TipPoint:Interpolate(dx,dy+math.sin(self.time)*a,dz,i)
            self.TipPoint.Y = self.TipPoint.Y + FRand(-0.1,0.1)
        else
            --    a = 0.15
            --    i = 1
            self.TipPoint:Set(dx,dy,dz)
        end
    end

    local dx,dy,dz = self.TipPoint:Get()
    local px,py,pz = ENTITY.GetPosition(self.ObjOwner._Entity)

    local j = MDL.GetJointIndex(self._Entity, "joint2")
    local px,py,pz = MDL.TransformPointByJoint(self._Entity,j,-0.1,0,0)
    local points

    if Game.GMode == GModes.SingleGame then
        points =
        {
            Vector:New(px,py,pz),
            Vector:New(cx+fx*7, (cy+fy*7) + math.cos(self.time)/2 + FRand(-0.1,0.1), cz+fz*7),
            Vector:New(cx+fx*7, (cy+fy*7) + math.sin(self.time)/3 + FRand(-0.2,0.2), cz+fz*7):Interpolate(self.TipPoint,0.5),
            self.TipPoint,
        }
    else
        points =
        {
            Vector:New(px,py,pz),
            self.TipPoint,
        }
    end
    self:DrawBezierLine(points,15,11,FRand(0.08,0.1),R3D.RGB(FRand(65,90),FRand(75,115),FRand(200,250)))
    self:DrawBezierLine(points,15,12,FRand(0.08,0.1),R3D.RGB(FRand(65,90),FRand(75,115),FRand(200,250)))
    if Game.GMode == GModes.SingleGame then
        points =
        {
            Vector:New(px,py,pz),
            Vector:New(cx+fx*4, cy+fy*4, cz+fz*4),
            Vector:New(cx+fx*4, cy+fy*4, cz+fz*4):Interpolate(self.TipPoint,0.9),
            self.TipPoint,
        }
    end
    self:DrawBezierLine(points,15,11,FRand(0.03,0.05),R3D.RGB(FRand(65,90),FRand(75,115),FRand(200,250)))
    self:DrawBezierLine(points,15,12,FRand(0.03,0.05),R3D.RGB(FRand(65,90),FRand(75,115),FRand(200,250)))

    if self._nearObj then
        local d = Templates["ElectroDisk.CItem"]
        d:RenderFX(self.TipPoint.X,self.TipPoint.Y,self.TipPoint.Z,self._nearObj)
    end

    self:EnableFX(sfx)

    -- fx position
    ENTITY.SetPosition(self._fxEnd,self.TipPoint.X,self.TipPoint.Y,self.TipPoint.Z)
    ENTITY.SetPosition(self._light,self.TipPoint.X-fx*0.5,self.TipPoint.Y+0.5,self.TipPoint.Z-fz*0.5)
    LIGHT.Setup(self._light,2,R3D.RGBA(200,200,255,255),0,0,0,FRand(1,2),"")
    LIGHT.SetFalloff(self._light,FRand(2,3),FRand(5,6))
end
--============================================================================
