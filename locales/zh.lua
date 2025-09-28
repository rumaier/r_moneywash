Language = Language or {}
Language['zh'] = { -- Simplified Chinese

    -- Notifications
    notify_title = '洗钱',
    insufficient_funds = '你没有足够的钱进行洗钱。',
    on_cooldown = '洗钱后你必须等待%s分钟才能再次洗钱。',
    wash_successful = '你已成功洗钱 $%s。',
    
    -- Target Options
    wash_money = '洗钱',
    teleporter_enter = '进入洗钱点',
    teleporter_exit = '离开洗钱点',
    
    -- UI Elements
    wash_amount = '洗钱金额',
    marked_worth = '价值: $%s',
    taxed_offer = '扣除%s%%税后你将获得$%s。',
    counting_money = '正在清点钱...',
    entering = '正在进入洗钱点...',
    exiting = '正在离开洗钱点...',
    
    -- Webhook
    player_id = '玩家ID',
    username = '用户名',
    money_washed = '洗钱金额',
    money_given = '给予金额',
    money_received = '收到金额',
    tax_rate = '税率',
    
    -- Console
    resource_version = '%s | v%s',
    bridge_detected = '^2桥接已检测并加载。^0',
    bridge_not_detected = '^1未检测到桥接，请确保它正在运行。^0',
    cheater_print = '你试图智取系统。系统反过来智取了你。',
    debug_enabled = '^1调试模式已开启！请勿在生产环境运行！^0',
}