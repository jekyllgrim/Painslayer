-- =======================================================================================
-- =======================================================================================
function Stake:OnInitTemplate()
    self:ReplaceFunction("_Synchronize","Synchronize")
    self:ReplaceFunction("Synchronize","nil")
    self.BindedActorIndex = 0
end
-- =======================================================================================
function Stake:Update()
    if self.TimeToLive then
		if self.TimeToLive > 0 then
			self.TimeToLive = self.TimeToLive - 1
		else
			GObjects:ToKill(self)
		end
	end
end
-- =======================================================================================
function Stake:OnCreateEntity()    
    
    ENTITY.EnableNetworkSynchronization(self._Entity,true,false,2)
    ENTITY.SetSynchroString(self._Entity,"Stake.CItem")
    
    if Game.GMode == GModes.SingleGame then 
        self:PO_Create(BodyTypes.FromMesh,nil,ECollisionGroups.Noncolliding)    
    else
        self:PO_Create(BodyTypes.Sphere,0.001,ECollisionGroups.Noncolliding)
    end
    
    ENTITY.RemoveFromIntersectionSolver(self._Entity)
    ENTITY.PO_SetMovedByExplosions(self._Entity, false)
    
    self:Client_OnCreateEntity(self._Entity)
    if self.ObjOwner.HasWeaponModifier then
        ENTITY.PO_SetMissile(self._Entity )
    else
        ENTITY.PO_SetMissile(self._Entity, MPProjectileTypes.Stake )
    end
end
--============================================================================
function Stake:OnPrecache()
	Cache:PrecacheParticleFX("GrenadeSmoke")
	Cache:PrecacheParticleFX("stakeHitWall")
	Cache:PrecacheParticleFX("stakeflame")        
	Cache:PrecacheItem("Grenade.CItem")     
	Cache:PrecacheItem("stake_imp.CItem")         
	Cache:PrecacheDecal('stake')         
    Cache:PrecacheTrail("trail_kolek_combo")
    Cache:PrecacheSounds("actor/hellangel/hella-throw-molotov")
    Cache:PrecacheSounds("weapons/stake/stake_onfly-loop")
    Cache:PrecacheSounds("impacts/barrel-wood-fire-loop")
end
-- =======================================================================================
function Stake:Client_OnCreateEntity(entity)    
    -- trail
    local t = ENTITY.Create(ETypes.Trail,"trail_kolek","trailName")
    ENTITY.SetPosition(t,0,0,-1.2)
    ENTITY.AttachTrailToBones(entity,t)
    WORLD.AddEntity(t)
    BindSoundToEntity(entity,"weapons/stake/stake_onfly-loop",3,18,true,nil,nil,nil,nil,0.1)
end
-- =======================================================================================
Stake.vlen = 1
Stake.ftime = 0.3
function Stake:Trace(ex,ey,ez,sx,sy,sz)
    local entity = ENTITY.GetPtrByIndex(self.BindedActorIndex)
    ENTITY.RemoveFromIntersectionSolver(self.ObjOwner._Entity)    
    ENTITY.RemoveFromIntersectionSolver(entity)
    local b,d,tx,ty,tz,nx,ny,nz,he,e = WORLD.LineTrace(ex,ey,ez,sx,sy,sz)    
    ENTITY.AddToIntersectionSolver(self.ObjOwner._Entity)    
    ENTITY.AddToIntersectionSolver(entity)
    return b,d,tx,ty,tz,nx,ny,nz,he,e
