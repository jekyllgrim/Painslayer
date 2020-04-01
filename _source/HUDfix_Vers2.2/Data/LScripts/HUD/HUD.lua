--============================================================================
Hud = 
{
    Enabled = true,
    DrawEyes = false,
    TickCount = 0,
    _matCrosshair = -1,
    _matAmmo = -1,
    _matGameOver = -1,
    _matHealth = -1,
    _matArmor = -1,
    _matArmorNormal = -1,
    _matArmorRed = -1,
    _matArmorGreen = -1,
    _matArmorYellow = -1,
    _matHead = -1,
    _matEyes = -1,
    _matDemons = -1,
    _matNumbers = -1,
    _matLifeIcon = -1,
    _matShieldIcon = -1,

	_matHUDTop = -1,
	_matHUDLeft = -1,
	_matHUDRight = -1,

	_matMoney = -1,
	_matPentagram = -1,
	_matStar = -1,

	_matBossFace = -1,
	_matBossAlastor = -1,
	_matBossGiant = -1,
	_matBossSwamp = -1,
	_matBossThor = -1,
	_matBossAlastor2 = -1,
	_matBossSpider = -1,
	_matCompassArrow = -1,
	_matCompassArrShadow = -1,
	_matCompassArrGlow = -1,
	_matCompassDown = -1,
	_matCompassDownOn = -1,
	_matCompassUp = -1,
	_matCompassUpOn = -1,
	_glowTime = 0.0,
	_glowDir = 0,
	_glowTrans = 0,
	_glowStart = 0.0,
	_glowTime2 = 0.0,
	_glowDir2 = 0,
	_glowTrans2 = 0,
	_glowStart2 = 0.0,
	showCompassArrow = true,
	r_closestEnemy = nil,
	_nearestCheckPoint = nil,
	_nearestIsCheckpoint = false,
	_lastTime = 0.0,

	_matDigits = {},
	_matDigitsRed = {},
	
--    _matShotgunIcon = -1,
--    _matGrenadeIcon = -1,

	_lastCross = -1,
    CrossScale = 1,

	_matModifier = -1,
	
	_showSPStats = false,

	-- MP messages
--	mpMsgColor = { 255, 255, 255 },
	mpMsgColor = { 255, 186, 122 },
	mpMsgPosition = { 0, 0 },
	mpMsgFont = "courbd",
--	mpMsgFontTex = "HUD/font_texturka",
	mpMsgFontTex = "",
	mpMsgFontSize = 20,
	
	_matDemonCross = nil,

	_crosshairs = {	"HUD/crosshair", "HUD/crossy/cross1", "HUD/crossy/cross2", "HUD/crossy/cross3",
				"HUD/crossy/cross4", "HUD/crossy/cross5", "HUD/crossy/cross6", "HUD/crossy/cross7",
				"HUD/crossy/cross8", "HUD/crossy/cross9", "HUD/crossy/cross91", "HUD/crossy/cross92",
				"HUD/crossy/cross93", "HUD/crossy/cross94", "HUD/crossy/cross95", "HUD/crossy/cross96",
				"HUD/crossy/cross97", "HUD/crossy/cross98", "HUD/crossy/cross99", "HUD/crossy/cross991",
				"HUD/crossy/cross992", "HUD/crossy/cross993", "HUD/crossy/cross994", "HUD/crossy/cross995",
				"HUD/crossy/cross996", "HUD/crossy/cross997", "HUD/crossy/cross998", "HUD/crossy/cross999",
				"HUD/crossy/cross9991", "HUD/crossy/cross9992", "HUD/crossy/cross9993", "HUD/crossy/cross9994" },

	_colors = { R3D.RGB(0,0,255) },
	
	_showCheckPointInfo = false,
	_showFPS = false,
	
	_showPacketLoss = false,
	_matPacketLoss = nil,

	_mpStatsDrawFunc = MPSTATS.Draw,
	
	_overlayMessage = "",
	_overlayMsgStart = 0,
}
--============================================================================
function Hud:LoadData()
--    self._matAmmo = MATERIAL.Create("HUD/waz_P 75 %transp", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
--    self._matHealth = MATERIAL.Create("HUD/waz_L 75 %transp", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

	self._matHealth = MATERIAL.Create("HUD/energia", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matArmorNormal = MATERIAL.Create("HUD/armor", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matArmorRed = MATERIAL.Create("HUD/armor_czerwony", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matArmorGreen = MATERIAL.Create("HUD/armor_zielony", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matArmorYellow = MATERIAL.Create("HUD/armor_zolty", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	
	self._matArmor = self._matArmorNormal

	if Cfg.Crosshair then
		if Cfg.Crosshair == 0 then Cfg.Crosshair = 1 end
		self._matCrosshair = MATERIAL.Create(self._crosshairs[Cfg.Crosshair], TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._lastCross = self._crosshairs[Cfg.Crosshair]
	else
		self._matCrosshair = MATERIAL.Create("HUD/crosshair", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._lastCross = "HUD/crosshair"
	end
    self._matHead = MATERIAL.Create("HUD/czaszka sama", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matEyes = MATERIAL.Create("HUD/oczy_do_czachy copy", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matDemons = MATERIAL.Create("HUD/demon count 64 % transp", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matDemonsGrey = MATERIAL.Create("HUD/demon count szary30 % transp", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matNumbers = MATERIAL.Create("HUD/cyfry", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matLifeIcon = MATERIAL.Create("HUD/eskulap", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matShieldIcon = MATERIAL.Create("HUD/tarcza", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
    self._matGameOver = MATERIAL.Create("HUD/gejm_ouwer", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

	if not Cfg.BlackEdition then
		self._matHUDTop = MATERIAL.Create("HUD/hud_top", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._matHUDLeft = MATERIAL.Create("HUD/hud_left", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._matHUDRight = MATERIAL.Create("HUD/hud_right", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	else
		self._matHUDTop = MATERIAL.Create("HUD/hud_top_black", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._matHUDLeft = MATERIAL.Create("HUD/hud_left_black", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._matHUDRight = MATERIAL.Create("HUD/hud_right_black", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	end

	self._matMoney = MATERIAL.Create("HUD/ikona_dusze_zlota", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matPentagram = MATERIAL.Create("HUD/pentagram", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matStar = MATERIAL.Create("HUD/gwiazdka", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

	for i=0,9 do
		self._matDigits[i+1] = MATERIAL.Create("HUD/numbers/"..i, TextureFlags.NoLOD + TextureFlags.NoMipMaps)
		self._matDigitsRed[i+1] = MATERIAL.Create("HUD/numbers/"..i.."_cz", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	end

	self._matBossFace = MATERIAL.Create("HUD/hud_boss", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matBossAlastor = MATERIAL.Create("HUD/kompas/icon_alastor", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matBossGiant = MATERIAL.Create("HUD/kompas/icon_giant", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matBossSwamp = MATERIAL.Create("HUD/kompas/icon_swamp", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matBossThor = MATERIAL.Create("HUD/kompas/icon_thor", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matBossAlastor2 = MATERIAL.Create("HUD/kompas/icon_alastor2", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matBossSpider = MATERIAL.Create("HUD/kompas/icon_spider", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassArrow = MATERIAL.Create("HUD/kompas/strzalka_kompas", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassArrShadow = MATERIAL.Create("HUD/kompas/strzalka_kompas_cien", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassArrGlow = MATERIAL.Create("HUD/kompas/strzalka_glow_next", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassDown = MATERIAL.Create("HUD/kompas/wsk_dol_wyl", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassDownOn = MATERIAL.Create("HUD/kompas/wsk_dol_wl", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassUp = MATERIAL.Create("HUD/kompas/wsk_gora_wyl", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._matCompassUpOn = MATERIAL.Create("HUD/kompas/wsk_gora_wl", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
	self._arrowRot = 0.0
	
	self._matPacketLoss = MATERIAL.Create("HUD/packet_loss", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

	self._matDemonCross = MATERIAL.Create("HUD/crossy/crosshair_demon_morph", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

	self._matModifier = MATERIAL.Create("HUD/modifier", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

--    self._matShotgunIcon = MATERIAL.Create("HUD/kulka_szotganowa", TextureFlags.NoLOD + TextureFlags.NoMipMaps)
--    self._matGrenadeIcon = MATERIAL.Create("HUD/raketa", TextureFlags.NoLOD + TextureFlags.NoMipMaps)

	CONSOLE.SetMPMsgColor( self.mpMsgColor[1], self.mpMsgColor[2], self.mpMsgColor[3] )
	CONSOLE.SetMPMsgPosition( self.mpMsgPosition[1], self.mpMsgPosition[2] )
	CONSOLE.SetMPMsgFont( self.mpMsgFont, self.mpMsgFontTex, self.mpMsgFontSize )

	CrossScale = Cfg.CrosshairSize

	HUD.SetTransparency( Cfg.HUDTransparency )
	AspectRatio = 576
end
--============================================================================
function Hud:Clear()
    if self._ShotGun then MDL.Release(self._ShotGun) end
    self.r_closestEnemy = nil
	self._nearestCheckPoint = nil
	self._lastTime = 0.0
end
--============================================================================
function Hud:Tick(delta)
    self.TickCount = self.TickCount + delta * 10
--    CrossScale = 0.85 +  (1 + math.sin(self.TickCount))/2 * 0.15       
end
--============================================================================
function Hud:Render(delta)
	if CONSOLE.DemoIsPlaying() then self:DrawForDemo(); return end

	local w,h = R3D.ScreenSize()

	AspectRatio  = 1024/(w/h)
	function round(AspectRatio)
        if AspectRatio >= 0 then return math.floor(AspectRatio+.5)
        else return math.ceil(AspectRatio-.5) end
    end


	if Cfg.Eyefinity == 1 then
		Eyefinity = (640*Cfg.Eyefinity) + Cfg.EyefinityAdjust else
		Eyefinity = 0
	end
	
	if self._showFPS or (Cfg.ShowFPS and Game.GMode ~= GModes.SingleGame) then
		local fps = string.format("FPS: %d",R3D.GetFPS())
		HUD.SetFont("timesbd",26)
		HUD.PrintXY(w-HUD.GetTextWidth(fps)+1,1,fps,"timesbd",15,15,15,26)
		HUD.PrintXY(w-HUD.GetTextWidth(fps),0,fps,"timesbd",230,161,97,26)
		if Game.GMode ~= GModes.SingleGame then
			local ploss = TXT.MPStats.PacketLoss..": "..NET.GetClientPacketLoss(NET.GetClientID()).."%"
			HUD.PrintXY(w-HUD.GetTextWidth(ploss)+1,HUD.GetTextHeight()+1,ploss,"timesbd",15,15,15,26)
			HUD.PrintXY(w-HUD.GetTextWidth(ploss),HUD.GetTextHeight(),ploss,"timesbd",230,161,97,26)
		end
	 end
	 
	if Game and Game.GMode ~= GModes.SingleGame and (self._showtimer or Cfg.ShowTimer) and Game._TimeLimitOut then
		local tm = (MPCfg.TimeLimit*60 - Game._TimeLimitOut) / 60
		if Cfg.ShowTimerCountUp == true then
			tm = (Game._TimeLimitOut) / 60
		end
        if Game._TimeLimitOut < 0 then tm = 0 end
		local m = math.floor(tm)
		local s = math.floor((tm - m) * 60)
		local red = false
		if(m <= 0.0) and Cfg.ShowTimerCountUp == false then
			red = true
		else if (m >= MPCfg.TimeLimit - 1) and Cfg.ShowTimerCountUp then
			red = true
			end
		end
		local time = string.format(m..":"..string.format("%02d",s))
		HUD.SetFont("timesbd",26)
		if (self._showtimer or Cfg.ShowTimer) and Game.GMode ~= GModes.SingleGame then
			HUD.PrintXY(w-HUD.GetTextWidth(time)+1,HUD.GetTextHeight()*2+1,time,"timesbd",15,15,15,26)
			if red then
				HUD.PrintXY(w-HUD.GetTextWidth(time),HUD.GetTextHeight()*2,time,"timesbd",230,0,0,26)
			else
				HUD.PrintXY(w-HUD.GetTextWidth(time),HUD.GetTextHeight()*2,time,"timesbd",230,161,97,26)
			end 
		else if Game.GMode ~= GModes.SingleGame then
			HUD.PrintXY(w-HUD.GetTextWidth(time)+1,1,time,"timesbd",15,15,15,26)
			if red then
				HUD.PrintXY(w-HUD.GetTextWidth(time),0,time,"timesbd",230,0,0,26)
			else
				HUD.PrintXY(w-HUD.GetTextWidth(time),0,time,"timesbd",230,161,97,26)
			end 
			end
	  	end 
	 end	
 
 	if Game and MPCfg.GameState == GameStates.Counting and Game._countTimer and Game._countTimer > 0.99 then
		HUD.SetFont("timesbd",26)
		local countdown = "Match begins in: "..string.format("%02d",Game._countTimer)
		HUD.PrintXY((w-HUD.GetTextWidth(countdown))/2+1,24+1,countdown,"timesbd",15,15,15,26)
		HUD.PrintXY((w-HUD.GetTextWidth(countdown))/2,24,countdown,"timesbd",230,161,97,26)
	 end
	 
	if Game and Game._voteTimeLeft > 0 then
		local yesVotes = 0
		local noVotes = 0
		for i,o in Game.PlayerStats do
			if o._vote and o.Spectator == 0 then
				if o._vote == 1 then
					yesVotes = yesVotes + 1
				elseif o._vote == 0 then
					noVotes = noVotes + 1
				end
			end
		end
		HUD.SetFont("timesbd",26)
		local currentvote = "Vote("..string.format("%02d",Game._voteTimeLeft).."): '"..Game._voteCmd.." "..Game._voteParams.."'  yes("..yesVotes..") no("..noVotes..")"
		HUD.PrintXY((w-HUD.GetTextWidth(currentvote))/2,h/6,currentvote,"timesbd",200,200,200,26)
	end
    
    if not self.Enabled then return end

	if Player then
        if not Player._died and Game.IsDemon then
			self:QuadRGBA(self._matDemonCross,w/2,h/2,CrossScale,true,255,255,255,Cfg.CrosshairTrans/100.0*96)
        end
        
        if Player.HasWeaponModifier then
			HUD.DrawQuad(self._matModifier,0,0,w,h)
        end
    end

    if Game.IsDemon and not Lucifer_001 then return end

	if Cfg.Crosshair and not Game.IsDemon then
		if self._crosshairs[Cfg.Crosshair] ~= self._lastCross then
			MATERIAL.Release(self._matCrosshair)
			self._matCrosshair = MATERIAL.Create(self._crosshairs[Cfg.Crosshair], TextureFlags.NoLOD + TextureFlags.NoMipMaps)
			self._lastCross = self._crosshairs[Cfg.Crosshair]
		end
	end

	local trans = HUD.GetTransparency()
	if Game.GMode == GModes.SingleGame then
		self:QuadTrans(self._matHUDTop,(512-Cfg.HUDSize*230)*w/1024,0,Cfg.HUDSize,false,trans)
	end

	local sizex, sizey = MATERIAL.Size(self._matHUDLeft)
	self:QuadTrans(self._matHUDLeft,0+Eyefinity,(AspectRatio-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false,trans)
	self:QuadTrans(self._matHUDRight,(1024-Cfg.HUDSize*sizex)*w/1024-Eyefinity,(AspectRatio-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false,trans)

	if Game.GMode == GModes.SingleGame then
		self:Quad(self._matPentagram,(512-Cfg.HUDSize*105)*w/1024,Cfg.HUDSize*14*h/AspectRatio,Cfg.HUDSize,false)
		self:Quad(self._matMoney,(512+Cfg.HUDSize*55)*w/1024,Cfg.HUDSize*4*h/AspectRatio,Cfg.HUDSize,false)
	end

	self:Quad(self._matHealth,Cfg.HUDSize*17*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*14)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
    
    if Player then
        if not Player._died and not Hud.NoCrosshair then
			self:QuadRGBA(self._matCrosshair,w/2,h/2,CrossScale,true,Cfg.CrosshairR,Cfg.CrosshairG,Cfg.CrosshairB,Cfg.CrosshairTrans/100.0*255)
        end

        if Player.ArmorType == 0 then
            self:Quad(self._matArmorNormal,Cfg.HUDSize*17*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
        elseif Player.ArmorType == 1 then
            self:Quad(self._matArmorGreen,Cfg.HUDSize*17*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
        elseif Player.ArmorType == 2 then
            self:Quad(self._matArmorYellow,Cfg.HUDSize*17*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
        elseif Player.ArmorType == 3 then
            self:Quad(self._matArmorRed,Cfg.HUDSize*17*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*49)-Cfg.HUDSize*sizey)*h/AspectRatio,Cfg.HUDSize,false)
        end
        if Player:GetCurWeapon() then
            Player:GetCurWeapon():DrawHUD(delta)
        end
        
        if Game.GMode == GModes.SingleGame then
			self:DrawDigitsText((512-Cfg.HUDSize*202)*w/1024,Cfg.HUDSize*14*h/AspectRatio,string.format("%05d",Game.BodyCountTotal),0.8 * Cfg.HUDSize)
			self:DrawDigitsText((512+Cfg.HUDSize*105)*w/1024,Cfg.HUDSize*14*h/AspectRatio,string.format("%05d",Player.SoulsCount),0.8 * Cfg.HUDSize,5-Game.Demon_HowManyCorpses)
		end
        local he = Player.Health
        if he < 1 and he > 0 then
            he = 1
        end
		self:DrawDigitsText(Cfg.HUDSize*52*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*16)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%03d",he),-3),0.9 * Cfg.HUDSize,Player.HealthWarning)
        local armor = Player.Armor
        if Player.FrozenArmor then armor = 0 end
		self:DrawDigitsText(Cfg.HUDSize*52*w/1024+Eyefinity,((AspectRatio+Cfg.HUDSize*50)-Cfg.HUDSize*sizey)*h/AspectRatio,string.sub(string.format("%03d",armor),-3),0.9 * Cfg.HUDSize,Player.ArmorWarning)
    end

	if Game.GMode == GModes.SingleGame then
		local time = INP.GetTime()
		if( time - self._lastTime ) >= 1.0 then
--			Game:Print( "Update" )
			self:UpdateCompass()
			self._lastTime = time
		end

		if self.showCompassArrow == true then
			self:RenderCompass()
		end

		if Game.MegaBossHealth and Game.MegaBossHealthMax then
			local size = Game.MegaBossHealth / Game.MegaBossHealthMax
			if Game.CurrChapter == 1 and not Game.AddOn then
				self:Quad(self._matBossGiant,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			elseif Game.CurrChapter == 2 then
				self:Quad(self._matBossSwamp,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			elseif Game.CurrChapter == 3 then
				self:Quad(self._matBossThor,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			elseif Game.CurrChapter == 4 then
				self:Quad(self._matBossAlastor,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			elseif Game.AddOn and Game.CurrLevel == 4 then
				self:Quad(self._matBossSpider,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			elseif Game.AddOn and Game.CurrLevel == 10 then
				self:Quad(self._matBossAlastor2,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			else
				self:Quad(self._matBossFace,(512-Cfg.HUDSize*48)*w/1024,Cfg.HUDSize*10*h/AspectRatio,Cfg.HUDSize,false)
			end
			if size < 0.01 and Game.MegaBossHealth > 0 then size = 0.01 end
			HUD.DrawBossHealth( size * 100 )
		else
			self:RenderUpDown()
		end

		if self._showSPStats then
			self:RenderSPStats()
		end

		if self._showCheckPointInfo then
			local w,h = R3D.ScreenSize()
			HUD.DrawBorder(312,290,400,140)
			HUD.PrintXY(-1,240*h/AspectRatio,Languages.Texts[647],"timesbd",230,161,97,26)
			HUD.PrintXY(-1,280*h/AspectRatio,Languages.Texts[648].."...","timesbd",230,161,97,26)
		end

		if self._overlayMessage ~= "" and self._overlayMsgStart == 0 then
			self._overlayMsgStart = INP.GetTime()
		end

		if self._overlayMessage ~= "" and ( INP.GetTime() - self._overlayMsgStart ) < 5 then
			local w,h = R3D.ScreenSize()
			HUD.SetFont("timesbd",26)
			local tw = HUD.GetTextWidth(self._overlayMessage)
			local th = HUD.GetTextHeight(self._overlayMessage)
			HUD.DrawBorder(((w-tw)/2)*1024/w-20,198,tw*1024/w+40,th*AspectRatio/h+40)
			HUD.PrintXY(-1,220*h/AspectRatio,self._overlayMessage,"timesbd",230,161,97,26)
		else
			self._overlayMessage = ""
			self._overlayMsgStart = 0
		end
	end

	if Game.Paused then
		local w,h = R3D.ScreenSize()
		HUD.DrawQuadRGBA(nil,0,0,w,h,0,0,0,90)
		HUD.DrawBorder(332,310,360,100)
		HUD.PrintXY(-1,260*h/AspectRatio,Languages.Texts[709],"timesbd",230,161,97,26)
	end

    if Game.IsDemon then return end
    
    -- speedmeter
    if  Tweak.PlayerMove.ShowSpeedmeter and Player and Player._Entity then
        local vx,vy,vz,vl = ENTITY.GetVelocity(Player._Entity)
        local hl = Dist2D(0,0,vx,vz) 
        HUD.DrawQuadRGBA(nil,w/2-50,h-17,100,13,100,100,100)
        HUD.DrawQuadRGBA(nil,w/2-50,h-17,hl*2,13,255,0,0)
        HUD.PrintXY(w/2-10,h-15,string.format("%.02f",hl))
    end
    
    if self._showPacketLoss and Game.GMode ~= GModes.SingleGame then
		local w,h = R3D.ScreenSize()
		local mw,mh = MATERIAL.Size(self._matPacketLoss)
		HUD.DrawQuad(self._matPacketLoss,w-(mw+8)*w/1024,8*h/AspectRatio,mw*w/1024,mh*h/AspectRatio)
    end
end
--============================================================================
function Hud:DrawForDemo()
	local w,h = R3D.ScreenSize()
	
	if self._showFPS or (Cfg.ShowFPS and Game.GMode ~= GModes.SingleGame) then
		local fps = string.format("FPS: %d",R3D.GetFPS())
		HUD.SetFont("timesbd",26)
		HUD.PrintXY(w-HUD.GetTextWidth(fps)+1,1,fps,"timesbd",15,15,15,26)
		HUD.PrintXY(w-HUD.GetTextWidth(fps),0,fps,"timesbd",230,161,97,26)
	 end
end
--============================================================================
function Hud:DrawSingleStat(index,name,val,total,bonus,show_star)
	local w,h = R3D.ScreenSize()

	HUD.SetFont("timesbd",26)
	local fh = HUD.GetTextHeight() + 8 * h/AspectRatio

	local sepPos = w/2 + 50*w/1024
	local spos = 0
	local sepWidth = HUD.GetTextWidth( ": " )
	local slashWidth = HUD.GetTextWidth( "/" )
	local numWidth = HUD.GetTextWidth( "000" )
	local minPos = sepPos + sepWidth
	local slashPos = minPos + numWidth
	local maxPos = slashPos + slashWidth

	local y = h/2-fh*5+index*fh

	local colorTxt = { 230, 161, 97 }
	local colorMin = { 214, 0, 23 }
	local colorMax = { 189, 0, 0 }

	spos = sepPos - HUD.GetTextWidth( name )
	HUD.PrintXY(spos,y,name..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)

	local star_pos = maxPos

	if val < 1000 then
		HUD.PrintXY(minPos,y,string.format("%03d",val),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
		HUD.PrintXY(slashPos,y,"/","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
		HUD.PrintXY(maxPos,y,string.format("%03d",total),"timesbd",colorMax[1],colorMax[2],colorMax[3],26)
		if bonus and bonus > 0 then
			HUD.PrintXY(maxPos+HUD.GetTextWidth(string.format("%03d",total)),y,string.format("+%d",bonus),"timesbd",120,120,120,26)
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d+%d",total,bonus))
		else
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d",total))
		end
	else
		local len = HUD.GetTextWidth(string.format("%d",val))
		local diff = len - HUD.GetTextWidth("000")
		HUD.PrintXY(minPos,y,string.format("%03d",val),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
		HUD.PrintXY(slashPos+diff,y,"/","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
		HUD.PrintXY(maxPos+diff,y,string.format("%03d",total),"timesbd",colorMax[1],colorMax[2],colorMax[3],26)
		if bonus and bonus > 0 then
			HUD.PrintXY(maxPos+diff+HUD.GetTextWidth(string.format("%03d",total)),y,string.format("+%d",bonus),"timesbd",120,120,120,26)
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d+%d",total,bonus))
		else
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d",total))
		end
	end

	if show_star and val >= total then
		self:Quad(self._matStar,star_pos,y+HUD.GetTextHeight()/2-18*h/AspectRatio,1)
	end
end
--============================================================================
function Hud:RenderSPStats()
	local colorTxt = { 230, 161, 97 }
	local colorMin = { 214, 0, 23 }
	local colorMax = { 189, 0, 0 }

	HUD.DrawBorder(150,80,724,640)

	local w,h = R3D.ScreenSize()

	HUD.SetFont("timesbd",26)
	local fh = HUD.GetTextHeight() + 8 * h/AspectRatio

	HUD.PrintXY(-1,h/2-fh*7,TXT.SPStats.YourScore,"timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)

	local min = math.abs(Game.LevelTime / 60)
	local sec = math.mod(Game.LevelTime, 60)

	local sepPos = w/2 + 50*w/1024
	local spos = 0
	local sepWidth = HUD.GetTextWidth( ": " )
	local slashWidth = HUD.GetTextWidth( "/" )
	local numWidth = HUD.GetTextWidth( "000" )
	local minPos = sepPos + sepWidth
	local slashPos = minPos + numWidth
	local maxPos = slashPos + slashWidth

	spos = sepPos - HUD.GetTextWidth( TXT.SPStats.GameplayTime )
	HUD.PrintXY(spos,h/2-fh*5,TXT.SPStats.GameplayTime..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	if min < 60 then
		HUD.PrintXY(minPos,h/2-fh*5,string.format("%02d",min)..":"..string.format("%02d",sec),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
	else
		local hour = math.floor(min/60)
		min = min - hour * 60
		HUD.PrintXY(minPos,h/2-fh*5,string.format("%02d",hour)..":"..string.format("%02d",min)..":"..string.format("%02d",sec),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
	end

	local diff = { TXT.Menu.Daydream, TXT.Menu.Insomnia, TXT.Menu.Nightmare, TXT.Menu.Trauma }

	spos = sepPos - HUD.GetTextWidth( TXT.SPStats.Difficulty )
	HUD.PrintXY(spos,h/2-fh*4,TXT.SPStats.Difficulty..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	HUD.PrintXY(minPos,h/2-fh*4,diff[Game.Difficulty+1],"timesbd",colorMin[1],colorMin[2],colorMin[3],26)

    if not Player then return end
	self:DrawSingleStat(2,TXT.SPStats.MonstersKilled,Game.BodyCountTotal,Game.TotalActors)
	self:DrawSingleStat(3,TXT.SPStats.SoulsCollected,Player.TotalSoulsCount,Game.TotalSouls)
	self:DrawSingleStat(4,TXT.SPStats.GoldFound,Game.PlayerMoneyFound-Player.BonusItems,Game.TotalMoney,Player.BonusItems)
	HUD.DrawQuadRGBA(nil,300*w/1024,h/2-5*h/AspectRatio,440*w/1024,1,230,161,97,255)
	self:DrawSingleStat(5,TXT.SPStats.ArmorFound,Player.ArmorFound,Game.TotalArmor,nil,true)
	self:DrawSingleStat(6,TXT.SPStats.HolyItemsFound,Player.HolyItems,Game.TotalHolyItems,nil,true)
	self:DrawSingleStat(7,TXT.SPStats.AmmoFound,Game.PlayerAmmoFound,Game.TotalAmmo,nil,true)
	self:DrawSingleStat(8,TXT.SPStats.ObjectsDestroyed,Game.PlayerDestroyedItems,Game.TotalDestroyed,nil,true)
	self:DrawSingleStat(9,TXT.SPStats.SecretsFound,Player.SecretsFound,Game.TotalSecrets,nil,true)

	HUD.PrintXY(-1,h/2+fh*6-8*w/AspectRatio,TXT.SPStats.CardCondition..":","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	HUD.PrintXY(-1,h/2+fh*7-8*w/AspectRatio,Lev._CardTask,"timesbd",colorMax[1],colorMax[2],colorMax[3],26)

	local cardStatus = Lev:GetCardStatus()
	local cardText = TXT.SPStats.Locked
	if cardStatus == 0 then
		cardText = TXT.SPStats.Failed
	elseif cardStatus == 1 then
		cardText = TXT.SPStats.Unlocked
	end

	if Game.Difficulty == 0 or Lev._Name == "C6L0_PCFHQ" then
		cardText = TXT.SPStats.NA
	end

	local statLen = HUD.GetTextWidth(TXT.SPStats.Status..": "..cardText)
	HUD.PrintXY(w/2-statLen/2,h/2+fh*8-8*w/AspectRatio,TXT.SPStats.Status..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	HUD.PrintXY(w/2+statLen/2-HUD.GetTextWidth(cardText),h/2+fh*8-8*w/AspectRatio,cardText,"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
end
--============================================================================
function Hud:DrawSingleStat2(index,name,val,total,bonus,show_star,diff)
	local w,h = R3D.ScreenSize()

	HUD.SetFont("timesbd",26)
	local fh = HUD.GetTextHeight() + 8 * h/AspectRatio

	local sepPos = w/2 - 80*w/1024
	local spos = 0
	local sepWidth = HUD.GetTextWidth( ": " )
	local slashWidth = HUD.GetTextWidth( "/" )
	local numWidth = HUD.GetTextWidth( "000" )
	local minPos = sepPos + sepWidth
	local slashPos = minPos + numWidth
	local maxPos = slashPos + slashWidth

	local y = h/2-fh*5+index*fh

	local colorTxt = { 230, 161, 97 }
	local colorMin = { 214, 0, 23 }
	local colorMax = { 189, 0, 0 }

	spos = sepPos - HUD.GetTextWidth( name )
	HUD.PrintXY(spos,y,name..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)

	local star_pos = maxPos

	if val < 1000 then
		HUD.PrintXY(minPos,y,string.format("%03d",val),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
		HUD.PrintXY(slashPos,y,"/","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
		HUD.PrintXY(maxPos,y,string.format("%03d",total),"timesbd",colorMax[1],colorMax[2],colorMax[3],26)
		if bonus and bonus > 0 then
			HUD.PrintXY(maxPos+HUD.GetTextWidth(string.format("%03d",total)),y,string.format("+%d",bonus),"timesbd",120,120,120,26)
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d+%d",total,bonus))
		else
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d",total))
		end
	else
		local len = HUD.GetTextWidth(string.format("%d",val))
		local diff = len - HUD.GetTextWidth("000")
		HUD.PrintXY(minPos,y,string.format("%03d",val),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
		HUD.PrintXY(slashPos+diff,y,"/","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
		HUD.PrintXY(maxPos+diff,y,string.format("%03d",total),"timesbd",colorMax[1],colorMax[2],colorMax[3],26)
		if bonus and bonus > 0 then
			HUD.PrintXY(maxPos+diff+HUD.GetTextWidth(string.format("%03d",total)),y,string.format("+%d",bonus),"timesbd",120,120,120,26)
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d+%d",total,bonus))
		else
			star_pos = maxPos+HUD.GetTextWidth(string.format("%03d",total))
		end
	end

	if show_star and val >= total then
		self:Quad(self._matStar,star_pos,y+HUD.GetTextHeight()/2-18*h/AspectRatio,1)
	end
	
	if diff then
		HUD.PrintXY(maxPos + HUD.GetTextWidth("000000000"),y,string.format("(%s)",diff),"timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	end
end
--============================================================================
function Hud_RenderLevelStats()
	if not Game then return end

	local name = PMENU.MapGetCurrLevelName()
	Game:MakeEmptyLevelStats(name)

	local stats = Game.LevelsStats[name]
	if not stats then return end
	
--	if stats.GameplayTime < 1 then return end

	local colorTxt = { 230, 161, 97 }
	local colorMin = { 214, 0, 23 }
	local colorMax = { 189, 0, 0 }

	HUD.DrawBorder(150,80,724,640)

	local w,h = R3D.ScreenSize()

	HUD.SetFont("timesbd",26)
	local fh = HUD.GetTextHeight() + 8 * h/AspectRatio

	HUD.PrintXY(-1,h/2-fh*7,TXT.SPStats.BestScore,"timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)

	local min = math.abs(stats.GameplayTime / 60)
	local sec = math.mod(stats.GameplayTime, 60)

	local sepPos = w/2 - 50*w/1024
	local spos = 0
	local sepWidth = HUD.GetTextWidth( ": " )
	local slashWidth = HUD.GetTextWidth( "/" )
	local numWidth = HUD.GetTextWidth( "000" )
	local minPos = sepPos + sepWidth
	local slashPos = minPos + numWidth
	local maxPos = slashPos + slashWidth

	local diff = { TXT.Menu.Daydream, TXT.Menu.Insomnia, TXT.Menu.Nightmare, TXT.Menu.Trauma }

	spos = sepPos - HUD.GetTextWidth( TXT.SPStats.GameplayTime )
	HUD.PrintXY(spos,h/2-fh*5,TXT.SPStats.GameplayTime..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	if min < 60 then
		HUD.PrintXY(minPos,h/2-fh*5,string.format("%02d",min)..":"..string.format("%02d",sec),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
	else
		local hour = math.floor(min/60)
		min = min - hour * 60
		HUD.PrintXY(minPos,h/2-fh*5,string.format("%02d",hour)..":"..string.format("%02d",min)..":"..string.format("%02d",sec),"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
	end

	if diff[stats.TimeDiff+1] then
		HUD.PrintXY(maxPos + HUD.GetTextWidth("000000000"),h/2-fh*5,string.format("(%s)",diff[stats.TimeDiff+1]),"timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	end

	local show_stars = true
	if stats.GameplayTime == 0 then show_stars = false end

	Hud:DrawSingleStat2(1,TXT.SPStats.MonstersKilled,stats.MonstersKilled,stats.TotalMonsters,nil,false,diff[stats.MonstersDiff+1])
	Hud:DrawSingleStat2(2,TXT.SPStats.SoulsCollected,stats.SoulsCollected,stats.TotalSouls,nil,false,diff[stats.SoulsDiff+1])
	Hud:DrawSingleStat2(3,TXT.SPStats.GoldFound,stats.GoldFound,stats.TotalGold,stats.BonusItems,false,diff[stats.GoldDiff+1])
	HUD.DrawQuadRGBA(nil,300*w/1024,h/2-5*h/AspectRatio-fh/2,440*w/1024,1,230,161,97,255)
	Hud:DrawSingleStat2(5,TXT.SPStats.ArmorFound,stats.ArmorsFound,stats.TotalArmors,nil,show_stars,diff[stats.ArmorsDiff+1])
	Hud:DrawSingleStat2(6,TXT.SPStats.HolyItemsFound,stats.HolyItemsFound,stats.TotalHolyItems,nil,show_stars,diff[stats.HolyDiff+1])
	Hud:DrawSingleStat2(7,TXT.SPStats.AmmoFound,stats.AmmoFound,stats.TotalAmmo,nil,show_stars,diff[stats.AmmoDiff+1])
	Hud:DrawSingleStat2(8,TXT.SPStats.ObjectsDestroyed,stats.ObjectsDestroyed,stats.TotalObjects,nil,show_stars,diff[stats.ObjectsDiff+1])
	Hud:DrawSingleStat2(9,TXT.SPStats.SecretsFound,stats.SecretsFound,stats.TotalSecrets,nil,show_stars,diff[stats.SecretsDiff+1])

	HUD.PrintXY(-1,h/2+fh*6-8*w/AspectRatio,TXT.SPStats.CardCondition..":","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	HUD.PrintXY(-1,h/2+fh*7-8*w/AspectRatio,PMENU.MapGetCurrLevelCardCondition(),"timesbd",colorMax[1],colorMax[2],colorMax[3],26)

	local cardStatus = Game.CardsAvailable[PMENU.MapGetCurrLevelCardIndex()]
	local cardText = TXT.SPStats.Locked
	if cardStatus == true then
		cardText = TXT.SPStats.Unlocked
	end

	local statLen = HUD.GetTextWidth(TXT.SPStats.Status..": "..cardText)
	HUD.PrintXY(w/2-statLen/2,h/2+fh*8-8*w/AspectRatio,TXT.SPStats.Status..": ","timesbd",colorTxt[1],colorTxt[2],colorTxt[3],26)
	HUD.PrintXY(w/2+statLen/2-HUD.GetTextWidth(cardText),h/2+fh*8-8*w/AspectRatio,cardText,"timesbd",colorMin[1],colorMin[2],colorMin[3],26)
end
--============================================================================
function Hud:RenderCompass()
	if not Player then return end
	local check = false
	self.upDown = 0
	local vert = 0
	if self.r_closestEnemy then
		local tx = self.r_closestEnemy._groundx - Player._groundx
		local tz = self.r_closestEnemy._groundz - Player._groundz

		local angle = math.atan2( tx, tz )
		self._arrowRot = AngDist( Player.angle, angle )
		
		vert = self.r_closestEnemy._groundy - Player._groundy
	elseif self._nearestCheckPoint then
		local tx = self._nearestCheckPoint.Pos.X - Player._groundx
		local tz = self._nearestCheckPoint.Pos.Z - Player._groundz

		local angle = math.atan2( tx, tz )
		self._arrowRot = AngDist( Player.angle, angle )
		
		vert = self._nearestCheckPoint.Pos.Y - Player._groundy

		check = true
	else
		self._arrowRot = 0.0
	end

	if vert < -2.0 then
		self.upDown = 1
	elseif vert > 2.0 then
		self.upDown = 2
	else
		self.upDown = 0
	end

	local time = INP.GetTime()
	if check and self._nearestIsCheckpoint then
		if self._glowTrans <= 0 and time - self._glowStart > 1.5 then
			local dist = Dist3D(self._nearestCheckPoint.Pos.X,self._nearestCheckPoint.Pos.Y,self._nearestCheckPoint.Pos.Z,Player._groundx,Player._groundy,Player._groundz)
			local vol = 120 - 4 * dist
			if vol > 0 then
				if vol > 100 then vol = 100 end
				PlaySound2D("pickup_health_minisphere",vol,true,false)
			end
			self._glowDir = 1
			self._glowTrans = 0
		end
		if self._glowTrans >= 255 then
			self._glowDir = -1
			self._glowTrans = 255
			self._glowStart = time
		end

		if ( time - self._glowTime ) > 0.001 then
			if self._glowDir == 1 then
				self._glowTrans = self._glowTrans + self._glowDir * 18
			else
				self._glowTrans = self._glowTrans + self._glowDir * 6
			end
			if self._glowTrans <= 0 then
				self._glowTrans = 0
			end
			if self._glowTrans >= 255 then
				self._glowTrans = 255
			end
			self._glowTime = time
		end
	else
		self._glowTrans = 0;
	end

	if self._glowTrans2 <= Tweak.HUD.CompassUpDownStrength then
		self._glowDir2 = 1
		self._glowTrans2 = Tweak.HUD.CompassUpDownStrength
	end
	if self._glowTrans2 >= 255 then
		self._glowDir2 = -1
		self._glowTrans2 = 255
		self._glowStart2 = time
	end

	if ( time - self._glowTime2 ) > 0.001 then
		self._glowTrans2 = self._glowTrans2 + self._glowDir2 * Tweak.HUD.CompassUpDownSpeed * ( time - self._glowTime2 )
		if self._glowTrans2 <= Tweak.HUD.CompassUpDownStrength then
			self._glowTrans2 = Tweak.HUD.CompassUpDownStrength
		end
		if self._glowTrans2 >= 255 then
			self._glowTrans2 = 255
		end
		self._glowTime2 = time
	end

	local w,h = R3D.ScreenSize()
	if not check then
		self:QuadRot(self._matCompassArrShadow,500*w/1024,Cfg.HUDSize*62*h/AspectRatio,Cfg.HUDSize,self._arrowRot,516*w/1024,Cfg.HUDSize*58*h/AspectRatio)
		self:QuadRot(self._matCompassArrow,495*w/1024,Cfg.HUDSize*58*h/AspectRatio,Cfg.HUDSize,self._arrowRot,511*w/1024,Cfg.HUDSize*54*h/AspectRatio)
	else
		self:QuadRot(self._matCompassArrShadow,500*w/1024,Cfg.HUDSize*62*h/AspectRatio,Cfg.HUDSize,self._arrowRot,516*w/1024,Cfg.HUDSize*58*h/AspectRatio)
		self:QuadRot(self._matCompassArrow,495*w/1024,Cfg.HUDSize*58*h/AspectRatio,Cfg.HUDSize,self._arrowRot,511*w/1024,Cfg.HUDSize*54*h/AspectRatio)
		self:QuadRotTrans(self._matCompassArrGlow,495*w/1024,Cfg.HUDSize*58*h/AspectRatio,Cfg.HUDSize,self._arrowRot,511*w/1024,Cfg.HUDSize*54*h/AspectRatio,self._glowTrans)
	end
end
--============================================================================
function Hud:RenderUpDown()
	local w,h = R3D.ScreenSize()
	local trans = HUD.GetTransparency()
	if self.upDown == 0 then
		self:QuadTrans(self._matCompassUp,(512-17*Cfg.HUDSize)*w/1024,0,Cfg.HUDSize,false,trans)
		self:QuadTrans(self._matCompassDown,(512-17*Cfg.HUDSize)*w/1024,87*Cfg.HUDSize*h/AspectRatio,Cfg.HUDSize,false,trans)
	elseif self.upDown == 1 then
		self:QuadTrans(self._matCompassUp,(512-17*Cfg.HUDSize)*w/1024,0,Cfg.HUDSize,false,trans)
		self:QuadTrans(self._matCompassDownOn,(512-17*Cfg.HUDSize)*w/1024,87*Cfg.HUDSize*h/AspectRatio,Cfg.HUDSize,false,self._glowTrans2)
	elseif self.upDown == 2 then
		self:QuadTrans(self._matCompassUpOn,(512-17*Cfg.HUDSize)*w/1024,0,Cfg.HUDSize,false,self._glowTrans2)
		self:QuadTrans(self._matCompassDown,(512-17*Cfg.HUDSize)*w/1024,87*Cfg.HUDSize*h/AspectRatio,Cfg.HUDSize,false,trans)
	end
end
--============================================================================
function Hud:UpdateCompass()
	self.r_closestEnemy = GetNearestLiveActor()
	if self.r_closestEnemy then
		-- kill active checkpoints
		for i,v in GObjects.CheckPoints do
			if v.Frozen == false and v.BaseObj == "CheckPoint.CItem" then
				GObjects:ToKill(v)
			end
		end
	end
	self._nearestIsCheckpoint = false
	self._nearestCheckPoint, self._nearestIsCheckpoint = GetNearestCheckPoint()
end
--============================================================================
function Hud:QuadSlice(mat,mw,mh,x,y,u1,v1,u2,v2)
    if u1 > 0 then
		mw = mw * (1 - u1)
    end
    if v1 > 0 then
		mh = mh * (1 - v1)
    end

    if u2 > 0 then
		mw = mw * (u2)
    end
    if v2 > 0 then
		mh = mh * (v2)
    end
    HUD.DrawQuad(mat,x,y,mw,mh,color,u1,v1,u2,v2)
end


--============================================================================ Compass Face
function Hud:Quad(mat,x,y,size,center)
    local mw,mh = MATERIAL.Size(mat)
    if mw == -1 then
        Game:Print('Hud:Quad - material: '.. mat.." not found!")
        return
    end
    local w,h = R3D.ScreenSize()
    mw = mw * size * w / 1024
    mh = mh * size * h / AspectRatio
    if center then
        x = x - mw/2
        y = y - mh/2
    end
    HUD.DrawQuad(mat,x,y,mw,mh)
end
--============================================================================unknown
function Hud:QuadUV(mat,x,y,size,center,u,v,u1,v1)
    local mw,mh = MATERIAL.Size(mat)
    local w,h = R3D.ScreenSize()
    mw = mw * size * w / 1024
    mh = mh * size * h / AspectRatio
    if center then
        x = x - mw/2
        y = y - mh/2
    end
    HUD.DrawQuad(mat,x,y,mw,mh,R3D.RGB(255,255,255),u,v,u1,v1)
end
--============================================================================
function Hud:QuadTrans(mat,x,y,size,center,trans)
    local mw,mh = MATERIAL.Size(mat)
    local w,h = R3D.ScreenSize()
    mw = mw * size * w /1024
    mh = mh * size * h / AspectRatio
    if center then
        x = x - mw/2
        y = y - mh/2
    end
    HUD.DrawQuadRGBA(mat,x,y,mw,mh,255,255,255,trans)
end
--============================================================================
function Hud:QuadTransUV(mat,x,y,size,center,trans,u,v,u1,v1)
    local mw,mh = MATERIAL.Size(mat)
    local w,h = R3D.ScreenSize()
    mw = mw * size * w /1024
    mh = mh * size * h / AspectRatio
    if center then
        x = x - mw/2
        y = y - mh/2
    end
    HUD.DrawQuadRGBA(mat,x,y,mw,mh,255,255,255,trans,u,v,u1,v1)
end
--============================================================================
function Hud:QuadRGBA(mat,x,y,size,center,r,g,b,a)
    local mw,mh = MATERIAL.Size(mat)
    local w,h = R3D.ScreenSize()
    mw = mw * size * w /1024
    mh = mh * size * h / AspectRatio
    if center then
        x = x - mw/2
        y = y - mh/2
    end
    HUD.DrawQuadRGBA(mat,x,y,mw,mh,r,g,b,a)
end
--============================================================================
function Hud:QuadRot(mat,x,y,size,angle,rotx,roty)
	local mw,mh = MATERIAL.Size(mat)
	local w,h = R3D.ScreenSize()
	mw = mw * size * w / 1024
	mh = mh * size * h / AspectRatio
	HUD.DrawQuadRotated(mat,x,y,mw,mh,angle,rotx,roty)
end
--============================================================================
function Hud:QuadRotTrans(mat,x,y,size,angle,rotx,roty,trans)
	local mw,mh = MATERIAL.Size(mat)
	local w,h = R3D.ScreenSize()
	mw = mw * size * w / 1024
	mh = mh * size * h / AspectRatio
	HUD.DrawQuadRotated(mat,x,y,mw,mh,angle,rotx,roty,255,255,255,trans)
end
--============================================================================
function Hud:DrawChar(x,y,chr,color,size)
    --Log(chr.."\n")
    local n = tonumber(chr)
    if not n then return end
    local cy = math.floor(n/4)
    local cx = n - (cy*4)
    local mw,mh = MATERIAL.Size(self._matNumbers)
    HUD.DrawQuad(self._matNumbers,x,y,mw/4*size,mh/4*size,color,cx*0.25,cy*0.25,cx*0.25+0.25,cy*0.25+0.25)
end
--============================================================================
function Hud:DrawText(x,y,txt,color,size)
    --Log("DrawText: "..txt.."\n")
    local l = string.len(txt)
    local mw,mh = MATERIAL.Size(self._matNumbers)
    for i=1,l do
        self:DrawChar(x+(i-1)*mw/4*size*0.5,y,string.sub(txt,i,i),color,size)
    end
end
--============================================================================
function Hud:DrawDigit(x,y,chr,scale)
	local w,h = R3D.ScreenSize()
	local n = tonumber(chr)
    if not n then return end
    local mw,mh = MATERIAL.Size(self._matDigits[n+1])
    HUD.DrawQuad(self._matDigits[n+1],x,y,mw*scale*w/1024,mh*scale*h/AspectRatio)
end
--============================================================================
function Hud:DrawDigitRed(x,y,chr,scale)
	local w,h = R3D.ScreenSize()
	local n = tonumber(chr)
    if not n then return end
    local mw,mh = MATERIAL.Size(self._matDigitsRed[n+1])
    HUD.DrawQuad(self._matDigitsRed[n+1],x,y,mw*scale*w/1024,mh*scale*h/AspectRatio)
end
--============================================================================
function Hud:DrawDigitsText(x,y,txt,scale,warning)
	local w,h = R3D.ScreenSize()
    local l = string.len(txt)
    local mw,mh = MATERIAL.Size(self._matDigits[5])

	if warning == nil or ( warning >= 0 and warning < tonumber(txt) ) or ( warning < 0 and -warning > tonumber(txt) ) then
		for i=1,l do
			self:DrawDigit(x+(i-1)*(mw-4)*(w/1024)*scale,y,string.sub(txt,i,i),scale)
		end
	else
		for i=1,l do
			self:DrawDigitRed(x+(i-1)*(mw-4)*(w/1024)*scale,y,string.sub(txt,i,i),scale)
		end
	end
end
--============================================================================
--============================================================================
--============================================================================
ConCommands =
{
	{ cmd = "god", params = { p1 = "GOD = true", p0 = "GOD = false", default = "p1" } },
	{ cmd = "quit", action = "Exit()" },
}
--============================================================================
function Hud_OnConsoleCommand(cmd)
    Console:OnCommand(cmd)
--    local txt = string.lower(cmd)
--    if txt == "god 1" or txt == "god" then GOD = true; return end
--    if txt == "god 0" then GOD = false; return end
    --dostring(cmd)

--[[
	local param = ""
	local found = string.find( txt, " " )
	if found then
		param = string.sub( txt, found + 1 )
		txt = string.sub( txt, 0, found - 1 )
	end

	for i=1,table.getn( ConCommands ) do
		if txt == ConCommands[i].cmd then
			Hud:ExecConsoleCommand( i, param )
			return
		end
	end

    if Player then 
        Game.SayToAll(Player.ClientID, cmd) 
    else
        Game.SayToAll(ServerID, cmd)
    end
    --]]
end
--============================================================================
function Hud_OnSayToAll(txt,color)
	if Game.GMode == GModes.SingleGame then return end
	txt = string.sub(txt,1,200)
	if not color then color = R3D.RGB(255,0,0) end
    Game.SayToAll(NET.GetClientID(), txt,color)
	CONSOLE.Activate(false)
end
--============================================================================
function Hud_OnSayToTeam(txt,color)
	if Game.GMode == GModes.SingleGame then return end
	txt = string.sub(txt,1,200)
    if Player then
		if not color then color = R3D.RGB(0,255,0) end
        Game.SayToTeam(NET.GetClientID(), txt, color)
    end
    CONSOLE.Activate(false)
end
--============================================================================
function Hud_OnSayTo(index)
	if not Cfg.MessagesTexts[index] then return end
	local txt = Cfg.MessagesTexts[index]
	local prefix = string.sub( txt, 1, 1 )
	local c = string.sub( txt, 2, 2 )
	local color = nil
	if prefix == "#" and c then
		Game:Print( "color message -"..c.."- "..txt )
		c = tonumber( c )
		if c and type(c) == "number" and c >=0 and c < 16 then
			local r,g,b = PMENU.GetTextColor(""..c)
			color = R3D.RGB(r,g,b)
			txt = string.sub( txt, 3 )
		end
	end

	if color then Game:Print( "Color ok" ) end

	if Cfg.MessagesSayAll[index] == 1 then
		Hud_OnSayToAll(txt,color)
	else
		Hud_OnSayToTeam(txt,color)
	end
end
--============================================================================
function Hud:ExecConsoleCommand( i, param )
	if ConCommands[i].params then
		if ConCommands[i].params["p"..param] then
			dostring( ConCommands[i].params["p"..param] )
		elseif param == "" then
			dostring( ConCommands[i].params[ConCommands[i].params.default] )
		end
	else
		if ConCommands[i].action then
			dostring( ConCommands[i].action )
		end
	end
end
--============================================================================
function Hud:OnConsoleTab(cmd)
    Console:OnPrompt(cmd)

    --[[
    local txt = string.lower(cmd)

	for i=1,table.getn( ConCommands ) do
		local found = string.find( ConCommands[i].cmd, txt )
		if found then
			if found == 1 then
				CONSOLE.SetCurrentText( ConCommands[i].cmd )
				return
			end
		end
	end
    --]]
end
--============================================================================
function Hud_OnConsoleTab(cmd)
	Hud:OnConsoleTab(cmd)
end

