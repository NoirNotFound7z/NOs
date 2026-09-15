local Custome = {}

Custome.sections = {
    {
        Section = "Avatar Actions",
        Position = "Left",
        Buttons = {
            { Name = "Aura Hub", URL = "https://raw.githubusercontent.com/L4rdberk/l4rd/refs/heads/main/avchalf3nonotileak.txt", NotifyTitle = "Copy Avatar" },
            { Name = "Nexus 5.0", URL = "https://avatar.sowonaha.workers.dev", NotifyTitle = "Copy Avatar" },
            { Name = "Clone Avatar", URL = "https://rawscripts.net/raw/Universal-Script-Avatar-Copier-Copy-Player-Avatar-83503", NotifyTitle = "Clone Avatar" },
        }
    },
    {
        Section = "Emotes",
        Position = "Left",
        Buttons = {
            { Name = "Vexro Hub", URL = "https://vexroscripts.com.tr/vexroemotes.luau", NotifyTitle = "Emotes" },
            { Name = "AFEM MAX [ Key ]", URL = "https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/refs/heads/main/afemmaxloader.lua", NotifyTitle = "Emotes" },
            { Name = "AFEM LITE [ No Key ]", URL = "https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/refs/heads/main/afemmaxlite.lua", NotifyTitle = "Emotes", Raw = false },
            { Name = "KitK4t Emotes", URL = "https://api.rubis.app/v2/scrap/qehrlb7Oh8oLOgu3/raw", NotifyTitle = "Emotes" },
            { Name = "7yd7 I Emote", URL = "https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua", NotifyTitle = "Emotes" },
            { Name = "Anim Pack", URL = "https://raw.githubusercontent.com/gwnrdt/gwnrdt/refs/heads/main/Animation.lua", NotifyTitle = "Emotes" },
            { Name = "Anim V2.5", URL = "https://raw.githubusercontent.com/Emerson2-creator/Scripts-Roblox/refs/heads/main/ScriptR6/AnimGuiV2.lua", NotifyTitle = "Emotes" },
            { Name = "Emote Tiktok | Delta Mad Stuffs", URL = "https://raw.githubusercontent.com/Gazer-Ha/Free-emote/refs/heads/main/Delta%20mad%20stuffs", NotifyTitle = "Emotes" },
            { Name = "Spycerr", URL = "https://raw.githubusercontent.com/sypcerr/scripts/refs/heads/main/c15.lua", NotifyTitle = "Emotes", Raw = true },
        }
    },
}

function Custome.RunScript(item)
    local success, err = pcall(function()
        loadstring(game:HttpGet(item.URL, item.Raw))()
    end)
    return success, err
end

return Custome