end
-- =======================================================================================
function Stake:Tick(delta)
    
    if not ENTITY.PO_IsEnabled(self._Entity) then return end    
    
    local x,y,z = ENTITY.GetPosition(self._Entity)
    local vx,vy,vz,l  = ENTITY.GetVelocity(self._Entity) -- predkosc kolka
    local dx,dy,dz  = vx/l, vy/l, vz/l -- znormalizowany kierunek                    
    
    if not self.r_BindedActor then        
        -- grenade combo
        if not self.combo then
            local s = Templates["StakeGunGL.CWeapon"]:GetSubClass()
            for i,o in GObjects.UpdateListItems do
                if not o._collided and o.BaseObj == "Grenade.CItem" and Vector:New_FromEntity(o._Entity):Dist(x,y,z) < s.ComboCatchDistance then
                    GObjects:ToKill(o)
                    self:Combo()
                end
            end
        end
        
        -- burn
        self.BurnAfterTime = self.BurnAfterTime - delta        
        if self.BurnAfterTime <= 0 and not self._burning and not self.combo then 
            self._burning = true
            self.BurnFX(self._Entity)
        end
        
        -- weapon modifier
        if not self.ObjOwner.HasWeaponModifier then
            self.ftime = self.ftime + delta        
            if not self.falling and self.ftime > 0.5 then
                ENTITY.PO_EnableGravity(self._Entity,true)
                local a = 0.35
                if self.combo then a = 0.7 end
                ENTITY.SetAngularVelocity(self._Entity, dz*a,0,-dx*a)
                self.falling = true
            end 
        end
    end

    -- wyliczam zakres trace'a
    self.Rot:FromEntity(self._Entity) 
    local x1,y1,z1 = self.Rot:TransformVector(0,0,self.vlen)
    
    local sx,sy,sz = x,y,z
    local ex,ey,ez = x+x1,y+y1,z+z1
    
    -- w przypadku duzej predkosci zapewniam ciaglosc sprawdzania
    if self._lastTraceStartPoint then
        sx,sy,sz = self._lastTraceStartPoint.X,self._lastTraceStartPoint.Y,self._lastTraceStartPoint.Z         
    else
        self._lastTraceStartPoint = Vector:New(x,y,z)
    end
    self._lastTraceStartPoint:Set(x,y,z)
    
    -- czy w cos sie wbil?    
    local b,d,tx,ty,tz,nx,ny,nz,he,e = self:Trace(sx,sy,sz,ex,ey,ez)    
    --Game:Print("sx: "..sx..", sy: "..sy..", sz: "..sz)
    --Game:Print("ex: "..ex..", ey: "..ey..", ez: "..ez)

    local cg = ENTITY.PO_GetCollisionGroup(e)
    if CheckStartGlass(he,tx,ty,tz,0.3,vx,vy,vz) or cg==7 or cg==8 then
        return
    end
       
    -- tak, w cos uderzyl
    if e then
        if Game.GMode == GModes.SingleGame and ENTITY.IsWater(e) then 
            self:InDeathZone(x,y,z,"wat")
            return
        end
    
        if self.combo then            
            local s = Templates["StakeGunGL.CWeapon"]:GetSubClass()
            local grenade = CloneTemplate("Grenade.CItem")
            grenade._Entity = self._Entity
            grenade.ExplosionStrength = s.ComboExplosionStrength
            grenade.ExplosionRange = s.ComboExplosionRange
            grenade.Damage = s.ComboExplosionDamage
            grenade.ObjOwner = self.ObjOwner
            grenade.WMGasAmount   = s.GrenadeWMGasAmount
            grenade.WMGasDamage   = s.GrenadeWMGasDamage
            grenade.WMGasRange    = s.GrenadeWMGasRange
            grenade.WMGasLifeTime = s.GrenadeWMGasLifeTime
            grenade:Explode()
            Templates["Stake.CItem"].OnHitSomething(self._Entity,e,1)            
            GObjects:ToKill(self)
            return
        end
        
        PlayLogicSound("RICOCHET",tx,ty,tz,8,16,Player)
        -- sprawdzam czy to entity posiada obiekt logiczny                
        local obj = EntityToObject[e]             
        if obj then
            --MsgBox(obj._Name)
        
            -- sprawdzam czy trafilem w cialo czy w jakis odpadajacy element, np kosa czy naramiennik                
            if  (obj._Class == "CActor" or obj._Class == "CPlayer") and not obj.stakeCanHitNotLinkedJoint then
                local joint = MDL.GetJointFromHavokBody(e,he)                
                local cb = MDL.JointsLinked(e,joint,MDL.GetJointIndex(e, "root"))
                if not cb then cb = MDL.JointsLinked(e,joint,MDL.GetJointIndex(e, "k_sub_root")) end -- stare modele
                if not cb and not obj.DontTestRootLink then 
                    -- wyjmuje ten obiekt z havoka i ponawiam trace'a
                    local ohe = he
                    PHYSICS.RemoveHavokBodyFromIS(ohe,true)
                    b,d,tx,ty,tz,nx,ny,nz,he,e = self:Trace(ex,ey,ez,sx,sy,sz)
                    PHYSICS.RemoveHavokBodyFromIS(ohe,false)                         
                    --Game:Print("przelatuje: "..joint.." "..MDL.GetJointName(e,joint)) 
                    if not b or not (e and EntityToObject[e]) then return end -- przelatuje  
                    obj = EntityToObject[e]
                    --MsgBox(obj._Class)
                end
            end
            
            local d = self.Damage
            if self._burning then d = self.BurningDamage end
			-- zadaje obrazenia
            if obj.OnDamage then
                obj:OnDamage(d,self.ObjOwner,AttackTypes.Stake,tx,ty,tz,nx,ny,nz,he)  
            end

			if obj.bulletsFliesThru then
				--Game:Print("kolek przelatuje")
				return
			end
            -- jezeli zabilem Actora
            if (obj._Class == "CActor" or obj._Class == "CPlayer") and obj._died then
       
                --Game:Print(obj._Name)
                if self.r_BindedActor then Game:Print(self.r_BindedActor._Name) end
                if obj._gibbed then -- przy gibie nic nie robie
                    GObjects:ToKill(self)
                    return
                end
                if obj._dontPinStake then
					RawCallMethod(CItem.DestroyItemFX,self._Entity,"Stake.CItem",0)
                    GObjects:ToKill(self)
                    return
				end

                local range = 10                
                -- przesuwam srodek kolka w punkt, w ktory sie wbil
                if not obj.Pinned and not obj._pinnedByAI then
                    --Game:Print("przesuwam")
					PlaySound3D('impacts/stake-body'..math.random(1,2),tx,ty,tz,9,33)
                    --Game:Print(dx..", "..dy..", "..dz)
                    x,y,z = tx-dx*0.5,ty-dy*0.5,tz-dz*0.5
                    ENTITY.SetPosition(self._Entity,x,y,z)                    
                else
                    range = 1.8 -- jezeli jest juz przybity to skracam zakres szukania sciany
                end
                
                local hx,hy,hz = PHYSICS.GetHavokBodyPosition(he)
                self.ox,self.oy,self.oz = x-hx,y-hy,z-hz
                --Game:Print(self.ox..", "..self.oy..", "..self.oz)
                
                -- sprawdzam czy za nim jest sciana
                ENTITY.RemoveFromIntersectionSolver(e)
                local b,d,tx1,ty1,tz1,nx,ny,nz,he1,e1 = WORLD.LineTrace(tx,ty,tz,tx+dx*range,ty+dy*range,tz+dz*range)
                ENTITY.AddToIntersectionSolver(e)
                                                                
                -- bede przybijal obiekt do sciany    
                if b and ENTITY.IsFixedMesh(e1) then
					--Game:Print("przybicie")
                    ENTITY.SetVelocity(self._Entity,vx/2,vy/2,vz/2) -- zmniejszam predkosc kolka
                    --PHYSICS.CreateRigidConstraint(tx,ty,tz,ENTITY.PO_GetPhysicsBody(self._Entity),he)                                                        
                    --PHYSICS.CreateSpringConstraint(ENTITY.PO_GetPhysicsBody(self._Entity),tx,ty,tz,he,tx,ty,tz,0,0,0)                          
                    self.r_BindedActor = obj
                    self.BindedActorIndex = ENTITY.GetIndex(e)
                    self.he = he
                    self.vlen = self.vlen + 0.3 -- wydluzam traca                    
                    -- jezeli juz wisi na scianie to nadaje lekki impulse bo nie bede ciagnal
                    if obj.Pinned then
						--Game:Print("przybicie juz pinned")
                        WORLD.HitPhysicObject(he,tx,ty,tz,dx*500,dy*500,dz*500)
                    end                    
                    return 
                end                 
            end
        end
        
        local mode = 0

        -- wylaczam fizyke
        ENTITY.PO_Enable(self._Entity,false)            

        -- przesuwam srodek kolka w punkt, w ktory sie wbil
        if obj and (obj._Class == "CActor" or obj._Class == "CPlayer") then -- aktora przebija
            ENTITY.SetPosition(self._Entity,tx,ty,tz)
        else
            -- przesuwam czubek kolka w punkt, w ktory sie wbil
            ENTITY.SetPosition(self._Entity,tx-dx/2,ty-dy/2,tz-dz/2)                
        end
        
        -- jezeli ciagnal za soba actora to go pinujemy
        if self.r_BindedActor then
            if self._setVel then
                local x,y,z = ENTITY.GetPosition(self._Entity)
                PHYSICS.SetHavokBodyPosition(self.he,x+self.ox,y+self.oy,z+self.oz)
            end
            --Game:Print(self.ox..", "..self.oy..", "..self.oz)
			PHYSICS.PinHavokBody(self.he) 
			self.r_BindedActor.Pinned = true
			PlaySound3D('weapons/stake/stake_hit'..math.random(1,2),tx,ty,tz,12)            
        end
                
        -- przy trafieniu w actora lub playera rozwalam kolek i odpycham pawn'a
        if obj and (obj._Class == "CActor" or obj._Class == "CPlayer") and not obj._died then
            local ib =  self.EnemyThrowBack
            local iu =  self.EnemyThrowUp
            if (not obj.NeverMove and not obj._disableHits) or obj.Health <= 0 then
				ENTITY.PO_Hit(e,tx,ty,tz,dx*ib,dy*ib+iu,dz*ib)
				if obj._Class == "CPlayer" then
					ENTITY.PO_SetPlayerShocked(e)
				end
			end
            --Game:Print(dx*ib.." "..dz*ib)
            mode = 1
        else
            ENTITY.PO_Remove(self._Entity)
            -- przywiazuje do trafionego obiektu
            local joint = MDL.GetJointFromHavokBody(e,he)
            ENTITY.ComputeChildMatrix(self._Entity,e,joint)
            ENTITY.RegisterChild(e,self._Entity,true,joint)                            
        end                        
                
        Templates["Stake.CItem"].OnHitSomething(self._Entity,e,mode)                                        

        -- kasuje obiekt logiczny kolka
        GObjects:ToKill(self,true)     

        if mode == 1 then
            ENTITY.Release(self._Entity)            
        else
            -- wlaczam autodestrukcje entity kolka za 10 sec
            if Game.GMode == GModes.SingleGame then
                ENTITY.SetTimeToDie(self._Entity,Cfg.StakeFadeTime)
            else
                ENTITY.SetTimeToDie(self._Entity,Cfg.StakeFadeTime)
            end
        end
        
        -- nadaje impuls trafionemu entity
        WORLD.HitPhysicObject(he,tx,ty,tz,dx*800,FRand(1,700),dz*800)
        return
    end
    
    -- jezeli ciagnie za soba actora to nadajemy mu predkosc (o ile nie zginal w miedzyczasie)
    if self.r_BindedActor then
        --Game:Print(self.BindedActorIndex)
        local entity = ENTITY.GetPtrByIndex(self.BindedActorIndex)
        if not entity then 
            --Game:Print("koniec???")
            GObjects:ToKill(self)
            return
        else
            --Game:Print(self._Name.."ciagnie")
            --if not self.r_BindedActor.Pinned then -- jezeli juz wisi na scianie to nie nadajemy mu predkosci
                
                -- ustawiamy pozycje temu kawalkowi ragdolla 
                local obj = EntityToObject[entity]
                if obj and (obj.Pinned or obj._pinnedByAI) then
				else
					--Game:Print(self._Name.."ciagnie i set pos")
					MDL.ApplyVelocitiesToAllJoints(entity,vx*0.7,vy*0.7,vz*0.7,0,0,0)
					PHYSICS.SetHavokBodyPosition(self.he,x+self.ox,y+self.oy,z+self.oz)    
                    self._setVel = true
                end
                
            --end
        end
    end

