-- Проект. Обзор бизнес-показателей маркетплейса

-- Автор: Наталья Мартынова
-- Дата: май 2026 г.

-- В данном файле выполнен первичный анализ и сбор данных.

-- Цель - изучить структуру данных и привести их в удобный для анализа вид.

-- Особенности:
-- Данные хранятся в шести таблицах: пользователи (Users), события (Events), заказы (Orders), кампании (Campaigns) и справочник товаров (Product_dict).
-- Некоторые поля имеют формат JSON. 
-- Нужно правильно выстроить связи между таблицами .

-- Выполнение:

-- 1. Сбор данных о пользователях
-- Отберём данные о клиентах маркетплейса, которые зарегистрировались в 2024 году. 
-- JSON-значения представим в виде отдельных столбцов для необходимых параметров.
-- Определим неделю привлечения (cohort_week) и месяц привлечения (cohort_month).

SELECT
    user_id,
    registration_date,
    user_params->>'age' AS age,
    user_params->>'gender' AS gender,
    user_params->>'region' AS region,
    user_params->>'acq_channel' AS acq_channel,
    user_params->>'buyer_segment' AS buyer_segment,
    DATE_TRUNC('week', registration_date)::date AS cohort_week,
    DATE_TRUNC('month', registration_date)::date AS cohort_month
FROM pa_graduate.Users
WHERE registration_date >= '2024-01-01'
  AND registration_date < '2025-01-01'
ORDER BY registration_date ASC
LIMIT 100;

-- 2. Сбор данных о событиях
-- Соберём набор данных о событиях, которые произошли в 2024 году. 

SELECT event_id,
       user_id,
       timestamp AS event_date,
       event_type,
       event_params->>'os' AS os,
       event_params->>'device' AS device,
       product_name,
       DATE_TRUNC('week', timestamp)::date AS event_week,
       DATE_TRUNC('month', timestamp)::date AS event_month
FROM pa_graduate.Events as pe 
LEFT JOIN pa_graduate.Product_dict as pp USING (product_id)
WHERE timestamp >= '2024-01-01'
  AND timestamp < '2025-01-01'
ORDER BY event_date
LIMIT 100;

-- 3. Сбор данных о заказах
-- Соберём набор данных о заказах, которые были сделаны в 2024 году. 

SELECT order_id,
       user_id,
       order_date,
       product_name,
       quantity,
       unit_price,
       total_price,
       category_name,
       DATE_TRUNC('week', order_date)::date AS order_week,
       DATE_TRUNC('month', order_date)::date AS order_month
FROM  pa_graduate.Orders as po
LEFT JOIN pa_graduate.Product_dict as pp USING (product_id)
WHERE order_date >= '2024-01-01'
  AND order_date < '2025-01-01'
ORDER BY order_date
LIMIT 100;

