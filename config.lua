--                                                           _
--  _ __  _ __ ___   ___  _ __   ___ _   ___      ____ _ ___| |__
-- | '__|| '_ ` _ \ / _ \| '_ \ / _ \ | | \ \ /\ / / _` / __| '_ \
-- | |   | | | | | | (_) | | | |  __/ |_| |\ V  V / (_| \__ \ | | |
-- |_|___|_| |_| |_|\___/|_| |_|\___|\__, | \_/\_/ \__,_|___/_| |_|
--  |_____|                          |___/
--
--  Need support? Join our Discord server for help: https://discord.gg/r-scripts
--
Cfg = {
    --  ___  ___ _ ____   _____ _ __
    -- / __|/ _ \ '__\ \ / / _ \ '__|
    -- \__ \  __/ |   \ V /  __/ |
    -- |___/\___|_|    \_/ \___|_|
    Server = {
        Language = 'en',          -- Resource language ('en': English, 'es': Spanish, 'fr': French, 'de': German, 'pt': Portuguese, 'zh': Chinese)
        Notification = 'default', -- Notification resource ('default', 'ox', 'custom': can be customized in bridge/framework/YOURFRAMEWORK)
        VersionCheck = true,      -- Version check (true: enabled, false: disabled)
    },
    --              _   _
    --   ___  _ __ | |_(_) ___  _ __  ___
    --  / _ \| '_ \| __| |/ _ \| '_ \/ __|
    -- | (_) | |_) | |_| | (_) | | | \__ \
    --  \___/| .__/ \__|_|\___/|_| |_|___/
    --       |_|
    Options = {
        Blip = {
            Enabled = true,                         -- Blip visibility (true: enabled, false: disabled)
            Sprite = 500,                           -- Blip sprite (https://docs.fivem.net/docs/game-references/blips/)
            Scale = 0.8,                            -- Blip scale (0.0 - 1.0)
            Color = 1,                              -- Blip color
            Label = 'Money Wash',                   -- Blip label
        },
        Location = vec3(1116.79, -3195.49, -41.40), -- Money wash location. (vector4)
        PedModel = 'a_m_m_og_boss_01',              -- Ped model (https://docs.fivem.net/docs/game-references/ped-models/)
        PedHeading = 265.89,                        -- Ped heading (0.0 - 360.0)

        Currency = 'black_money',                   -- Currency item (supports items or qb-core 'markedbills')
        TaxRate = 25,                               -- Tax rate. (0 - 100) if DynamicTax is enabled, this value will be ignored.
        DynacmicTax = true,                         -- Changing tax rate (true: enabled, false: disabled)
        DynamicTimer = 60,                          -- Tax rate change timer (minutes)
        DynamicRange = { 15, 35 },                  -- Range for changing tax rate { min, max }
        WashTime = 10,                              -- Wash time (seconds)
        MinWash = 100,                              -- Minimum amount of money that can be washed, does not apply when Currency = 'markedbills'
        MaxWash = 10000,                            -- Maximum amount of money that can be washed, does not apply when Currency = 'markedbills'
        Cooldown = 30,                              -- Player cooldown time (minutes, false: disabled)

        Teleporter = {
            Enabled = true,                                       -- Teleporter (true: enabled, false: disabled)
            Entrance = vec4(-220.27, -1285.82, 31.29, 315.84),    -- Teleporter entrance (vector4)
            Exit = vec4(1138.0793, -3199.1890, -39.6656, 180.42), -- Teleporter exit (vector4)
        },
    },
    --               _     _                 _
    -- __      _____| |__ | |__   ___   ___ | | __
    -- \ \ /\ / / _ \ '_ \| '_ \ / _ \ / _ \| |/ /
    --  \ V  V /  __/ |_) | | | | (_) | (_) |   <
    --   \_/\_/ \___|_.__/|_| |_|\___/ \___/|_|\_\
    Webhook = {
        Enabled = true,            -- Webhook Logs (true: enabled, false: disabled)
        Url = 'YOUR_WEBHOOK_HERE', -- Webhook URL
    },
    --      _      _
    --   __| | ___| |__  _   _  __ _
    --  / _` |/ _ \ '_ \| | | |/ _` |
    -- | (_| |  __/ |_) | |_| | (_| |
    --  \__,_|\___|_.__/ \__,_|\__, |
    --                         |___/
    Debug = {
        Prints = true,  -- Debug prints (true: enabled, false: disabled)
        Targets = true, -- Debug targets (true: enabled, false: disabled)
    }
}
