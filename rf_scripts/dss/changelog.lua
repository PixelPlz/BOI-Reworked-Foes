DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.1.4", [[

{FSIZE2}Additions

- Added a warning for when there are
incompatible mods enabled,
such as Hardmode Major Boss Patterns

- Added the Visage heart resprite
from Ferpe's Mask of Infamy
resprite mod

- Enemy Crack the Sky beams no longer
have an unnecessarily large hitbox



{FSIZE2}Fixes

- Fixed Hera's (White Gish)
Altar Scamps spawning as champions


]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.1.3", [[

{FSIZE2}Additions

- Added a config option to toggle
Eternal Flies keeping their appearance
when chasing the player



{FSIZE2}Fixes

- Fixed Salem softlocking
in the It Lives fight


]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.1.2", [[

{FSIZE2}Balance changes

- Isaac's spiral light beam pattern
now has more safe spots around
the room and is slightly slower



{FSIZE2}Fixes

- Fixed Sister Vis and Mom's Dead Hands
not taking damage from Terra tears

- Fixed Wrath and Super Wrath being
unkillable on the Hot Potato challenge

- Fixed Blue Peep's eyes not using
the correct animations in some cases


]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.1.1", [[

{FSIZE2}Balance changes

- Red Krampus' projectile barrage is
now easier but it can rotate both ways



{FSIZE2}Other changes

- Added the boss portrait for Hush
that was meant to be included
in the last update

- C.H.A.D. is now forced to surface
if he is submerged for too long
to avoid softlocks

- Scolex is now forced to jump out
if he is underground for too long
to avoid softlocks



{FSIZE2}Fixes

- Fixed the Stain's tentacles checking
for the wrong damage reduction value
when taking damage

- Fixed Red Krampus and Blue Pin having
the wrong Enhanced Boss Bars icons
when Fiend Folio is enabled

- Fixed Steven's 2nd phase also
not taking damage sometimes
when Retribution is enabled


]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.1.0", [[

{FSIZE2}Across the Edmund-verse!


{FSIZE2}Reworks / Additions

- Ultra Pride has been reworked!

- Steven has been reworked!

- Gish has been reworked!

- Sister Vis has been reworked!

- Triachnid has been reworked!

- Mask of Infamy has been reworked!


- New Pin champion based off
Larries Lament from Super Meat Boy

- Isaac now was 2 additional variants
for his 3rd phase light beam attack

- Bumbino got a bit smarter

- Added a config option to toggle
Greed-themed enemies stealing coin pickups


- The mod now includes elements
from "Beast Tweaks"
by DeadInfinity and kittenchilly:

- Fixed hitboxes for falling stalactites

- Falling stalactites can now
spawn after the first charge,
and become more common as
the Beast's health drops

- The Beast can now do any of her
attacks in both the first
and second phase, with a set order
(suck > double shot >
suck > souls > repeat)

- The Beast now spends less time
being idle between attacks

- The lava ball attack now starts
faster after the first time

- The Beast will now laugh
at your untimely demise



{FSIZE2}Balance changes

- Coffers now drop half of their
picked up coins and shoot
the other half as projectiles,
instead of shooting all of them

- Membrains now have a less
intense homing effect on their shots

- Reverted the Forsaken's health
nerf so it's 400 again

- Increased Rag Mega's health
from 300 to 350

- Decreased Reap Creep's health
from 690 to 600

- Decreased the Cage's health
from 800 to 720

- Increased Loki and each Lokii pair's
health from 350 to 420

- Increased Teratomar's health
from 100 to 150

- Increased Daddy Long Leg's health
from 500 to 650

- Black Husk no longer shoots
when spawning Ticking Spiders

- Boom Flies now gain a trail
to better show that they were
launched by black Husk

- The Stain now only takes 20%
reduced damage through his tentacles
instead of 50%

- Charmed Mama Gurdy's spikes will
no longer target enemies
and instantly kill them

- Hush's Blue Baby phase now has a
different orbiting projectile attack
for its second phase

- Reduced the max number of Blue Gapers
for Hush's Blue Baby phase



{FSIZE2}Other changes

- New sprites and animations for
Hush's Blue Baby phase and Blue Gapers

- Gazing Globins now have new sprites
that make them distinguishable from
regular Globins while in their goo form

- C.H.A.D. and Scolex are now forced
to surface if they don't have a path
to their target positions

- Gapers, Fatties and Skinnies can
no longer turn into their burnt versions
in rooms with water

- Improved effects for several
bosses and enemies

