local mod = ReworkedFoes

mod.RNG = RNG()



--[[ New entity enums ]]--
mod.Entities = {
	-- Projectiles
	FeatherProjectile = Isaac.GetEntityVariantByName("Angelic Feather Projectile"),
	SuckerProjectile  = Isaac.GetEntityVariantByName("Sucker Projectile"),
	EggSackProjectile = Isaac.GetEntityVariantByName("Egg Sack Projectile"),


	-- Enemies
	Type = 200,

	Brazier 	= Isaac.GetEntityVariantByName("Brazier"),
	Teratomar 	= Isaac.GetEntityVariantByName("Teratomar"),
	GiantSpike 	= Isaac.GetEntityVariantByName("Giant Spike"),
	Wallace 	= Isaac.GetEntityVariantByName("Wallace"),
	Coffer 		= Isaac.GetEntityVariantByName("Coffer"),
	BoneOrbital = Isaac.GetEntityVariantByName("Enemy Bone Orbital"),
	Mullicocoon = Isaac.GetEntityVariantByName("Mullicocoon"),
	RagPlasma 	= Isaac.GetEntityVariantByName("Rag Mega Plasma"),
	SkyLaser 	= Isaac.GetEntityVariantByName("Sister Vis Laser"),

	ClottySketch  = Isaac.GetEntityVariantByName("Clotty Sketch"),
	ChargerSketch = Isaac.GetEntityVariantByName("Charger Sketch"),
	GlobinSketch  = Isaac.GetEntityVariantByName("Globin Sketch"),
	MawSketch 	  = Isaac.GetEntityVariantByName("Maw Sketch"),

	BlueBabyExtras = Isaac.GetEntityVariantByName("Forgotten Body (Boss)"),
		ForgottenBody  = 0,
		ForgottenChain = 1,
		LostHolyOrb	   = 2,


	-- Champion subtypes (They're defined here so they can be changed by the compatibility mods)
	PinChampion 	= 2,
	KrampusChampion = 1,


	-- Effects
	DirtHelper 	   = Isaac.GetEntityVariantByName("Scolex Dirt Helper"),
	HealingAura    = Isaac.GetEntityVariantByName("Healing Aura"),
	HolyTracer 	   = Isaac.GetEntityVariantByName("Holy Tracer"),
	BrimstoneSwirl = Isaac.GetEntityVariantByName("Single Brimstone Swirl"),
	OneTimeEffect  = Isaac.GetEntityVariantByName("One Time Effect"),
	SkyLaserEffect = Isaac.GetEntityVariantByName("Sister Vis Laser Effect"),

	TriachnidLeg = Isaac.GetEntityVariantByName("Triachnid Leg Segment"),
		TriachnidJoint    = 0,
		TriachnidUpperLeg = 1,
		TriachnidLowerLeg = 2,
}



--[[ Colors ]]--
mod.Colors = {}

mod.Colors.BrimShot   = Color(1,0.25,0.25, 1, 0.25,0,0)
mod.Colors.ShadyRed   = Color(-1,-1,-1, 1, 1,0,0)
mod.Colors.Tar 		  = Color(1,1,1, 1)   						mod.Colors.Tar:SetColorize(1,1,1, 1)   mod.Colors.Tar:SetTint(0.5,0.5,0.5, 1)
mod.Colors.WhiteShot  = Color(1,1,1, 1, 0.5,0.5,0.5)   		 	mod.Colors.WhiteShot:SetColorize(1,1,1, 1)
mod.Colors.SunBeam 	  = Color(1,1,1, 1, 0.3,0.3,0)
mod.Colors.DustPoof   = Color(0.7,0.7,0.7, 0.75)
mod.Colors.DustTrail  = Color(0.8,0.8,0.8, 0.8, 0.05,0.025,0)   mod.Colors.DustTrail:SetColorize(1,1,1, 1)
mod.Colors.BlackBony  = Color(0.18,0.18,0.18, 1)
mod.Colors.PukeEffect = Color(0,0,0, 1, 0.48,0.36,0.3)
mod.Colors.PukeOrange = Color(0.5,0.5,0.5, 1, 0.64,0.4,0.16)
mod.Colors.Sketch 	  = Color(0,0,0, 1, 0.48,0.4,0.36)
mod.Colors.Heal 	  = Color(1,1,1, 1, 0.64,0,0)

mod.Colors.CrispyMeat   = Color(1,1,1, 1);   				 mod.Colors.CrispyMeat:SetColorize(0.32,0.25,0.2, 1)
mod.Colors.EmberFade    = Color(0,0,0, 1.1, 1,0.514,0.004)   mod.Colors.EmberFade:SetColorize(0,0,0, 0)    mod.Colors.EmberFade:SetTint(0,0,0, 1.1)
mod.Colors.PurpleFade   = Color(0,0,0, 1.1, 0.65,0.125,1)    mod.Colors.PurpleFade:SetColorize(0,0,0, 0)   mod.Colors.PurpleFade:SetTint(0,0,0, 1.1)
mod.Colors.BlueFire 	= Color(0,1,1, 1, -0.5,0.35,0.9)     mod.Colors.BlueFire:SetColorize(1,1,1, 1)
mod.Colors.BlueFireShot = Color(1,1,1, 1, 0,0.6,1.2)   	     mod.Colors.BlueFireShot:SetColorize(1,1,1, 1)

mod.Colors.Ipecac 			= Color(1,1,1, 1, 0,0,0)   mod.Colors.Ipecac:SetColorize(0.4,2,0.5, 1)
mod.Colors.GreenCreep 		= Color(0,0,0, 1, 0,0.5,0)
mod.Colors.GreenBlood 		= Color(0.4,0.8,0.4, 1, 0,0.4,0)
mod.Colors.CorpseGreen 		= Color(1,1,1, 1)   	   mod.Colors.CorpseGreen:SetColorize(1.5,2,1, 1)
mod.Colors.CorpseGreenTrail = Color(0,0,0, 1, 0.15,0.25,0.07)
mod.Colors.CorpseYellow 	= Color(1,1,1, 1)   	   mod.Colors.CorpseYellow:SetColorize(3.5,2.5,1, 1) -- Yellowish green

mod.Colors.PortalShot 	   = Color(0.6,0.5,0.8, 1, 0.1,0,0.2)
mod.Colors.PortalShotTrail = Color(0,0,0, 1, 0.45,0.3,0.6)
mod.Colors.PortalSpawn 	   = Color(0.2,0.2,0.3, 0, 1.5,0.75,3)

mod.Colors.ForgottenBone = Color(0.34,0.34,0.34, 1)
mod.Colors.SoulShot 	 = Color(0.8,0.8,0.8, 0.7, 0.1,0.2,0.4)
mod.Colors.LostShot 	 = Color(1,1,1, 0.75, 0.25,0.25,0.25)
mod.Colors.HolyOrbShot   = Color(1,1,1, 0.7, 0.4,0.4,0)

mod.Colors.HushGreen    = Color(1,1,1, 1, 0.2,0.2,0)
mod.Colors.HushBlue 	= Color(1,1,1, 1, 0,0.2,0.4)
mod.Colors.HushDarkBlue = Color(0.6,0.6,0.6, 1, 0,0,0.1) -- For Blue Boils
mod.Colors.HushOrange   = Color(1,1,1, 1, 0.4,0.2,0)
mod.Colors.HushPink 	= Color(1,1,1, 1, 0.2,0,0.2)

mod.Colors.CageCreep 	  = Color(1,1,1, 1)   mod.Colors.CageCreep:SetColorize(3.25,3.25,2.25, 1) -- Not 100% accurate but it's close enough
mod.Colors.CageGreenShot  = Color(1,1,1, 1)   mod.Colors.CageGreenShot:SetColorize(0.75,1,0.5, 1)
mod.Colors.CageGreenCreep = Color(1,1,1, 1)   mod.Colors.CageGreenCreep:SetColorize(2.25,3.25,1.25, 1)
mod.Colors.CagePinkShot   = Color(1,1,1, 1)   mod.Colors.CagePinkShot:SetColorize(1,0.9,0.7, 1)

mod.Colors.PrideGray = Color(0,0,0, 1, 0.31,0.31,0.31)
mod.Colors.PridePink = Color(0,0,0, 1, 0.75,0.31,0.46)
mod.Colors.PrideHoly = Color(0,0,0, 1, 0.75,0.66,0.31)

mod.Colors.RagManPurple = Color(0,0,0, 1, 0.6,0.1,0.6)
mod.Colors.RagManBlood  = Color(0,0,0, 1, 0.35,0.1,0.35)
mod.Colors.RagManPink   = Color(1,1,1, 1, 0.4,0.1,0.2)

mod.Colors.GhostTrail 		= Color(0,0,0, 0.35, 0.6,0.6,0.6)
mod.Colors.GhostTransparent = Color(1,1,1, 0.5)
mod.Colors.GhostGibs 		= Color(1,1,1, 0.25, 1,1,1)

mod.Colors.TearEffect = Color(0,0,0, 0.65, 0.54,0.64,0.78)
mod.Colors.TearTrail  = Color(0,0,0, 1, 0.54,0.64,0.78)

mod.Colors.DamageFlash = Color(0.5,0.5,0.5, 1, 0.8,0,0)
mod.Colors.ArmorFlash  = Color(1,1,1, 1, 0.2,0.2,0.2)



--[[ New sound enums ]]--
mod.Sounds = {
	-- C.H.A.D.
	ChadAttackSwim = Isaac.GetSoundIdByName("C.H.A.D. Attack Swim"),
	ChadAttackJump = Isaac.GetSoundIdByName("C.H.A.D. Attack Jump"),
	ChadAttackSpit = Isaac.GetSoundIdByName("C.H.A.D. Attack Spit"),
	ChadStunned    = Isaac.GetSoundIdByName("C.H.A.D. Stunned"),
	ChadDeath 	   = Isaac.GetSoundIdByName("C.H.A.D. Death"),

	-- Blue Pin
	LarryScream = Isaac.GetSoundIdByName("Larry Scream"),

	-- Steven
	StevenVoice  = Isaac.GetSoundIdByName("Steven Voice"),
	StevenTP 	 = Isaac.GetSoundIdByName("Steven Teleport Loop"),
	StevenChange = Isaac.GetSoundIdByName("Steven Layer Change"),
	StevenLand   = Isaac.GetSoundIdByName("Steven Land"),
	StevenDeath  = Isaac.GetSoundIdByName("Steven Death"),

	-- Triachnid
	TriachnidHappy = Isaac.GetSoundIdByName("Triachnid Happy"),
	TriachnidHurt  = Isaac.GetSoundIdByName("Triachnid Hurt"),

	-- Sister Vis
	GiantLaserLoop = Isaac.GetSoundIdByName("Giant Laser Loop Fixed"),
}