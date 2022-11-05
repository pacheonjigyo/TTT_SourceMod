
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/////////////////////////////////////////////////////////////////
//					         //
//	#1 Define Symbol			         //
//					         //
/////////////////////////////////////////////////////////////////

new bool:GameRestarting = false;
new bool:Restartings = false;
new bool:Spawn = false;
new bool:IsPlayerDie[MAXPLAYERS+1] = false;
new bool:accesskey[MAXPLAYERS+1] = false;
new bool:DNAEND[MAXPLAYERS+1] = false;

new Check1[MAXPLAYERS+1];
new Check2[MAXPLAYERS+1]; 
new Check3[MAXPLAYERS+1];
new Round_Timer_Minute;
new Round_Timer_Second;
new TeamInfo[33] = 0;
new VictoryTeam = 0;
new g_BeamSprite;
new footstepsprite;
new lingcolors[4] = {255, 0, 0, 255};

new String:Class[33][255];
new String:K1SOUND[128] = "lmnop/knife/knife_s1.wav";
new String:D1SOUND[128] = "lmnop/knife/death.wav";
new String:D2SOUND[128] = "lmnop/knife/death_r1.wav";
new String:D3SOUND[128] = "lmnop/knife/death_r2.wav";
new String:RESETSOUND[128] = "lmnop/deathrun/Round4.mp3";
new String:WINSOUND[128] = "lmnop/knife/won.wav";
new String:LOSESOUND[128] = "lmnop/knife/lost.wav";
new String:CONNECTSOUND[128] = "lmnop/deathrun/connect.wav";

#define knife1    "lmnop/knife/knife_s1.wav"
#define death    "lmnop/knife/death.wav"
#define death2    "lmnop/knife/death_r1.wav"
#define death3    "lmnop/knife/death_r2.wav"
#define reset    "lmnop/deathrun/Round4.mp3"
#define win    "lmnop/knife/won.wav"
#define lose    "lmnop/knife/lost.wav"
#define connect    "lmnop/deathrun/connect.wav"
#define RP_DEFAULT_WAGES 0
#define VIRTUAL_RESPAWN 21

new Handle:RespawnHandle = INVALID_HANDLE;


/////////////////////////////////////////////////////////////////
//					         //
//	Stocks / Bools			         //
//					         //
/////////////////////////////////////////////////////////////////

public bool:IsCanEntity(Client)
{
	if(IsValidEntity(Client))
	{
		return true;
	}
	return false;
}

public bool:IsStillConnect(Client)
{
	if(IsValidEntity(Client))
	{
		if(Client <= GetMaxClients())
		{
			if(Client != 0)
			{
				if(IsClientConnected(Client))
				{
					return true;
				}
			}
		}
	}	return false;
}

public bool:IsStillAlive(Client)
{
	if(IsValidEntity(Client))
	{
		if(Client < GetMaxClients() +1)
		{
			if(Client != 0)
			{
				if(IsClientConnected(Client))
				{
					if(IsPlayerAlive(Client))
					{
						return true;
					}
				}
			}
		}
	}	return false;
}

stock bool:AllCheck(client)
{
	if(client > 0 && client <= MaxClients)
	{
		if(IsClientInGame(client) == true)
		{
			return true;
		}
		else
		{	
			return false;
		}
	}
	else
	{
		return false;
	}
}


/////////////////////////////////////////////////////////////////
//					         //
//	#2 Settings			         //
//					         //
/////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(VIRTUAL_RESPAWN);
	RespawnHandle = EndPrepSDKCall();

	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("player_death", Player_Death, EventHookMode_Pre);
	RegConsoleCmd("jointeam", JointeamBlock);
}

