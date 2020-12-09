/*
 __  __             ______    _ _ _             
|  \/  |           |  ____|  | (_) |            
| \  / | __ _ _ __ | |__   __| |_| |_ ___  _ __ 
| |\/| |/ _` | '_ \|  __| / _` | | __/ _ \| '__|
| |  | | (_| | |_) | |___| (_| | | || (_) | |   
|_|  |_|\__,_| .__/|______\__,_|_|\__\___/|_|   
             | |                                
             |_|     
			 
The MapEditor Project
Created by JariZ & Scripts18
Based on SparkyMcSparks' HideNSeek
Ported by Century
(c) JariZ.nl 2011
This a open-source project. for more information see LICENSE.TXT
*/

#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_globallogic_score;
#include maps\mp\gametypes\Props\assets;

buildMode()
{
	self notify("me_buildmode");
    self notify("stop_ammo");

    if (IsDefined(self.pers["myprop"]))
    {
        self.pers["myprop"] Delete();
	}

    //modes
	if (self.pers["mode"] == "normal")
	{
		usableModelsKeys = GetArrayKeys(level.usableModels);
		self.pers["myprop"] = spawn("script_model", self.origin);
		self.pers["myprop"].health = 10000;
		self.pers["myprop"].owner = self;
		self.pers["myprop"].angles = self.angles;
		self.pers["myprop"].indexKey = RandomInt(level.MAX_USUABLE_MODELS);
		self.pers["myprop"] SetModel(level.usableModels[usableModelsKeys[self.pers["myprop"].indexKey]]);
        self.currentModeltext setText("Current model: " + level.usableModels[usableModelsKeys[self.pers["myprop"].indexKey]]);
	}

    self.pers["myprop"] SetCanDamage(true);
    self.pers["myprop"] thread detachOnDisconnect(self);
    self.pers["myprop"] thread attachModel(self);
    self thread monitorKeyPress();
}

attachModel(player)
{
    player endon("disconnect");
    player endon("killed_player");
    player endon("death");
    self endon("death");
	
    for(;;)
    {
        wait 0.01;
        if (self.origin != player.origin)
        {
            self MoveTo(player.origin, 0.1);
        }
    }
}

detachOnDisconnect(player)
{
    player endon("death");
    player endon("killed_player");
	
    player waittill("disconnect");
	
    modelOrigin = self.origin;
    self Delete();
}

onPrecacheGameModels()
{
    precacheLevelModels();
    if (IsDefined(level.availableModels) && level.availableModels.size > 0 )
    {
        level.availableModels = array_randomize(level.availableModels);
        if (level.availableModels.size < level.MAX_USUABLE_MODELS)
        {
            level.MAX_USUABLE_MODELS = level.availableModels.size;
        }

        availableModelsKeys = GetArrayKeys(level.availableModels);
        if (!IsDefined(level.usableModels))
        {
            level.usableModels = [];
        }

        for (x = 0; x < level.availableModels.size; x++)
        {
            PreCacheModel(level.availableModels[availableModelsKeys[x]]);
            level.usableModels[level.availableModels[availableModelsKeys[x]]] = level.availableModels[availableModelsKeys[x]];
            if (level.usableModels.size >= level.MAX_USUABLE_MODELS)
            {
                return;
            }
        }
    }
	else
    {
		self iPrintln("[me] loading models failed, no models assigned");
    }
}

