-- LocalScript (MOBİL) - HAREKET MENÜSÜ
-- Yeri: StarterPlayer > StarterPlayerScripts
--
-- Kırmızı butona bas = menü açılır. Butonu basılı tutup sürükleyerek yerini değiştirebilirsin.
-- Sekmeler: Hareketler | Favoriler | MM2 | Duvar Fazı | Ayarlar
-- Bir harekete bas = başlar, tekrar bas (veya DURDUR) = kapanır.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- AYARLAR (menüden de değiştirilebilir) ----------------------
local settings = {
	speed = 1,                                -- hareket hızı
	loop = true,                              -- sonsuz tekrar
	stopOnMove = false,                       -- yürüyünce durdur
	buttonSize = 60,                          -- buton boyutu
	buttonColor = Color3.fromRGB(220, 20, 40) -- buton rengi
}
local PLAY_ONCE_TIME = 4 -- sonsuz tekrar kapalıyken hareket kaç saniye sürsün
-------------------------------------------------------------

local favorites = {} -- [hareketAdı] = true

local WHITE = Color3.new(1, 1, 1)
local PANEL_COLOR = Color3.fromRGB(18, 18, 24)
local ROW_COLOR = Color3.fromRGB(34, 34, 44)
local ACTIVE_COLOR = Color3.fromRGB(150, 20, 40)
local RED = Color3.fromRGB(200, 30, 50)
local GOLD = Color3.fromRGB(255, 200, 40)

----------------------------------------------------------------
-- HAREKET VERİLERİ
----------------------------------------------------------------
local rad, sin, abs, floor = math.rad, math.sin, math.abs, math.floor

-- Derece cinsinden döndürme
local function A(x, y, z)
	return CFrame.Angles(rad(x or 0), rad(y or 0), rad(z or 0))
end

-- Roblox'un kendi hareket animasyonları (diğer oyuncular da görür)
local BUILTIN = {
	R15 = {
		dance1 = 507771019, dance2 = 507771955, dance3 = 507772104,
		cheer = 507770677, laugh = 507770818, wave = 507770239, point = 507770453,
	},
	R6 = {
		dance1 = 182435998, dance2 = 182491037, dance3 = 182491065,
		cheer = 129423030, laugh = 129423131, wave = 128777973, point = 128853357,
	},
}

local ROBOT = {
	[0] = { rs = A(0, 0, 90), ls = A(0, 0, -90) },
	[1] = { rs = A(0, 0, 90), ls = A(0, 0, -90), re = A(90), le = A(90), neck = A(0, 40), waist = A(0, 20) },
	[2] = { rs = A(90), ls = A(90) },
	[3] = { rs = A(0, 0, 45), ls = A(0, 0, -45), re = A(90), le = A(90), neck = A(0, -40), waist = A(0, -20) },
}

local T_POSE = { rs = A(0, 0, 90), ls = A(0, 0, -90) }

local DAB = {
	neck = A(35, -25),
	waist = A(-6, -18),
	rs = A(55, 0, -35), re = A(125),
	ls = A(0, 0, -150),
}

local function nz(t, speed, seed)
	return math.noise(t * speed, seed + 0.37)
end

