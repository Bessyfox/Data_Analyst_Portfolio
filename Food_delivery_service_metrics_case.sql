-- Расчёт метрик сервиса доставки еды
-- Сервису доставки еды «Всё.из.кафе» нужна срочная аналитическая помощь.
-- Вам необходимо разработать дашборд, который с разных сторон отразит состояние 
-- клиентской базы в городе Саранске. На основе этого дашборда необходимо составить аналитический отчёт.

-- Описание данных
-- Продукт, который вы будете анализировать в проекте, — сервис доставки еды «Всё.из.кафе». 
-- Данные продукта состоят из несколько таблиц:

-- analytics_events — журнал аналитических событий, или логи. Напомним, что логами называют записи, 
-- которые фиксируют действия пользователей в рамках работы сервиса. Сюда попадают данные о посещении 
-- пользователем страниц продукта и покупках.
-- advertisement_budgets — рекламные затраты по дням и каналам привлечения.
-- partners — справочник партнёрских сетей и их ресторанов.
-- dishes — справочник блюд.
-- cities — справочник городов.

-- Таблица analytics_events
-- В таблице хранятся данные о событиях в период с 30.04.2021 по 02.07.2021. Поля таблицы:
-- visitor_uuid — идентификатор посетителя. Это идентификатор, который система присваивает любому новому пользователю независимо от того, регистрировался ли он в продукте.
-- user_id — идентификатор зарегистрированного пользователя. Присваивается посетителю после создания учётной записи: ввода логина, пароля, адреса доставки и контактных данных.
-- device_type — тип платформы, с которой посетитель зашёл в продукт.
-- city_id — город, из которого посетитель зашёл в сервис.
-- age — возрастная группа пользователя. Она указывается при регистрации.
-- source — рекламный источник привлечения посетителя.
-- first_date — дата первого посещения продукта.
-- visit_id — уникальный идентификатор сессии.
-- event — название аналитического события.
-- datetime — дата и время события.
-- log_date — дата события.
-- rest_id — уникальный идентификатор сети, к которой принадлежит ресторан. Заполняется для заказов, карточек ресторанов и блюд.
-- object_id — уникальный идентификатор блюда. Заполняется для заказов и карточек блюд.
-- listing_id — уникальный идентификатор блюда в листинге. Листингом называется набор блюд, которые система рекомендует пользователю при просмотре страницы ресторана. Заполняется только для событий rest_page.
-- position — позиция блюда в листинге. Чем меньше номер, тем ближе блюдо к началу страницы. Заполняется только для событий rest_page.
-- order_id — уникальный идентификатор заказа.
-- revenue — выручка от заказа в рублях. Это та сумма, которую пользователь видит при оплате.
-- delivery — стоимость доставки в рублях.
-- commission — комиссия, которую «Всё.из.кафе» берёт с выручки ресторана.
-- В поле event таблицы также хранятся данные о нескольких типах аналитических событий:
-- main_page — посещение главной страницы приложения.
-- authorization — ввод логина и пароля, авторизация.
-- rest_page — просмотр страницы ресторана.
-- object_page — просмотр карточки блюда.
-- order — оплата заказа.

-- Таблица advertisement_budgets
-- В таблице хранятся данные о ежедневных затратах на рекламу. Поля таблицы:
-- source — рекламный источник.
-- date — дата рекламных затрат.
-- budget — дневной бюджет в рублях.

--Таблица partners
--Это справочник партнёрских сетей и их ресторанов. Поля таблицы:
--rest_id — уникальный идентификатор сети, к которой принадлежит ресторан (одна сеть может быть представлена в нескольких городах).
--chain — название сети, к которой принадлежит ресторан.
--type — тип кухни.
--city_id — город, в котором находится ресторан.
--commission — комиссия в процентах, которую «Всё.из.кафе» берёт с выручки ресторана.

-- Таблица dishes
-- Это справочник блюд, доступных в партнёрских ресторанах. Поля таблицы:
-- object_id — уникальный идентификатор блюда.
-- name — название блюда.
-- spicy — логический признак острых блюд. 1 — блюдо острое.
-- fish — логический признак рыбных блюд. 1 — блюдо содержит морепродукты.
-- meat — логический признак мясных блюд. 1 — блюдо содержит мясо.
-- rest_id — уникальный идентификатор ресторана, из которого можно заказать блюдо.

-- Таблица cities
-- Справочник населённых пунктов, в которых можно пользоваться продуктом. Поля таблицы:
-- city_id — уникальный идентификатор населённого пункта.
-- city_name — название населённого пункта.

-- Задача 1. Расчёт DAU
-- Рассчитайте ежедневное количество активных зарегистрированных клиентов (user_id) за май и июнь 2021 года в городе Саранске. 
-- Критерием активности клиента считайте размещение заказа. Это позволит оценить эффективность вовлечения клиентов 
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

