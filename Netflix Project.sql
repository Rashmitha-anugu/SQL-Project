use practice;
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
INSERT INTO netflix (
    show_id, type, title, director, casts, country, date_added, release_year,
    rating, duration, listed_in, description
) VALUES
('s1', 'Movie', 'Inception', 'Christopher Nolan', 'Leonardo DiCaprio, Joseph Gordon-Levitt', 'United States', 'July 16, 2010', 2010, 'PG-13', '148 min', 'Action, Sci-Fi', 'A thief steals corporate secrets through dream-sharing technology.'),
('s2', 'TV Show', 'Friends', 'David Crane, Marta Kauffman', 'Jennifer Aniston, Courteney Cox, Lisa Kudrow', 'United States', 'September 22, 1994', 1994, 'TV-14', '10 Seasons', 'Comedy, Romance', 'Follows the lives of six friends living in New York City.'),
('s3', 'Movie', '3 Idiots', 'Rajkumar Hirani', 'Aamir Khan, R. Madhavan, Sharman Joshi', 'India', 'December 25, 2009', 2009, 'PG-13', '170 min', 'Comedy, Drama', 'Two friends search for their long-lost companion.'),
('s4', 'TV Show', 'Sacred Games', 'Anurag Kashyap, Vikramaditya Motwane', 'Nawazuddin Siddiqui, Saif Ali Khan', 'India', 'July 6, 2018', 2018, 'TV-MA', '2 Seasons', 'Crime, Thriller', 'A Mumbai police officer receives a phone call from a gangster.');

-- 1. Count the Number of Movies vs TV Shows
SELECT 
    type,
    COUNT(*)
FROM netflix
GROUP BY 1;

-- Objective: Determine the distribution of content types on Netflix.

-- 2. Find the Most Common Rating for Movies and TV Shows
WITH RatingCounts AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT 
        type,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank_num
    FROM RatingCounts
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rank_num = 1;

-- Objective: Identify the most frequently occurring rating for each type of content.

-- 3. List All Movies Released in a Specific Year (e.g., 2020)
SELECT * 
FROM netflix
WHERE release_year = 2020;

-- Objective: Retrieve all movies released in a specific year.
-- 4. Find the Top 5 Countries with the Most Content on Netflix
WITH RECURSIVE split_countries AS (
    -- Anchor member: extract the first country
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
        SUBSTRING_INDEX(country, ',', -1) AS rest,
        country AS original_country,
        1 AS part_num
    FROM netflix
    WHERE country IS NOT NULL

    UNION ALL

    -- Recursive member: extract remaining countries
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(rest, ',', 1)),
        IF(rest LIKE '%,%', SUBSTRING_INDEX(rest, ',', -1), NULL),
        original_country,
        part_num + 1
    FROM split_countries
    WHERE rest IS NOT NULL AND rest != original_country
)

SELECT 
    country,
    COUNT(*) AS total_content
FROM split_countries
WHERE country IS NOT NULL AND country != ''
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;

-- 5. Identify the Longest Movie
SELECT 
    *
FROM netflix
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

-- objective: Find the movie with the longest duration.
-- 6. Find Content Added in the Last 5 Years
SELECT *
FROM netflix
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;

-- Objective: Retrieve content added to Netflix in the last 5 years.

-- 7. Find All Movies/TV Shows by Director 'Rashmitha Anugu'
SELECT *
FROM netflix
WHERE FIND_IN_SET('Rashmitha Anugu', director) > 0;

-- Objective: List all content directed by 'Rashmitha Anugu'.

-- 8. List All TV Shows with More Than 5 Seasons
SELECT *
FROM netflix
WHERE type = 'TV Show'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;
  
  -- 9. Count the Number of Content Items in Each Genre
WITH RECURSIVE genre_split AS (
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        SUBSTRING_INDEX(listed_in, ',', -1) AS rest,
        listed_in AS original,
        1 AS part
    FROM netflix
    WHERE listed_in IS NOT NULL

    UNION ALL

    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
        IF(rest LIKE '%,%', SUBSTRING_INDEX(rest, ',', -1), NULL),
        original,
        part + 1
    FROM genre_split
    WHERE rest IS NOT NULL AND rest != original
)

SELECT 
    genre,
    COUNT(*) AS total_content
FROM genre_split
WHERE genre IS NOT NULL AND genre != ''
GROUP BY genre
ORDER BY total_content DESC;

-- Objective: Count the number of content items in each genre.
-- Objective: Identify TV shows with more than 5 seasons.

-- 10.Find each year and the average numbers of content release in India on netflix.
SELECT 
    release_year,
    COUNT(*) AS total_releases
FROM netflix
WHERE FIND_IN_SET('India', country) > 0
GROUP BY release_year
ORDER BY total_releases DESC
LIMIT 5;
-- Objective: Calculate and rank years by the average number of content releases by India.

-- 11. List All Movies that are Documentaries
SELECT * 
FROM netflix
WHERE listed_in LIKE '%Documentaries';

-- Objective: Retrieve all movies classified as documentaries.

-- 12. Find All Content Without a Director
SELECT * 
FROM netflix
WHERE director IS NULL;

-- Objective: List content that does not have a director.
-- 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years
SELECT * 
FROM netflix
WHERE casts LIKE '%Salman Khan%'
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;
  
-- Objective: Count the number of movies featuring 'Salman Khan' in the last 10 years.
-- 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
WITH RECURSIVE actor_split AS (
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(casts, ',', 1)) AS actor,
        SUBSTRING_INDEX(casts, ',', -1) AS rest,
        casts AS original,
        1 AS part
    FROM netflix
    WHERE FIND_IN_SET('India', country) > 0
      AND type = 'Movie'
      AND casts IS NOT NULL

    UNION ALL

    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
        IF(rest LIKE '%,%', SUBSTRING_INDEX(rest, ',', -1), NULL),
        original,
        part + 1
    FROM actor_split
    WHERE rest IS NOT NULL AND rest != original
)

SELECT 
    actor,
    COUNT(*) AS appearances
FROM actor_split
WHERE actor IS NOT NULL AND actor != ''
GROUP BY actor
ORDER BY appearances DESC
LIMIT 10;

-- Objective: Identify the top 10 actors with the most appearances in Indian-produced movies.

-- 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
SELECT 
    category,
    COUNT(*) AS content_count
FROM (
    SELECT 
        CASE 
            WHEN LOWER(description) LIKE '%kill%' OR LOWER(description) LIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY category;
-- Objective: Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.