public OnMapStart()
{
	VictoryTeam = 0;

	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{
		TeamInfo[Client] = 0;
	}

	Restartings = false;
	ServerCommand("mp_forcerespawn 1");
	CreateTimer(10.0, StartGame);

	decl String:file1[256];
	decl String:file2[256];
	decl String:file3[256];
	decl String:file4[256];
	decl String:file5[256];
	decl String:file6[256];
	decl String:file7[256];
	decl String:file8[256];
	
	AddFileToDownloadsTable(file1);
	AddFileToDownloadsTable(file2);
	AddFileToDownloadsTable(file3);
	AddFileToDownloadsTable(file4);
	AddFileToDownloadsTable(file5);
	AddFileToDownloadsTable(file6);
	AddFileToDownloadsTable(file7);
	AddFileToDownloadsTable(file8);

	Format(file1, 256, "sound/%s", D3SOUND);
	Format(file2, 256, "sound/%s", D1SOUND);
	Format(file3, 256, "sound/%s", RESETSOUND);
	Format(file4, 256, "sound/%s", WINSOUND);
	Format(file5, 256, "sound/%s", LOSESOUND);
	Format(file6, 256, "sound/%s", CONNECTSOUND);
	Format(file7, 256, "sound/%s", K1SOUND);
	Format(file8, 256, "sound/%s", D2SOUND);
	Format(file1, 256, "sound/%s", D3SOUND);

	PrecacheSound(D1SOUND, true);
	PrecacheSound(RESETSOUND, true);
	PrecacheSound(WINSOUND, true);
	PrecacheSound(LOSESOUND, true);
	PrecacheSound(CONNECTSOUND, true);
	PrecacheSound(K1SOUND, true);
	PrecacheSound(D2SOUND, true);
	PrecacheSound(D3SOUND, true);

	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt"); 
	footstepsprite = PrecacheModel("materials/sprites/steam1.vmt");
}