-- Задача 2. Расчёт Conversion Rate
-- Теперь вам нужно определить активность аудитории: как часто зарегистрированные пользователи переходят к размещению заказа, 
-- будет ли одинаковым этот показатель по дням или видны сезонные колебания в поведении пользователей. 
-- Для решения этой задачи рассчитайте конверсию зарегистрированных пользователей, которые посещают приложение, 
-- в активных клиентов. Напомним, что критерий активности — размещение заказа. Конверсия должна быть рассчитана за каждый день 
-- в мае и июне 2021 года для клиентов из Саранска.

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

-- Задача 3. Расчёт среднего чека
-- Следующая метрика, за которой следят аналитики сервиса «Всё.из.кафе», — средний чек. В рамках этой задачи вам предстоит 
-- рассчитать средний чек активных клиентов в Саранске в мае и в июне.
-- Напомним: средний чек — это средний доход за одну транзакцию, то есть заказ. Учитывайте, что вы анализируете средний чек 
-- сервиса доставки, а не ресторанов. Значит, вам необходимо вычислить его как среднее значение комиссии со всех заказов за месяц. 
-- Таким образом, для корректного расчёта метрики вычислите общий размер комиссии и количество заказов. 
-- Разделив сумму комиссии на количество заказов, вы рассчитаете величину среднего чека за месяц.


WITH orders AS -- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
    (SELECT *,
            revenue * commission AS commission_revenue
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')
SELECT CAST(DATE_TRUNC('month', log_date) AS date) AS "Месяц",
       --COUNT(DISTINCT order_id) AS "Количество заказов",
       --ROUND(SUM(commission_revenue)::numeric, 2) AS "Сумма комиссии",
       ROUND(SUM(commission_revenue)::numeric / COUNT(DISTINCT order_id), 2) AS "Средний чек"
FROM orders
GROUP BY DATE_TRUNC ('month', log_date)
ORDER BY DATE_TRUNC ('month', log_date);

-- Месяц     |Средний чек|
-- ----------+-----------+
-- 2021-05-01|     135.88|
-- 2021-06-01|     147.66|

-- Задача 4. Расчёт LTV ресторанов
-- Определите три ресторана из Саранска с наибольшим LTV с начала мая до конца июня. Как правило, LTV рассчитывается 
-- для пользователя приложения. Однако клиентами для сервиса доставки будут и рестораны, как и пользователи, которые делают заказы.
-- В рамках этой задачи считайте LTV как суммарную комиссию, которая была получена от заказов в ресторане за эти два месяца.

-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
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

-- Задача 5. Расчёт LTV ресторанов — самые популярные блюда
-- Как вы видите, наибольший LTV с большим отрывом у двух ресторанов Саранска: «Гурманское Наслаждение» и «Гастрономический Шторм». 
-- Теперь вам нужно узнать, сколько LTV принесли пять самых популярных блюд этих ресторанов. При этом популярных блюд должно быть всего пять, 
-- а не по пять из каждого ресторана.
-- Вам необходимо проанализировать данные о ресторанах и их блюдах, чтобы определить вклад самых популярных блюд из двух 
-- ресторанов Саранска — «Гурманское Наслаждение» и «Гастрономический Шторм» — в общий показатель LTV. 
-- Для этого нужно выбрать пять блюд с максимальным LTV за весь рассматриваемый период, то есть за май — июнь, из этих двух ресторанов.
-- Для каждого блюда требуется вывести название ресторана, название блюда, признаки того, является ли блюдо острым, рыбным или мясным, 
-- а также значение LTV, округлённое до копеек.

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

-- Задача 6. Расчёт Retention Rate
-- В рамках этой задачи вам предстоит определить показатель возвращаемости: какой процент пользователей возвращается 
-- в приложение в течение первой недели после регистрации и в какие дни. Рассчитайте показатель Retention Rate 
-- в первую неделю для всех новых пользователей в Саранске.
-- Напомним, что в проекте вы анализируете данные за май и июнь, и для корректного расчёта недельного Retention Rate 
-- нужно, чтобы с момента первого посещения прошла хотя бы неделя. Поэтому для этой задачи ограничьте дату первого 
-- посещения продукта, выбрав промежуток с начала мая по 24 июня. Retention Rate считайте по любой активности пользователей, 
-- а не только по факту размещения заказа.
-- В данных могут встречаться дубликаты по полю user_id, поэтому для корректного расчёта используйте условие log_date >= first_date.

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
    WHERE log_date >= first_date)
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

-- Задача 7. Сравнение Retention Rate по месяцам
-- Используя эталонный код из предыдущей задачи, разделите пользователей на две когорты по месяцу первого посещения продукта. 
-- Так вы сможете сравнить Retention Rate этих когорт между собой.

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