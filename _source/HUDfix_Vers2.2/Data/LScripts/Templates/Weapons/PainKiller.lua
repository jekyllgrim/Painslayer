o._painHeadEntity = nil
o._ComboDelay = 0
--============================================================================
-- HUD
--============================================================================
function PainKiller:LoadHUDData()
	self._matAmmoOpenIcon = MATERIAL.Create("HUD/painkiller_open", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matAmmoCloseIcon = MATERIAL.Create("HUD/painkiller_close", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matInfinity = MATERIAL.Create("HUD/infinity", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
end
--============================================================================
function PainKiller:OnCreateEntity()
    self._sndRotor = SOUND2D.Create(self:GetSndInfo("rotor_loop",true),false,true)
    self._sndElectro = SOUND2D.Create(self:GetSndInfo("electro_loop",true),false,true)
    self._sndShock = SOUND2D.Create(self:GetSndInfo("shock_loop",true),false,true)
    self:ReloadTextures()
end
--============================================================================
function PainKiller:OnPrecache()
    CloneTemplate("PainKiller.CWeapon"):LoadHUDData()
	Cache:PrecacheParticleFX("FX_pain_elektro")    
	Cache:PrecacheItem("PainHead.CItem")     
    MATERIAL.Create("particles/trailpainkiller")
end
--============================================================================
function PainKiller:ReloadTextures()
	if not self._Entity then return end
    if Cfg.WeaponNormalMap == true then    
        if Cfg.WeaponSpecular == false then
            MATERIAL.Replace("models/pkw/pkw_pb","models/pkw/pkw_pb_no_specular")
        else
            MATERIAL.Replace("models/pkw/pkw_pb","models/pkw/pkw_pb")
        end
    end
	MDL.EnableNormalMaps(self._Entity,Cfg.WeaponNormalMap)
end
--============================================================================
function PainKiller:EnableEnergyFX(enable)
    if enable then
        --Game:Print("true")
        if not self._fx then
            self._fx = AddPFX("FX_pain_elektro",0.03,Vector:New(0,0,0))
            ENTITY.RegisterChild(self._Entity,self._fx,true)
            PARTICLE.SetParentOffset(self._fx,0.04,0.04,0.02,MDL.GetJointIndex(self._Entity,"joint5"))
        end
    else
        --Game:Print("false")
        ENTITY.Release(self._fx)
        self._fx = nil        
        SOUND2D.Pause(self._sndElectro)    
    end    
end
--============================================================================
function PainKiller:OnReleaseEntity()
    SOUND2D.Delete(self._sndRotor)
    SOUND2D.Delete(self._sndElectro)
    SOUND2D.Delete(self._sndShock)
end
--============================================================================
function PainKiller:DrawHUD(delta)
    local w,h = R3D.ScreenSize()
    local gray = R3D.RGB(120,120,70)
    local sizex, sizey = MATERIAL.Size(Hud._matHUDLeft)
    
    if not (INP.IsFireSwitched() or (not Game.SwitchFire[1] and Cfg.SwitchFire[1]) or (not Cfg.SwitchFire[1] and Game.SwitchFire[1])) then
		Hud:Quad(self._matAmmoOpenIcon,(1024-62*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*12)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoCloseIcon,(1024-62*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
    else
		Hud:Quad(self._matAmmoCloseIcon,(1024-62*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*12)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
		Hud:Quad(self._matAmmoOpenIcon,(1024-62*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*44)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
    end
    
    Hud:Quad(self._matInfinity,(1024-121*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*15)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
    Hud:Quad(self._matInfinity,(1024-121*Cfg.HUDSize)*w/1024-Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
end
--============================================================================
-- FIRE - Painkiller closed (Server Side)
--============================================================================
function PainKiller:Fire()
    if self.r_PainHead then 
        self._ActionState = "Idle"
        return 
    end    

    self.StartFireSFX(self.ObjOwner.ClientID,self.ObjOwner._Entity)
end
--============================================================================
function PainKiller:OnFinishFire()
    if self.r_PainHead then return end    
    self.FinishFireSFX(self.ObjOwner.ClientID,self.ObjOwner._Entity)
end
--============================================================================
-- ALT FIRE - PainKiller opened (Server Side)
--============================================================================
function PainKiller:AltFire(first,combo)

    self._ActionState = "Idle"
    if not first then return end
    
    if not self.r_PainHead and not self.ObjOwner._jammed then       
        self._spinning = combo
        
        -- create rocket object
        local obj = GObjects:Add(TempObjName(),CloneTemplate("PainHead.CItem"))
        -- set position
        local x,y,z = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
        local fv = self.ObjOwner.ForwardVector       
        
        obj._lastTraceStartPoint =  Vector:New(x,y,z)
        obj.Pos:Set(x+fv.X*1.7,y+fv.Y*1.7,z+fv.Z*1.7)
        obj.Rot:FromNormalZ(fv.X,fv.Y,fv.Z)     
        obj.ObjOwner = self.ObjOwner
        obj._spinning = self._spinning
        obj:Apply()
        
        if obj._spinning then
            local ax,ay,az = Quaternion:New_FromEntity(obj._Entity):TransformVector(0,0,30)
            ENTITY.PO_EnableGravity(obj._Entity,false)
            ENTITY.SetAngularVelocity(obj._Entity,ax,ay,az)            
            MDL.SetAnim(obj._Entity,"opened",false,1,0)
            obj.ObjOwner.State = 13 -- krecacy
        else
            obj.ObjOwner.State = 12 -- promien
        end
        
        local s = self:GetSubClass()
        
        obj.Damage = s.PainHeadDamage
        if obj._spinning then 
            obj.Damage = s.PainHeadSpinningDamage
        end
        if self.ObjOwner.HasQuad then            
            obj.Damage = math.floor(obj.Damage * 4)
        end

        obj.BackSpeed = s.PainHeadBackSpeed                
        obj.BackImpulse = s.PainHeadBackImpulse
        obj.MonstersBackVelocity = s.PainHeadMonstersBackVelocity
        obj.Range = s.PainHeadRange
        self.r_PainHead = obj
        
        local speed = s.PainHeadSpeed
        if obj._spinning then speed =  s.PainHeadSpinningSpeed end
        ENTITY.SetVelocity(obj._Entity,fv.X*speed,fv.Y*speed,fv.Z*speed)
        ENTITY.PO_EnableGravity(obj._Entity,false)

        PlayLogicSound("FIRE",self.ObjOwner.Pos.X,self.ObjOwner.Pos.Y,self.ObjOwner.Pos.Z,12,26,self.ObjOwner)           
        local cb = 0
        if combo then cb = 1 end
        self.AltFireSFX(self.ObjOwner._Entity,obj._Entity,cb)    
    else        
        if self.r_PainHead then
            self.r_PainHead._back = true                        
        end
    end
end
PainKiller._points = { {0,0,1.8}, {1,1,1.5}, {1,-1,1.5}, {-1,1,1.5}, {-1,-1,1.5} }
--============================================================================
function PainKiller:OnUpdate()

    if self._ComboDelay > 0 then self._ComboDelay = self._ComboDelay - 1 end
    local s = self:GetSubClass()     
    if self._painHeadEntity and self.r_PainHead and not self.r_PainHead._back and not self._spinning then        
    
        if Game.GMode ~= GModes.MultiplayerClient then 
            local x,y,z = ENTITY.GetPosition(self.r_PainHead._Entity)        
            local cx,cy,cz = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity)
            local fv = self.ObjOwner.ForwardVector
            
            local d = R3D.DistToLine(x,y,z,cx,cy,cz,cx+fv.X*900,cy+fv.Y*900,cz+fv.Z*900)    
            if self.ObjOwner.HasWeaponModifier or d < s.PainRayTolerance then        
                
                local px,py,pz = cx,cy-0.5,cz
                
                if Game.GMode == GModes.SingleGame then
                    local j = MDL.GetJointIndex(self._Entity, "joint5") 
                    px,py,pz = MDL.TransformPointByJoint(self._Entity,j,0.03,0.04,0)--,0,0,0) 
                end
    
                ENTITY.RemoveFromIntersectionSolver(self.ObjOwner._Entity)
                local b,d,tx,ty,tz,nx,ny,nz,he,e = WORLD.LineTrace(px,py,pz,x-fv.X,y-fv.Y,z-fv.Z)
                ENTITY.AddToIntersectionSolver(self.ObjOwner._Entity)
                
                if b then                            
                    local obj = EntityToObject[e]             
                    if obj then          
                        if math.random(100) < 50 then                            
                            local damage = s.PainRayDamage
                            if self.ObjOwner.HasQuad then            
                                damage = math.floor(damage * 4)
                            end
                            obj:OnDamage(damage,self.ObjOwner,AttackTypes.Painkiller,tx,ty,tz,nx,ny,nz, he)
                        end
                    end
                end        
            end        
        end
        
    elseif self.Animation == "obrot" or self.Animation == "rozkrecenie" then -- mlocka
        local fv = self.ObjOwner.ForwardVector
        local rot = Quaternion:New_FromNormalZ(fv.X,fv.Y,fv.Z) 
        local cx,cy,cz = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity) 
                        
        local b,d,tx,ty,tz,nx,ny,nz,he,e        
        for i,o in self._points do
            local sx,sy,sz = rot:TransformVector(o[1],o[2],o[3])
            b,d,tx,ty,tz,nx,ny,nz,he,e = self.ObjOwner:TraceToPoint(cx+sx,cy+sy,cz+sz)
            if b then break end
        end
        if b then
            if Game.GMode ~= GModes.MultiplayerClient then 
                local fv = self.ObjOwner.ForwardVector
                local obj = EntityToObject[e]
                if obj and obj.OnDamage then
                    local d = s.PainKnifeDamage
                    if self.ObjOwner.HasWeaponModifier then d = d * 2 end
                    obj:OnDamage(s.PainKnifeDamage,self.ObjOwner,AttackTypes.PainkillerRotor,tx,ty,tz,nx,ny,nz, he)
                    if self.ObjOwner == Player and self.ObjOwner == Player and obj._Class == "CActor" then
                        self:Snd2D("rotor_hit_enemy")
                    end                
                end
    
                local imp = s.PainKnifeImpulse
                WORLD.HitPhysicObject(he,tx,ty,tz,fv.X*imp,fv.Y*imp,fv.Z*imp)
            end
            
            if self.ObjOwner == Player then 
                if ENTITY.GetType(e) ==  ETypes.Model then
                    self:Snd2D("rotor_hit_enemy")
                else
                    self:Snd2D("rotor_hit_wall")
                end
            end            
            
        end        
    end
end
--============================================================================
function PainKiller:OnTick(delta)
    if self.r_PainHead and (not self.r_PainHead._Entity or self._changed)then
        self.BackHeadSFX(self.ObjOwner.ClientID,self.ObjOwner._Entity)    
    end    
end
--============================================================================
function PainKiller:ComboCheck()
    
    if not (self._ActionState == "Fire" and self._ComboDelay <= 0) then return end    
    
    if ENTITY.PO_IsActionState(self.ObjOwner._Entity,Actions.AltFire) then
        self._ActionState = "Idle"
        self._fire = false
        self._altfire = true
        self:AltFire(true,true)
    end

end
--============================================================================
function PainKiller:OnChangeWeapon()
    if self.r_PainHead then
        if self.ObjOwner._died then
            GObjects:ToKill(self.r_PainHead)
        end
        self.r_PainHead._back = true
        self._changed = true
        self:OnTick()
        self._changed = nil
        self.ObjOwner.State = 1
    end
    self:EnableEnergyFX(false)
    self:ForceAnim("idle",true)
    SOUND2D.Stop(self._sndRotor)
    SOUND2D.Stop(self._sndElectro)
    SOUND2D.Stop(self._sndShock)
end
--============================================================================
function PainKiller:OnFinishAnim(anim)
    if anim == "zwolnienie" or anim == "pchniecie" then
        self.ShotTimeOut = -1
        self:SetAnim("idle") 
    else
        if anim == "rozkrecenie" then
            --Game:Print("obrot")
            self:SetAnim("obrot")
       end
    end
    
    if anim == "back" or anim == "shot" then
        self._ActionState = "Idle"
    end
end
--============================================================================
function PainKiller:Render()

    if WORLD.IsGamePaused() or Player ~= self.ObjOwner then return end

    if not self._painHeadEntity or (self.r_PainHead and self.r_PainHead._back) or self._spinning then 
        if self.ObjOwner.HasWeaponModifier and self.Animation == "obrot" and not self._combo then
            self:EnableEnergyFX(true)
        else
            self:EnableEnergyFX(false)
        end
        return         
    end
        
    local disableFX = false
    local s = self:GetSubClass()
    
    local x,y,z = ENTITY.GetPosition(self._painHeadEntity)    
    local cx,cy,cz = ENTITY.PO_GetPawnHeadPos(self.ObjOwner._Entity) 
    local fv = self.ObjOwner.ForwardVector

    local d = R3D.DistToLine(x,y,z,cx,cy,cz,cx+fv.X*900,cy+fv.Y*900,cz+fv.Z*900)    
    if self.ObjOwner.HasWeaponModifier or d < s.PainRayTolerance then
        local j = MDL.GetJointIndex(self._Entity, "joint5") 
        local px,py,pz = MDL.TransformPointByJoint(self._Entity,j,0.03,0.04,0)--,0,0,0) 
        
        ENTITY.RemoveFromIntersectionSolver(self.ObjOwner._Entity)
        local b,d,tx,ty,tz,nx,ny,nz,he,e = WORLD.LineTrace(px,py,pz,x-fv.X,y-fv.Y,z-fv.Z)
        ENTITY.AddToIntersectionSolver(self.ObjOwner._Entity)
        
        local isObj = false
        if b and e then
            if Game.GMode == GModes.SingleGame then
                local obj = EntityToObject[e]
                if obj and obj.OnDamage then isObj = true end
            else
                if ENTITY.GetType(e) ==  ETypes.Model or 
                    ( ENTITY.GetType(e) ==  ETypes.Mesh and not ENTITY.IsFixedMesh(e) ) then 
                    isObj = true
                end
            end            
        end
        
        if isObj or not b then 
            R3D.DrawSprite1DOF(px,py,pz,x,y,z,0.1,R3D.RGB(255,255,255),"particles/trailpainkiller") 
            self:EnableEnergyFX(true)            
            if not SOUND2D.IsPlaying(self._sndElectro) then 
                SOUND2D.SetLoopCount(self._sndElectro,0)             
                SOUND2D.Play(self._sndElectro) 
            end             
            if isObj then
                if not SOUND2D.IsPlaying(self._sndShock) then 
                    SOUND2D.SetLoopCount(self._sndShock,0)                                 
                    SOUND2D.Play(self._sndShock) 
                end
            else
                SOUND2D.Pause(self._sndShock)                                
            end
        else
            disableFX = true
        end
    else
        disableFX = true
    end
    
    if disableFX then
        self:EnableEnergyFX(false)
        SOUND2D.Pause(self._sndElectro)
        SOUND2D.Pause(self._sndShock)
    end

end
--============================================================================
function PainKiller:StartFireSFX(pe)    
    local player = EntityToObject[pe]       
    local t = Templates["PainKiller.CWeapon"]
    local x,y,z = ENTITY.GetPosition(pe)

    if player then
        local w = player:GetCurWeapon()
        w._ComboDelay = 15
        w:SetAnim("rozkrecenie",false)
        player.State = 11
        w._ActionState = "Fire" -- to musimy recznie ustawic na kliencie
        if player == Player then
            SOUND2D.SetLoopCount(w._sndRotor,0)        
            SOUND2D.Play(w._sndRotor)    
        end
    end    
    t:SndEnt("rotor_start",pe)
    QuadSound(pe)    
end
Network:RegisterMethod("PainKiller.StartFireSFX", NCallOn.ServerAndAllClients, NMode.ReliableForSingle, "e") 
--============================================================================
function PainKiller:AltFireSFX(pe,he,combo)    
    local player = EntityToObject[pe]       
    local t = Templates["PainKiller.CWeapon"]
    
    if player then        
        local cw = player:GetCurWeapon()
        cw:ForceAnim("shot",false)                   
        cw._stakeTime = 0.75       
        cw._painHeadEntity = he
        if combo == 1 then
            cw._spinning = true
        end        
        if player == Player then
            cw._ActionState = "Shot"
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape28",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape49",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape46",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape50",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape47",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape44",false)
            MDL.SetMeshVisibility(cw._Entity,"pCylinderShape14",false)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape29",false)    
            MDL.SetMeshVisibility(cw._Entity,"kolekShape",false)
            SOUND2D.Stop(cw._sndRotor)    
            cw:EnableEnergyFX(false)
        end
    end    
    ENTITY.RegisterChild(pe,he,false,-1,false)
    t:SndEnt("head_shot",pe)
    QuadSound(pe)    
end
Network:RegisterMethod("PainKiller.AltFireSFX", NCallOn.ServerAndAllClients, NMode.Reliable, "eeb") 
--============================================================================
function PainKiller:BackHeadSFX(pe)    
    local player = EntityToObject[pe] 
    local t = Templates["PainKiller.CWeapon"]
    if player then        
        local cw = player.Weapons[1]
        if player == Player then
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape28",true)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape49",true)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape46",true)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape50",true)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape47",true)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape44",true)
            MDL.SetMeshVisibility(cw._Entity,"pCylinderShape14",true)
            MDL.SetMeshVisibility(cw._Entity,"polySurfaceShape29",true)            
            SOUND2D.Pause(cw._sndElectro)    
            SOUND2D.Pause(cw._sndShock)    
            cw._ActionState = "End"
        end
        cw:ForceAnim("back",false)
        cw.r_PainHead = nil
        cw._spinning = nil        
        cw._painHeadEntity = nil        
        player.State = 1
    end
    t:SndEnt("head_reload",pe)
end
Network:RegisterMethod("PainKiller.BackHeadSFX", NCallOn.ServerAndAllClients, NMode.ReliableForSingle, "e") 
--============================================================================
function PainKiller:FinishFireSFX(pe)    
    local player = EntityToObject[pe]       
    local t = Templates["PainKiller.CWeapon"]
    local x,y,z = ENTITY.GetPosition(pe)

    if player then
        local w = player:GetCurWeapon()
        w:SetAnim("zwolnienie",false)
        player.State = 1
        
        if player == Player then
            w._ActionState = "Idle" -- to musimy recznie ustawic na kliencie
            SOUND2D.Stop(w._sndRotor)    
            w:EnableEnergyFX(false)
        end
    end
    t:SndEnt("rotor_stop",pe)    
end
Network:RegisterMethod("PainKiller.FinishFireSFX", NCallOn.ServerAndAllClients, NMode.ReliableForSingle, "e") 
--============================================================================
