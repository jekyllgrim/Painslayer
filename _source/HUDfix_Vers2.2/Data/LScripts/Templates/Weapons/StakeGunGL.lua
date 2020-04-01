o._stakeTime = 0
--============================================================================
function StakeGunGL:OnCreateEntity()
	self:ReloadTextures()
end
--============================================================================
function StakeGunGL:OnPrecache()
    CloneTemplate("StakeGunGL.CWeapon"):LoadHUDData()
	Cache:PrecacheItem("Stake.CItem")     
	Cache:PrecacheItem("Grenade.CItem")             
    Cache:PrecacheTrail("trail_kolek")        
    Cache:PrecacheTrail("trail_kolek_combo")
    Cache:PrecacheParticleFX("grenademodif")
end
--============================================================================
function StakeGunGL:OnChangeWeapon()
    self._stakeTime = 0
end
--============================================================================
function StakeGunGL:ReloadTextures()
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
function StakeGunGL:LoadHUDData()
	self._matAmmoIcon = MATERIAL.Create("HUD/kolki", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matAmmoRocketIcon = MATERIAL.Create("HUD/rocket", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
end
--============================================================================
function StakeGunGL:DrawHUD(delta)
    local w,h = R3D.ScreenSize()
    local gray = R3D.RGB(120,120,70)
    local sizex, sizey = MATERIAL.Size(Hud._matHUDLeft)
    
    if not (INP.IsFireSwitched() or (not Game.SwitchFire[3] and Cfg.SwitchFire[3]) or (not Cfg.SwitchFire[3] and Game.SwitchFire[3])) then
		Hud:Quad(self._matAmmoIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*11)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoRocketIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Stakes),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Stakes)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Grenades),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Grenades)
	else
		Hud:Quad(self._matAmmoRocketIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*17)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoIcon,(1024-52*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*47)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Grenades),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Grenades)
		Hud:DrawDigitsText((1024-118*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%04d",Player.Ammo.Stakes),-3),0.9*Cfg.HUDSize,Player.s_SubClass.AmmoWarning.Stakes)
	end
end
--============================================================================
function StakeGunGL:Client_FirePrediction(first)    
    if first and self.ObjOwner.Ammo.Stakes > 0 then
        RawCallMethod(self.FireSFX,self.ObjOwner._Entity)        
        self.AfterPrediction = true
        Game:Print("Fire - prediction")
    end
end
--============================================================================
function StakeGunGL:Fire(prevstate) -- Stake
    local s = self:GetSubClass()
    if self.ObjOwner.Ammo.Stakes > 0 then       
        
        -- create rocket object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("Stake.CItem"))        
        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)                
        local fv = self.ObjOwner.ForwardVector
        y = y - 0.2
        
        obj._lastTraceStartPoint =  Vector:New(x,y,z)
        obj.Pos:Set(x+fv.X*1,y+fv.Y*1,z+fv.Z*1)
        obj.Rot:FromNormalZ(fv.X,fv.Y,fv.Z)     
        obj.ObjOwner = self.ObjOwner
        obj:Apply()
        obj.Damage = s.StakeDamage
        if self.ObjOwner.HasQuad then            
            obj.Damage = math.floor(obj.Damage * 4)
        end
        obj.BurningDamage = s.BurningStakeDamage
        if self.ObjOwner.HasQuad then            
            obj.BurningDamage = math.floor(obj.BurningDamage * 4)
        end

        if self.ObjOwner.HasWeaponModifier then
            obj.BurnAfterTime = 0.05
        else
            obj.BurnAfterTime = s.BurnStakeAfterTime
        end
        obj.EnemyThrowBack = s.EnemyThrowBack
        obj.EnemyThrowUp   = s.EnemyThrowUp

        local speed = s.StakeSpeed
        if self.ObjOwner.HasWeaponModifier then speed = speed * 1.6 end
        
        ENTITY.SetVelocity(obj._Entity,fv.X*speed,fv.Y*speed,fv.Z*speed)
        ENTITY.PO_EnableGravity(obj._Entity,false)
        
        PlayLogicSound("FIRE",self.ObjOwner.Pos.X,self.ObjOwner.Pos.Y,self.ObjOwner.Pos.Z,12,24,self.ObjOwner)   
        self.FireSFX(self.ObjOwner._Entity)
        return obj
    else
        self.OutOfAmmoFX(self.ObjOwner._Entity,1)
        self.ShotTimeOut = s.AltFireTimeout
    end