end
-- =======================================================================================
function Stake:OnHitSomething(se,e,mode)
    if not se then return end
        
    --Game:Print("STAKE ON HIT SOMETHING")
    --ENTITY.SetPosition(se,x,y,z)                    
    
    if mode == 1 then
        -- roztrzaskal sie
        RawCallMethod(CItem.DestroyItemFX,se,"Stake.CItem",0)
    else        
        
        ENTITY.UnregisterAllChildren(se,ETypes.Trail)        
        ENTITY.KillAllChildrenByName(se,"weapons/stake/stake_onfly-loop")
        if ENTITY.KillAllChildrenByName(se,"stakeflame") then -- burning?
            -- add smoke
            local smokefx = AddPFX("GrenadeSmoke",1)
            PARTICLE.SetParentOffset(smokefx,0,0,0.4)
            ENTITY.RegisterChild(se,smokefx)       
        end
        
    end

    -- decal on the wall
    if e then
		if ENTITY.IsFixedMesh(e) then
			local x,y,z = ENTITY.GetPosition(se)
			local rot = Quaternion:New_FromEntity(se)
			local x1,y1,z1 = rot:TransformVector(0, 0, -0.4)
			local x2,y2,z2 = rot:TransformVector(0, 0, 0.8)
	        
			PlaySound3D('impacts/stake-default'..math.random(1,5),x,y,z,12,36,false)

			ENTITY.RemoveFromIntersectionSolver(se)        
			local b,d,tx,ty,tz,nx,ny,nz,he,e = ENTITY.PO_LineTrace(e,x+x1,y+y1,z+z1,x+x2,y+y2,z+z2)
			--local b,d,tx,ty,tz,nx,ny,nz,he,e = WORLD.LineTrace(x+x1,y+y1,z+z1,x+x2,y+y2,z+z2)
			if b then 
				local px,py,pz = tx+nx*0.3,ty+ny*0.3,tz+nz*0.3
				if e and mode == 0 then ENTITY.SpawnDecal(e,'stake',tx,ty,tz,nx,ny,nz) end            
				local r = Quaternion:New_FromNormal(nx,ny,nz)                
				if Game.GMode == GModes.SingleGame then 
					local sizes = {0.7,1.4}
					for i=1,3 do
						local vx,vy,vz  = r:TransformVector(FRand(-12,12),FRand(12,25),FRand(-12,12)) 
						local ke = AddItem("stake_imp.CItem",sizes[math.random(1,2)],Vector:New(px+FRand(-0.1,0.1),py+FRand(-0.1,0.1),pz+FRand(-0.1,0.1)),false,Quaternion:New_FromNormal(-vx,-vy,-vz))
						ENTITY.SetVelocity(ke,vx,vy,vz)
						ENTITY.SetTimeToDie(ke,FRand(1,2))
					end
				end
				AddPFX("stakeHitWall",0.25,Vector:New(px,py,pz),r)
			end
		else
			
			local obj = EntityToObject[e]
			--if obj then
				--Game:Print("STAKE ON HIT SOMETHING?")
			--end
			if obj and obj.Health and (obj.Health > 0 or obj._enabledRD or obj._gibbed)then
				if obj._Class == "CActor" and obj._enabledRD then
					--Game:Print("STAKE ON HIT SOMETHING:body")
					PlaySound3D('impacts/stake-body'..math.random(1,2),x,y,z,12,36,false)
				elseif obj.s_SubClass and obj.s_SubClass.SoundsDefinitions and obj.s_SubClass.SoundsDefinitions.SoundHitByBullet then
					if obj.s_SubClass.SoundsDefinitions.SoundHitByBullet.samples[1] == "bullet-metal" then
						--Game:Print("STAKE ON HIT SOMETHING:metal")
						PlaySound3D('impacts/stake-shield'..math.random(1,3),x,y,z,12,36,false)
					else
						if not obj.SoundHitByBulletMiniGunOnly then
							obj:PlaySound("SoundHitByBullet")
						end
					end
				else
					--Game:Print("STAKE ON HIT SOMETHING:rest")
					PlaySound3D('impacts/stake-default'..math.random(1,5),x,y,z,12,36,false)
				end
			end
		end
    end
    