-- anim = Roblox'un hazır animasyonu | proc = kodla yapılan hareket (sadece sen görürsün, R15 ister)
local EMOTES = {
	-- DANSLAR
	{ category = "DANSLAR", name = "Klasik Dans", anim = "dance1" },
	{ category = "DANSLAR", name = "Şen Dans", anim = "dance2" },
	{ category = "DANSLAR", name = "Çılgın Dans", anim = "dance3" },
	{ category = "DANSLAR", name = "Floss Dansı", proc = function(t)
		local w = sin(t * 9)
		return {
			root = CFrame.new(-0.4 * w, 0, 0),
			waist = A(0, 0, -6 * w),
			rs = A(30, 0, 55 * w), ls = A(-30, 0, 55 * w),
			neck = A(0, 12 * w),
		}
	end },
	{ category = "DANSLAR", name = "Robot Dansı", proc = function(t)
		return ROBOT[floor(t * 3) % 4]
	end },
	{ category = "DANSLAR", name = "Fırıldak Dönme", proc = function(t)
		return {
			root = CFrame.new(0, 0.15 * abs(sin(t * 6)), 0) * A(0, (t * 300) % 360, 0),
			rs = A(0, 0, 80), ls = A(0, 0, -80),
		}
	end },
	{ category = "DANSLAR", name = "Tavuk Dansı", proc = function(t)
		local f = sin(t * 10)
		local b = abs(sin(t * 5))
		return {
			rs = A(0, 0, 55 + 25 * f), ls = A(0, 0, -55 - 25 * f),
			re = A(40), le = A(40),
			neck = CFrame.new(0, 0, -0.25 * sin(t * 5)),
			root = CFrame.new(0, -0.3 * b, 0),
			rh = A(20 * b), lh = A(20 * b),
			rk = A(-35 * b), lk = A(-35 * b),
		}
	end },
	{ category = "DANSLAR", name = "Dab Pozu", proc = function(t) return DAB end },
	{ category = "DANSLAR", name = "T Duruşu", proc = function(t) return T_POSE end },

	-- KOMİK / TROLL
	{ category = "KOMİK / TROLL", name = "Troll Dansı", proc = function(t)
		local w = sin(t * 8)
		return {
			root = CFrame.new(0.3 * w, 0.25 * abs(w), 0) * A(0, 0, -8 * w),
			waist = A(0, 30 * w),
			neck = A(0, -30 * w, 8 * w),
			rs = A(55 * w, 0, 25), ls = A(-55 * w, 0, -25),
			rh = A(20 * w), lh = A(-20 * w),
		}
	end },
	{ category = "KOMİK / TROLL", name = "Dalga Geçme", proc = function(t)
		local w = sin(t * 6)
		local h = sin(t * 12)
		return {
			neck = A(0, 0, 22 * w),
			waist = A(0, 0, -10 * w),
			rs = A(-30, 0, 125 + 12 * h),
			ls = A(-30, 0, -125 - 12 * h),
			root = CFrame.new(0.25 * w, 0, 0),
		}
	end },
	{ category = "KOMİK / TROLL", name = "Kafa Sallama", proc = function(t)
		local n = sin(t * 10)
		return {
			neck = A(30 * n),
			waist = A(-6 * n),
			rs = A(0, 0, 15), ls = A(0, 0, -15),
		}
	end },
	{ category = "KOMİK / TROLL", name = "Hayır Kafası", proc = function(t)
		local n = sin(t * 7)
		return {
			neck = A(0, 45 * n),
			waist = A(0, 8 * n),
		}
	end },
	{ category = "KOMİK / TROLL", name = "Gülme", anim = "laugh" },
	{ category = "KOMİK / TROLL", name = "Kahkaha Atma", proc = function(t)
		local b = sin(t * 16)
		return {
			waist = A(-14 + 7 * b),
			neck = A(-18 + 8 * b),
			rs = A(35, 0, -10), re = A(75),
			ls = A(35, 0, 10), le = A(75),
			root = CFrame.new(0, 0.1 * abs(b), 0),
		}
	end },
	{ category = "KOMİK / TROLL", name = "El Sallama", anim = "wave" },
	{ category = "KOMİK / TROLL", name = "Parmakla Gösterme", anim = "point" },
	{ category = "KOMİK / TROLL", name = "Sevinç Gösterisi", anim = "cheer" },

	-- KORKUNÇ
	{ category = "KORKUNÇ", name = "Zombi Yürüyüşü", proc = function(t)
		local w = sin(t * 3)
		return {
			rs = A(88 + 6 * w), ls = A(88 - 6 * w),
			re = A(10), le = A(10),
			neck = A(10, 8 * w, 22),
			waist = A(-12, 10 * w, 4 * w),
			root = CFrame.new(0.1 * w, 0, 0) * A(0, 0, 5 * w),
			rh = A(28 * w), lh = A(-28 * w),
			rk = A(-30 * math.max(0, -w)), lk = A(-30 * math.max(0, w)),
		}
	end },
	{ category = "KORKUNÇ", name = "Kafa Döndürme", proc = function(t)
		return {
			neck = A(0, (t * 220) % 360, 4 * sin(t * 30)),
			waist = A(-8),
			rs = A(0, 0, 12), ls = A(0, 0, -12),
		}
	end },
	{ category = "KORKUNÇ", name = "Korkudan Titreme", proc = function(t)
		return {
			waist = A(3 * sin(t * 37), 3 * sin(t * 41), 4 * sin(t * 35)),
			neck = A(-5 + 4 * sin(t * 43), 5 * sin(t * 39)),
			rs = A(35 + 4 * sin(t * 45), 0, -20), re = A(115),
			ls = A(35 + 4 * sin(t * 47), 0, 20), le = A(115),
			rk = A(-25 + 4 * sin(t * 40)), lk = A(-25 + 4 * sin(t * 44)),
			rh = A(18), lh = A(18),
			root = CFrame.new(0, -0.35, 0),
		}
	end },
	{ category = "KORKUNÇ", name = "Hayalet Süzülmesi", proc = function(t)
		local f = sin(t * 2)
		return {
			root = CFrame.new(0, 0.8 + 0.4 * f, 0) * A(-8, 0, 6 * sin(t * 1.5)),
			rs = A(55, 0, -6), ls = A(55, 0, 6),
			re = A(35), le = A(35),
			neck = A(10, 0, 12 * sin(t * 1.5)),
			rh = A(8), lh = A(8),
			rk = A(-25 - 8 * f), lk = A(-25 - 8 * f),
		}
	end },
	{ category = "KORKUNÇ", name = "Şeytani Kahkaha", proc = function(t)
		local b = sin(t * 14)
		local r = sin(t * 10)
		return {
			waist = A(-24 + 7 * b),
			neck = A(-30 + 8 * b),
			rs = A(45 + 6 * r, 0, -15), re = A(105),
			ls = A(45 - 6 * r, 0, 15), le = A(105),
			root = CFrame.new(0, 0.08 * b, 0),
		}
	end },
	{ category = "KORKUNÇ", name = "Kukla Hareketi", proc = function(t)
		return {
			neck = A(70 * nz(t, 1.5, 1), 50 * nz(t, 1.5, 2), 40 * nz(t, 1.5, 3)),
			waist = A(30 * nz(t, 1.2, 4), 40 * nz(t, 1.2, 5), 25 * nz(t, 1.2, 6)),
			rs = A(110 * nz(t, 1.3, 7), 0, 25 + 60 * abs(nz(t, 1.3, 8))),
			ls = A(110 * nz(t, 1.3, 9), 0, -25 - 60 * abs(nz(t, 1.3, 10))),
			re = A(60 + 60 * nz(t, 1.4, 11)),
			le = A(60 + 60 * nz(t, 1.4, 12)),
			rh = A(50 * nz(t, 1.1, 13)), lh = A(50 * nz(t, 1.1, 14)),
			rk = A(-30 - 40 * abs(nz(t, 1.1, 15))), lk = A(-30 - 40 * abs(nz(t, 1.1, 16))),
			root = CFrame.new(0, 0.3 * nz(t, 1.5, 17), 0),
		}
	end },
}