public OnClientPutInServer(Client)
{
	SDKHook(Client, SDKHook_WeaponCanUse, WeaponCanUse);
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
	EmitSoundToAll(connect, SOUND_FROM_PLAYER, _, _, _, 1.0);
	CreateTimer(0.0, SetSpector, Client);
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsStillAlive(Client))
	{
		if(buttons & IN_USE)
		{
			if(accesskey[Client] == false)
			{
				What(Client);
				accesskey[Client] = true;
			}
		}
		else if(buttons & IN_ATTACK)
		{
			if(accesskey[Client] == false)
			{
				Why(Client);
				accesskey[Client] = true;
			}
		}
		else if(buttons & IN_ATTACK2)
		{
			if(accesskey[Client] == false)
			{
				How(Client);
				accesskey[Client] = true;
			}
		}
		else
		{
			accesskey[Client] = false;
		}
	}
	
	if(impulse == 51)
	{
		PrintToChat(Client, "\x01임펄스 51을 쓸 수 없습니다.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SayHook(Client, Args)
{
	if(IsPlayerDie[Client])
	{
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}


/////////////////////////////////////////////////////////////////
//					         //
//	#3 System			         //
//					         //
/////////////////////////////////////////////////////////////////
 
public Action:StartGame(Handle:Timer)
{
	if(GetClientCount() > 2)
	{
		CreateTimer(1.0, GetTimerInf);
		Restartings = true;
		for(new Client = 1; Client <= GetMaxClients(); Client++)
		{
			if(IsCanEntity(Client))
			{
				PrintCenterText(Client, "게임이 시작됩니다!");
			}
		}
	} else {
		for(new Client = 1; Client <= GetMaxClients(); Client++)
		{
			if(IsCanEntity(Client))
			{
				PrintCenterText(Client, "3명 이상이 있어야 가능하므로 플레이어가 올때까지 기다려 주세요.");
			}
		}
		CreateTimer(2.0, StartGame);
	}
}

public Action:GetTimerInf(Handle:Timer)
{
	new TCount = 0;
	new ECount = 0;

	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{
		if(IsStillAlive(Client))
		{
			if(StrContains(Class[Client], "트레이터", false) != -1)
			{
				TCount++;
			}

			if(StrContains(Class[Client], "이노센트", false) != -1)
			{
				ECount++;
			}
		}
	}
	if(TCount == 0 || ECount == 0)
	{
		if(!GameRestarting && Restartings)
		{
			new p;
			p = GetClientCount();
		
			if(p > 2)
			{
				CreateTimer(10.0, ChooseT);
				CreateTimer(12.0, ChooseF);
			}
			if(p > 6)
			{
				CreateTimer(10.0, ChooseT1);
				CreateTimer(12.0, ChooseF1);
			}
			if(p > 10)
			{
				CreateTimer(10.0, ChooseT2);
				CreateTimer(12.0, ChooseF2);
			}
			if(p > 14)
			{
				CreateTimer(10.0, ChooseT3);
				CreateTimer(12.0, ChooseF3);
			}
			if(p > 18)
			{
				CreateTimer(10.0, ChooseT4);
				CreateTimer(12.0, ChooseF4);
			}

			Round_Timer_Minute = 5
			Round_Timer_Second = 0

			for(new Client = 1; Client <= GetMaxClients(); Client++)
			{
				if(IsStillAlive(Client))
				{
					if(StrContains(Class[Client], "트레이터", false) != -1)
					{
						VictoryTeam = 2
					}

					if(StrContains(Class[Client], "이노센트", false) != -1)
					{
						VictoryTeam = 3
					}

					if(StrContains(Class[Client], "탐정", false) != -1)
					{
						VictoryTeam = 3
					}
				}

				if(Client == GetMaxClients())
				{
					GameRestarting = true;
					Spawn = true;

					CreateTimer(0.1, BonusTeam);
					CreateTimer(0.3, RestartGame);
					CreateTimer(3.0, RespawnPlayer);
					CreateTimer(10.0, Start2);	
					CreateTimer(16.0, Stop);
				}

				if(IsCanEntity(Client))
				{
					ChangeClientTeam(Client, 1);
					PrintCenterText(Client, "게임을 재시작합니다. 잠시만 기다려주세요!");
				}
			}
		}
	}

	if(!GameRestarting && Restartings)
	{
		if(Round_Timer_Minute < 0)
		{
			PrintCenterTextAll("작전 시간이 끝났습니다.");

			for(new Client = 1; Client <= GetMaxClients(); Client++)
			{
				if(StrContains(Class[Client], "트레이터", false) != -1)
				{
					CreateTimer(1.0, SetSpector, Client);
				}
			}
		}

		for(new Client = 1; Client <= GetMaxClients(); Client++)
		{
			CreateTimer(1.0, CountDown, Client);
		}

		CreateTimer(1.0, Action_Exp);
	}

	if(TCount != 0 && ECount != 0)
		GameRestarting = false;

	if(GetClientCount() == 0)
	{
		GameRestarting = false;
		Restartings = false;

		for(new i = 1; i <= GetMaxClients(); i++)
		{
			TeamInfo[i] = 0;
		}

		VictoryTeam = 0;

		CreateTimer(5.0,StartGame);
	}
	CreateTimer(1.0, GetTimerInf);

	TCount = 0;
	ECount = 0;
}

public Action:RestartGame(Handle:Timer)
{
	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{
		if(IsCanEntity(Client))
		{
			TeamInfo[Client] = 3;
		}

		if(Client == GetMaxClients())
		{
			new RebelCount = 0;

			for(new i = 1; i < GetMaxClients(); i++)
			{
				if(IsCanEntity(i))
				{
					TeamInfo[i] = 3;
					RebelCount++;
				}
			}
		}
	}
}

public Action:RespawnPlayer(Handle:Timer)
{
	ServerCommand("mp_restartgame 5");
	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{
		if(IsCanEntity(Client))
		{
			if(TeamInfo[Client] == 3)
			{
				Class[Client] = "이노센트";
				ChangeClientTeam(Client, 3);
			}
		}
		VictoryTeam = 0;
	}
}

public Action:BonusTeam(Handle:Timer)
{
	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{
		if(IsStillAlive(Client))
		{
			//
		}

		if(VictoryTeam == 0)
		{
			CreateTimer(1.0, SetSpector, Client);
		}

		if(VictoryTeam == 2)
		{
			CreateTimer(1.0, SetSpector, Client);
			CreateTimer(1.0, Win2, Client);
			EmitSoundToAll(lose, SOUND_FROM_PLAYER, _, _, _, 1.0);
		}

		if(VictoryTeam == 3)
		{
			CreateTimer(1.0, SetSpector, Client);
			CreateTimer(1.0, Win3, Client);
			EmitSoundToAll(win, SOUND_FROM_PLAYER, _, _, _, 1.0);
		}
	}
}

public Action:ChooseT(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(1, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
	
			PrintToChat(select, "\x01당신은 \x04트레이터\x01를 잡을 \x04탐정 \x01입니다.");

			Class[select] = "탐정";
			TeamInfo[select] = 2;

			ChangeClientTeam(select, 1);
			ChangeClientTeam(select, 2);
			CreateTimer(0.2, RespawnClient, select);
		}
	}
}

public Action:ChooseF(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(1, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x05배신자, \x04트레이터 \x01입니다!");
			Class[select] = "트레이터";
			TeamInfo[select] = 3;
			CreateTimer(2.5, Give, select);
		}
	}
}

public Action:ChooseT1(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(2, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x04트레이터\x01를 잡을 \x04탐정 \x01입니다.");
			Class[select] = "탐정";
			TeamInfo[select] = 2;
			ChangeClientTeam(select, 1);
			ChangeClientTeam(select, 2);
			CreateTimer(0.2, RespawnClient, select);
		}
	}
}

