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
Cfg.VersionCheck = true -- Intermittent version checking (boolean) — server-only, not sent to clients
Cfg.Debug = false       -- Debug prints, not recommended for live servers (boolean)

Cfg.EnableTeleport = true -- Enable or disable the teleporter system
Cfg.TeleportEnter = {
    target = vec3(-219.93, -1285.36, 31.78),        -- Outside entrance target (knock to enter)
    coords = vec4(-220.32, -1285.77, 31.29, 127.02) -- Outside spawn when exiting the wash
}
Cfg.TeleportExit = {
    target = vec3(1138.14, -3199.45, -39.43),      -- Interior exit target
    coords = vec4(1138.09, -3199.05, -39.66, 6.32) -- Interior spawn when entering the wash
}

Cfg.Blip = {
    enabled = true, -- Enable or disable the blip
    sprite = 500,   -- Blip sprite (https://docs.fivem.net/docs/game-references/blips/)
    color = 1,      -- Blip color (https://docs.fivem.net/docs/game-references/blips/#blip-colors)
    scale = 0.8,    -- Blip scale (0.0 to 1.0+)
}

Cfg.Ped = {
    coords = vec4(1116.79, -3195.49, -41.40, 265.89), -- The coordinates of the ped
    model = 'a_m_m_og_boss_01',                       -- The model of the ped
}

-- CurrencyType: 'account' (framework balance) or 'item' (inventory item).
-- For QB marked bills, set Currency = 'markedbills' (MinAmount/MaxAmount do not apply to bill worth).
Cfg.CurrencyType = 'account'
Cfg.Currency = 'black_money'

Cfg.MinAmount = 100                      -- Minimum wash amount (account/item; ignored for markedbills)
Cfg.MaxAmount = 10000                    -- Maximum wash amount (account/item; ignored for markedbills)
Cfg.WashTax = 25                         -- Starting tax percentage for the wash
Cfg.DynamicTax = true                    -- Randomly adjust tax on a timer (not based on wash volume)
Cfg.PercentChange = { min = 2, max = 8 } -- Percent the tax rate may move each change
Cfg.TaxLimits = { min = 10, max = 50 }   -- Minimum and maximum tax percentage
Cfg.ChangeTimer = 60                     -- Minutes between dynamic tax changes
Cfg.WashTimer = 10                       -- Seconds the wash progress takes on the client
Cfg.WashCooldown = 30                    -- Minutes a player must wait between washes

-------------------------------------------
-- Configure logging in server/_util.lua --
-------------------------------------------
