// Future forwards go here
void CreateForwards()
{
    g_gfOnPunishAdded = new GlobalForward("GFLBans_OnPlayerPunished", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String);
    g_gfOnPunishRemoved = new GlobalForward("GFLBans_OnPunishRemoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);
}