public Action:ChooseF1(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(2, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x05배신자, \x04트레이터 \x01입니다!");
			Class[select] = "트레이터";
			TeamInfo[select] = 3;
			CreateTimer(2.5, Give, select);
		}
	}
}

public Action:ChooseT2(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(2, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x04트레이터\x01를 잡을 \x04탐정 \x01입니다.");
			Class[select] = "탐정";
			TeamInfo[select] = 2;
			ChangeClientTeam(select, 1);
			ChangeClientTeam(select, 2);
			CreateTimer(0.2, RespawnClient, select);
		}
	}
}

public Action:ChooseF2(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(3, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x05배신자, \x04트레이터 \x01입니다!");
			Class[select] = "트레이터";
			TeamInfo[select] = 3;
			CreateTimer(2.5, Give, select);
		}
	}
}

public Action:ChooseT3(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(3, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x04트레이터\x01를 잡을 \x04탐정 \x01입니다.");
			Class[select] = "탐정";
			TeamInfo[select] = 2;
			ChangeClientTeam(select, 1);
			ChangeClientTeam(select, 2);
			CreateTimer(0.2, RespawnClient, select);
		}
	}
}

public Action:ChooseF3(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(4, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x05배신자, \x04트레이터 \x01입니다!");
			Class[select] = "트레이터";
			TeamInfo[select] = 3;
			CreateTimer(2.5, Give, select);
		}
	}
}

public Action:ChooseT4(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(4, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x04트레이터\x01를 잡을 \x04탐정 \x01입니다.");
			Class[select] = "탐정";
			TeamInfo[select] = 2;
			ChangeClientTeam(select, 1);
			ChangeClientTeam(select, 2);
			CreateTimer(0.2, RespawnClient, select);
		}
	}
}

public Action:ChooseF4(Handle:Timer)
{
	new maxselect = 0;
	new selects[MaxClients+1];

	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsStillAlive(i) == true)
		{
			if(GetClientTeam(i) == 3)
			{
				maxselect++;
				selects[maxselect] = i;
			}
		}
	}

	if(maxselect > 0)
	{
		new select = selects[GetRandomInt(5, maxselect)];
			
		if(IsClientConnected(select) && IsPlayerAlive(select))
		{
			new String:choose[32];
			GetClientName(select, choose, 32);	
			PrintToChat(select, "\x01당신은 \x05배신자, \x04트레이터 \x01입니다!");
			Class[select] = "트레이터";
			TeamInfo[select] = 3;
			CreateTimer(2.5, Give, select);
		}
	}
}


/////////////////////////////////////////////////////////////////
//					         //
//	#5 Other Actions			         //
//					         //
/////////////////////////////////////////////////////////////////

public Action:SetSpector(Handle:Timer, any:Client)
{
	ChangeClientTeam(Client, 1);
	IsPlayerDie[Client] = true;
}

