o._ShotInterval = 0
--============================================================================
function MiniGunRL:OnReleaseEntity()
    if self._sndRotor then
        SOUND2D.Delete(self._sndRotor)
        SOUND2D.Delete(self._sndRotor2)
    end
    ENTITY.Release(self._smokepfx)
end
--============================================================================
function MiniGunRL:OnCreateEntity()
    self._sndRotor = SOUND2D.Create(self:GetSndInfo("rotor_loop",true))
    self._sndRotor2 = SOUND2D.Create(self:GetSndInfo("rotor_loop2",true))
    self:ReloadTextures()
    --Game:Print(" ??? MiniGunRL - CreateSounds")
end
--============================================================================
function MiniGunRL:OnPrecache()
    CloneTemplate("MiniGunRL.CWeapon"):LoadHUDData()
	Cache:PrecacheParticleFX("hainrl_fx")
	Cache:PrecacheParticleFX("HaingunHitWall")
	Cache:PrecacheParticleFX("HaingunHitWater")
	Cache:PrecacheItem("hainKamyk.CItem")
	Cache:PrecacheItem("Rocket.CItem")
	Cache:PrecacheDecal('bullethole')
--	Cache:PrecacheDecal('splash')
end
--============================================================================
function MiniGunRL:ReloadTextures()
	if not self._Entity then return end
    if Cfg.WeaponNormalMap == true then
        if Cfg.WeaponSpecular == false then
            MATERIAL.Replace("models/crl/crl_pb","models/crl/crl_pb_no_specular")
        else
            MATERIAL.Replace("models/crl/crl_pb","models/crl/crl_pb")
        end
    end
	MDL.EnableNormalMaps(self._Entity,Cfg.WeaponNormalMap)
end
--============================================================================
function MiniGunRL:LoadHUDData()
--    self._matMiniGunIcon = MATERIAL.Create("HUD/naboje_do_czejngana", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
--    self._matGrenadeIcon = MATERIAL.Create("HUD/granat", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
--	self._matAmmoIcon = MATERIAL.Create("HUD/ammo", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matAmmoMiniIcon = MATERIAL.Create("HUD/minigun", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matAmmoRocketIcon = MATERIAL.Create("HUD/rocket", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
end
--============================================================================
function MiniGunRL:MuzzleFlashFX(mode,size)
    -- protection for multiply lights simultaneously
    if not self._LightName or getfenv()[self._LightName] == nil then
        local a
        if mode == 0 then
            a = AddAction({{"Light:PX,PY+2.3,PZ,200,200,150, 5, 8 , 1, 0,0.065,0"}})
        else
            a = AddAction({{"Light:PX,PY+2.3,PZ,255,255,215, 5, 8 , 2, 0,0,0.2"}})
        end
        self._LightName = a._Name
        self:MuzzleFlash("joint4",0,0,0,size)
    end
end
--============================================================================
function MiniGunRL:OnChangeWeapon()
    self._ActionState = "Idle"
    self._altfire = false
    SOUND2D.Stop(self._sndRotor)
    SOUND2D.Stop(self._sndRotor2)
end
--============================================================================
function MiniGunRL:DrawHUD(delta)
    local w,h = R3D.ScreenSize()
    local gray = R3D.RGB(120,120,70)
    local sizex, sizey = MATERIAL.Size(Hud._matHUDLeft)

    if not (INP.IsFireSwitched() or (not Game.SwitchFire[4] and Cfg.SwitchFire[4]) or (not Cfg.SwitchFire[4] and Game.SwitchFire[4])) then
		Hud:Quad(self._matAmmoMiniIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoRocketIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*17)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%03d",Player.Ammo.Grenades),-3),0.9 * Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Grenades)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%03d",Player.Ammo.MiniGun),-3),0.9 * Cfg.HUDSize,Player.s_SubClass.AmmoWarning.MiniGun)
	else
		Hud:Quad(self._matAmmoMiniIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*17)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoRocketIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%03d",Player.Ammo.MiniGun),-3),0.9 * Cfg.HUDSize,Player.s_SubClass.AmmoWarning.MiniGun)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%03d",Player.Ammo.Grenades),-3),0.9 * Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Grenades)
	end