local CATEGORY_ORDER = { "DANSLAR", "KOMİK / TROLL", "KORKUNÇ" }

-- Başka hareketin kodunu tekrar kullanmak için
local function procOf(name)
	for _, e in ipairs(EMOTES) do
		if e.name == name then
			return e.proc
		end
	end
end

-- MM2 SEKMESİ ------------------------------------------------
-- Murder Mystery 2'deki animasyon hareketlerine (Zen, Sit, Ninja Rest, Headless, Zombie, Floss, Dab)
-- benzeyen taklitler + oyunun rollerinden esinlenen pozlar.
local function zenPose(t)
	local f = sin(t * 1.5)
	return {
		root = CFrame.new(0, 1.2 + 0.4 * f, 0),
		rh = A(75, 0, 35), lh = A(75, 0, -35),
		rk = A(-125), lk = A(-125),
		rs = A(35, 0, -10), ls = A(35, 0, 10),
		re = A(25), le = A(25),
		waist = A(-6), neck = A(8),
	}
end

local function sitPose(t)
	return {
		root = CFrame.new(0, -1.2, 0),
		rh = A(90, 0, 15), lh = A(90, 0, -15),
		rk = A(-90), lk = A(-90),
		rs = A(25, 0, -5), ls = A(25, 0, 5),
		neck = A(0, 35 * sin(t * 1.2)),
	}
end

local function ninjaRestPose(t)
	local sway = sin(t * 2)
	return {
		root = CFrame.new(0, -1.0, 0) * A(0, 0, -80 + 8 * sway),
		neck = A(0, 0, 70 - 8 * sway),
		rs = A(0, 0, 80),
		ls = A(0, 0, -20),
		rh = A(0, 0, 4 * sway), lh = A(0, 0, -4 * sway),
	}
end

local function headlessPose(t)
	local k = math.clamp(sin(t * 0.7) * 1.6, 0, 1)
	return {
		neck = CFrame.new(1.0 * k, -0.7 * k, -1.9 * k) * A(0, -25 * k, 0),
		rs = A(80 * k, 0, -5 * k),
		re = A(10 * k),
		ls = A(0, 0, -8 * k),
	}
end

local function murdererPose(t)
	local b = sin(t * 2)
	return {
		rs = A(95, 0, -10 + 4 * b), re = A(35),
		ls = A(0, 0, -15),
		neck = A(15, 10 * sin(t), 12),
		waist = A(-10, 12, 0),
		root = CFrame.new(0, -0.2, 0),
		rh = A(10), lh = A(-10),
		rk = A(-10), lk = A(-10),
	}
end

local function sheriffPose(t)
	return {
		rs = A(90, 0, -3), re = A(5),
		ls = A(60, 0, 8), le = A(80),
		neck = A(0, -8),
		waist = A(0, -10),
		rh = A(10), lh = A(-12),
	}
end

