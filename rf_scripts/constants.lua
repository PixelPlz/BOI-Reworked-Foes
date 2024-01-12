local mod = ReworkedFoes

mod.RNG = RNG()

-- Randomize the seed, since RNG is always initialized at 2853650767
if REPENTOGON then
	mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
		mod.RNG:SetSeed(Game():GetSeeds():GetStartSeed())
	end)
end



--[[ Entity enums ]]--
mod.Entities = {
	-- Projectiles
	FeatherProjectile = Isaac.GetEntityVariantByName("Angelic Feather Projectile"),
	SuckerProjectile  = Isaac.GetEntityVariantByName("Sucker Projectile"),
	EggSackProjectile = Isaac.GetEntityVariantByName("Egg Sack Projectile"),


	-- Enemies / Bosses
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


	-- Champion subtypes
	PinChampion 	= 2,
	KrampusChampion = 1,


	-- Effects
	OneTimeEffect  = Isaac.GetEntityVariantByName("One Time Effect"),
	DirtHelper 	   = Isaac.GetEntityVariantByName("Scolex Dirt Helper"),
	HealingAura    = Isaac.GetEntityVariantByName("Healing Aura"),
	HolyTracer 	   = Isaac.GetEntityVariantByName("Holy Tracer"),
	BrimstoneSwirl = Isaac.GetEntityVariantByName("Single Brimstone Swirl"),
	SkyLaserEffect = Isaac.GetEntityVariantByName("Sister Vis Laser Effect"),
	FireRingHelper = Isaac.GetEntityVariantByName("Fire Ring Helper"),

	TriachnidLeg = Isaac.GetEntityVariantByName("Triachnid Leg Segment"),
		TriachnidJoint    = 0,
		TriachnidUpperLeg = 1,
		TriachnidLowerLeg = 2,
}



--[[ Colors ]]--
mod.Colors = {
	BrimShot   = Color(1,0.25,0.25, 1, 0.25,0,0),
	ShadyRed   = Color(-1,-1,-1, 1, 1,0,0),
	Tar 	   = mod:ColorEx({1,1,1, 1, 0,0,0},   {1,1,1, 1},   {0.5,0.5,0.5, 1}),
	WhiteShot  = mod:ColorEx({1,1,1, 1, 0.5,0.5,0.5},   {1,1,1, 1}),
	SunBeam    = Color(1,1,1, 1, 0.3,0.3,0),
	DustPoof   = Color(0.7,0.7,0.7, 0.75),
	DustTrail  = mod:ColorEx({0.8,0.8,0.8, 0.8, 0.05,0.025,0},   {1,1,1, 1}),
	BlackBony  = Color(0.18,0.18,0.18, 1),
	PukeEffect = Color(0,0,0, 1, 0.48,0.36,0.3),
	PukeOrange = Color(0.5,0.5,0.5, 1, 0.64,0.4,0.16),
	Sketch 	   = Color(0,0,0, 1, 0.48,0.4,0.36),
	CrispyMeat = mod:ColorEx({1,1,1, 1},   {0.32,0.25,0.2, 1}),
	DrossPoop  = mod:ColorEx({1,1,1, 1},   {0.9,0.8,0.7, 1}),

	EmberFade    = mod:ColorEx({0,0,0, 1.1, 1,0.514,0.004},   {0,0,0, 0},   {0,0,0, 1.1}),
	RedFireShot  = Color(1,1,1, 1, 0.6,0.1,0),
	BlueFire 	 = mod:ColorEx({0,1,1, 1, -0.5,0.35,0.9},   {1,1,1, 1}),
	BlueFireShot = mod:ColorEx({1,1,1, 1, 0,0.6,1.2},   {1,1,1, 1}),
	PurpleFade   = mod:ColorEx({0,0,0, 1.1, 0.5,0,0.5},   {0,0,0, 0},   {0,0,0, 1.1}),

	Ipecac 			 = mod:ColorEx({1,1,1, 1},   {0.4,2,0.5, 1}),
	GreenCreep 		 = Color(0,0,0, 1, 0,0.5,0),
	GreenBlood 		 = Color(0.4,0.8,0.4, 1, 0,0.4,0),
	CorpseGreen 	 = mod:ColorEx({1,1,1, 1},   {1.5,2,1, 1}),
	CorpseGreenTrail = Color(0,0,0, 1, 0.15,0.25,0.07),
	CorpseYellow 	 = mod:ColorEx({1,1,1, 1},   {3.5,2.5,1, 1}),

	PortalShot 		= Color(0.6,0.5,0.8, 1, 0.1,0,0.2),
	PortalShotTrail = Color(0,0,0, 1, 0.45,0.3,0.6),
	PortalSpawn 	= Color(0.2,0.2,0.3, 0, 1.5,0.75,3),

	ForgottenBone = Color(0.34,0.34,0.34, 1),
	SoulShot 	  = Color(0.8,0.8,0.8, 0.7, 0.1,0.2,0.4),
	LostShot 	  = Color(1,1,1, 0.75, 0.25,0.25,0.25),
	HolyOrbShot   = Color(1,1,1, 0.7, 0.4,0.4,0),

	HushGreen 	 = Color(1,1,1, 1, 0.2,0.2,0),
	HushBlue 	 = Color(1,1,1, 1, 0,0.2,0.4),
	HushDarkBlue = Color(0.6,0.6,0.6, 1, 0,0,0.1),
	HushOrange   = Color(1,1,1, 1, 0.4,0.2,0),
	HushPink 	 = Color(1,1,1, 1, 0.2,0,0.2),

	CageCreep 	   = mod:ColorEx({1,1,1, 1},   {3.2, 3.2, 2.3, 1}),
	CageGreenShot  = mod:ColorEx({1,1,1, 1},   {0.75,1,0.5, 1}),
	CageGreenCreep = mod:ColorEx({1,1,1, 1},   {2.25,3.25,1.25, 1}),
	CagePinkShot   = mod:ColorEx({1,1,1, 1},   {1,0.9,0.7, 1}),

	PrideGray = Color(0,0,0, 1, 0.31,0.31,0.31),
	PridePink = Color(0,0,0, 1, 0.75,0.31,0.46),
	PrideHoly = Color(0,0,0, 1, 0.75,0.66,0.31),

	RagManPurple = Color(0,0,0, 1, 0.6,0.1,0.6),
	RagManBlood  = mod:ColorEx({1,1,1, 1},   {0.84,0.4,0.68, 1}),
	RagManPink   = Color(1,1,1, 1, 0.4,0.1,0.2),

	GhostTrail 		 = Color(0,0,0, 0.35, 0.6,0.6,0.6),
	GhostTransparent = Color(1,1,1, 0.5),
	GhostGibs 		 = Color(1,1,1, 0.25, 1,1,1),

	TearEffect = Color(0,0,0, 0.65, 0.54,0.64,0.78),
	TearTrail  = Color(0,0,0, 1, 0.54,0.64,0.78),

	Heal 		= Color(1,1,1, 1, 0.64,0,0),
	DamageFlash = Color(0.5,0.5,0.5, 1, 0.8,0,0),
	ArmorFlash  = Color(1,1,1, 1, 0.25,0.25,0.25),
}



--[[ Sound enums ]]--
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