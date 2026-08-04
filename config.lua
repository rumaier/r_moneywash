--                                                           _
--  _ __  _ __ ___   ___  _ __   ___ _   ___      ____ _ ___| |__
-- | '__|| '_ ` _ \ / _ \| '_ \ / _ \ | | \ \ /\ / / _` / __| '_ \
-- | |   | | | | | | (_) | | | |  __/ |_| |\ V  V / (_| \__ \ | | |
-- |_|___|_| |_| |_|\___/|_| |_|\___|\__, | \_/\_/ \__,_|___/_| |_|
--  |_____|                          |___/
--
--  Need support? Join our Discord server for help: https://discord.gg/TR38cZFdQk
--
Cfg = {}

Cfg.Language = 'en'     -- Languages: 'en': English, 'es': Spanish, 'fr': French, 'de': German, 'pt': Portuguese, 'zh': Chinese
Cfg.NuiColor = 'violet' -- Colors: 'dark', 'gray', 'red', 'pink', 'grape', 'violet', 'indigo', 'blue', 'cyan', 'teal', 'green', 'lime', 'yellow', 'orange'
Cfg.VersionCheck = true -- Intermittent version checking (boolean) — server-only, not sent to clients
Cfg.Debug = true        -- Debug prints, not recommended for live servers (boolean)

Cfg.EnableTeleport = true                           -- Enable or disable the teleporter system
Cfg.TeleportEnter = {
    target = vec3(-219.93, -1285.36, 31.78),        -- The position of the entrance target
    coords = vec4(-220.32, -1285.77, 31.29, 127.02) -- The coordinates the player is sent to when exiting
}
Cfg.TeleportExit = {
    target = vec3(1138.14, -3199.45, -39.43),      -- The position of the exit target
    coords = vec4(1138.09, -3199.05, -39.66, 6.32) -- The coordinates the player is sent to when entering
}

Cfg.Blip = {
    enable = true, -- Enable or disable the blip
    sprite = 500,  -- TBlip sprite (https://docs.fivem.net/docs/game-references/blips/)
    color = 1,     -- Blip color (https://docs.fivem.net/docs/game-references/blips/#blip-colors)
    scale = 0.8,   -- Blip scale (0.0 to 1.0+)
}

Cfg.Ped = {
    coords = vec4(1116.79, -3195.49, -41.40, 265.89), -- The coordinates of the ped
    model = 'a_m_m_og_boss_01',                       -- The model of the ped
}

Cfg.CurrencyType = 'account' -- The type of currency to use ('item' or 'account')
Cfg.Currency = 'black_money' -- The name of the currency to use

Cfg.MinAmount = 100                      -- The minimum amount of money a player needs to wash
Cfg.MaxAmount = 10000                    -- The maximum amount of money a player can wash
Cfg.WashTax = 25                         -- The tax percentage for the wash
Cfg.DynamicTax = true                    -- Whether to use a dynamic tax based on the amount of money being washed
Cfg.PercentChange = { min = 2, max = 8 } -- The percentage change for the dynamic tax
Cfg.TaxLimits = { min = 10, max = 50 }   -- The minimum and maximum tax percentage
Cfg.ChangeTimer = 60                     -- The time in minutes between tax rate changes
Cfg.WashTimer = 10                       -- The time in seconds it takes to wash the money
Cfg.WashCooldown = 30                    -- The time in minutes a player must wait between washes

-------------------------------------------
-- Configure logging in server/_util.lua --
-------------------------------------------