local function surrenderPose(t)
	local sh = sin(t * 20)
	return {
		rs = A(0, 0, 150 + 3 * sh), ls = A(0, 0, -150 - 3 * sh),
		neck = A(-8),
		root = CFrame.new(0, -0.15 + 0.03 * sh, 0),
		rk = A(-12), lk = A(-12), rh = A(8), lh = A(8),
	}
end

local function deadPose(t)
	return {
		root = CFrame.new(0, -2.4, 0) * A(90),
		neck = A(-10 + 2 * sin(t * 3)),
		rs = A(0, 0, 20), ls = A(0, 0, -20),
	}
end

table.insert(EMOTES, { category = "MM2", name = "Zen Meditasyonu", proc = zenPose })
table.insert(EMOTES, { category = "MM2", name = "Oturma", proc = sitPose })
table.insert(EMOTES, { category = "MM2", name = "Ninja Dinlenmesi", proc = ninjaRestPose })
table.insert(EMOTES, { category = "MM2", name = "Kafasız Gösteri", proc = headlessPose })
table.insert(EMOTES, { category = "MM2", name = "Zombi (MM2)", proc = procOf("Zombi Yürüyüşü") })
table.insert(EMOTES, { category = "MM2", name = "Floss (MM2)", proc = procOf("Floss Dansı") })
table.insert(EMOTES, { category = "MM2", name = "Dab (MM2)", proc = procOf("Dab Pozu") })
table.insert(EMOTES, { category = "MM2", name = "Katil Pozu", proc = murdererPose })
table.insert(EMOTES, { category = "MM2", name = "Şerif Nişanı", proc = sheriffPose })
table.insert(EMOTES, { category = "MM2", name = "Teslim Olma", proc = surrenderPose })
table.insert(EMOTES, { category = "MM2", name = "Ölü Taklidi", proc = deadPose })

-- DUVAR FAZI SEKMESİ -----------------------------------------
-- phase = true olan hareket açıkken duvarların içinden geçersin (karakter yarı saydam olur)
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Duvar Fazı", phase = true, proc = function(t)
	local s = sin(t * 3)
	return {
		root = CFrame.new(0, 0.15 * s, 0),
		rs = A(25, 0, -8), ls = A(25, 0, 8),
		neck = A(0, 0, 6 * s),
		waist = A(-4 + 2 * s),
	}
end })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Hayalet Geçişi", phase = true, proc = procOf("Hayalet Süzülmesi") })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Zombi Fazı", phase = true, proc = procOf("Zombi Yürüyüşü") })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Zen Fazı", phase = true, proc = zenPose })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Floss Fazı", phase = true, proc = procOf("Floss Dansı") })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Troll Fazı", phase = true, proc = procOf("Troll Dansı") })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Fırıldak Fazı", phase = true, proc = procOf("Fırıldak Dönme") })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Kafasız Faz", phase = true, proc = headlessPose })
table.insert(EMOTES, { category = "DUVAR FAZI", name = "Kukla Fazı", phase = true, proc = procOf("Kukla Hareketi") })

-- R15 eklemlerini bul
local function findJoints(char)
	local function j(partName, jointName)
		local part = char:FindFirstChild(partName)
		return part and part:FindFirstChild(jointName)
	end
	return {
		neck = j("Head", "Neck"),
		waist = j("UpperTorso", "Waist"),
		root = j("LowerTorso", "Root"),
		rs = j("RightUpperArm", "RightShoulder"),
		ls = j("LeftUpperArm", "LeftShoulder"),
		re = j("RightLowerArm", "RightElbow"),
		le = j("LeftLowerArm", "LeftElbow"),
		rh = j("RightUpperLeg", "RightHip"),
		lh = j("LeftUpperLeg", "LeftHip"),
		rk = j("RightLowerLeg", "RightKnee"),
		lk = j("LeftLowerLeg", "LeftKnee"),
	}
end

----------------------------------------------------------------
-- HAREKET MOTORU
----------------------------------------------------------------
-- DUVAR FAZI SİSTEMİ
-- Hareket açıkken karakterin çarpışması kapatılır (sadece senin ekranında geçerli).
-- Hareket bitince duvarın içindeysen, dışarı çıkana kadar çarpışma kapalı kalır
-- (yoksa duvarın içinde sıkışırsın).
local phaseConn, phaseChar
local phaseSaved = {}
local phaseExiting = false
local phaseExitStart = 0

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function overlapsWorld(char, root)
	overlapParams.FilterDescendantsInstances = { char }
	local parts = workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(3, 4.5, 3), overlapParams)
	for _, p in ipairs(parts) do
		if p.CanCollide then
			return true
		end
	end
	return false
end

local function setGhost(char, amount)
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = amount
		end
	end
end

