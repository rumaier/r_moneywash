Language = Language or {}
Language['fr'] = { -- French

    -- Notifications
    notify_title = 'Blanchiment d’argent',
    insufficient_funds = 'Vous n’avez pas assez d’argent à blanchir.',
    on_cooldown = 'Vous devez attendre %s minutes après avoir blanchi avant de pouvoir recommencer.',
    wash_successful = 'Vous avez blanchi des fonds d’une valeur de $%s.',
    
    -- Target Options
    wash_money = 'Blanchir de l’argent',
    teleporter_enter = 'Entrer dans le blanchiment d’argent',
    teleporter_exit = 'Sortir du blanchiment d’argent',
    
    -- UI Elements
    wash_amount = 'Montant à blanchir',
    marked_worth = 'Valeur : $%s',
    taxed_offer = 'Vous recevrez $%s après une taxe de %s%%.',
    counting_money = 'Comptage de l’argent...',
    entering = 'Entrée dans le blanchiment d’argent...',
    exiting = 'Sortie du blanchiment d’argent...',
    
    -- Webhook
    player_id = 'ID Joueur',
    username = "Nom d'utilisateur",
    money_washed = 'Argent blanchi',
    money_given = 'Argent donné',
    money_received = 'Argent reçu',
    tax_rate = 'Taux d’imposition',
    
    -- Console
    resource_version = '%s | v%s',
    bridge_detected = '^2Pont détecté et chargé.^0',
    bridge_not_detected = '^1Pont non détecté, veuillez vous assurer qu’il est en cours d’exécution.^0',
    cheater_print = 'Vous avez essayé de déjouer le système. Le système vous a déjoué.',
    debug_enabled = '^1Le mode debug est ACTIVÉ ! Ne pas utiliser en production !^0',
}