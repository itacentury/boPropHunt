#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

/*
TODO:
Import all models from map editor
Remove too small models, as they are too unfair
Get game logic right
Import text and shader methods
Change team names to "Props" and "Hunter"
Game lengh 10 minutes
Add UAV for Hunter for the last minute
Players who join the game after prophunt already started are frozen, given an info message, then killed and then set to spectator mode 
*/

init()
{
	level.clientid = 0;
	level.currentGametype = getDvar("g_gametype");
	level.propHuntStarted = false;

	maps\mp\gametypes\Props\props::onPrecacheGameModels();
	level thread onPlayerConnect();
}
onPlayerConnect()
{
	for (;;)
	{
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;

		player.propTeam = undefined; //"Prop" "Hunter" "Spectator"

		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	firstSpawn = true;

	for (;;)
	{
		self waittill("spawned_player");

		if (firstSpawn)
		{
			if (level.currentGametype == "tdm")
			{
				self iPrintln("Welcome to Prop Hunt Black Ops Edition");
				self FreezeControls(false);

				if (self isHost())
				{
					if (!level.propHuntStarted)
					{
						self startPropHuntText();
					}
				}
				else
				{
					//if player joins the game and prophunt already started, he becomes a spectator until the next game
					if (level.propHuntStarted)
					{
						if (isAlive(self))
						{
							self suicide();
							self.propTeam = "spectator";
							self changeMyTeam("spectator");
						}
					}
				}

				self monitorButtons();
			}
			else
			{
				self iPrintln("Only TDM is supported. Please restart and change the gametype.");
			}
			
			firstSpawn = false;
		}
	}
}

setupGameDvars()
{
	scorelimit = (level.players.size - 1) * 100;
	if (scorelimit > 0)
	{
		setDvar("scr_tdm_scorelimit", int(scorelimit));
		self setclientdvar("cg_objectiveText", maps\mp\gametypes\_globallogic_ui::getObjectiveScoreText(self.pers["team"]), int(scorelimit));
	}

	level.allow_teamchange = "0";
	setDvar("scr_disable_cac", 1);
	setDvar("g_allow_teamchange", 0);
	setDvar("ui_allow_teamchange", 0);

	setDvar("scr_tdm_numlives", 1);
	setDvar("scr_numLives", 1);
	setDvar("scr_player_numlives", 1);

	setDvar("g_TeamName_Allies", "^2Props");
    setDvar("g_TeamName_Axis", "^1Hunter");
	setDvar("ls_gametype", "PROP HUNT");
	setDvar("ui_gametype", "PROP HUNT");
	setDvar("ui_customModeEditName", "PROP HUNT");
}

monitorButtons()
{
	self endon("disconnect");

	for (;;)
	{
		if (!level.propHuntStarted)
		{
			if (self isHost())
			{
				if (self ADSButtonPressed() && self ActionSlotTwoButtonPressed())
				{
					self setupGameDvars();
					self startPropHunt();
					iPrintln("Prop Hunt ^2started!");
					level.propHuntStarted = true;

					self.startPropHuntText destroy();

					wait 0.12;
				}
			}
		}
		else
		{
			if (self.propTeam == "prop")
			{
				//monitorButtons for props
			}
			else if (self.propTeam == "hunter")
			{
				//monitorButtons for hunter
			}
		}
		wait 0.05;
	}
}

startPropHuntText()
{
	self.startPropHuntText = createText("default", 1.5, "CENTER", "CENTER", 0, -50, 2, false, "");
	self.startPropHuntText setText("Press [{+speed_throw}] & [{+actionslot 2}] to start the Prop Hunt!");
	self.startPropHuntText setColor(1, 1, 1, 1);
}

startPropHunt()
{
	playerNumber = level.players.size;
	hunterNumber = randomInt(playerNumber - 1);
	hunter = level.players[hunterNumber];
	hunter.propTeam = "hunter";
	level.hunterPlayer = hunter;

	//testing
	getHostPlayer().propTeam = "hunter";

	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];

		if (!isDefined(player.propTeam))
		{
			player.propTeam = "prop";
		}

		if (player.propTeam == "prop")
		{
			player propLogic();
		}
		else if (player.propTeam == "hunter")
		{
			player hunterLogic();
		}
	}
}