end
Network:RegisterMethod("Stake.OnHitSomething", NCallOn.AllClients, NMode.Reliable, "eeb") 
-- =======================================================================================
function Stake:BurnFX(se)
    local x,y,z = ENTITY.GetPosition(se)
    local fxFire = AddPFX("stakeflame",0.25)
    ENTITY.RegisterChild(se,fxFire)
    PARTICLE.SetParentOffset(fxFire,0,0,1)
    
    BindSoundToEntity(se,"actor/hellangel/hella-throw-molotov",3,18)    
    BindSoundToEntity(se,"impacts/barrel-wood-fire-loop",3,18,true,nil,nil,nil,nil,0.1)             
end
Network:RegisterMethod("Stake.BurnFX", NCallOn.AllClients, NMode.Reliable, "e") 
-- =======================================================================================
function Stake:_EditRender()
    
    self.Rot:FromEntity(self._Entity) 
    local x,y,z = ENTITY.GetPosition(self._Entity)
    local x1,y1,z1 = self.Rot:TransformVector(0,0,1)
    local x2,y2,z2 = self.Rot:TransformVector(0,0,0)
    
    R3D.RenderBox(x+x1-0.1,y+y1-0.1,z+z1,x+x1+0.1,y+y1+0.1,z+z1+0.1,2222)        
    R3D.RenderBox(x+x2-0.1,y+y2-0.1,z+z2,x+x2+0.1,y+y2+0.1,z+z2+0.1,1112)               
    
end
-- =======================================================================================
function Stake:Combo()
    self.combo = true
    local g = ENTITY.Create(ETypes.Mesh,"../Data/Items/granat.dat","polySurfaceShape234",6)        
    local rot = Quaternion:New_FromEuler(-math.pi/2,0,0)
    WORLD.AddEntity(g)
    rot:ToEntity(g)
    ENTITY.SetPosition(g,0,0,9)        
    ENTITY.RegisterChild(self._Entity,g,true) 
    -- trail combo
    ENTITY.UnregisterAllChildren(self._Entity,ETypes.Trail)        
    local t = ENTITY.Create(ETypes.Trail,"trail_kolek_combo","trailName")
    ENTITY.SetPosition(t,0,0,-1.2)
    ENTITY.AttachTrailToBones(self._Entity,t)
    WORLD.AddEntity(t)    
    local t = Templates["StakeGunGL.CWeapon"]
    t:SndEnt("combo_shot",self._Entity)
end
-- =======================================================================================
