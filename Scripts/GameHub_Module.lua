local GameHub = {}

GameHub.categories = {
    {
        Name = "Combat",
        Icon = "swords",
        Games = {
            { Section = "Jujutsu Shenanigans", Buttons = {
                { Name = "Jujutsu Shenanigans (TBO)", URL = "https://raw.githubusercontent.com/cool5013/TBO/main/TBOscript" },
                { Name = "Jujutsu Shenanigans II", URL = "https://raw.githubusercontent.com/scriptjame/Jujutsu-Shenanigans/refs/heads/main/hai.lua" },
            }},
            { Section = "M1 Reset", Buttons = {
                { Name = "M1 reset", URL = "https://raw.githubusercontent.com/NoirGoodBoi/NoirScripts/main/M1Reset.lua" },
            }},
            { Section = "The Strongest Battleground", Buttons = {
                { Name = "The Strongest Battleground (TThanh Hub)", URL = "https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/Tthanh%20Tong%20Hop%20Tech.txt" },
                { Name = "The Strongest Battleground II", URL = "https://raw.githubusercontent.com/scriptjame/TheStrongestBattlegrounds/refs/heads/main/main.lua" },
            }},
            { Section = "Legend Battleground", Buttons = {
                { Name = "Legend Battleground", URL = "https://raw.githubusercontent.com/solarastuff/legendsbattlegrounds/refs/heads/main/legendary.lua" },
            }},
            { Section = "Evade", Buttons = {
                { Name = "Evade (Elderwyrm Hub)", URL = "https://raw.githubusercontent.com/Vraigos/Elderwyrm-Hub-X/refs/heads/main/Scripts/Evade/Overhaul.lua" },
                { Name = "Evade", URL = "https://raw.githubusercontent.com/scriptjame/evade/refs/heads/main/shabi.lua" },
            }},
            { Section = "Forsaken", Buttons = {
                { Name = "Forsaken I", URL = "https://raw.githubusercontent.com/Snowt69/SNT-HUB/refs/heads/main/Forsaken" },
                { Name = "Forsaken II", URL = "https://raw.githubusercontent.com/scriptjame/Forsaken/refs/heads/main/null.lua" },
            }},
            { Section = "Bite By Night", Buttons = {
                { Name = "Bite By Night", URL = "https://raw.githubusercontent.com/scriptjame/BiteBynight/refs/heads/main/ty.lua" },
            }},
            { Section = "Murder Mystery 2", Buttons = {
                { Name = "Murder Mystery 2 I", URL = "https://pastefy.app/wwfom1bX/raw", Raw = true },
                { Name = "Murder Mystery 2 II", URL = "https://raw.githubusercontent.com/scriptjame/mm2/refs/heads/main/bawe.lua", Raw = true },
            }},
            { Section = "Rivals", Buttons = {
                { Name = "Rivals", URL = "https://raw.githubusercontent.com/scriptjame/rivals/refs/heads/main/loot.lua" },
            }},
            { Section = "Arsenal", Buttons = {
                { Name = "Arsenal", URL = "https://raw.githubusercontent.com/scriptjame/Arsenal/refs/heads/main/nah.lua" },
            }},
            { Section = "Blade Ball", Buttons = {
                { Name = "Blade Ball I", URL = "https://raw.githubusercontent.com/AgentX771/ArgonHubX/main/Loader.lua" },
                { Name = "Blade Ball II", URL = "https://raw.githubusercontent.com/scriptjame/test2/refs/heads/main/bladeball.lua" },
            }},
            { Section = "Aura-Ascension", Buttons = {
                { Name = "Aura-Ascension", URL = "https://raw.githubusercontent.com/scriptjame/Aura-Ascension/refs/heads/main/looot.lua" },
            }},
        }
    },
    {
        Name = "Survival",
        Icon = "shield",
        Games = {
            { Section = "99 Night In The Forest", Buttons = {
                { Name = "99 Night In The Forest I", URL = "https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/loader.lua", Raw = true },
                { Name = "99 Night In The Forest II", URL = "https://raw.githubusercontent.com/scriptjame/99Nights/refs/heads/main/shiba.lua" },
            }},
            { Section = "Ink Game", Buttons = {
                { Name = "Ink Game", URL = "https://raw.githubusercontent.com/wefwef34/inkgames.github.io/refs/heads/main/ringta.lua" },
            }},
            { Section = "Deadrail", Buttons = {
                { Name = "Deadrail (Ringta)", URL = "https://raw.githubusercontent.com/erewe23/deadrailsring.github.io/refs/heads/main/ringta.lua" },
                { Name = "Deadrail II", URL = "https://raw.githubusercontent.com/scriptjame/Dead-Rails/refs/heads/main/hola.lua" },
            }},
            { Section = "Farm Bond", Buttons = {
                { Name = "Farm Bond (Skull Hub)", URL = "https://raw.githubusercontent.com/hungquan99/SkullHub/main/loader.lua" },
            }},
            { Section = "Tower Of Zombies", Buttons = {
                { Name = "Tower Of Zombies", URL = "https://raw.githubusercontent.com/gumanba/Scripts/main/TowerofZombies" },
            }},
            { Section = "Survive Zombie Arena", Buttons = {
                { Name = "Survive Zombie Arena", URL = "https://pastefy.app/qcHi3xbp/raw", Raw = true },
            }},
            { Section = "Raft 101 Survival", Buttons = {
                { Name = "Raft 101 Survival", URL = "https://pastebin.com/raw/NUunqb1w", Raw = true },
            }},
            { Section = "Doors", Buttons = {
                { Name = "Doors I", URL = "https://raw.githubusercontent.com/Iliankytb/Iliankytb/main/NewBestDoorsScriptIliankytb" },
                { Name = "Doors II", URL = "https://raw.githubusercontent.com/scriptjame/Doors/refs/heads/main/wwsp.lua" },
            }},
        }
    },
    {
        Name = "Grinding",
        Icon = "coins",
        Games = {
            { Section = "Blox Fruit", Buttons = {
                { Name = "Blox Fruit", URL = "https://raw.githubusercontent.com/scriptjame/bloxfruit/refs/heads/main/main.lua" },
            }},
            { Section = "Sailor Piece", Buttons = {
                { Name = "Sailor Piece", URL = "https://raw.githubusercontent.com/scriptjame/SailorPiece/refs/heads/main/heh.lua" },
            }},
            { Section = "Cursed Blade", Buttons = {
                { Name = "Cursed Blade", URL = "https://api.glua.xyz/loader" },
            }},
            { Section = "Bee Swarm Simulator", Buttons = {
                { Name = "Bee Swarm Simulator", URL = "https://raw.githubusercontent.com/scriptjame/BeeSwarmSimulator/refs/heads/main/loot.lua" },
            }},
            { Section = "Brookhaven RP", Buttons = {
                { Name = "Brookhaven RP", URL = "https://raw.githubusercontent.com/scriptjame/Brookhaven-RP/refs/heads/main/wsp.lua" },
            }},
            { Section = "Adopt Me", Buttons = {
                { Name = "Adopt Me", URL = "https://raw.githubusercontent.com/scriptjame/testadp/main/adpt.lua" },
            }},
            { Section = "Fish It", Buttons = {
                { Name = "Fish It", URL = "https://raw.githubusercontent.com/scriptjame/fishit/refs/heads/main/nice.lua" },
            }},
        }
    },
    {
        Name = "Story",
        Icon = "book-open",
        Games = {
            { Section = "Break In", Buttons = {
                { Name = "Break In 1", URL = "https://raw.githubusercontent.com/Iptxt/AXHub-Loader/refs/heads/main/Loader" },
                { Name = "Break In 2", URL = "https://raw.githubusercontent.com/EnesXVC/Breakin2/main/script" },
            }},
        }
    },
    {
        Name = "Brainrot",
        Icon = "brain",
        Games = {
            { Section = "Info", Paragraphs = {
                { Title = "Info", Content = "Sorry, I have no fucking idea what to name this internal tab. I just saw games like Steal A Brainrot, Steal An Egg, Escape Tatsunami For Brainrot, or Escape Keyboard, etc. All of them are cheap, mindless slop that isn't worth playing. Well, that's just my opinion, but if you don't like it, cope, who's scared of who?" },
            }},
            { Section = "Steal A Brainrot", Buttons = {
                { Name = "Steal A Brainrot", URL = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua" },
            }},
        }
    },
    {
        Name = "Misc",
        Icon = "package",
        Games = {
            { Section = "Fling Things And People", Buttons = {
                { Name = "Fling Things And People (key: BestScriptYK)", URL = "https://raw.githubusercontent.com/BloodyV2/BloodyScript/refs/heads/main/Free" },
            }},
            { Section = "Uma Racing", Buttons = {
                { Name = "Uma Racing", URL = "https://rawscripts.net/raw/UPDATE-1.0-Uma-Racing-Simple-And-Open-Source-63947" },
            }},
        }
    },
}

function GameHub.RunScript(url, raw)
    pcall(function()
        loadstring(game:HttpGet(url, raw))()
    end)
end

return GameHub