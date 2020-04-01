--============================================================================
-- Weapon class
--============================================================================
CWeapon = 
{
    Model = "shotgun",
    Pos = Vector:New(0,0,0),
    Ang = Vector:New(0,0,0),
    Scale = 1,
    ShotTimeOut = -1,
    AmmoType1 = "",
    AmmoType2 = "",
    Animation = "",
    ObjOwner = nil,
    Type = 0,
    _ActionState = "Idle",
    _CurAnimLength = 0,
    _CurAnimTime = 0,
    _LastAnimTime = -1,
--    _MeshEffect = nil,
    _Class = "CWeapon",
    _fire = false,
    _altfire = false,
    FireCount = 0,
    AltFireCount = 0,
    ComboFireCount = 0,
}
Inherit(CWeapon,CObject)
--============================================================================
function CWeapon:RestoreFromSave()
    self._CurAnimLength = MDL.GetAnimLength(self._Entity, self._CurAnimIndex)
    self._lastTime = nil
end
--============================================================================
function CWeapon:Delete()
    if self.OnReleaseEntity then self:OnReleaseEntity() end
    ENTITY.Release(self._Entity)
    --ENTITY.Release(self._MeshEffect)
    self._Entity = nil
end
--============================================================================
function CWeapon:ForceAnim(anim,loop,speed,bt)
    self.Animation = ""
    self:SetAnim(anim,loop,speed,bt)
end
--============================================================================
function CWeapon:GetSubClass()
    if Game.GMode ~= GModes.SingleGame then
        return self.s_MPSubClass
    end
    return self.s_SubClass
end
--============================================================================
function CWeapon:SetAnim(anim,loop,speed,blendtime)
    if anim == self.Animation then return end

    --Game:Print(anim)
    
    local s = self:GetSubClass()
    if s and s.Animations and s.Animations[anim] then
        if not speed and s.Animations[anim][1] then 
            speed = s.Animations[anim][1]
        end
        if not blendtime and self.s_SubClass.Animations[anim][1] then 
            blendtime = s.Animations[anim][2]
        end
    end

    if not speed then speed = 1 end
    if not blendtime then blendtime = 0.5 end

	speed = speed / Game.ReloadSpeedFactor
    
    self.Animation = anim    
    self._CurAnimIndex = MDL.SetAnim(self._Entity,anim,loop,speed,blendtime)    
    self._CurAnimLength = MDL.GetAnimLength(self._Entity,self._CurAnimIndex)    
    self._LastAnimTime = 0
end
--============================================================================
function CWeapon:Apply(old)    
    --if not (self.Template and self.Template~="") then 
    --    self.s_SubClass = SubClasses["CWeapon"][self.Model]    
    --end
    
    if not old or old.Model ~= self.Model then 
        ENTITY.Release(self._Entity)
        self._Entity = ENTITY.Create(ETypes.Model,self.Model,"",self.Scale*0.1,true)    
        ENTITY.EnableGunPass(self._Entity,true)
        if self.OnCreateEntity then self:OnCreateEntity(self._Entity) end
        --self._MeshEffect = ENTITY.Create(ETypes.Mesh,"../Data/Items/ogien.dat","trans_fajerekShape",0.16,true)
        --WORLD.AddEntity(self._MeshEffect,true)
        ENTITY.EnableDraw(self._Entity,Cfg.ViewWeaponModel)
        self:LoadHUDData()
        self.FireCount = 0
		self.AltFireCount = 0
		self.ComboFireCount = 0
    end   