precacheLevelModels()
{
    if (IsDefined(level.force_hns_models))
    {
        [[level.force_hns_models]]();
        return;
    }

    switch (GetDvar(#"mapname"))
    {
        case "mp_array":
            mpArrayPrecache();
            break;
        case "mp_berlinwall2":
            mpBerlinwall2Precache();
            break;
        case "mp_cairo":
            mpCairoPrecache();
            break;
        case "mp_cosmodrome":
            mpCosmodromePrecache();
            break;
        case "mp_cracked":
            mpCrackedPrecache();
            break;
        case "mp_crisis":
            mpCrisisPrecache();
            break;
        case "mp_discovery":
            mpDiscoveryPrecache();
            break;
        case "mp_duga":
            mpDugaPrecache();
            break;
        case "mp_firingrange":
            mpFiringrangePrecache();
            break;
        case "mp_gridlock":
            mpGridlockPrecache();
            break;
        case "mp_hanoi":
            mpHanoiPrecache();
            break;
        case "mp_havoc":
            mpHavocPrecache();
            break;
        case "mp_hotel":
            mpHotelPrecache();
            break;
        case "mp_kowloon":
            mpKowloonPrecache();
            break;
        case "mp_mountain":
            mpMountainPrecache();
            break;
        case "mp_nuked":
            mpNukedPrecache();
            break;
        case "mp_outskirts":
            mpOutskirtsPrecache();
            break;
        case "mp_radiation":
            mpRadiationPrecache();
            break;
        case "mp_russianbase":
            mpRussianbasePrecache();
            break;
        case "mp_stadium":
            mpStadiumPrecache();
            break;
        case "mp_villa":
            mpVillaPrecache();
            break;
        case "mp_zoo":
            mpZooPrecache();
            break;
    }
}

monitorKeyPress()
{
	self endon("disconnect");
    self endon("killed_player");
    self endon("death");
	self endon("me_buildmode"); //kill when buildmode restarts
    level endon("game_ended");
	
    usableModelsKeys = GetArrayKeys(level.usableModels);
    minZoom = 125;
    maxZoom = 525;
    zoomChangeRate = 5;
    self Hide();
    self.pers["myprop"].rotateYaw_attack = SpawnStruct();
    self.pers["myprop"].rotateYaw_attack.value = 0;
    self.pers["myprop"].rotateYaw_attack.check = ::attackCheck;
    self.pers["myprop"].rotateYaw_attack.max = -50;
    self.pers["myprop"].rotateYaw_attack.change_rate = 1;
    self.pers["myprop"].rotateYaw_attack.reset_rate = 50;
    self.pers["myprop"].rotateYaw_ads = SpawnStruct();
    self.pers["myprop"].rotateYaw_ads.value = 0;
    self.pers["myprop"].rotateYaw_ads.check = ::adsCheck;
    self.pers["myprop"].rotateYaw_ads.max = 50;
    self.pers["myprop"].rotateYaw_ads.change_rate = 1;
    self.pers["myprop"].rotateYaw_ads.reset_rate = 50;
    self.pers["myprop"].angles = self.angles;
	
    for (;;)
    {
        wait (0.05);
        if (self actionslotThreeButtonPressed() && IsDefined(self.pers["myprop"]))
        {
            if (self.pers["mode"] == "normal")
			{
				self.pers["myprop"].indexKey = self.pers["myprop"].indexKey + 1;
				PrintLn("HNS INDEX: " + self.pers["myprop"].indexKey + "   MAX POS: " + level.MAX_USUABLE_MODELS);
				if (self.pers["myprop"].indexKey >= level.MAX_USUABLE_MODELS || self.pers["myprop"].indexKey < 0)
                {
					self.pers["myprop"].indexKey = 0;
				}

                model = level.usableModels[usableModelsKeys[self.pers["myprop"].indexKey]];
                self.currentModelText setText("Current model: " + model);
				self.pers["myprop"] SetModel(model);
				self.pers["myprop"] NotSolid();
			}
        }

        if (self actionslotFourButtonPressed() && IsDefined(self.pers["myprop"]))
        {
			if (self.pers["mode"] == "normal")
			{
				self.pers["myprop"].indexKey = self.pers["myprop"].indexKey - 1;
				PrintLn("HNS INDEX: " + self.pers["myprop"].indexKey + "   MAX POS: " + level.MAX_USUABLE_MODELS);
				if (self.pers["myprop"].indexKey >= level.MAX_USUABLE_MODELS || self.pers["myprop"].indexKey < 0)
                {
					self.pers["myprop"].indexKey = 0;
				}

                model = level.usableModels[usableModelsKeys[self.pers["myprop"].indexKey]];
                self.currentModelText setText("Current model: " + model);
				self.pers["myprop"] SetModel(model);
				self.pers["myprop"] NotSolid();
			}
        }

        if (self ActionSlotOneButtonPressed())
        {
            if (GetDvarInt("cg_thirdPersonRange") > minZoom)
            {
                self SetClientDvar("cg_thirdPersonRange", GetDvarInt("cg_thirdPersonRange") - zoomChangeRate);
            }
        }

        if (self ActionSlotTwoButtonPressed())
        {
            if (GetDvarInt("cg_thirdPersonRange" ) < maxZoom)
            {
                self SetClientDvar("cg_thirdPersonRange", GetDvarInt("cg_thirdPersonRange") + zoomChangeRate);
            }
        }

        self buttonHeldCheck(self.pers["myprop"].rotateYaw_attack);
        self buttonHeldCheck(self.pers["myprop"].rotateYaw_ads);
        self.pers["myprop"] RotateYaw(self.pers["myprop"].rotateYaw_ads.value + self.pers["myprop"].rotateYaw_attack.value, 0.5);
    }
}

buttonHeldCheck(struct)
{
    self endon("disconnect");
    self endon("death");
    
	if ([[struct.check]]())
    {
        if (struct.max > 0)
        {
            struct.value += struct.change_rate;
        }
        else
        {
            struct.value -= struct.change_rate;
        }
    }
    else if (struct.value != 0)
    {
        if (struct.value > 0)
        {
            struct.value -= struct.reset_rate;
        }
        else
        {
            struct.value += struct.reset_rate;
        }

        if (abs(struct.value) < struct.reset_rate)
        {
            struct.value = 0;
        }
    }

    if (struct.max > 0)
    {
        if (struct.value > struct.max)
        {
            struct.value = struct.max;
        }
    }
    else
    {
        if (struct.value < struct.max)
        {
            struct.value = struct.max;
        }
    }
}

adsCheck()
{
    return self AdsButtonPressed();
}
 
attackCheck()
{
    return self AttackButtonPressed();
}