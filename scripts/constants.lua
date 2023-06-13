local mod = BetterMonsters

IRFrng = RNG()



--[[ New entity enums ]]--
IRFentities = {
	-- Projectiles
	FeatherProjectile = Isaac.GetEntityVariantByName("Angelic Feather Projectile"),
	SuckerProjectile  = Isaac.GetEntityVariantByName("Sucker Projectile"),


	-- Enemies
	Type = 200,

	Teratomar 	  = Isaac.GetEntityVariantByName("Teratomar"),
	Coffer 		  = Isaac.GetEntityVariantByName("Coffer"),
	HushFlyAttack = Isaac.GetEntityVariantByName("Hush Fly Attack"),
	BoneOrbital   = Isaac.GetEntityVariantByName("Enemy Bone Orbital"),
	Mullicocoon   = Isaac.GetEntityVariantByName("Mullicocoon"),
	RagPlasma 	  = Isaac.GetEntityVariantByName("Rag Mega Plasma"),

	BlueBabyExtras = Isaac.GetEntityVariantByName("Forgotten Body (Boss)"),
		ForgottenBody  = 0,
		ForgottenChain = 1,
		LostHolyOrb	   = 2,

	KrampusChampion = 1, -- It's defined here so it can be changed by the FF compatibility mod


	-- Effects
	DirtHelper 	   = Isaac.GetEntityVariantByName("Scolex Dirt Helper"),
	HealingAura    = Isaac.GetEntityVariantByName("Healing Aura"),
	HolyTracer 	   = Isaac.GetEntityVariantByName("Holy Tracer"),
	BrimstoneSwirl = Isaac.GetEntityVariantByName("Single Brimstone Swirl"),
}



--[[ Colors ]]--
IRFcolors = {}

IRFcolors.BrimShot   = Color(1,0.25,0.25, 1, 0.25,0,0)
IRFcolors.ShadyRed   = Color(-1,-1,-1, 1, 1,0,0)
IRFcolors.Tar 		 = Color(1,1,1, 1);   						IRFcolors.Tar:SetColorize(1,1,1, 1);   IRFcolors.Tar:SetTint(0.5,0.5,0.5, 1)
IRFcolors.WhiteShot  = Color(1,1,1, 1, 0.5,0.5,0.5);   			IRFcolors.WhiteShot:SetColorize(1,1,1, 1)
IRFcolors.CrispyMeat = Color(1,1,1, 1);   						IRFcolors.CrispyMeat:SetColorize(0.32,0.25,0.2, 1)
IRFcolors.Ipecac 	 = Color(1,1,1, 1, 0,0,0);   				IRFcolors.Ipecac:SetColorize(0.7,2,0.7, 1)
IRFcolors.GreenBlood = Color(0.4,0.8,0.4, 1, 0,0.4,0)
IRFcolors.SunBeam 	 = Color(1,1,1, 1, 0.3,0.3,0)
IRFcolors.DustTrail  = Color(0.8,0.8,0.8, 0.8, 0.05,0.025,0);   IRFcolors.DustTrail:SetColorize(1,1,1, 1)
IRFcolors.BlackBony  = Color(0.18,0.18,0.18, 1)

IRFcolors.BlueFire 	   = Color(0,1,1, 1, -0.5,0.35,0.9);   IRFcolors.BlueFire:SetColorize(1,1,1, 1)
IRFcolors.BlueFireShot = Color(1,1,1, 1, 0,0.6,1.2);     IRFcolors.BlueFireShot:SetColorize(1,1,1, 1)

IRFcolors.CorpseGreen 	   = Color(1,1,1, 1);   IRFcolors.CorpseGreen:SetColorize(0.6,1,0.3, 1)
IRFcolors.CorpseGreenTrail = Color(0,0,0, 1, 0.3,0.5,0.15)
IRFcolors.CorpseYellow 	   = Color(1,1,1, 1);   IRFcolors.CorpseYellow:SetColorize(2,2,1, 1)

IRFcolors.PortalShot 	  = Color(0.6,0.5,0.8, 1, 0.1,0,0.2)
IRFcolors.PortalShotTrail = Color(0,0,0, 1, 0.45,0.3,0.6)
IRFcolors.PortalSpawn 	  = Color(0.2,0.2,0.3, 0, 1.5,0.75,3)

IRFcolors.ForgottenBone = Color(0.34,0.34,0.34, 1)
IRFcolors.SoulShot 		= Color(0.8,0.8,0.8, 0.7, 0.1,0.2,0.4)
IRFcolors.LostShot 		= Color(1,1,1, 0.75, 0.25,0.25,0.25)
IRFcolors.HolyOrbShot 	= Color(1,1,1, 0.7, 0.4,0.4,0)

IRFcolors.HushBlue 	   = Color(1,1,1, 1, 0,0.2,0.4)
IRFcolors.HushDarkBlue = Color(0.6,0.6,0.6, 1, 0,0,0.1) -- For Blue Boils
IRFcolors.HushGreen    = Color(1,1,1, 1, 0.2,0.2,0)
IRFcolors.HushOrange   = Color(1,1,1, 1, 0.4,0.2,0)
IRFcolors.HushPink 	   = Color(1,1,1, 1, 0.2,0,0.2)

IRFcolors.LambShot 		= Color(1,1,1, 1);   IRFcolors.LambShot:SetColorize(0.6,0.5,0.7, 1)
IRFcolors.LambShotTrail = Color(0,0,0, 1, 0.3,0.2,0.4)

IRFcolors.CageCreep 	 = Color(1,1,1, 1);   IRFcolors.CageCreep:SetColorize(3.25,3.25,2.25, 1) -- Not 100% accurate but it's close enough
IRFcolors.CageGreenShot  = Color(1,1,1, 1);   IRFcolors.CageGreenShot:SetColorize(0.75,1,0.5, 1)
IRFcolors.CageGreenCreep = Color(1,1,1, 1);   IRFcolors.CageGreenCreep:SetColorize(2.25,3.25,1.25, 1)
IRFcolors.CagePinkShot   = Color(1,1,1, 1);   IRFcolors.CagePinkShot:SetColorize(1,0.9,0.7, 1)

IRFcolors.prideGray = Color(0,0,0, 1, 0.31,0.31,0.31)
IRFcolors.pridePink = Color(0,0,0, 1, 0.75,0.31,0.46)
IRFcolors.prideHoly = Color(0,0,0, 1, 0.75,0.66,0.31)

IRFcolors.RagManPurple = Color(0,0,0, 1, 0.6,0.1,0.6)
IRFcolors.RagManBlood  = Color(0,0,0, 1, 0.35,0.1,0.35)
IRFcolors.RagManPink   = Color(1,1,1, 1, 0.4,0.1,0.2)

IRFcolors.GhostTrail 	   = Color(0,0,0, 0.35, 0.6,0.6,0.6)
IRFcolors.GhostTransparent = Color(1,1,1, 0.5)
IRFcolors.GhostGibs 	   = Color(1,1,1, 0.25, 1,1,1)

IRFcolors.TearEffect = Color(0,0,0, 0.65, 0.54,0.64,0.78)
IRFcolors.TearTrail  = Color(0,0,0, 1, 0.54,0.64,0.78)

IRFcolors.DamageFlash = Color(0.5,0.5,0.5, 1, 0.8,0,0)
IRFcolors.ArmorFlash  = Color(1,1,1, 1, 0.2,0.2,0.2)