end
--============================================================================
function CWeapon:OnChangeWeapon()
end
--============================================================================
function CWeapon:HitTest(target)    
end
--============================================================================
function CWeapon:LoadHUDData()
end
--============================================================================
function CWeapon:DrawHUD(delta)
end
--============================================================================
function CWeapon:InterpretAction()    
    if self.ObjOwner._died then return end    
    local entity = self.ObjOwner._Entity
      
    -- special fire (fast combo - alt and fire without timeout)
    local specialfire = false    
    if self._altfire and ENTITY.PO_IsActionState(entity,Actions.Fire) and not self.ObjOwner._SwitchToWeapon and
       self.ObjOwner._CurWeaponIndex == 2 then -- na razie tylko dla shotguna
        specialfire = true 
        self._altfire = false        
    end    
    
    
    if not WEAPON_PREDICTION then
        if self.ComboCheck then self:ComboCheck() end
    end
        
    --Game:Print(self.ShotTimeOut)
    if specialfire or ( self.ShotTimeOut * Game.ReloadSpeedFactor < 0 ) then                       
        if not ENTITY.PO_IsActionState(entity,Actions.Fire) and self._fire then
            local oldstate = self._ActionState
            self._ActionState = "Idle"
            self._fire = false
            if not WEAPON_PREDICTION then
                if  self.OnFinishFire then self:OnFinishFire(oldstate) end
            end
        end        
                
        if not ENTITY.PO_IsActionState(entity,Actions.AltFire) and self._altfire then
            local oldstate = self._ActionState
            self._ActionState = "Idle"          
            self._altfire = false
            if not WEAPON_PREDICTION then
                if self.OnFinishAltFire then self:OnFinishAltFire(oldstate) end           
            end
        end        
        
        if self._combo and not (ENTITY.PO_IsActionState(entity,Actions.Fire) and ENTITY.PO_IsActionState(entity,Actions.AltFire)) then
            self._ActionState = "Idle"          
            self._combo = false            
        end
        
        if (specialfire or self._ActionState == "Idle" or self._ActionState == "End") and not self.ObjOwner._jammed then
            if not specialfire and ENTITY.PO_IsActionState(entity,Actions.ComboFire) then 
                local of = self._combo
                self._ActionState = "Combo"
                if not WEAPON_PREDICTION then
                    self._combo = self:Combo(not of)
                end
                if self._combo then self.ComboFireCount = self.ComboFireCount + 1 end
                return
            end
            if ENTITY.PO_IsActionState(entity,Actions.Fire) then 
                local of = self._fire
                                
                self._fire = true                                
                
                if WEAPON_PREDICTION then
                    if self.Client_FirePrediction then 
                        self:Client_FirePrediction(not of) 
                    end
                else                
                    self._ActionState = "Fire"
                    self:Fire(not of)
                end
                
                self.FireCount = self.FireCount + 1
                return
            end        
            if not specialfire and ENTITY.PO_IsActionState(entity,Actions.AltFire ) then 
                local of = self._altfire
                
                self._altfire = true
                
                if WEAPON_PREDICTION then
                    if self.Client_AltFirePrediction then 
                        self:Client_AltFirePrediction(not of) 
                    end
                else                
                    self._ActionState = "AltFire"
                    self:AltFire(not of)
                end
                
                self.AltFireCount = self.AltFireCount + 1
                return
            end
        end        
    end   
end
--============================================================================
function CWeapon:ClientTick()
    if self.OnClientTick then self:OnClientTick(delta) end
end
--============================================================================
function CWeapon:Update()
    if self.OnUpdate then self:OnUpdate() end
end
--============================================================================
function CWeapon:Combo()    
    self._ActionState = "Idle"
    self._combo = false
    return false
end
--============================================================================
function CWeapon:Tick(delta)    
    
    local tm = INP.GetTime()
    if not self._lastTime then self._lastTime = tm end
    self.ShotTimeOut = self.ShotTimeOut - (tm - self._lastTime) *30 / Game.ReloadSpeedFactor
    self._lastTime = tm 
    
    if self.ShotTimeOut < -1 and self._ActionState == "Idle" then
        self._pfx = nil
        if self.ObjOwner._Walking then            
            self:SetAnim("walk") 
        else
            self:SetAnim("idle") 
        end        
    end
    if self.ShotTimeOut < 0 then 
        self.ShotTimeOut = -2
    end

    if self.OnFinishAnim then
        self._CurAnimTime = MDL.GetAnimTime(self._Entity,self._CurAnimIndex)
        if  self._CurAnimTime < self._LastAnimTime or self._CurAnimTime == self._CurAnimLength then 
            if self._CurAnimTime ~= self._LastAnimTime then
                self:OnFinishAnim(self.Animation)
            end
        end
        self._LastAnimTime = self._CurAnimTime
    end    
    if self.OnTick then self:OnTick(delta) end
end
--============================================================================
--function CWeapon:OnFinishAnim(anim)    
--    if anim ~= "idle" then
--        MsgBox(anim)
--    end
--end
--============================================================================
--function CWeapon:OnFinishFire()    
--    MsgBox("finish fire")
--end
--============================================================================
--function CWeapon:OnFinishAltFire()    
--    MsgBox("finish altfire")
--end
--============================================================================
function CWeapon:GetTopPos()
    local cx,cy,cz = CAM.GetPos()     
    local fx,fy,fz = CAM.GetForwardVector()   
    local rx,ry,rz = CAM.GetRightVector()   
    local ux,uy,uz = CAM.GetUpVector()   
    
    local x = cx + fx*0.22 + rx*0.034 + ux*-0.05
    local y = cy + fy*0.22 + ry*0.034 + uy*-0.05
    local z = cz + fz*0.22 + rz*0.034 + uz*-0.05
    return x,y,z
