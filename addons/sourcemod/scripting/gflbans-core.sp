#include <sourcemod>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

#include "gflbans-core/natives.sp"
#include "gflbans-core/misc.sp"
#include "gflbans-core/api.sp"

/* ===== Global Variables ===== */
ConVar g_cvAPIUrl;
ConVar g_cvAPIKey;
ConVar g_cvAPIServerID;
ConVar g_cvAcceptGlobalBans;
ConVar g_cvDebug;
char g_sAPIUrl[512];
char g_sAPIKey[256];
char g_sAPIServerID[32];
char g_sAPIAuthHeader[512];
char g_sMap[64];
char g_sMod[16];
char g_sServerHostname[96];
char g_sServerOS[8];
int g_iMaxPlayers;
bool g_bServerLocked;
Handle hbTimer;
Handle g_hGData;
HTTPClient httpClient;

/* ===== Definitions ===== */
#define PREFIX "\x01[\x0CGFLBans\x01]"

/* ===== Plugin Info ===== */
public Plugin myinfo =
{
    name        =    "GFLBans - Core",
    author        =    "Infra",
    description    =    "GFLBans Core plugin",
    version        =    "0.3-BETA",
	url        =    "https://github.com/GFLClan"
};

/* ===== Main Code ===== */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNatives(); // From natives.sp
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hGData = LoadGameConfigFile("gflbans.games");

    g_cvAPIUrl = CreateConVar("gb_api_url", "bans.gflclan.com/api/v1", "GFLBans API URL");
    g_cvAPIKey = CreateConVar("gb_api_key", "", "GFLBans API Key", FCVAR_PROTECTED);
    g_cvAPIServerID = CreateConVar("gb_api_svid", "", "GFLBans API Server ID.", FCVAR_PROTECTED);
    g_cvAcceptGlobalBans = CreateConVar("gb_accept_global_infractions", "1", "Accept global GFL bans. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);
    g_cvDebug = CreateConVar("gb_enable_debug_mode", "0", "Enable detailed logging of actions. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "GFLBans-Core");
}

public void OnConfigsExecuted()
{
    GetConVarString(g_cvAPIUrl, g_sAPIUrl, sizeof(g_sAPIUrl));
    GetConVarString(g_cvAPIKey, g_sAPIKey, sizeof(g_sAPIKey));
    GetConVarString(g_cvAPIServerID, g_sAPIServerID, sizeof(g_sAPIServerID));
    Format(g_sAPIAuthHeader, sizeof(g_sAPIAuthHeader), "SERVER %s %s", g_sAPIServerID, g_sAPIKey);

    CheckMod(g_sMod); // Check what game we are on.
    CheckOS(g_hGData, g_sServerOS); // Check what OS we are on.

    // Start the HTTP Connection:
    httpClient = new HTTPClient(g_sAPIUrl);
    httpClient.SetHeader("Authorization", g_sAPIAuthHeader);
}

public void OnMapStart()
{
    hbTimer = CreateTimer(30.0, pulseTimer, _, TIMER_REPEAT); // Start the Heartbeat pulse timer
}

public Action pulseTimer(Handle timer)
{
    GetServerInfo(); // Grab whatever is needed for the Heartbeat pulse.
    API_Heartbeat(httpClient, g_sServerHostname, g_iMaxPlayers, g_sServerOS, g_sMod, g_sMap, g_bServerLocked, g_cvAcceptGlobalBans.BoolValue);

    return Plugin_Continue;
}

public void OnMapEnd()
{
    CloseHandle(hbTimer); // Close the Heartbeat timer handle (started in OnMapStart)
}

void GetServerInfo()
{
    char svPwd[128];

    GetCurrentMap(g_sMap, sizeof(g_sMap));
    g_iMaxPlayers = GetMaxHumanPlayers();
    GetConVarString(FindConVar("hostname"), g_sServerHostname, sizeof(g_sServerHostname));

    // Check if the server is locked:
    GetConVarString(FindConVar("sv_password"), svPwd, sizeof(svPwd));
    if(!StrEqual(svPwd, ""))
        g_bServerLocked = true;
    else 
        g_bServerLocked = false;
}