local function endPhaseNow()
	if phaseConn then
		phaseConn:Disconnect()
		phaseConn = nil
	end
	for part, original in pairs(phaseSaved) do
		if part.Parent then
			part.CanCollide = original
			part.LocalTransparencyModifier = 0
		end
	end
	phaseSaved = {}
	phaseChar = nil
	phaseExiting = false
end

local function beginPhase(char)
	if phaseConn and phaseChar ~= char then
		endPhaseNow()
	end
	phaseExiting = false
	if phaseConn then return end

	phaseChar = char
	phaseSaved = {}
	phaseConn = RunService.Stepped:Connect(function()
		local c = phaseChar
		if not c or not c.Parent then
			endPhaseNow()
			return
		end
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then
				if phaseSaved[p] == nil then
					phaseSaved[p] = p.CanCollide
				end
				p.CanCollide = false
				if not phaseExiting then
					p.LocalTransparencyModifier = 0.55
				end
			end
		end
		if phaseExiting then
			local root = c:FindFirstChild("HumanoidRootPart")
			if not root or os.clock() - phaseExitStart > 8 or not overlapsWorld(c, root) then
				endPhaseNow()
			end
		end
	end)
end

local function requestPhaseExit()
	if not phaseConn or phaseExiting then return end
	phaseExiting = true
	phaseExitStart = os.clock()
	if phaseChar then
		setGhost(phaseChar, 0)
	end
end

local activeName, activeTrack, poseConn, activeStart
local activeIsProc = false
local motors, origC0 = {}, {}

local rows = {}          -- ekrandaki hareket satırları (vurgulamak için)
local statusLabel

local function refreshHighlights()
	for name, row in pairs(rows) do
		if row.Parent then
			row.BackgroundColor3 = (name == activeName) and ACTIVE_COLOR or ROW_COLOR
		end
	end
end

local function updateStatus()
	if statusLabel then
		statusLabel.Text = activeName and ("Çalan: " .. activeName) or "Çalan: Hiçbiri"
	end
end

local function toast(text)
	if statusLabel then
		statusLabel.Text = text
		task.delay(2.5, updateStatus)
	end
end

local function stopEmote()
	requestPhaseExit()
	if poseConn then
		poseConn:Disconnect()
		poseConn = nil
	end
	if activeTrack then
		local tr = activeTrack
		activeTrack = nil
		tr:Stop(0.2)
	end
	for _, motor in pairs(motors) do
		if motor.Parent and origC0[motor] then
			motor.C0 = origC0[motor]
		end
	end
	motors, origC0 = {}, {}
	activeName = nil
	activeIsProc = false
	updateStatus()
	refreshHighlights()
end

local function playEmote(emote)
	-- Aynı harekete tekrar basınca kapat
	if activeName == emote.name then
		stopEmote()
		return
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local isR15 = hum.RigType == Enum.HumanoidRigType.R15
	if emote.proc and not isR15 then
		toast("Bu hareket R15 karakter ister")
		return
	end

	stopEmote()

	if emote.anim then
		-- Hazır Roblox animasyonu
		local ids = isR15 and BUILTIN.R15 or BUILTIN.R6
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. ids[emote.anim]

		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = settings.loop
		track:Play(0.2, 1, settings.speed)

		activeTrack = track
		activeName = emote.name
		activeIsProc = false
		track.Stopped:Connect(function()
			if activeTrack == track then
				stopEmote()
			end
		end)
	else
		-- Kodla yapılan hareket
		local joints = findJoints(char)
		motors, origC0 = {}, {}
		for key, motor in pairs(joints) do
			if motor:IsA("Motor6D") then
				motors[key] = motor
				origC0[motor] = motor.C0
			end
		end

		activeName = emote.name
		activeIsProc = true
		activeStart = os.clock()

		if emote.phase then
			beginPhase(char)
		end

		local phase = 0
		poseConn = RunService.RenderStepped:Connect(function(dt)
			phase = phase + dt * settings.speed
			local pose = emote.proc(phase)
			for key, motor in pairs(motors) do
				if motor.Parent then
					local p = pose[key] or CFrame.identity
					if key == "root" then
						motor.C0 = p * origC0[motor]
					else
						motor.C0 = origC0[motor] * p
					end
				end
			end
		end)
	end

	updateStatus()
	refreshHighlights()
end

-- Ölünce, yürüyünce (ayara bağlı) veya süre dolunca (tekrar kapalıysa) durdur
RunService.Heartbeat:Connect(function()
	if not activeName then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		stopEmote()
		return
	end
	if settings.stopOnMove and hum.MoveDirection.Magnitude > 0.1 then
		stopEmote()
		return
	end
	if activeIsProc and not settings.loop and os.clock() - activeStart > PLAY_ONCE_TIME then
		stopEmote()
	end
end)

player.CharacterRemoving:Connect(stopEmote)