end

--============================================================================
-- ALT FIRE - BULLET (Server Side)
--============================================================================
function MiniGunRL:AltFire() -- bullets
    if self.ObjOwner.Ammo.MiniGun > 0 then
        PlayLogicSound("FIRE",self.ObjOwner.Pos.X,self.ObjOwner.Pos.Y,self.ObjOwner.Pos.Z,15,30,self.ObjOwner)
        self.StartAltFireFX(self.ObjOwner.ClientID, self.ObjOwner._Entity, self.ObjOwner.Ammo.MiniGun)
    else
        local s = self:GetSubClass()
        self.OutOfAmmoFX(self.ObjOwner._Entity,2)
        self.ShotTimeOut = s.AltFireTimeout * 5
        -- to jakos inaczej rozwiazac, zeby outofammo od razu ustawialo idle'a
        self._ActionState = "Idle"
        self._altfire = false
    end
end
--============================================================================
function MiniGunRL:StartAltFireFX(pe,ammo)
    local player = EntityToObject[pe]
    if not player then return end

    local s = Templates["MiniGunRL.CWeapon"]:GetSubClass()

    player.Ammo.MiniGun = ammo
    local cw = player:GetCurWeapon()
    cw._ShotInterval = 0
    cw.ShotTimeOut = s.AltFireTimeout * (s.MinBurst-1) -- min ilosc naboi
    QuadSound(pe)

    if player == Player then
        SOUND2D.SetLoopCount(cw._sndRotor,0)
        SOUND2D.SetLoopCount(cw._sndRotor2,0)
        SOUND2D.Play(cw._sndRotor)
        SOUND2D.Play(cw._sndRotor2)
         -- to musimy recznie ustawic na kliencie
        cw:SetAnim("cshot")
        cw._ActionState = "AltFire"
    end
end
Network:RegisterMethod("MiniGunRL.StartAltFireFX", NCallOn.ServerAndSingleClient, NMode.Reliable, "eu")
--============================================================================
function MiniGunRL:OnFinishAltFire()
    --Game:Print("OnFinishFire")
    self.FinishAltFireFX(self.ObjOwner.ClientID, self.ObjOwner._Entity,self.ObjOwner.Ammo.MiniGun)
end
--============================================================================
function MiniGunRL:FinishAltFireFX(pe,ammo)
    local player = EntityToObject[pe]
    if not player then return end

    player.Ammo.MiniGun = ammo
    local cw = player:GetCurWeapon()
    cw._ActionState = "Idle"
    cw._altfire = false

    if player == Player then
        -- na kliencie jest jeszcze zwolnienie obrotow lufy
        cw:SetAnim("endshot",false)
        cw._ActionState = "End"
        cw._altfire = false
        SOUND2D.Stop(cw._sndRotor2)
        SOUND2D.SetLoopCount(cw._sndRotor,1)
        cw:SndEnt("rotor_stop",pe)
    end
end
Network:RegisterMethod("MiniGunRL.FinishAltFireFX", NCallOn.ServerAndSingleClient, NMode.Reliable, "eu")
--============================================================================
-- FIRE - ROCKET (Server Side)
--============================================================================
function MiniGunRL:Client_FirePrediction(first)    
    if first and self.ObjOwner.Ammo.Grenades > 0 then
        RawCallMethod(self.FireSFX,self.ObjOwner._Entity,nil)        
        self.AfterPrediction = true
        Game:Print("Fire - prediction")
    end
