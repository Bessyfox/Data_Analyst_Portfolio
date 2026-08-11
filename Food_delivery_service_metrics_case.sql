-- Расчёт метрик сервиса доставки еды в Саранске

-- Цель - создание системы метрик для оценки эффективности сервиса

-- Задачи:
-- 1. Рассчитать ключевые бизнес-метрики сервиса с помощью SQL (в этом файле)
-- 2. Создать интерактивную BI-визуализацию в Yandex Datalens, которая с разных сторон отразит состояние 
-- клиентской базы
-- 3. Подготовить аналитический отчёт

-- Данные продукта состоят из пяти таблиц:

-- 1. analytics_events — журнал аналитических событий
-- 2. advertisement_budgets - данные о ежедневных затратах на рекламу
-- 3. partners - справочник партнёрских сетей и их ресторанов
-- 4. dishes - справочник блюд, доступных в партнёрских ресторанах
-- 5. cities - справочник населённых пунктов, в которых можно пользоваться продуктом

-- Выполнение:

-- 1. Расчёт DAU
-- Рассчитаем ежедневное количество активных зарегистрированных клиентов за май и июнь 2021 года. 
-- Критерием активности клиента будем считать размещение заказа. Это позволит оценить эффективность вовлечения клиентов 
-- в ключевую бизнес-цель — совершение покупки.

SELECT log_date,
       COUNT (DISTINCT user_id) AS DAU
FROM rest_analytics.analytics_events
JOIN rest_analytics.cities USING (city_id)
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
      AND city_name = 'Саранск'
      AND order_id IS NOT NULL
      GROUP BY log_date
ORDER BY log_date
LIMIT 10;

-- log_date  |dau|
-- ----------+---+
-- 2021-05-01| 56|
-- 2021-05-02| 36|
-- 2021-05-03| 72|
-- 2021-05-04| 85|
-- 2021-05-05| 60|
-- 2021-05-06| 52|
-- 2021-05-07| 52|
-- 2021-05-08| 52|
-- 2021-05-09| 33|
-- 2021-05-10| 35|

-- 2. Расчёт Conversion Rate
-- Теперь определим активность аудитории: как часто зарегистрированные пользователи переходят к размещению заказа, 
-- будет ли одинаковым этот показатель по дням или видны сезонные колебания в поведении пользователей. 
-- Для этого рассчитаем конверсию зарегистрированных пользователей, которые посещают приложение, 
-- в активных клиентов.

SELECT log_date,
       ROUND (COUNT (DISTINCT user_id) FILTER (WHERE order_id IS NOT NULL) :: numeric / COUNT (DISTINCT user_id ), 2) AS CR
FROM rest_analytics.analytics_events
JOIN rest_analytics.cities USING (city_id)
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
      AND city_name = 'Саранск'
GROUP BY log_date
ORDER BY log_date
LIMIT 10;

-- log_date  |cr  |
-- ----------+----+
-- 2021-05-01|0.43|
-- 2021-05-02|0.28|
-- 2021-05-03|0.41|
-- 2021-05-04|0.41|
-- 2021-05-05|0.32|
-- 2021-05-06|0.25|
-- 2021-05-07|0.28|
-- 2021-05-08|0.33|
-- 2021-05-09|0.28|
-- 2021-05-10|0.30|

-- 3. Расчёт среднего чека
-- Рассчитаем средний чек активных клиентов в Саранске в мае и в июне.

