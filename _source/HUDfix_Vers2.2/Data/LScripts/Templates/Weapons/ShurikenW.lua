-------------------------------------------------------------------------------
function ShurikenW:OnCreateEntity()
    ENTITY.EnableNetworkSynchronization(self._Entity,true,false,2)
    ENTITY.SetSynchroString(self._Entity,"ShurikenW.CItem")

    self:PO_Create(BodyTypes.SphereSweep,0.001,ECollisionGroups.Noncolliding) 
    --ENTITY.EnableCollisions(self._Entity)
    ENTITY.PO_SetMovedByExplosions(self._Entity, false)
    ENTITY.PO_EnableGravity(self._Entity, false)
    self._time = 0
    self._lPos = Vector:New(self.Pos)    
    self:Client_OnCreateEntity(self._Entity)
    ENTITY.PO_SetMissile(self._Entity)
end
-------------------------------------------------------------------------------
function ShurikenW:Client_OnCreateEntity(entity)
    BindSoundToEntity(entity,"Weapons/DriverElectro/shuricane-onfly-loop",3,18,true,nil,nil,nil,nil,0.1)   
    BindTrailToEntity(entity,"trail_shuriken",-1,0,0,0)
end
-------------------------------------------------------------------------------
function ShurikenW:OnInitTemplate()
    self:ReplaceFunction("_Synchronize","Synchronize")
    self:ReplaceFunction("Synchronize","nil")
end
--============================================================================
function ShurikenW:OnPrecache()
	Cache:PrecacheParticleFX("explo_shuriken")
	Cache:PrecacheParticleFX("spark_shuriken")        
    Cache:PrecacheTrail("trail_shuriken")
end
-------------------------------------------------------------------------------
--function ShurikenW:Update()
    --self.Timeout = self.Timeout - 1
    --if self.Timeout <= 0 then   
    --    self:OnCollision(self.Pos.X,self.Pos.Y,self.Pos.Z,0,-1,0)
    --end
--end
-------------------------------------------------------------------------------
function ShurikenW:Tick(delta)    
    
    self._time = self._time + delta    
    local x,y,z = ENTITY.GetWorldPosition(self._Entity)
    
    if not self._binded then
        local vx,vy,vz,vl = ENTITY.GetVelocity(self._Entity)    
        
        ENTITY.RemoveFromIntersectionSolver(self.ObjOwner._Entity)
        ENTITY.RemoveFromIntersectionSolver(self._Entity)    
        local b,d,lx,ly,lz,nx,ny,nz,he,e = WORLD.LineTrace(self._lPos.X,self._lPos.Y,self._lPos.Z,x,y,z)            
        --Game:Print(self._lPos.X..","..self._lPos.Y..","..self._lPos.Z..","..x..","..y..","..z)
        ENTITY.AddToIntersectionSolver(self.ObjOwner._Entity)
        ENTITY.AddToIntersectionSolver(self._Entity)
        
        self._lPos:Set(x,y,z)
    
        if b then 
            if Game.GMode == GModes.SingleGame and ENTITY.IsWater(e) then 
                self:InDeathZone(lx,ly,lz,"wat")
            else
                local cg = ENTITY.PO_GetCollisionGroup(e)
                if not CheckStartGlass(he,lx,ly,lz,0.3,vx,vy,vz) and cg~=7 and cg~=8 then
                    self:OnCollision(lx,ly,lz,nx,ny,nz,e,he)
                end
            end
        end
    end
    
    self._ExplodeTimer = self._ExplodeTimer - delta
    if not ENTITY.GetPtrByIndex(self._Entity) or self._ExplodeTimer <=0 then
        if not ENTITY.GetPtrByIndex(self._Entity) and self._ox then
            x,y,z = self._ox,self._oy,self._oz
        end
        ENTITY.PO_Enable(self._Entity, false)
        Explosion(x,y,z,self.ExplosionStrength,self.ExplosionRange,self.ObjOwner.ClientID,AttackTypes.Shuriken,self.ExplosionDamage)            
        GObjects:ToKill(self)
        self.HitFX(self._Entity,0)        
    end    
    self._ox,self._oy,self._oz = x,y,z
end
-------------------------------------------------------------------------------
function ShurikenW:OnCollision(x,y,z,nx,ny,nz,e,he)

    ENTITY.SetPosition(self._Entity,x,y,z)
    
    -- instant damage
    local obj = EntityToObject[e]        
    if obj and not obj._ToKill and not obj._died and obj.OnDamage then 
        --Game:Print("*** INSTANT_DAMAGE: "..obj._Name.." ["..self.Damage.."]")
        obj:OnDamage(self.Damage,self.ObjOwner,AttackTypes.Shuriken,x,y,z,nx,ny,nz,he)
        if obj.bulletsFliesThru then
			--Game:Print("fly through")
            return
        end
        obj._GotInstantExplosion = Game.Counter
    end

    local etype = 1
    if obj and (obj._Class == "CActor" or obj._Class == "CPlayer") then etype = 2 end

    local vx,vy,vz,l  = ENTITY.GetVelocity(self._Entity)
    local dx,dy,dz  = vx/l, vy/l, vz/l
    
    
    if not self.ObjOwner.HasWeaponModifier then    
        GObjects:ToKill(self,true)
        ENTITY.SetTimeToDie(self._Entity,Cfg.StakeFadeTime)        
        if Game.GMode ~= GModes.SingleGame and etype == 2 then
            ENTITY.SetTimeToDie(self._Entity,Cfg.StakeFadeTime)        
        else
            ENTITY.SetTimeToDie(self._Entity,Cfg.StakeFadeTime)        
        end
        self._ExplodeTimer = 1
    else
        self._binded = true
    end
    
    ENTITY.PO_Remove(self._Entity)
    
    -- bind
    local joint = MDL.GetJointFromHavokBody(e,he)    
    PlayLogicSound("RICOCHET",x,y,z,8,16,Player)

    -- hit PO
    WORLD.HitPhysicObject(he,x,y,z,dx*300,dy*300,dz*300)
    
    -- fx
    ENTITY.EnableCollisions(self._Entity, false)
    self.HitFX(self._Entity,etype)
    
    ENTITY.ComputeChildMatrix(self._Entity,e,joint)
    ENTITY.RegisterChild(e,self._Entity,true,joint) 
end
-------------------------------------------------------------------------------
function ShurikenW:HitFX(se,etype)
	se = ENTITY.GetPtrByIndex(se)
	if se then
		local x,y,z = ENTITY.GetWorldPosition(se)

		if etype == 0 then
			AddPFX("explo_shuriken", 0.4 ,Vector:New(x,y,z))
			local t = Templates["DriverElectro.CWeapon"]
			t:Snd3D("shuriken_explosion",x,y,z)        
			return
		end
	       
		ENTITY.UnregisterAllChildren(se, ETypes.Trail)
		ENTITY.KillAllChildren(se, ETypes.Sound)

		if etype == 1 then
			AddPFX("spark_shuriken", 0.2 ,Vector:New(x,y,z))
			SOUND.Play3D("impacts/driver-default"..math.random(1,3),x,y,z,20,40)
		else
			AddPFX("spark_shuriken", 0.2 ,Vector:New(x,y,z))
			SOUND.Play3D("impacts/driver-body"..math.random(1,2),x,y,z,20,40)
		end    
	end
end
Network:RegisterMethod("ShurikenW.HitFX", NCallOn.AllClients, NMode.Unreliable, "eb") 
