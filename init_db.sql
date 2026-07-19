-- Создание структуры таблицы subscriptions
CREATE TABLE subscriptions (
    customer_id VARCHAR,
    membership_start_date DATE,
    membership_end_date DATE,
    membership_status VARCHAR
);

-- Наполнение демонстрационными данными
INSERT INTO subscriptions (customer_id, membership_start_date, membership_end_date, membership_status) 
VALUES
    -- Клиент с id 115: Базовый сценарий (Free -> Paid -> Non-member пауза -> Paid)
    ('115', '2020-01-01', '2020-02-15', 'Free'),
    ('115', '2020-02-15', '2020-03-15', 'Paid'),
    ('115', '2020-03-15', '2020-04-01', 'Non-member'),
    ('115', '2020-04-01', '2020-10-01', 'Paid'),

    -- Клиент с id 116: Короткий цикл (Free -> Paid -> Окончательный Churn)
    ('116', '2020-05-01', '2020-06-01', 'Free'),
    ('116', '2020-06-01', '2020-09-01', 'Paid'),

    -- Клиент с id 117: Прямой платный старт и продление (Paid -> Paid -> Churn)
    ('117', '2020-01-15', '2020-02-15', 'Paid'),
    ('117', '2020-02-15', '2020-03-15', 'Paid'),

    -- Клиент с id 118: Бесплатное продление с паузой и платным возвратом (Free -> Free -> Non-member -> Paid)
    ('118', '2020-02-01', '2020-03-01', 'Free'),
    ('118', '2020-03-01', '2020-04-01', 'Free'),
    ('118', '2020-04-01', '2020-06-01', 'Non-member'),
    ('118', '2020-06-01', '2021-01-01', 'Paid');