public Action:Give(Handle:Timer, any:Client)
{
	if(IsStillAlive(Client))
	{
		if(StrContains(Class[Client], "탐정", false) != -1)
		{
			PrintToChat(Client, "\x05골드건[357]\x01과 \x05DNA분석기[Stunstick]\x01를 \x04지급 \x01받았습니다.");
			GivePlayerItem(Client, "weapon_357");
			GivePlayerItem(Client, "weapon_stunstick");
			PrecacheModel("models/Characters/cop.mdl", true);
			SetEntityModel(Client, "models/Characters/cop.mdl");

		}

		if(StrContains(Class[Client], "트레이터", false) != -1)
		{
			PrintToChat(Client, "\x05이노센트 제거용 무기[Crowbar]\x01를 \x04지급 \x01받았습니다.");
			GivePlayerItem(Client, "weapon_crowbar");
		}
	}
}

public Action:WeaponRev(Handle:Timer, any:Client)
{
	new Weapon_Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	new Max_Guns = 16;
	Max_Guns = 20;

	for(new i = 0; i < Max_Guns; i = (i + 4))
	{
		new Weapon_ID = GetEntDataEnt2(Client, Weapon_Offset + i);

		if(Weapon_ID > 0)
		{
			RemovePlayerItem(Client, Weapon_ID);
			RemoveEdict(Weapon_ID);
		}
	}
	GivePlayerItem(Client, "weapon_pistol");
}

public Action:RespawnClient(Handle:Timer, any:Client)
{
	if(IsStillConnect(Client))
	{
		SDKCall(RespawnHandle, Client);
		if(GetClientTeam(Client) == 2)
		{
			new AlivePlayer = 0;	
			for(new x; x <= GetMaxClients(); x++)
			{
				if(IsStillAlive(x) && GetClientTeam(x) == 3)
				{
					AlivePlayer++;
				}
			}
		}
	}
}

public Action:DNA(Handle:Timer, any:Client)
{
	new Float:clientposition[3], Float:Angle[3], Float:PointAngle[3];
	GetClientAbsOrigin(Client, clientposition);
	Angle[0] = GetRandomFloat(-1.0, 1.0);
	Angle[1] = GetRandomFloat(-1.0, 1.0);
	Angle[2] = GetRandomFloat(-1.0, 1.0);
	PointAngle[0] = 0.0;
	PointAngle[1] = 0.0;
	PointAngle[2] += 15.0;

	TE_SetupBloodSprite(clientposition, Angle, lingcolors, 50, footstepsprite, g_BeamSprite)
	TE_SendToAll();

	if(DNAEND[Client])
	{
		CreateTimer(0.25, DNA, Client);
	}
}

public Action:DNAX(Handle:Timer, any:Client)
{
	DNAEND[Client] = false;
}

public Action:Start(Handle:Timer, any:Client)
{
	SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
}

public Action:Stop(Handle:Timer)
{
	Spawn = false;
}

public Action:Start2(Handle:Timer)
{
	EmitSoundToAll(reset, SOUND_FROM_PLAYER, _, _, _, 1.0);
}

public Action:What(Client)
{
	if(Check1[Client] > 0)
	{
		new Player;
		Player = GetClientAimTarget(Client, true);

		if(IsStillAlive(Player) && IsStillAlive(Client))
		{
			Check1[Client] = (Check1[Client] - 1);
			new String:to[32];
			new String:from[32];
			GetClientName(Client, to, 32);
			GetClientName(Player, from, 32);

			PrintCenterTextAll("%s : 지금 제 앞에는 %s님이 지나가고 있습니다.", to, from);
			PrintToChat(Client, "\x05앞으로 \x04%d번 \x01사용하면 \x04더이상 \x01사용할 수 \x05없습니다.", Check1[Client])
		}
	}
	else
	{
		//
	}
}

public Action:Why(Client)
{
	new Player;
	Player = GetClientAimTarget(Client, true);

	if(IsStillAlive(Player) && IsStillAlive(Client))
	{
		new String:to[32];
		new String:from[32];
		GetClientName(Client, to, 32);
		GetClientName(Player, from, 32);

		if(Check2[Client] > 0)
		{
			if(StrContains(Class[Client], "탐정", false) != -1)
			{
				//
			}
			else
			{
				Check2[Client] = (Check2[Client] - 1);
				PrintCenterTextAll("%s : 살려주세요! %s님이 저를 죽이려고 합니다!", from, to);
				PrintToChat(Player, "\x05앞으로 \x04%d번 \x01사용하면 \x04더이상 \x01사용할 수 \x05없습니다.", Check2[Client])
			}	
		}

		if(StrContains(Class[Client], "트레이터", false) != -1)
		{
			if(StrContains(Class[Player], "트레이터", false) != -1)
			{
				PrintToChat(Client, "\x05멈추십시오! \x04동료 트레이터[%s] \x01입니다!", from);
			}
		}
	}
	else
	{
		//
	}
}

