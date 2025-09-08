--                                                           _
--  _ __  _ __ ___   ___  _ __   ___ _   ___      ____ _ ___| |__
-- | '__|| '_ ` _ \ / _ \| '_ \ / _ \ | | \ \ /\ / / _` / __| '_ \
-- | |   | | | | | | (_) | | | |  __/ |_| |\ V  V / (_| \__ \ | | |
-- |_|___|_| |_| |_|\___/|_| |_|\___|\__, | \_/\_/ \__,_|___/_| |_|
--  |_____|                          |___/
--  Need support? Join our Discord server for help: https://discord.gg/rscripts
--
Cfg = {
    --  ___  ___ _ ____   _____ _ __
    -- / __|/ _ \ '__\ \ / / _ \ '__|
    -- \__ \  __/ |   \ V /  __/ |
    -- |___/\___|_|    \_/ \___|_|
    Server = {
        Language = 'en',     -- Resource language ('en': English, 'es': Spanish, 'fr': French, 'de': German, 'pt': Portuguese, 'zh': Chinese)
        VersionCheck = true, -- Version check (true: enabled, false: disabled)
    },
    --              _   _
    --   ___  _ __ | |_(_) ___  _ __  ___
    --  / _ \| '_ \| __| |/ _ \| '_ \/ __|
    -- | (_) | |_) | |_| | (_) | | | \__ \
    --  \___/| .__/ \__|_|\___/|_| |_|___/
    --       |_|
    Options = {

        Teleporter = {
            enabled = true,                                 -- Enable teleporter (true: enabled, false: disabled)
            enter = vec4(-220.27, -1285.82, 31.29, 315.84), -- Teleporter entrance (vec4)
            exit = vec4(1138.07, -3199.18, -39.66, 180.42), -- Teleporter exit (vec4)
        },

        Blip = {
            enabled = true,
            sprite = 500,         -- Blip sprite (https://docs.fivem.net/docs/game-references/blips/)
            color = 1,            -- Blip color (https://docs.fivem.net/docs/game-references/blips/#blip-colors)
            scale = 0.8,          -- Blip scale
            label = 'Money Wash', -- Blip label
        },

        WashPed = {
            location = vec4(1116.79, -3195.49, -41.40, 265.89), -- Ped location (vec4)
            model = 'a_m_m_og_boss_01',                         -- Ped model (https://docs.fivem.net/docs/game-references/ped-models/)
        },

        MoneyWash = {
            currency = 'black_money',   -- Currency type (supports items or qb-core 'markedbills')
            min = 100,                  -- Minimum amount of money that can be washed, does not apply when currency = 'markedbills'
            max = 10000,                -- Maximum amount of money that can be washed, does not apply when currency = 'markedbills'
            tax = 20,                   -- Tax percentage (0-100)
            dynamicTax = true,         -- Dynamic tax based on amount washed (true: enabled, false: disabled)
            taxChangeTimer = 60,        -- Time in minutes for tax to change when dynamicTax is enabled
            taxChangeRange = { 5, 10 }, -- Range for tax change when dynamicTax is enabled (min, max)
            timer = 10,                 -- Time in seconds to wash money
            cooldown = 30,              -- Cooldown time in minutes between washes
        },

        WebhookEnabled = true, -- Enable webhook logging (true: enabled, false: disabled)
        -- Webhook URL can be set in core/server/webhook.lua
    },
    --      _      _
    --   __| | ___| |__  _   _  __ _
    --  / _` |/ _ \ '_ \| | | |/ _` |
    -- | (_| |  __/ |_) | |_| | (_| |
    --  \__,_|\___|_.__/ \__,_|\__, |
    --                         |___/
    Debug = true -- Enable debug prints (true: enabled, false: disabled)
}