- Lots of code improvements
(note for compatibility:
make sure enums are properly updated)



{FSIZE2}Fixes

- Fixed friendly Black Bonies
not working properly

- Fixed Lust's fart attack
not doing damage

- Fixed Scolex sometimes not taking
damage if Retribution is enabled

- Fixed Clotty and Clot
Curdle variants from Retribution
using the wrong projectile types

- Fixed the Fiend Folio Krampus
champion's Enhanced Boss Bars icon being
overwritten by this mod

- Fixed red Mom's eye going invisible
during its attack with mods that
change her door sprites


]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.7", [[

{FSIZE2}Balance changes

- Champion Envy will no longer act like
reworked Envy if the rework is supposed
to be disabled (he will now simply
shoot rings of shots when splitting
if it's disabled)

- Increased the spread of Mama Gurdy's
bullets for her spike trap attack
to make going between them easier



{FSIZE2}Other changes

- Custom Gusher and Pacer variants will
no longer turn into Braziers when burnt

- C.H.A.D. and Forsaken will now spawn less
creep and smoke respectively to reduce
lag if multiple of them are present



{FSIZE2}Fixes

- Fixed C.H.A.D. and Scolex
getting stuck underground
(hopefully for the last time)

- Fixed C.H.A.D.'s segments sometimes
getting desynced during his charge

- Fixed grid Hosts from Fiend Folio
using the wrong sprites when
their skull gets cracked


]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.6", [[

{FSIZE2}Reworks / Additions

- Camillo Jr. has been redone
to be more consistent

- Tumors and Psy Tumors now also have
short cooldowns similar to Camillo Jr.

- C.H.A.D. now has unique sounds
from Super Meat Boy!


- Added the option for modders to easily
add compatibility with the
'Breakable Hosts' option
(check the scripts/enemies/hostBreaking.lua
file on how to do it)

- Added compatibility with Fiend Folio
trinkets that affect female enemies

- Added compatibility with
the mod 'Enemy Bullet Trails'

- Added Retribution downgrade
and upgrade support for new enemies

- Bloated Flies, Drowned Maggots,
Drowned (Conjoined) Spitties and
Mega Clots from Retribution now have
behaviour that's more consistent
with reworked enemies from this mod

- Added a custom anm2 option for
custom Black Bony variants



{FSIZE2}Balance changes

- Changed most of It Lives' attacks
to be easier and get slightly
faster as the fight goes on

- It Lives now only does
one continuous attack when retracted
instead of doing several short ones

- It Lives now has an easier selection
of enemies and bosses

- It Lives no longer pushes away tears
and no longer has damage reduction
when entering his last phase

- Reduced the duration of
It Lives' blood cell attack


- Reduced the amount of damage required
to break Scolex's armor
from 50 to 40 per segment

- Red Mr. Maws no longer self destruct
their head when it gets close to the
player like Red Maws
(regular Mr. Maw heads don't shoot so
it makes sense for them to
also not keep their head behaviour)

- Drowned Hives now shoot diagonally
and spawn a Drowned Charger on death
instead of creating lingering projectiles

- Satan now has 800 health per phase
instead of 600

- Satan's hand projectile attack
now works more like its vanilla version

- Fallen Uriel now has 500 HP
instead of 450

- Gabriel now has 520 HP
instead of 660
and Fallen Gabriel now has 666 HP
instead of 750

- Mr. Fred's jump has been improved and
he now shoots a ring of 12 shots
after his jump instead of 8

- Lowered the shotspeed for Cod Worms

- Lowered the max bounce speed for Envy


- Champion Wrath no longer
has increased health

- Champion Envy now has
15% less health instead of 10%

- Champion Envy's shot direction
now depends on the bounce direction
instead of always being the same
and now only shoots 2 shots

- Increased the time between
blue Peep's eye shots



{FSIZE2}Fixes

- Fixed some reworked enemies / bosses
not moving as they should
while charmed or friendly

- Fixed more reworked enemies / bosses
not moving as they should
while feared or confused

- Fixed Cod Worms not taking damage
from certain things

- Fixed Wrath and Super Wrath
having missing heads in the bestiary

- Fixed Dart Flies having
messed up reflections

- Fixed minor errors with It Lives

- Fixed Black Gate and Black Frail's
fire waves being the wrong color if they
get created after their spawners died

- Fixed Scolex not taking damage
from Mom's Knife if the mod
"Mom's Knife Synergies" is enabled
(and hopefully in other cases too)

]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.5", [[