public Action:How(Client)
{
	if(Check3[Client] > 0)
	{
		new Player;
		Player = GetClientAimTarget(Client, true);

		if(IsStillAlive(Player) && IsStillAlive(Client))
		{
			Check3[Client] = (Check3[Client] - 1);
			new String:to[32];
			new String:from[32];
			GetClientName(Client, to, 32);
			GetClientName(Player, from, 32);

			PrintCenterTextAll("%s : 저는 %s님이 수상합니다!", to, from);
			PrintToChat(Client, "\x05앞으로 \x04%d번 \x01사용하면 \x04더이상 \x01사용할 수 \x05없습니다.", Check3[Client])
		}
	}
	else
	{
		//
	}
}


/////////////////////////////////////////////////////////////////
//					         //
//	#6 Hud Timers			         //
//					         //
/////////////////////////////////////////////////////////////////

public Action:Win2(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client))
	{
		if(IsClientInGame(Client) == false)

			return Plugin_Handled;
		SetHudTextParams(-1.0, -1.0, 5.0, 255, 0, 0, 255, 0, 3.0, 0.1, 0.2);
		ShowHudText(Client, -1, "///////////////////////////////////\n//트레이터가 승리하였습니다.//\n//////////////////////////////");
	}
	return Plugin_Handled;
}

public Action:Win3(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client))
	{
		if(IsClientInGame(Client) == false)

			return Plugin_Handled;
		SetHudTextParams(-1.0, -1.0, 5.0, 0, 0, 255, 255, 0, 3.0, 0.1, 0.2);
		ShowHudText(Client, -1, "/////////////////////////////\n//이노센트가 승리하였습니다.//\n///////////////////////////");
	}
	return Plugin_Handled;
}

public Action:Choose(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client))
	{
		if(IsClientInGame(Client) == false)
			return Plugin_Handled;
		SetHudTextParams(-1.0, -1.0, 5.0, 0, 255, 0, 255, 0, 3.0, 0.1, 0.2);
		ShowHudText(Client, -1, "이노센트, 트레이터, 탐정을\n\n선택하는 중입니다, 준비하십시오...");
	}
	return Plugin_Handled;
}

