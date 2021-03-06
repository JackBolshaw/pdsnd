## Q1. Which of the family friendly categories is rented the most?

WITH table1 AS

(
SELECT f.title film_title, f.film_id film_id, c.name category
FROM   film f
JOIN   film_category fc
ON     fc.film_id = f.film_id
JOIN   category c
ON     fc.category_id = c.category_id
ORDER BY 2
),

table2 AS
(
SELECT i.film_id, COUNT(*) count
FROM   rental r
JOIN   inventory i
ON     r.inventory_id = i.inventory_id
GROUP BY 1
ORDER BY 2,1
),

table3 AS
(
SELECT table1.film_title film_title,
       table1.category category,
       COALESCE (table2.count, 0) rental_count
FROM   table1
FULL JOIN   table2
ON     table1.film_id = table2.film_id
WHERE  table1.category = 'Classics' OR
       table1.category = 'Animation' OR
       table1.category = 'Children' OR
       table1.category = 'Comedy' OR
       table1.category = 'Family' OR
       table1.category = 'Music'
ORDER BY 2,1
)

SELECT table3.category category,
       COUNT(table3.category) film_count,
       SUM(table3.rental_count) total_amt_rentals,
       SUM(table3.rental_count) / COUNT(table3.category) avg_rental_amt_per_category
FROM   table3
GROUP BY 1
ORDER BY 4 DESC
;

*/ Q2. levels based on the quartiles (25%, 50%, 75%) of the rental duration for movies
across all categories? And compare this with the spread of each of the family
friendly categories. */

(SELECT f.title film_title,
        c.name category,
        f.rental_duration rental_duration,
        NTILE(4) OVER (ORDER BY rental_duration) standard_quartile
FROM   film f
JOIN   film_category fc
ON     f.film_id = fc.film_id
JOIN   category c
ON     fc.category_id = c.category_id
WHERE  c.name = 'Classics' OR
        c.name = 'Animation' OR
        c.name = 'Children' OR
        c.name = 'Comedy' OR
        c.name = 'Family' OR
        c.name = 'Music'
ORDER BY 4,3)

UNION ALL

(SELECT f.title film_title,
       COALESCE ('all_movies','all_movies') category,
       f.rental_duration rental_duration,
       NTILE(4) OVER (ORDER BY rental_duration) standard_quartile
FROM   film f
JOIN   film_category fc
ON     f.film_id = fc.film_id
JOIN   category c
ON     fc.category_id = c.category_id
ORDER BY 4,3)

ORDER BY 2,3;

## Q3. Provide a table with the family-friendly film category,
each of the quartiles, and the corresponding count of movies within each
combination of film category for each corresponding rental duration category.

WITH table1 AS
(
SELECT f.title film_title,
       c.name category,
       f.rental_duration rental_duration,
       NTILE(4) OVER (ORDER BY rental_duration) standard_quartile
FROM   film f
JOIN   film_category fc
ON     f.film_id = fc.film_id
JOIN   category c
ON     fc.category_id = c.category_id
WHERE  c.name = 'Classics' OR
       c.name = 'Animation' OR
       c.name = 'Children' OR
       c.name = 'Comedy' OR
       c.name = 'Family' OR
       c.name = 'Music'
ORDER BY 4,3
)

SELECT table1.category category,
       table1.standard_quartile quartile,
       COUNT (table1.standard_quartile)
FROM   table1
GROUP BY 1,2
ORDER BY 1,2;

## Q4. Out of the 5 categories in the family friend movies group, which should
the Sakila DVD Rental invest in?

Note to marker: Tables 1-2 calculate the average income per movies
                Tables 3-6 calculate the average return rate
                Tables 7-8 calculate the average replacement cost

I also queried whether I should include a factor of rental duration into my final
solution but after deliberation I decided that this has already been accounted for
in the average income per movie table by using the totality of the companies data.

WITH table1 AS
(
SELECT c.name category, f.title film, COALESCE (SUM(p.amount),0) total_revenue_to_date
FROM   category c
JOIN   film_category fc
ON     fc.category_id = c.category_id
JOIN   film f
ON     f.film_id = fc.film_id
FULL JOIN   inventory i
ON     i.film_id = f.film_id
FULL JOIN   rental r
ON     r.inventory_id = i.inventory_id
FULL JOIN   payment p
ON     p.rental_id = r.rental_id
GROUP BY 1,2
ORDER BY 3 DESC
),

table2 AS
(
SELECT table1.category, SUM(table1.total_revenue_to_date) / COUNT (table1.category) avg_income_per_movie
FROM   table1
WHERE  table1.category = 'Classics' OR
       table1.category = 'Animation' OR
       table1.category = 'Children' OR
       table1.category = 'Comedy' OR
       table1.category = 'Family' OR
       table1.category = 'Music'
GROUP BY 1
ORDER BY 2 DESC
),

table3 AS
(
SELECT i.film_id,
       r.return_date,
       CASE WHEN (r.return_date) IS NULL THEN ('0') ELSE 1 END returned
FROM   rental r
FULL JOIN inventory i
ON     r.inventory_id = i.inventory_id
ORDER BY 3
),

table4 AS
(
SELECT fc.film_id film_id, c.name category
FROM   film_category fc
JOIN   category c
ON     fc.category_id = c.category_id
),

table5 AS
(
SELECT table3.film_id,
       table4.category,
       table3.returned

FROM   table3
JOIN   table4
ON     table4.film_id = table3.film_id
),

table6 AS
(
SELECT table5.category category,
       (CAST(SUM(table5.returned) AS decimal(15,3))/CAST(COUNT(table5.category) AS decimal(15,3)))*100 return_rate
FROM   table5
WHERE  table5.category = 'Classics' OR
       table5.category = 'Animation' OR
       table5.category = 'Children' OR
       table5.category = 'Comedy' OR
       table5.category = 'Family' OR
       table5.category = 'Music'
GROUP BY 1
),

table7 AS
(
SELECT c.name category,
       f.replacement_cost replacement_cost,
       COUNT (replacement_cost) count
FROM   film f
JOIN   film_category fc
ON     f.film_id = fc.film_id
JOIN   category c
ON     fc.category_id = c.category_id
WHERE  c.name = 'Classics' OR
       c.name = 'Animation' OR
       c.name = 'Children' OR
       c.name = 'Comedy' OR
       c.name = 'Family' OR
       c.name = 'Music'
GROUP BY 1,2
ORDER BY 1,2
),

table8 AS
(
SELECT table7.category category,
       SUM (table7.replacement_cost * table7.count) / SUM (table7.count) avg_replacement_cost
FROM   table7
GROUP BY 1
ORDER BY 1
)

SELECT table8.category,
       table2.avg_income_per_movie avg_net_income,
       table8.avg_replacement_cost,
       table6.return_rate,
       table2.avg_income_per_movie - (table8.avg_replacement_cost / (table6.return_rate / 100)) gross_profit_per_movie
FROM   table8
JOIN   table2
ON     table8.category = table2.category
JOIN   table6
ON     table2.category = table6.category
ORDER BY 5 DESC;