{FSIZE2}Fixes

- Fixed Fallen Angel
Delirium sprites not working

- Fixed more softlocks with It Lives

]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.4", [[

{FSIZE2}Additions
- Fallen Angels now have
unique Delirium sprites



{FSIZE2}Balance changes

- Increased the space between
projectiles for one of
It Lives' attacks

- Reduced the duration of
It Lives' blood cell phase



{FSIZE2}Fixes

- Fixed the Husk unlocking the Forgotten

- Fixed some of blue Peep's effects
being the wrong color when spawned

- Fixed It Lives softlocking
in the Seeing Double challenge

]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.3", [[

{FSIZE2}Additions

- Added a separate changelogs button
in the Reworked Foes section for DSS
if there are multiple DSS sections
(for people that couldn't find it before)



{FSIZE2}Fixes

- Fixed C.H.A.D.'s Sucker projectiles
spawning Suckers when they shouldn't

- Fixed C.H.A.D.'s pathfinding not taking
spikes into account (this also fixes him
not surfacing in some room layouts)

- Fixed issue with Carrion Queen's charge

]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.2", [[

{FSIZE2}Balance changes

- It Lives is now easier in Normal Mode

- Increased the space between the
projectiles for some of
It Lives' attacks

- Increased the time between
It Lives' gut attacks

- Decreased the amount of shots
for some of It Lives' attacks

- Increased the time between shots
for Mama Gurdy's spike cage attack



{FSIZE2}Fixes

- Fixed Mama Gurdy's spikes
killing her if she is affected
by Rotten Tomato

]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.1", [[

{FSIZE2}Balance changes

- Lowered the Gate's shotspeed
during his Host attack

- The Forsaken now gives more time
for the player to move
out of the way of his lasers

- Increased the space between the
Forsaken's projectiles during his
triple clone attack

- Teratomar now only
shoots 4 shots again



{FSIZE2}Fixes

- Fixed DSS not saving settings

- Fixed Mama Gurdy's spikes not working

- Fixed the Forsaken being able to
telefrag the player when teleporting
to the center of the room

]])