WITH orders AS -- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
    (SELECT *,
            revenue * commission AS commission_revenue
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')
SELECT CAST(DATE_TRUNC('month', log_date) AS date) AS "Месяц",
       ROUND(SUM(commission_revenue)::numeric / COUNT(DISTINCT order_id), 2) AS "Средний чек"
FROM orders
GROUP BY DATE_TRUNC ('month', log_date)
ORDER BY DATE_TRUNC ('month', log_date);

-- Месяц     |Средний чек|
-- ----------+-----------+
-- 2021-05-01|     135.88|
-- 2021-06-01|     147.66|

-- 4. Расчёт LTV ресторанов
-- Определим три ресторана из Саранска с наибольшим LTV с начала мая до конца июня. 
-- Клиентами для сервиса доставки являются и рестораны, и пользователи, которые делают заказы.
-- Считаем LTV как суммарную комиссию, которая была получена от заказов в ресторане за эти два месяца.

WITH orders AS -- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
    (SELECT analytics_events.rest_id,
            analytics_events.city_id,
            revenue * commission AS commission_revenue
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')
SELECT rest_id,
       chain AS "Название сети",
       type AS "Тип кухни",
       ROUND (SUM (commission_revenue) :: numeric, 2) AS LTV
FROM orders
JOIN rest_analytics.partners USING (rest_id, city_id)
GROUP BY rest_id, chain, type
ORDER BY LTV DESC
LIMIT 3;

-- rest_id                         |Название сети         |Тип кухни   |ltv      |
-- --------------------------------+----------------------+------------+---------+
-- 2e2b2b9c458b42ce9da395ba9c247fdc|Гурманское Наслаждение|Ресторан    |170479.19|
-- b94505e7efff41d2b2bf6bbb78fe71f2|Гастрономический Шторм|Ресторан    |164508.16|
-- 42d14fe9fd254ba9b18ab4acd64d4f33|Шоколадный Рай        |Кондитерская| 61199.76|

-- 5. Самые популярные блюда
-- Рассчитаем, сколько LTV принесли пять самых популярных блюд двух ресторанов с наибольшим LTV. 

WITH orders AS (
    SELECT analytics_events.rest_id,
            analytics_events.city_id,
            analytics_events.object_id,
            revenue * commission AS commission_revenue
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'
), 
top_ltv_restaurants AS -- Рассчитываем два ресторана с наибольшим LTV 
    (SELECT orders.rest_id,
            chain,
            type,
            ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
     FROM orders
     JOIN rest_analytics.partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id
     GROUP BY 1, 2, 3
     ORDER BY LTV DESC
     LIMIT 2
),
top_objects AS (
    SELECT object_id,
           ROUND(SUM(commission_revenue)::numeric, 2) AS LTV_objects
    FROM orders
    WHERE rest_id IN (SELECT rest_id FROM top_ltv_restaurants)
    GROUP BY object_id
    ORDER BY LTV_objects DESC
    LIMIT 5
)
SELECT chain AS "Название сети",
       name AS "Название блюда",
       spicy,
       fish,
       meat,
       ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
FROM orders
JOIN rest_analytics.dishes USING (object_id, rest_id)
JOIN rest_analytics.partners USING (rest_id, city_id)
WHERE object_id IN (SELECT object_id FROM top_objects)
GROUP BY chain, name, spicy, fish, meat
ORDER BY LTV DESC;

-- Название сети         |Название блюда                                      |spicy|fish|meat|ltv     |
-- ----------------------+----------------------------------------------------+-----+----+----+--------+
-- Гастрономический Шторм|brokkoli zapechennaja v duhovke s jajcami i travami |    0|   1|   1|41140.43|
-- Гурманское Наслаждение|govjazhi shashliki v pesto iz kinzi                 |    0|   1|   1|36676.77|
-- Гурманское Наслаждение|medaloni iz lososja                                 |    0|   1|   1|14946.87|
-- Гурманское Наслаждение|myasnye ezhiki                                      |    0|   0|   1|14337.89|
-- Гастрономический Шторм|teljatina s sousom iz belogo vina petrushki         |    0|   1|   1|13980.96|

-- 6. Расчёт Retention Rate
-- Рассчитаем показатель Retention Rate в первую неделю для всех новых пользователей в Саранске.
-- Для корректного расчёта недельного Retention Rate нужно, чтобы с момента первого посещения прошла хотя бы неделя, поэтому 
-- ограничим дату первого посещения продукта, выбрав промежуток с начала мая по 24 июня. 
-- Retention Rate будем считать по любой активности пользователей, а не только по факту размещения заказа.

WITH new_users AS
    (SELECT DISTINCT first_date,
            user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),
daily_retention AS (
    SELECT n.user_id,
           first_date,
           log_date::date - first_date::date AS day_since_install
    FROM new_users n
    JOIN active_users a
    on n.user_id = a.user_id
    WHERE log_date >= first_date) -- чтобы исключить дубликаты по полю user_id
SELECT day_since_install,
       COUNT(DISTINCT user_id) AS retained_users,
       ROUND (1.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (ORDER by day_since_install), 2) AS retention_rate
FROM daily_retention
WHERE day_since_install < 8
GROUP BY day_since_install
ORDER BY day_since_install;

-- day_since_install|retained_users|retention_rate|
-- -----------------+--------------+--------------+
--                 0|          5572|          1.00|
--                 1|           768|          0.14|
--                 2|           419|          0.08|
--                 3|           283|          0.05|
--                 4|           251|          0.05|
--                 5|           207|          0.04|
--                 6|           205|          0.04|
--                 7|           205|          0.04|

-- 7. Сравнение Retention Rate по месяцам
-- Разделим пользователей на две когорты по месяцу первого посещения продукта и сравним Retention Rate этих когорт между собой.

WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),
daily_retention AS
    (SELECT new_users.user_id,
            first_date,
            log_date::date - first_date::date AS day_since_install
     FROM new_users
     JOIN active_users ON new_users.user_id = active_users.user_id
     AND log_date >= first_date
)
SELECT DISTINCT CAST(DATE_TRUNC('month', first_date) AS date) AS "Месяц",
        day_since_install,
        COUNT(DISTINCT user_id) AS retained_users,
        ROUND((1.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (PARTITION BY CAST(DATE_TRUNC('month', first_date) AS date) ORDER BY day_since_install))::numeric, 2) AS retention_rate
FROM daily_retention
WHERE day_since_install < 8
GROUP BY "Месяц", day_since_install
ORDER BY "Месяц", day_since_install;

-- Месяц     |day_since_install|retained_users|retention_rate|
-- ----------+-----------------+--------------+--------------+
-- 2021-05-01|                0|          3069|          1.00|
-- 2021-05-01|                1|           443|          0.14|
-- 2021-05-01|                2|           223|          0.07|
-- 2021-05-01|                3|           144|          0.05|
-- 2021-05-01|                4|           142|          0.05|
-- 2021-05-01|                5|           122|          0.04|
-- 2021-05-01|                6|           120|          0.04|
-- 2021-05-01|                7|           140|          0.05|
-- 2021-06-01|                0|          2576|          1.00|
-- 2021-06-01|                1|           328|          0.13|
-- 2021-06-01|                2|           196|          0.08|
-- 2021-06-01|                3|           140|          0.05|
-- 2021-06-01|                4|           109|          0.04|
-- 2021-06-01|                5|            86|          0.03|
-- 2021-06-01|                6|            85|          0.03|
-- 2021-06-01|                7|            65|          0.03|