public Action:Info(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client))
	{
		if(IsStillAlive(Client))
		{
			if(IsClientInGame(Client) == false)
				return Plugin_Handled;
			SetHudTextParams(0.05, 0.015, 1.0, 120, 90, 24, 255, 0, 6.0, 0.1, 0.2);
			ShowHudText(Client, -1, "먹는거임's TTT서버\n\n신분 : %s", Class[Client]);
			CreateTimer(0.5, Info, Client);
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CountDown(Handle:Timer, any:Client)
{
	SetHudTextParams(-1.0, 0.85, 1.0, 255, 90, 24, 255, 0, 0.5, 0.1, 0.2);

	if(AllCheck(Client))
	{
		if(Round_Timer_Second >= 10)
		{
			ShowHudText(Client, -1, "Trouble in Terrorist Town\n\n남은시간 : %d분 %d초", Round_Timer_Minute, Round_Timer_Second);
		}
		else
		{
			ShowHudText(Client, -1, "Trouble in Terrorist Town\n\n남은시간 : %d분 0%d초", Round_Timer_Minute, Round_Timer_Second);
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Action_Exp(Handle:Timer)
{
	if(Round_Timer_Second > 0)
	{
		Round_Timer_Second--;
	}
	else
	{
		Round_Timer_Minute--;
		Round_Timer_Second = 59
	}
	if(Round_Timer_Second > 59)
	{
		Round_Timer_Minute++;
		Round_Timer_Second = Round_Timer_Second - 59
	}
}


/////////////////////////////////////////////////////////////////
//					         //
//	#7 SDK Hooks			         //
//					         //
/////////////////////////////////////////////////////////////////

public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	IsPlayerDie[Client] = false;

	CreateTimer(0.1, WeaponRev, Client);
	CreateTimer(0.5, Give, Client);
	CreateTimer(1.0, Info, Client);
	Check1[Client] = 3;
	Check2[Client] = 3;
	Check3[Client] = 3;

	if(StrContains(Class[Client], "이노센트", false) != -1)
	{
		CreateTimer(0.5, Choose, Client);
		CreateTimer(3.0, Start, Client);
		SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
	}
}

public Event_Hurt(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new Client = Getn ClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(Spawn_Event, "attacker"));
	new String:Attacker_Name[32], String:Client_Name[32], String:Attacker_Weapon[32];

	GetClientName(Attacker, Attacker_Name, 32);
	GetClientName(Client, Client_Name, 32);	
	
	if(IsStillAlive(Attacker))
	{
		GetClientWeapon(Attacker, Attacker_Weapon, 32); 
	}
	
	if(StrEqual(Attacker_Weapon, "weapon_stunstick"))
	{	
		if(StrContains(Class[Attacker], "탐정", false) != -1)
		{
			PrintToChat(Attacker, "\x04DNA분석\x01을 \x05시작\x01했습니다! \x05곧 결과\x01가 나옵니다.");
			PrintToChat(Client, "\x04탐정\x01이 \x05당신\x01의 \x04DNA\x01를 \x05측정하기 \x01시작했습니다.");

			if(StrContains(Class[Client], "트레이터", false) != -1)
			{
				PrintToChat(Attacker, "\x05결과\x01: 그는 \x04트레이터 \x01였습니다!");
				PrintToChat(Client, "\x04탐정\x01이 \x05당신\x01의 \x04정체\x01를 알아내었습니다. 도망가십시오!");
			}
			else if(StrContains(Class[Client], "이노센트", false) != -1)
			{
				PrintToChat(Attacker, "\x05결과\x01: 그는 \x04이노센트 \x01였습니다!");
			}
		}
	}
	
	if(StrContains(Class[Attacker], "트레이터", false) != -1)
	{
		if(StrContains(Class[Client], "트레이터", false) != -1)
		{
			PrintToChat(Attacker, "\x01멈추십시오! \x05당신의 \x04동료 트레이터\x01입니다!!");
		}

		if(StrEqual(Attacker_Weapon, "weapon_crowbar"))
		{
			EmitSoundToAll(knife1, SOUND_FROM_PLAYER, _, _, _, 1.0);
		}
	}
}

public Action:Player_Death(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));

	IsPlayerDie[Client] = true;
	DNAEND[Client] = false;

	IsStillAlive(Attacker)
	{
		if(GetClientTeam(Attacker) == 3 && GetClientTeam(Client) == 3)
		{
			SetEntProp(Attacker, Prop_Data, "m_iFrags", GetClientFrags(Attacker) + 1);
		}

		if(GetClientTeam(Attacker) == 3 && GetClientTeam(Client) == 2)
		{
			SetEntProp(Attacker, Prop_Data, "m_iFrags", GetClientFrags(Attacker) - 1);
		}
	}
	
	decl Chances;
	Chances = GetRandomInt(1, 3); 
		
	decl Float:targetposition[3], Float:vector[3];
	GetClientEyePosition(Client, targetposition);
	NormalizeVector(vector, vector);

	if(Chances == 1)
	{
		EmitSoundToAll(death, SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,targetposition,NULL_VECTOR,true,0.0);
	}

	if(Chances == 2)
	{
		EmitSoundToAll(death2, SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,targetposition,NULL_VECTOR,true,0.0);
	}

	if(Chances == 3)
	{
		EmitSoundToAll(death3, SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,targetposition,NULL_VECTOR,true,0.0);
	}

	CreateTimer(1.0, SetSpector, Client);

	if(GetClientTeam(Attacker) == 3)
	{
		DNAEND[Attacker] = true;
		CreateTimer(1.0, DNA, Attacker);
		CreateTimer(11.0, DNAX, Attacker);
	}
		
	new String:to[32];
	GetClientName(Client, to, 32);

	if(StrContains(Class[Client], "트레이터", false) != -1)
	{
		PrintToChat(Attacker, "\x01죽은 그는 \x04트레이터 \x01였습니다!");
		PrintToChatAll("\x01이번 라운드의 \x05트레이터\x01는 \x04%s\x01님이었습니다!", to);
		PrintCenterTextAll("%s 님이 이번 라운드의 트레이터였습니다!", to);
	}

	if(Attacker != Client)
	{
		if(IsStillAlive(Attacker))
		{
			if(StrContains(Class[Client], "이노센트", false) != -1)
			{
				PrintToChat(Attacker, "\x01죽은 그는 \x04이노센트 \x01였습니다!");
			}
			else if(StrContains(Class[Client], "탐정", false) != -1)
			{
				PrintToChat(Attacker, "\x01죽은 그는 \x04탐정 \x01이였습니다!");
			}

			if(StrContains(Class[Attacker], "트레이터", false) != -1)
			{
				PrintToChat(Client, "\x04누군가\x01가 \x04당신\x01을 \x05죽였습니다. \x04트레이터\x01일 \x05확률\x01이 큽니다!");
				Round_Timer_Second = (Round_Timer_Second + 30);
			}

			PrintCenterTextAll("\x01누군가가 살인을 저질렀습니다! 핏자국을 따라가십시오!");
			PrintToChat(Attacker, "\x04당신\x01은 \x04사람\x01을 \x05죽였습니다. \x05당장 도망\x01가십시오!");
			PrintToChat(Attacker, "\x04남아있는 핏자국\x01이 \x04사라지려면 \x0510초\x01가 지나야 합니다..");
		}
	}
	else
	{
		PrintToChat(Client, "\x01자결 하였습니다.");
		CreateTimer(1.0, SetSpector, Client);
	}

	if(Attacker == 0)
	{
		if(!Spawn)
		{
			CreateTimer(1.0, SetSpector, Client);
		}
	}

	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(IsStillAlive(attacker))
	{
		decl String:sWeapon[32];

		GetClientWeapon(attacker, sWeapon, 32);

		if((StrEqual(sWeapon, "weapon_357")) || (StrEqual(sWeapon, "weapon_crowbar")))
		{
			damage *= 100.0;
			return Plugin_Changed;
		}
		else if(StrEqual(sWeapon, "weapon_stunstick"))
		{
			damage -= 39.0;
			return Plugin_Changed;
		}
		else if(StrEqual(sWeapon, "weapon_pistol"))
		{
			damage += 2.0;
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:WeaponCanUse(Client, weapon)
{
	if(StrContains(Class[Client], "탐정", false) != -1)
	{
		decl String:sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
		if((StrEqual(sWeapon, "weapon_slam")) || (StrEqual(sWeapon, "weapon_ar2")) || (StrEqual(sWeapon, "weapon_crossbow")) || (StrEqual(sWeapon, "weapon_shotgun")) || (StrEqual(sWeapon, "weapon_rpg")) || (StrEqual(sWeapon, "item_battery")))

		return Plugin_Handled;
	}
	else
	{
		decl String:sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
		if((StrEqual(sWeapon, "weapon_slam")) || (StrEqual(sWeapon, "weapon_ar2")) || (StrEqual(sWeapon, "weapon_crossbow")) || (StrEqual(sWeapon, "weapon_shotgun")) || (StrEqual(sWeapon, "weapon_rpg")) || (StrEqual(sWeapon, "item_battery")))

		return Plugin_Handled;
	}
	return Plugin_Continue;
}


/////////////////////////////////////////////////////////////////
//					         //
//	#8 Arguments			         //
//					         //
/////////////////////////////////////////////////////////////////

public Action:JointeamBlock(client,args)
{
	new String:Arg[8];
	GetCmdArg(1, Arg, sizeof(Arg));

	if(StrEqual(Arg, "2") || StrEqual(Arg, "3") || StrEqual(Arg, "1"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg949\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