end
--============================================================================
function StakeGunGL:OnFinishFire(oldstate)
end
--============================================================================
-- ALT FIRE - GRENADE (Server Side)
--============================================================================
function StakeGunGL:AltFire() -- grenade
    local s = self:GetSubClass()
    if self.ObjOwner.Ammo.Grenades > 0  then
       
       if Player then Player.ExplosiveFired = true end
       
        -- create grenade object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("Grenade.CItem"))
        obj.ObjOwner = self.ObjOwner		

        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)                
        local fv = self.ObjOwner.ForwardVector
        y = y - 0.2
        
        local b = self.ObjOwner:Trace(1.3)
        if not b then 
            x,y,z = x + fv.X*1.3, y + fv.Y*1.3, z + fv.Z*1.3    
        end
        
        obj.Pos:Set(x,y,z)
        obj.Rot:FromNormalY(fv.X,fv.Y,fv.Z)     
        obj:Apply()
        obj.ExplosionStrength = s.GrenadeExplosionStrength
        obj.ExplosionRange    = s.GrenadeExplosionRange        
        obj.Damage            = s.GrenadeDamage        
        if self.ObjOwner.HasQuad then            
            obj.Damage = math.floor(obj.Damage * 4)
        end
        obj.WMGasAmount       = s.GrenadeWMGasAmount
        obj.WMGasDamage       = s.GrenadeWMGasDamage
        if self.ObjOwner.HasQuad then            
            obj.WMGasDamage = math.floor(obj.WMGasDamage * 4)
        end
        obj.WMGasRange        = s.GrenadeWMGasRange
        obj.WMGasLifeTime     = s.GrenadeWMGasLifeTime
        
        -- add some velocity from player
        local pvx,pvy,pvz = ENTITY.GetVelocity(self.ObjOwner._Entity)       
        pvx,pvy,pvz = pvx*math.abs(fv.X)*0.7,pvy*math.abs(fv.Y)/2*0.7,pvz*math.abs(fv.Z)*0.7 
        local gvf = s.GrenadeVelocityForward
        local gvu = s.GrenadeVelocityUp
        --if self.ObjOwner.HasWeaponModifier then
        --    gvf = gvf * 2
        --    gvu = gvu * 1.2
        --end
        ENTITY.SetVelocity(obj._Entity, fv.X*gvf+pvx, fv.Y*gvf+gvu+pvy, fv.Z*gvf+pvz) 
        local a = FRand(2,3)
        --ENTITY.SetAngularVelocity(obj._Entity, fv.Z*a,0,-fv.X*a)        
        ENTITY.SetAngularVelocity(obj._Entity, fv.Z*a,0,-fv.X*a)
        
        -- launch SpecialFX on all clients
        self.AltFireSFX(self.ObjOwner._Entity,obj._Entity)        
        PlayLogicSound("FIRE",x,y,z,26,52,player)
    else
        self.OutOfAmmoFX(self.ObjOwner._Entity,2)
        self.ShotTimeOut = s.AltFireTimeout
    end
end
--============================================================================
function StakeGunGL:OnTick(delta)
    if self._stakeTime > 0 then 
        self._stakeTime = self._stakeTime - delta         
    else
        if self._stakeTime < 0 then
            self._stakeTime = 0
        end
        if self.ObjOwner.Ammo.Stakes > 0  then                     
            MDL.SetMeshVisibility(self._Entity,"KolekShape",true)
        end
    end
end
--============================================================================
-- NET EVENTS
--============================================================================
function StakeGunGL:FireSFX(pe,prediction)
    local player = EntityToObject[pe]   
    
    local t = Templates["StakeGunGL.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)
    
    local fx = true        

    if player and player._Class ~= "CPlayer" then MsgBox("Bad player object: "..player._Class) end

    -- update ammo on proper client and server
    if player then
        
        if not WEAPON_PREDICTION then
            if not Game.NoAmmoLoss then player.Ammo.Stakes = player.Ammo.Stakes - 1 end
            if player.Ammo.Stakes < 0 then player.Ammo.Stakes=0 end
        end
    
        -- set next shot timeout
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut =  s.FireTimeout
        cw._ActionState = "Idle"
        
        if cw.AfterPrediction then
            fx = false
            cw.AfterPrediction = false
        end

        if player == Player then
            cw:ForceAnim("pinshot",false)                   
            MDL.SetMeshVisibility(cw._Entity,"KolekShape",false)
            cw._stakeTime = 0.75         
        end
    end

    if fx then
        if Game.GMode == GModes.SingleGame then
            t:SndEnt("stake_shot",pe)
        else
            t:SndEnt("stake_shot_mp",pe)
        end
        QuadSound(pe)                
    end
end
Network:RegisterMethod("StakeGunGL.FireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "e") 
-- potwierdzony poniewaz i tak doklei sie do komunikatu stworzenia nowego entity kolka
--============================================================================
function StakeGunGL:AltFireSFX(pe,ge)
    local player = EntityToObject[pe]

    local t = Templates["StakeGunGL.CWeapon"]
    local s = t:GetSubClass()
    local x,y,z = ENTITY.GetPosition(pe)
    
    -- update ammo on proper client and server
    if player then 
        if not Game.NoAmmoLoss then player.Ammo.Grenades = player.Ammo.Grenades -1 end
        -- set next shot timeout
        local cw = player:GetCurWeapon()
        cw.ShotTimeOut   =  s.AltFireTimeout
        cw._ActionState = "Idle" -- bo korzystamy z timeout'a        
        Game._EarthQuakeProc:Add(x,y,z, 2, 4, s.ShotCamMove, s.ShotCamRotate, false)        
        if player == Player then
            cw:ForceAnim("grshot",false)                
        end        
        if player.HasWeaponModifier then
            local pfx = AddPFX("grenademodif",0.2)
            ENTITY.RegisterChild(ge,pfx) 
        end            
    end
          
    t:SndEnt("grenade_shot",pe)
    t:SndEnt("grenade_reload",pe)
    QuadSound(pe)           
end
Network:RegisterMethod("StakeGunGL.AltFireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "ee") 
--============================================================================
function StakeGunGL:OutOfAmmoFX(entity,fire)
    Templates["StakeGunGL.CWeapon"]:SndEnt("out_of_ammo",entity)
end
Network:RegisterMethod("StakeGunGL.OutOfAmmoFX", NCallOn.AllClients, NMode.Reliable, "eb") 
--============================================================================