end
--============================================================================
function CWeapon:PositionParticle(pfx,pe)    
    if 1 == 1 then return end
    
    -- to nie dziala bo particle jest automatycznie kasowany po skonczeniu
    -- trzeba bindowac go innym mechanizmem, juz przy stworzeniu
    if pfx then
        local x,y,z 
        if pe == Player._Entity then
            x,y,z = self:GetTopPos() 
        else
            --x,y,z = ENTITY.GetPosition(pe)            
            x,y,z = BindPoint(pe,-0.03,1.45,0.15)
        end
        ENTITY.SetPosition(pfx,x,y,z)
        ENTITY.SetRotationCAM(pfx,0.15,0.0,0.15)
    end
end
GX = 0.39
GY = -0.49
GZ = -1.2
GAX = 0
GAY = -1.57
GAZ = -0.03
--============================================================================
function CWeapon:ClientTick2(delta)
    local back = 0.3 + (Cfg.WeaponFOV/100)
    if Cfg.FOV > 85 then back = -((Cfg.FOV - 110)/150 - (Cfg.WeaponFOV)/100) end
    --MDL.ResetFrame(self._Entity)
    ENTITY.SetPosAndRotRelativeToCamera(self._Entity,self.Pos.X,self.Pos.Y,self.Pos.Z-back,self.Ang.X,self.Ang.Y,self.Ang.Z)  
    --if self.ObjOwner._CurWeaponIndex == 7 then
    --    ENTITY.SetPosAndRotRelativeToCamera(self._Entity,GX,GY,GZ,GAX,GAY,GAZ)  
    --end
    --ENTITY.SetPosAndRotRelativeToCamera(self._Entity,GX,GY,GZ,GAX,GAY,GAZ)  
    --local j = MDL.GetJointIndex(self._Entity,"joint5") 
    --local x,y,z,rw,rx,ry,rz = MDL.TransformPointByJoint(self._Entity,j,-1.75,0.2,0.1,3.14,0.0,0.0)  
    --ENTITY.SetPosition(self._MeshEffect,x,y,z)    
    --Quaternion:New(rw,rx,ry,rz):ToEntity(self._MeshEffect)
    
    --ENTITY.SetPosAndRotRelativeToCamera(self._MeshEffect,self.Pos.X,self.Pos.Y,self.Pos.Z,self.Ang.X,self.Ang.Y,self.Ang.Z)  
    --ENTITY.SetPosAndRotRelativeToCamera(self._MeshEffect,0.3, -0.2 ,-1.3,0,1.45,0)    
    --self:PositionParticle(self._pfx,self.ObjOwner._Entity)
    if self.OnTick2 then self:OnTick2(delta) end
end
--============================================================================
MuzzleFlash = Clone(CProcess)
MuzzleFlash.Pos = Vector:New(0,0,0)
MuzzleFlash.TimeOut = 0.14
MuzzleFlash._Joint = -1
MuzzleFlash._Obj = -1
--============================================================================
function MuzzleFlash:Init(obj,jointname,ox,oy,oz,size)
    self._Joint = MDL.GetJointIndex(obj._Entity,jointname) 
    self.Pos = Vector:New(ox,oy,oz)
    if not size then size = 1 end
    self.Size = size
    self._Obj = obj
end
--============================================================================
function MuzzleFlash:Render(delta)
    self.TimeOut = self.TimeOut - delta
    if self.TimeOut < 0 then 
        GObjects:ToKill(self)
    else
        local x,y,z = MDL.TransformPointByJoint(self._Obj._Entity,self._Joint,self.Pos.X,self.Pos.Y,self.Pos.Z) --z,y,x
        local tex = "Items/"..math.random(1,3)
        if self._tex then 
            tex = self._tex .."_0"..math.random(0,4)
        end
        local rot = FRand(0,6.28)
        if self._rot then rot = self._rot end
        R3D.DrawSprite(x,y,z,FRand(0.6,0.6)*self.Size,rot,Color:New(150,150,150,255):Compose(),tex)
    end
end
--============================================================================
function CWeapon:MuzzleFlash(jointname,ox,oy,oz,size,tex,rot)
    if Cfg.ViewWeaponModel == false then return end
    local p = GObjects:Add(TempObjName(),Clone(MuzzleFlash))
    p._tex = tex
    p._rot = rot
    p:Init(self,jointname,ox,oy,oz,size)
end
--============================================================================
function CWeapon:ClientRender(delta)
    if self._Entity and not Game.IsDemon and INP.Key(Keys.E) ~= 2 then        
        --R3D.ClearZBuffer()
        --ENTITY.Draw(self._MeshEffect)
        --ENTITY.Draw(self._Entity)
    end
end
--============================================================================