end
--============================================================================
function MiniGunRL:Fire() -- rocket
    local s = self:GetSubClass()

    if self.ObjOwner.Ammo.Grenades > 0 and not self.ObjOwner._jammed then
        if Player then Player.ExplosiveFired = true end

        -- create rocket object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("Rocket.CItem"))
        -- set position
        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
        local orientation = ENTITY.GetOrientation(self.ObjOwner._Entity)
        --y = y - 0.65
        --x = x - math.cos(orientation)*0.4
        --z = z + math.sin(orientation)*0.4
        local fv = self.ObjOwner.ForwardVector

        local b = self.ObjOwner:Trace(0.2)
        if not b then
            x,y,z = x + fv.X*0.2, y + fv.Y*0.2, z + fv.Z*0.2
        end

        obj.Pos:Set(x,y,z)
        obj.Rot:FromEulerZYX(1.57-fv.Y,-orientation+1.57,0)
        obj:Apply()
        obj.ObjOwner = self.ObjOwner

        local speed = s.RocketSpeed
        if self.ObjOwner.HasWeaponModifier then
            speed = speed * 1.5
        end

        ENTITY.SetVelocity(obj._Entity,fv.X*speed,fv.Y*speed,fv.Z*speed)
        ENTITY.PO_EnableGravity(obj._Entity,false)
        obj.ExplosionStrength = s.RocketExplosionStrength
        obj.ExplosionRange    = s.RocketExplosionRange
        obj.Damage            = s.RocketDamage
        if self.ObjOwner.HasQuad then            
            obj.Damage = math.floor(obj.Damage * 4)
        end

        PlayLogicSound("FIRE",self.ObjOwner.Pos.X,self.ObjOwner.Pos.Y,self.ObjOwner.Pos.Z,12,30,self.ObjOwner)
        -- launch SpecialFX on all clients
        self.FireSFX(self.ObjOwner._Entity)
    else
        self.OutOfAmmoFX(self.ObjOwner._Entity,1)
        self.ShotTimeOut = s.FireTimeout
    end