hunterLogic()
{
	self iprintlnbold("You are the Hunter! Wait till the Props are hiden, then find and kill them!");

	self EnableInvulnerability();
	self changeMyTeam("axis");

	self ClearPerks();
	self TakeAllWeapons();
	//Sleight of Hand Pro
	self SetPerk("specialty_fastreload");
	self SetPerk("specialty_fastads");
	//Lightweight Pro
	self SetPerk("specialty_fallheight");
	self SetPerk("specialty_movefaster");
	//Scavenger
	self SetPerk("specialty_scavenger");
	//Hardened Pro
	self setPerk("specialty_bulletpenetration");
	self setPerk("specialty_armorpiercing");
	self setPerk("specialty_bulletflinch");
	//Steady Aim Pro
	self setPerk("specialty_bulletaccuracy");
	self setPerk("specialty_sprintrecovery");
	self setPerk("specialty_fastmeleerecovery");
	//Marathon Pro
	self setPerk("specialty_longersprint");
	self setPerk("specialty_unlimitedsprint");

	self FreezeControls(true);
	self.blindHunter = createRectangle("CENTER", "CENTER", 0, 0, 1920, 10000, 2, "black");
	
	for (i = 60; i > 0; i--)
	{
		self iprintln("Start hunting in: " + i);
		wait 1;
	}

	self.blindHunter destroy();
	self FreezeControls(false);
	primary = "mac11_mp";
	secondary = "asp_mp";
	self giveWeapon(primary);
	self giveWeapon(secondary);
	self SwitchToWeapon(primary);
}

propLogic()
{
	self iprintlnbold("You are a Prop! Change your model and hide somewhere!");

	self changeMyTeam("allies");
	self.pers["lives"] = 1;
	self.pers["mode"] = "normal";
	self DisableWeapons();
    self AllowAds(false);
	self SetClientDvars("cg_thirdPerson", "1", "cg_thirdPersonAngle", "360", "cg_thirdPersonRange", "200");
	self propControlsText();
	self maps\mp\gametypes\Props\props::buildMode();
	self.inMapEditor = true;

	self ClearPerks();
	//Ninja Pro
	self SetPerk("specialty_quieter");
	self SetPerk("specialty_loudenemies");
	//Lightweight Pro
	self SetPerk("specialty_fallheight");
	self SetPerk("specialty_movefaster");
	//No name from Ghost Perk
	self SetPerk("specialty_noname");
}

propControlsText()
{
	self.changeModelText = createText("default", 1, "LEFT", "CENTER", -425, -110, 2, false, "");
	self.changeModelText setText("Press [{+actionslot 3}] or [{+actionslot 4}] to change your model!");
	self.changeModelText setColor(1, 1, 1, 1);

	self.rotateModelText = createText("default", 1, "LEFT", "CENTER", -425, -90, 2, false, "");
	self.rotateModelText setText("Press [{+speed_throw}] or [{+attack}] to rotate your model!");
	self.rotateModelText setColor(1, 1, 1, 1);

	self.changeFOVText = createText("default", 1, "LEFT", "CENTER", -425, -70, 2, false, "");
	self.changeFOVText setText("Press [{+actionslot 1}] or [{+actionslot 2}] to change your FOV!");
	self.changeFOVText setColor(1, 1, 1, 1);

	self.currentModeltext = createText("default", 1, "LEFT", "CENTER", -425, -50, 2, false, "");
	self.currentModeltext setColor(1, 1, 1, 1);
}

resetOnDeath()
{
	self waittill("death");

	self.inMapEditor = false;
	self EnableWeapons();
	self AllowAds(true);
	self SetClientDvar("cg_thirdPerson", "0");
	self show();
	
	if (IsDefined(self.pers["myprop"]))
	{
		self.pers["myprop"] Delete();
	}

	self.changeModelText destroy();
	self.rotateModelText destroy();
	self.changeFOVText destroy();
	self.currentModeltext destroy();

	//delete text
	//set spectator
}

changeMyTeam(assignment)
{
	self.pers["team"] = assignment;
	self.team = assignment;
	self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();
	if (level.teamBased)
	{
		self.sessionteam = assignment;
	}
	else
	{
		self.sessionteam = "none";
		self.ffateam = assignment;
	}
	
	if (!isAlive(self))
	{
		self.statusicon = "hud_status_dead";
	}

	self notify("joined_team");
	level notify("joined_team");
	
	self setclientdvar("g_scriptMainMenu", game["menu_class_" + self.pers["team"]]);
}

createText(font, fontScale, point, relative, xOffset, yOffset, sort, hideWhenInMenu, text)
{
    textElem = createFontString(font, fontScale);
    textElem setText(text);
    textElem setPoint(point, relative, xOffset, yOffset);
    textElem.sort = sort;
    textElem.hideWhenInMenu = hideWhenInMenu;
    return textElem;
}

setColor(r, g, b, a)
{
	self.color = (r, g, b);
	self.alpha = a;
}

createRectangle(align, relative, x, y, width, height, sort, shader)
{
    barElemBG = newClientHudElem(self);
    barElemBG.elemType = "bar";
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG setParent(level.uiParent);
    barElemBG setShader(shader, width, height);
    barElemBG.hidden = false;
    barElemBG setPoint(align, relative, x, y);
    return barElemBG;
}