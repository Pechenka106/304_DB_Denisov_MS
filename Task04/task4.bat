#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS User1, u2.name AS User2, m.title AS Movie FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON r1.user_id = u1.id JOIN users u2 ON r2.user_id = u2.id JOIN movies m ON r1.movie_id = m.id LIMIT 100;"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RankedRatings AS (SELECT r.movie_id, r.user_id, r.rating, r.timestamp, ROW_NUMBER() OVER(PARTITION BY r.user_id ORDER BY r.timestamp DESC) as rn FROM ratings r) SELECT m.title, u.name, rr.rating, date(rr.timestamp, 'unixepoch') AS review_date FROM RankedRatings rr JOIN users u ON rr.user_id = u.id JOIN movies m ON rr.movie_id = m.id WHERE rr.rn = 1 ORDER BY rr.timestamp DESC LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH MovieAvgs AS (SELECT movie_id, AVG(rating) as avg_rating FROM ratings GROUP BY movie_id), Extremes AS (SELECT MAX(avg_rating) as max_r, MIN(avg_rating) as min_r FROM MovieAvgs) SELECT m.title, m.year, ma.avg_rating, CASE WHEN ma.avg_rating = e.max_r THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM MovieAvgs ma CROSS JOIN Extremes e JOIN movies m ON ma.movie_id = m.id WHERE ma.avg_rating = e.max_r OR ma.avg_rating = e.min_r ORDER BY m.year, m.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.id) AS ratings_count, AVG(r.rating) AS avg_rating FROM ratings r JOIN users u ON r.user_id = u.id WHERE u.gender = 'F' AND strftime('%Y', date(r.timestamp, 'unixepoch')) BETWEEN '2010' AND '2012';"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Сортировка по году и названиям. Первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH MovieAvgs AS (SELECT movie_id, AVG(rating) as avg_rating FROM ratings GROUP BY movie_id), RankedMovies AS (SELECT movie_id, avg_rating, RANK() OVER(ORDER BY avg_rating DESC) as rank FROM MovieAvgs) SELECT m.title, rm.avg_rating, rm.rank FROM RankedMovies rm JOIN movies m ON rm.movie_id = m.id ORDER BY m.year, m.title LIMIT 20;"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации'."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT CASE WHEN instr(name, ' ') > 0 THEN substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) ELSE name END || '|' || register_date AS UserInfo FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE num1(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM num1 WHERE x < 10), num2(y) AS (SELECT 1 UNION ALL SELECT y+1 FROM num2 WHERE y < 10) SELECT x || 'x' || y || '=' || (x*y) AS 'Таблица умножения' FROM num1 CROSS JOIN num2;"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(genre, rest) AS (SELECT SUBSTR(genres || '|', 1, INSTR(genres || '|', '|') - 1), SUBSTR(genres || '|', INSTR(genres || '|', '|') + 1) FROM movies WHERE genres IS NOT NULL AND genres != '' UNION ALL SELECT SUBSTR(rest, 1, INSTR(rest, '|') - 1), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split_genres WHERE rest <> '') SELECT DISTINCT genre FROM split_genres WHERE genre <> '' ORDER BY genre;"
echo " "