----------------------------------------------------------------
-- ARAYÜZ
----------------------------------------------------------------
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function round(inst, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) }, inst)
end

local gui = new("ScreenGui", {
	Name = "HareketMenusu",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
}, player:WaitForChild("PlayerGui"))

-- MENÜ PANELİ ------------------------------------------------
local panel = new("Frame", {
	Name = "Menu",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.62, 0.86),
	BackgroundColor3 = PANEL_COLOR,
	BackgroundTransparency = 0.05,
	Visible = false,
}, gui)
round(panel, 14)
new("UISizeConstraint", { MinSize = Vector2.new(300, 240), MaxSize = Vector2.new(440, 360) }, panel)
new("UIStroke", { Color = RED, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel)

-- Başlık
local header = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, panel)
new("TextLabel", {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(1, -52, 1, 0),
	BackgroundTransparency = 1,
	Text = "HAREKET MENÜSÜ",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)
local closeBtn = new("TextButton", {
	Position = UDim2.new(1, -36, 0, 4),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = RED,
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = WHITE,
}, header)
round(closeBtn, 14)

-- Sekmeler
-- Sekme çubuğu: parmakla sağa sola kaydırılır
local tabBar = new("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 38),
	Size = UDim2.new(1, -16, 0, 30),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.X,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
}, panel)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local TAB_NAMES = { "Hareketler", "Favoriler", "MM2", "Duvar Fazı", "Ayarlar" }
local tabButtons = {}
local currentTab = "Hareketler"

for i, tabName in ipairs(TAB_NAMES) do
	local b = new("TextButton", {
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = ROW_COLOR,
		Text = tabName,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = WHITE,
		LayoutOrder = i,
	}, tabBar)
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, b)
	round(b, 8)
	tabButtons[tabName] = b
end

-- İçerik alanı
local content = new("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 74),
	Size = UDim2.new(1, -16, 1, -124),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, content)

-- Alt çubuk: çalan hareket + DURDUR
local footer = new("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 8, 1, -6),
	Size = UDim2.new(1, -16, 0, 38),
	BackgroundColor3 = ROW_COLOR,
}, panel)
round(footer, 8)

