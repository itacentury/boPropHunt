#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	level.clientid = 0;
	level.currentGametype = getDvar("g_gametype");
	level.propHuntStarted = false;

	level thread onPlayerConnect();
}
onPlayerConnect()
{
	for (;;)
	{
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;

		player.propTeam = undefined;

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
							//make spectator
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
					self reorganizeTeams();
					iPrintln("Prop Hunt ^2started!");
					level.propHuntStarted = true;

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
	//Press Ads + DPAD DOWN to start the prophunt
}

reorganizeTeams()
{
	playerNumber = level.players.size;
	//get random player and make him hunter
	//set team for hunters and props
	//take all weapons and give specific perks for props
	//give specific weapons and perks to hunter
	//set lives to 1 with no respawn
}

propControlsText()
{
	//Display text to change model, rotate
}