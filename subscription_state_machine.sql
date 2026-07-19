WITH last_subscriptions AS (
    -- Шаг 1: Находим самую последнюю запись для каждого клиента.
    -- Это нужно, чтобы извлечь финальную дату окончания всей истории подписок (membership_end_date).
    -- Используем ROW_NUMBER(), чтобы отсортировать даты окончания по убыванию.
    SELECT 
        customer_id,
        membership_end_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY membership_end_date DESC
        ) AS rn
    FROM subscriptions
),

timeline_union AS (
    -- Шаг 2: Формируем единую временную шкалу.
    -- Объединяем все даты начала периодов из исходной таблицы и добавляем к ним 
    -- только одну финальную точку закрытия контракта.
    -- В этот момент статус пользователя меняется на 'Non-member'.
    SELECT 
        customer_id,
        membership_start_date AS change_date,
        membership_status
    FROM subscriptions
    
    UNION ALL
    
    SELECT 
        customer_id,
        membership_end_date AS change_date,
        'Non-member' AS membership_status
    FROM last_subscriptions
    WHERE rn = 1
),

transitions AS (
    -- Шаг 3: Сопоставляем текущий статус с предыдущим.
    -- Оконная функция LAG() позволяет "посмотреть" на статус из предыдущей строки хронологии.
    -- Для самого первого события, когда предыдущей строки нет, подставляем 'Non-member'.
    SELECT 
        customer_id,
        change_date,
        LAG(membership_status, 1, 'Non-member') OVER (
            PARTITION BY customer_id 
            ORDER BY change_date ASC
        ) AS pr_st,
        membership_status AS cur_st
    FROM timeline_union
),

classified_events AS (
    -- Шаг 4: Применяем бизнес-логику для классификации событий.
    -- Конструкция CASE WHEN сопоставляет пары переходов с целевыми названиями событий.
    SELECT 
        customer_id,
        change_date,
        CASE
            WHEN pr_st = 'Free' AND cur_st = 'Paid' THEN 'Convert'
            WHEN pr_st = 'Paid' AND cur_st = 'Free' THEN 'ReverseConvert'
            WHEN pr_st = 'Paid' AND cur_st = 'Non-member' THEN 'Cancel' 
            WHEN pr_st = 'Free' AND cur_st = 'Non-member' THEN 'Cancel'
            WHEN pr_st = 'Non-member' AND cur_st = 'Paid' THEN 'ColdStart'
            WHEN pr_st = 'Non-member' AND cur_st = 'Free' THEN 'WarmStart'
            WHEN pr_st = 'Paid' AND cur_st = 'Paid' THEN 'Renewal'
            WHEN pr_st = 'Free' AND cur_st = 'Free' THEN 'Renewal'
        END AS event
    FROM transitions
)

-- Шаг 5: Получаем итоговый результат.
-- Фильтруем строки, оставляя только значимые изменения статуса (где event IS NOT NULL).
-- Сортируем данные по требованиям ТЗ: сначала по клиенту, затем по дате изменения.
SELECT 
    customer_id,
    change_date,
    event
FROM classified_events
WHERE event IS NOT NULL
ORDER BY 
    customer_id ASC,
    change_date ASC;