end
--============================================================================
function MiniGunRL:FireSFX(pe)
    local player = EntityToObject[pe]
    local t = Templates["MiniGunRL.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)

    local fx = true        
    
    -- update ammo on client and server
    if player then
        if not WEAPON_PREDICTION then
            if not Game.NoAmmoLoss then player.Ammo.Grenades = player.Ammo.Grenades -1 end            
        end        
        
        local cw = player:GetCurWeapon()                
        cw._ActionState = "Idle"        
        cw.ShotTimeOut = s.FireTimeout 
        if cw.AfterPrediction then
            fx = false
            cw.AfterPrediction = false
            --cw.ShotTimeOut = s.FireTimeout - (NET.GetLastFrameLatency()/1000) * 30
        end
                
        if fx and player == Player  then --and (prediction or cw.ShotTimeOut > s.FireTimeout)  then
            -- trzesienie kamera
            Game._EarthQuakeProc:Add(x,y,z, 15, 4, s.ShotCamMove, s.ShotCamRotate, false)
            -- dym z lufy
            if not cw._smokepfx then
                if Cfg.ViewWeaponModel then
                    cw._smokepfx = AddPFX("hainrl_fx",0.5)
                    PARTICLE.SetImmortal(cw._smokepfx)
                    cw:OnClientTick()
                end
            else
                PARTICLE.Restart(cw._smokepfx)
            end
            -- blysk i swiatlo
            cw:MuzzleFlashFX(1,0.4)
            cw:ForceAnim("RL",false)        
        end
    else
        local px,py,pz = BindPoint(pe,0,2.3,1)
        AddAction({{"Light:a[1],a[2],a[3],255,255,185, 3, 4 , 2, 0, 0, 0.1"}},nil,nil,px,py,pz)
    end
    
    if fx then
        t:SndEnt("rocket_launch",pe)
        QuadSound(pe)
    end    
end
Network:RegisterMethod("MiniGunRL.FireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "e")
--============================================================================
function MiniGunRL:OnFinishAnim(anim)
    if anim == "endshot" then
        --Game:Print("endshot")
        self._ActionState = "Idle"
    end
end
--============================================================================
function MiniGunRL:OnUpdate()
    --Game:Print(self._ActionState)
    --Game:Print(self._ShotInterval)
    --if self._altfire then Game:Print("true") else Game:Print("false") end

    local s = Templates["MiniGunRL.CWeapon"]:GetSubClass()

    if self._ActionState == "AltFire" and self.ObjOwner.Ammo.MiniGun > 0 then
        self._ShotInterval = self._ShotInterval - 1
        if self._ShotInterval <= 0 then
            self.shotFX = true
            if not Game.NoAmmoLoss then self.ObjOwner.Ammo.MiniGun = self.ObjOwner.Ammo.MiniGun - 1 end
            self._ShotInterval = s.AltFireTimeout
            -- strzal dziala tylko na serwerze
            if Game.GMode ~= GModes.MultiplayerClient then
                self:HitTest()
                if self.ObjOwner.Ammo.MiniGun <= 0 then
                    self.ObjOwner.Ammo.MiniGun = 0
                    self:OnFinishAltFire();
                end
            end
        end
        self.ObjOwner.State = 41
    else
        self.ObjOwner.State = 4
    end
    --Game:Print(self._ActionState)
end
--============================================================================
function MiniGunRL:OnClientTick(delta)
    if self._smokepfx then
        local j = MDL.GetJointIndex(self._Entity,"joint4")
        local x,y,z,rw,rx,ry,rz = MDL.TransformPointByJoint(self._Entity,j,0,0,0)--0,0,0)
        ENTITY.SetPosition(self._smokepfx,x,y,z)
    end

    if self._ActionState == "AltFire" and self.shotFX then
        self:MuzzleFlashFX(0,0.3)
        -- launch weapon's particle and sounds
        local x,y,z = ENTITY.GetPosition(self.ObjOwner._Entity)
        local t = Templates["MiniGunRL.CWeapon"]
        local s = t:GetSubClass()
        t:Snd2D("shot")
        t:Snd2D("shell")
        PlayLogicSound("FIRE",x,y,z,8,16,player)
        Game._EarthQuakeProc:Add(x,y,z, 2, 4, s.ShotCamMove, s.ShotCamRotate, false)
        self.shotFX = false
    end

end
--============================================================================
-- Shells Hit Test
--============================================================================
function MiniGunRL:HitTest()
    local s = Templates["MiniGunRL.CWeapon"]:GetSubClass()
    -- havok's trace from player
    local b,d,x,y,z,nx,ny,nz,he,e = self.ObjOwner:Trace(s.AltFireRange)
    if b and e then
        local fv = self.ObjOwner.ForwardVector
        if Game.GMode == GModes.SingleGame and ENTITY.IsWater(e) then
            self:HitWaterSFX(x,y,z,nx,ny,nz,fv.X,fv.Y,fv.Z,e)
        else
            local damage = s.AltFireDamage
            if self.ObjOwner.HasWeaponModifier then
                damage = math.floor(damage * 1.5)
            end
            if self.ObjOwner.HasQuad then            
                damage = math.floor(damage * 4)
            end
            local obj = EntityToObject[e] -- LUA gameobject
            if obj and damage > 0 and obj.OnDamage then
                obj:OnDamage(damage,self.ObjOwner,AttackTypes.MiniGun,x,y,z,nx,ny,nz,he)
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
--		    if obj._Class == "CPlayer" then
--			    ENTITY.PO_SetPlayerShocked(e)
--		    end
            if Game.GMode == GModes.SingleGame then
                if not CanBurning(obj) then 
                    self:HitWallSFX(e,x,y,z,nx,ny,nz,fv.X,fv.Y,fv.Z)
                end
            end
		end
                -- hit ragdoll body
                WORLD.HitPhysicObject(he,x,y,z,fv.X*150,fv.Y*150,fv.Z*150)
            else
                -- hit havok body
                WORLD.HitPhysicObject(he,x,y,z,fv.X*150,fv.Y*150,fv.Z*150)
                if Game.GMode == GModes.SingleGame then
                    self:HitWallSFX(e,x,y,z,nx,ny,nz,fv.X,fv.Y,fv.Z)
                end
            end
            CheckStartGlass(he,x,y,z,0.1,fv.X*50,fv.Y*50,fv.Z*50)
        end
        PlayLogicSound("RICOCHET",x,y,z,8,16,nil)
    end
end
--============================================================================
function MiniGunRL:HitWallSFX(entity,x,y,z,nx,ny,nz,fx,fy,fz)

    --Game:Print("HitWallSFX:"..x..", "..y..", "..z..", "..nx..", "..ny..", "..nz..", "..fx..", "..fy..", "..fz)
    local px,py,pz = x-fx,y-fy,z-fz
    if entity then ENTITY.SpawnDecal(entity,'bullethole',x,y,z,nx,ny,nz) end

    local t = Templates["MiniGunRL.CWeapon"]
    local r = Quaternion:New_FromNormal(nx,ny,nz)

    local obj = EntityToObject[entity]
    if obj and obj.s_SubClass and obj.s_SubClass.SoundsDefinitions and obj.s_SubClass.SoundsDefinitions.SoundHitByBullet and math.random(100) < 50 then
        obj:PlaySound("SoundHitByBullet",nil,nil,nil,nil,x,y,z)
    else
        if math.random(100) < 50 then  t:Snd3D("bullet_hit_wall",x,y,z) end
        if Game.GMode == GModes.SingleGame then
            if math.random(0,2) == 1  then
                local vx,vy,vz  = r:TransformVector(FRand(-60,93),FRand(40,60),FRand(-60,93))
                local sizes = {0.7,1.4}
                local ke = AddItem("hainKamyk.CItem",sizes[math.random(1,2)],Vector:New(px+FRand(-0.03,0.03),py+FRand(-0.03,0.03),pz+FRand(-0.03,0.03)),false,Quaternion:New_FromNormal(-vx,-vy,-vz))
                ENTITY.SetVelocity(ke,vx,vy,vz)
                ENTITY.SetTimeToDie(ke,FRand(0.2,0.3))
                --ENTITY.PO_SetPinned(ke,true)
            end
        end
    end

    AddPFX("HaingunHitWall",0.25,Vector:New(px,py,pz),r)
end
--============================================================================
function MiniGunRL:HitWaterSFX(x,y,z,nx,ny,nz,fx,fy,fz,e)
    -- launch sparks and decals
    local px,py,pz = x-fx,y-fy,z-fz
--    ENTITY.SpawnDecal(e,'splash',x,y,z,nx,ny,nz)
	AddPFX("HaingunHitWater",0.3,Vector:New(px,py,pz),Quaternion:New_FromNormal(nx,ny,nz))
    Templates["MiniGunRL.CWeapon"]:Snd3D("bullet_hit_water",x,y,z)
end
--============================================================================
function MiniGunRL:OutOfAmmoFX(entity,fire)
    Templates["MiniGunRL.CWeapon"]:SndEnt("out_of_ammo",entity)
end
Network:RegisterMethod("MiniGunRL.OutOfAmmoFX", NCallOn.AllClients, NMode.Reliable, "eb")
--============================================================================
function MiniGunRL:Render()
    if self.ObjOwner.HasWeaponModifier and self._ActionState == "AltFire" and math.random(0,10) == 5 then
        local j = MDL.GetJointIndex(self._Entity, "joint4")
        local px,py,pz = MDL.TransformPointByJoint(self._Entity,j,0,0.06,0)
        local ex,ey,ez = MDL.TransformPointByJoint(self._Entity,j,0,0.06,-3)
        local fv = self.ObjOwner.ForwardVector
        R3D.DrawSprite1DOF(px,py,pz,ex,ey,ez,0.04,R3D.RGB(255,200,200),"particles/trailpainkiller")
    end
end
--============================================================================