DeadSeaScrollsMenu.AddChangelog("reworked foes", "v3.0.0", [[

{FSIZE2}Blood and Guts update!


{FSIZE2}Reworks / Additions

- Your future's past awaits...

- C.H.A.D. has been reworked!

- The Gate has been reworked!

- The Husk has been reworked!

- Mama Gurdy has been reworked!

- Blastocyst's biggest form
has been reworked!

- Drowned Chargers have been
re-reworked!


- The mod now uses a buit-in
Dead Sea Scrolls menu
(as you can tell)

- Added an option to toggle
Black Bonies having bomb effects

- The mod "Hush Fix" by hgrfff
is now also included.
This mod fixes Hush spamming his
attacks when on low HP and his
lasers not getting slowed.

- Bone Knights now alert other knights
into charging towards the player
and have also recieved new sprites!

- Flaming Gapers now spawn
a unique Flaming Gusher enemy
(can be turned off)

- Camillo Jr. now works like his
vanilla version but with a laser indicator
and a cooldown between attacks

- Drowned Hives now spawn
Drowned Chargers again and
create lingering projectiles on death

- Scarred Para-Bites now shoot
regular projectiles
instead of lingering projectiles

- Raglings no longer
create purple fires on death

- Mega Maw's volley of shots
is now homing

- Mega Maw's fire projectiles
can now ignite his Hoppers,
turning them into purple Flaming Hoppers


- Blue Larry Jr. now creates
slippery tear creep

- Golden Hollow now steals money
from the player like other greedy enemies

- Gray Monstro's attack is now
a stream of projectiles
instead of a single burst

- Green Gurdy now spawns
a new set of enemies

- Black Frail has recieved
improved attacks

- Black Death's Horse now always
charges at the player horizontally

- Black Death now spawns
homing scythes instead of Red Maws

- Blue Gemini now creates
slippery tear creep

- Green Gemini now creates
green creep while charging

- Black Mega Maw now shoots
a homing projectile that splits into
more homing projectiles on impact
instead of a volley of shots

- Green Cage now shoots out projectiles
when hitting a wall during his roll

- Green Cage's shockwaves are now
replaced with 4 lines of creep
that shoot out projectiles from them

- Black Brownie now spawns
Black Dingle on death
instead of Dank Squirts


- Danglers from Fiend Folio can now
also collect coins
like other greedy enemies

- Seducers from Fiend Folio can now
also heal when touching
a player like Lust

- Added support for custom
Black Bony variants (check the
scripts/enemies/blackBony.lua
file on how to do it)



{FSIZE2}Balance changes

- Teratomar now shoots a spread of
5 shots instead of 4

- Removed the Brimstone Bomb
variant for Black Bonies

- The Stain's tentacles now
always spawn cardinally to the player

- Triachnid's stomp shots now have
longer range and their shot speed
depends on the amount of shots

- Reduced the Forsaken's health
from 400 to 350

- Mr. Fred's Harlequin Baby attack
no longer creates creep
when hitting obstacles

- Reduced the amount of damage
required to break Scolex's armor
from 80 to 50 per segment

- Angelic Babies no longer
shoot projectiles when teleporting

- Black Globin Heads spawned from
the room layout no longer
turn into full Black Globins

- Slightly reduced the
initial cooldown on Slides

- Psy Tumor lingering projectiles
now disappear faster

- Selfless Knights now move
and shoot slightly faster

- Ulcers no longer spawn Dips if there
are 5 or more of them in the room

- Reduced the initial and
max speed of Envy's heads

- Fallen Gabriel's Brimstone Swirls
no longer rotate towards the player

- Base coin healing for greedy enemies
is now only 3%
(this is multiplied by the coin's value)
instead of 5%

- Lust can no longer repeat
any pill effects

- Removed teleport effects from Lust

- Lust's lemon party effects
are now larger and last longer

- Lust now only heals 12% health
(24% for champion / Super)
with her healing effects instead of 15%
(was 30% for champion / Super)

- Decreased Hush Baby's cooldown
between attacks


- Increased ???'s damage reduction
after he spawns from 50% to 60%

- Decreased ???'s cooldown
between attacks

- ??? can no longer perform the
same attack multiple times in a row

- ??? now only shoots one
ring of homing shots after his
boomerang tear attack

- ??? can no longer teleport to the
closest corner to the player
during his teleport attack


- All champion minibosses now
have a consistent 15% size increase

- Champion Sloth and champion Wrath
now have a 15% health increase

- Champion Gluttony, champion Pride
and red Conquest no longer
have a 15% health increase

- Champion Gluttony can now only
have 4 Maggots spawned

- Champion Lust now creates
5 sun beams instead of 4
with the Sun card

- Champion Lust's High Priestess
stomp now takes more time
to move to the player

- Champion Wrath now slides his
bomb towards the player
like vanilla Wrath

- Red Conquest now shoots a
ring of 6 (8 in his second phase)
shots instead of explosive shots

- Reduced the number of Globins
red Conquest can have active
from 5 to 4

- Increased the shot speed for
purple Headless Horseman's Body



{FSIZE2}Other changes

- Wrath's charge attack is now
visually distinguishable and is
faster than his walking speed
instead of being slower

- New charred sprites for
Flaming Gapers, Fatties and Hoppers
to keep them consistent with
other Burning Basement enemies

- Fire rings from Flaming Fatties
and Flaming Hoppers now work like
the fire rings created by Redskulls

- Improved Soft Host and
Flesh Floast sprites

- New sprites for Death's scythes

- Fallen Uriel and Fallen Gabriel
now have a unique spawning animation

- Skinnies that get turned into Crispies
after they took their skin off
will now have a unique sprite

- Cyan Peep's eyes now have
unique sprites and an animation
for when they're about to shoot

- Improved projectile visuals
for several enemies

- New sounds and effects
for several enemies

- MANY code improvements
(note for compatibility:
all enums have also been changed)



{FSIZE2}Fixes

- Fixed Cod Worms not taking
damage from Mom's Knife

- Fixed some reworked enemies and
bosses not moving as they should
while feared or confused

- The Cage no longer has a hitbox
before he visually lands

- Fixed Portals and Flaming Gapers
having missing layers in the Bestiary

- Fixed Turdlings having
the wrong hand sprites

- Fixed Rag Mega not killing his
Raglings on death like in vanilla

- ???'s Holy Orb now disappears
if ??? dies while it's active

- Fixed Homunculus and Begotten
cord breaking sounds playing
when they shouldn't


- Fixed Rotties not working properly
when HoneyVee's Monster Resprites mod
is installed (for now it just overrides
that mod's version, sorry!)

- Fixed Sloth Heads from Fiend Folio
turning into Black Globins

- Fixed grid Hosts from Fiend Folio not
turning into the proper fleshy variants
when their skull is broken

- Fixed Mr. Mines shooting the wrong
projectiles on The Future floor

]])