statusLabel = new("TextLabel", {
	Position = UDim2.fromOffset(10, 0),
	Size = UDim2.new(1, -104, 1, 0),
	BackgroundTransparency = 1,
	Text = "",
	Font = Enum.Font.GothamMedium,
	TextSize = 14,
	TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, footer)

local stopBtn = new("TextButton", {
	Position = UDim2.new(1, -94, 0.5, -15),
	Size = UDim2.fromOffset(86, 30),
	BackgroundColor3 = RED,
	Text = "DURDUR",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = WHITE,
}, footer)
round(stopBtn, 8)
stopBtn.Activated:Connect(stopEmote)

-- KIRMIZI BUTON ----------------------------------------------
local openBtn = new("TextButton", {
	Name = "MenuButonu",
	Size = UDim2.fromOffset(settings.buttonSize, settings.buttonSize),
	Position = UDim2.fromOffset(16, math.floor(camera.ViewportSize.Y * 0.3)),
	BackgroundColor3 = settings.buttonColor,
	Text = "MENÜ",
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = WHITE,
	AutoButtonColor = false,
	ZIndex = 10,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, openBtn)
new("UIStroke", { Color = WHITE, Transparency = 0.4, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, openBtn)
new("UIPadding", {
	PaddingLeft = UDim.new(0.16, 0), PaddingRight = UDim.new(0.16, 0),
	PaddingTop = UDim.new(0.3, 0), PaddingBottom = UDim.new(0.3, 0),
}, openBtn)

local function setButtonPos(x, y)
	local vp = camera.ViewportSize
	local size = settings.buttonSize
	x = math.clamp(x, 0, math.max(vp.X - size, 0))
	y = math.clamp(y, 0, math.max(vp.Y - size, 0))
	openBtn.Position = UDim2.fromOffset(x, y)
end

local function applyButtonLook()
	openBtn.Size = UDim2.fromOffset(settings.buttonSize, settings.buttonSize)
	openBtn.BackgroundColor3 = settings.buttonColor
	setButtonPos(openBtn.Position.X.Offset, openBtn.Position.Y.Offset)
end

----------------------------------------------------------------
-- SEKMELER
----------------------------------------------------------------
local showTab

local function clearContent()
	table.clear(rows)
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function addHeader(text, order)
	new("TextLabel", {
		Size = UDim2.new(1, -6, 0, 22),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 90, 90),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
	}, content)
end

local function addEmoteRow(emote, order)
	local row = new("Frame", {
		Size = UDim2.new(1, -6, 0, 40),
		BackgroundColor3 = (emote.name == activeName) and ACTIVE_COLOR or ROW_COLOR,
		LayoutOrder = order,
	}, content)
	round(row, 8)
	rows[emote.name] = row

	local playBtn = new("TextButton", {
		Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1,
		Text = emote.name,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, playBtn)
	playBtn.Activated:Connect(function()
		playEmote(emote)
	end)

	local fav = new("TextButton", {
		Position = UDim2.new(1, -42, 0, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Text = favorites[emote.name] and "★" or "☆",
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextColor3 = favorites[emote.name] and GOLD or Color3.fromRGB(150, 150, 160),
	}, row)
	fav.Activated:Connect(function()
		favorites[emote.name] = (not favorites[emote.name]) or nil
		if currentTab == "Favoriler" then
			showTab("Favoriler")
		else
			fav.Text = favorites[emote.name] and "★" or "☆"
			fav.TextColor3 = favorites[emote.name] and GOLD or Color3.fromRGB(150, 150, 160)
		end
	end)
end

local function buildEmoteTab()
	local order = 0
	for _, category in ipairs(CATEGORY_ORDER) do
		order += 1
		addHeader(category, order)
		for _, emote in ipairs(EMOTES) do
			if emote.category == category then
				order += 1
				addEmoteRow(emote, order)
			end
		end
	end
end

local function buildFavoritesTab()
	local order = 0
	for _, emote in ipairs(EMOTES) do
		if favorites[emote.name] then
			order += 1
			addEmoteRow(emote, order)
		end
	end
	if order == 0 then
		new("TextLabel", {
			Size = UDim2.new(1, -6, 0, 70),
			BackgroundTransparency = 1,
			Text = "Henüz favori yok.\nHareketler sekmesinde ☆ simgesine basarak ekle.",
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(170, 170, 180),
		}, content)
	end
end

-- MM2 ve Duvar Fazı sekmeleri: tek kategorinin hareketlerini listeler
local function buildCategoryTab(category, note)
	local order = 0
	if note then
		order += 1
		new("TextLabel", {
			Size = UDim2.new(1, -6, 0, 54),
			BackgroundTransparency = 1,
			Text = note,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(170, 170, 180),
			LayoutOrder = order,
		}, content)
	end
	for _, emote in ipairs(EMOTES) do
		if emote.category == category then
			order += 1
			addEmoteRow(emote, order)
		end
	end
end

-- Ayarlar satırları
local function addStepper(label, getText, onMinus, onPlus, order)
	local row = new("Frame", {
		Size = UDim2.new(1, -6, 0, 44),
		BackgroundColor3 = ROW_COLOR,
		LayoutOrder = order,
	}, content)
	round(row, 8)
	new("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local minus = new("TextButton", {
		Position = UDim2.new(1, -134, 0.5, -15),
		Size = UDim2.fromOffset(34, 30),
		BackgroundColor3 = RED,
		Text = "-",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = WHITE,
	}, row)
	round(minus, 8)
	local value = new("TextLabel", {
		Position = UDim2.new(1, -96, 0.5, -15),
		Size = UDim2.fromOffset(54, 30),
		BackgroundTransparency = 1,
		Text = getText(),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = WHITE,
	}, row)
	local plus = new("TextButton", {
		Position = UDim2.new(1, -42, 0.5, -15),
		Size = UDim2.fromOffset(34, 30),
		BackgroundColor3 = RED,
		Text = "+",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = WHITE,
	}, row)
	round(plus, 8)

	minus.Activated:Connect(function()
		onMinus()
		value.Text = getText()
	end)
	plus.Activated:Connect(function()
		onPlus()
		value.Text = getText()
	end)
end

local function addToggle(label, getValue, onToggle, order)
	local row = new("Frame", {
		Size = UDim2.new(1, -6, 0, 44),
		BackgroundColor3 = ROW_COLOR,
		LayoutOrder = order,
	}, content)
	round(row, 8)
	new("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local btn = new("TextButton", {
		Position = UDim2.new(1, -92, 0.5, -15),
		Size = UDim2.fromOffset(84, 30),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = WHITE,
	}, row)
	round(btn, 8)

	local function refresh()
		local on = getValue()
		btn.Text = on and "AÇIK" or "KAPALI"
		btn.BackgroundColor3 = on and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(90, 90, 100)
	end
	refresh()
	btn.Activated:Connect(function()
		onToggle()
		refresh()
	end)
end

local COLORS = {
	Color3.fromRGB(220, 20, 40),   -- kırmızı
	Color3.fromRGB(30, 120, 255),  -- mavi
	Color3.fromRGB(40, 190, 90),   -- yeşil
	Color3.fromRGB(150, 60, 230),  -- mor
	Color3.fromRGB(255, 140, 0),   -- turuncu
	Color3.fromRGB(255, 80, 170),  -- pembe
	Color3.fromRGB(25, 25, 25),    -- siyah
}

local function addColorPicker(order)
	local row = new("Frame", {
		Size = UDim2.new(1, -6, 0, 76),
		BackgroundColor3 = ROW_COLOR,
		LayoutOrder = order,
	}, content)
	round(row, 8)
	new("TextLabel", {
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -20, 0, 24),
		BackgroundTransparency = 1,
		Text = "Buton Rengi",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local holder = new("Frame", {
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -20, 0, 34),
		BackgroundTransparency = 1,
	}, row)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, holder)

	local strokes = {}
	for i, color in ipairs(COLORS) do
		local sw = new("TextButton", {
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = color,
			Text = "",
			AutoButtonColor = false,
		}, holder)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
		strokes[i] = new("UIStroke", {
			Color = WHITE,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Enabled = (settings.buttonColor == color),
		}, sw)
		sw.Activated:Connect(function()
			settings.buttonColor = color
			applyButtonLook()
			for j, st in ipairs(strokes) do
				st.Enabled = (j == i)
			end
		end)
	end
end

local function buildSettingsTab()
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	addStepper("Hareket Hızı",
		function() return tostring(settings.speed) .. "x" end,
		function()
			settings.speed = math.clamp(settings.speed - 0.25, 0.25, 3)
			if activeTrack then activeTrack:AdjustSpeed(settings.speed) end
		end,
		function()
			settings.speed = math.clamp(settings.speed + 0.25, 0.25, 3)
			if activeTrack then activeTrack:AdjustSpeed(settings.speed) end
		end,
		nextOrder())

	addToggle("Sonsuz Tekrar",
		function() return settings.loop end,
		function()
			settings.loop = not settings.loop
			if activeTrack then activeTrack.Looped = settings.loop end
			if activeIsProc then activeStart = os.clock() end
		end,
		nextOrder())

	addToggle("Yürüyünce Durdur",
		function() return settings.stopOnMove end,
		function() settings.stopOnMove = not settings.stopOnMove end,
		nextOrder())

	addStepper("Buton Boyutu",
		function() return tostring(settings.buttonSize) end,
		function()
			settings.buttonSize = math.clamp(settings.buttonSize - 10, 40, 120)
			applyButtonLook()
		end,
		function()
			settings.buttonSize = math.clamp(settings.buttonSize + 10, 40, 120)
			applyButtonLook()
		end,
		nextOrder())

	addColorPicker(nextOrder())
end

function showTab(name)
	currentTab = name
	for tabName, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (tabName == name) and RED or ROW_COLOR
	end
	clearContent()
	content.CanvasPosition = Vector2.zero

	if name == "Hareketler" then
		buildEmoteTab()
	elseif name == "Favoriler" then
		buildFavoritesTab()
	elseif name == "MM2" then
		buildCategoryTab("MM2", "Murder Mystery 2'deki hareketlere benzeyen taklitler ve oyunun rollerinden esinlenen pozlar.")
	elseif name == "Duvar Fazı" then
		buildCategoryTab("DUVAR FAZI", "Bu hareketler açıkken duvarların içinden geçersin. Kapatınca duvarın içindeysen, dışarı çıkana kadar geçiş sürer.")
	else
		buildSettingsTab()
	end
end

for tabName, btn in pairs(tabButtons) do
	btn.Activated:Connect(function()
		showTab(tabName)
	end)
end

----------------------------------------------------------------
-- MENÜYÜ AÇ / KAPAT + BUTONU SÜRÜKLEME
----------------------------------------------------------------
local function toggleMenu()
	panel.Visible = not panel.Visible
	if panel.Visible then
		showTab(currentTab)
	end
end

closeBtn.Activated:Connect(function()
	panel.Visible = false
end)

local dragInput, dragStart, startX, startY, dragged

openBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragInput = input
		dragStart = input.Position
		startX = openBtn.Position.X.Offset
		startY = openBtn.Position.Y.Offset
		dragged = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragInput then return end
	local isMove = (input == dragInput)
		or (input.UserInputType == Enum.UserInputType.MouseMovement
			and dragInput.UserInputType == Enum.UserInputType.MouseButton1)
	if not isMove then return end

	local delta = input.Position - dragStart
	if delta.Magnitude > 8 then
		dragged = true
	end
	if dragged then
		setButtonPos(startX + delta.X, startY + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not dragInput then return end
	local isEnd = (input == dragInput)
		or (input.UserInputType == Enum.UserInputType.MouseButton1
			and dragInput.UserInputType == Enum.UserInputType.MouseButton1)
	if isEnd then
		if not dragged then
			toggleMenu()
		end
		dragInput = nil
	end
end)

updateStatus()
print("Hareket menüsü yüklendi")
