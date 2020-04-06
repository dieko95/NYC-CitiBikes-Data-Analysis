  -- Can you find any traces of empty stations?
  -- If yes, how big is this problem?
  /*

Latest Timestamp: 2020-03-28T00:00:00
Oldest Timestamp: "2020-03-27T00:00:00"

936 Distinct bike stations
11 bike stations that are completely empty (0 available bikes)

However, how many bike racks have 10% or less of their capacity?

NOTE: The citibike_stations table has data from the last two days. 
		I am going to use the most updated information of Citibike_trips and assume that the stations followed the same
		pattern as in mid 2018. 
*/

-- Query to check how many empty stations there are 
SELECT
  name,
  num_bikes_available,
  num_docks_available,
  capacity,
  last_reported,
  is_installed
FROM
  `bigquery-public-data.new_york_citibike.citibike_stations`
WHERE
  num_bikes_available = 0 and 
  is_renting = True



-- Quantity of distinct bike Stations  

-- SELECT distinct count(name) from `bigquery-public-data.new_york_citibike.citibike_stations`  

-- Count of how empty docs
-- 11 Docks with no bikes 
SELECT
  name
FROM
  `bigquery-public-data.new_york_citibike.citibike_stations`
WHERE
  num_bikes_available = 0 and 
  is_renting = True
-- name
-- Stephen St & Seneca Ave
-- Jefferson Ave & Evergreen Ave
-- Madison St & Evergreen Ave
-- Cypress Ave & George St
-- Woodward Ave & Harman St
-- Queens Plaza North & Crescent St
-- Madison Ave & E 82 St
-- St. Nicholas Ave & W 126 St



  -- How many Docks have 10 % of their capacity?

SELECT
  name,
  num_bikes_available,
  num_docks_disabled,
  num_bikes_disabled,
  capacity,
  CONCAT(latitude,',', longitude) as lat_long
FROM
  `bigquery-public-data.new_york_citibike.citibike_stations`
WHERE
  num_bikes_available <= capacity * 0.1
ORDER BY
  -- capacity ASC;
  
  -- Is there any relationship between how big the station is and its emptiness?
  -- Answer: These stations are very small, the majority belongs to less the top 25% smallest stations.
  -- Probably this stations are remote
  /* 
  I calculated these quartiles by copy and pasting the results of the following query 
  in google sheets and calculating the quartiles with the QUARTILE() function

Q1	    Q2	  Q3	Q4
28.5	44	59.5	80

*/
SELECT
  DISTINCT capacity
FROM
  `bigquery-public-data.new_york_citibike.citibike_stations`
ORDER BY
  1 ASC;



-- What are the most popular stations in the network?
-- When does their usage peak?

/*

The most popular stations are in the top 25% quantile of largest stations. 
However, there's one that is in the low 25% of the smallest stations 8 Ave & W 31 St and Great Jones St
It is necessary to expand this stations!! 

*/


-- The analysis will take place from Jan 2018 till August 2018 
WITH popular_stations AS (
  SELECT
    start_station_id,
    COUNT(*) AS number_trips
  FROM
     `bigquery-public-data.new_york_citibike.citibike_trips` 
  WHERE 
    starttime >= '2018-01-01T00:00:00'
  GROUP BY
    1
)

-- Viewing the capacity of the most popular stations' capacity
SELECT -- Outer Query to filter only the capacity 
    name,
  capacity,
  number_trips
FROM
    (SELECT -- Innery Query to find the most popular trips' capacity
      name,
      capacity,
      number_trips
    FROM 
      popular_stations -- Subquery that contains the 20 most popular trips from 2018-01 to 2018-09
    INNER JOIN 
      `bigquery-public-data.new_york_citibike.citibike_stations` 
    ON station_id  = start_station_id 
    ORDER BY 
      3 DESC
    LIMIT 
      20)
ORDER BY 2 ASC


/*

PEAK USAGE OF MOST POPULAR STATIONS


+-------------------------------+------------+------------------------+
|       start_station_name      | date_start | max_number_daily_trips |
+-------------------------------+------------+------------------------+
|     Pershing Square North     |      3     |          11218         |
+-------------------------------+------------+------------------------+
|        W 21 St & 6 Ave        |      3     |          6261          |
+-------------------------------+------------+------------------------+
|       E 17 St & Broadway      |      3     |          5783          |
+-------------------------------+------------+------------------------+
|       E 47 St & Park Ave      |      3     |          5665          |
+-------------------------------+------------+------------------------+
|        W 33 St & 7 Ave        |      3     |          5517          |
+-------------------------------+------------+------------------------+
|       Broadway & E 14 St      |      3     |          4966          |
+-------------------------------+------------+------------------------+
|     Lafayette St & E 8 St     |      3     |          4595          |
+-------------------------------+------------+------------------------+
|        6 Ave & W 33 St        |      3     |          4362          |
+-------------------------------+------------+------------------------+
|         Great Jones St        |      3     |          4316          |
+-------------------------------+------------+------------------------+
| Christopher St & Greenwich St |      3     |          4287          |
+-------------------------------+------------+------------------------+
|    Cooper Square & Astor Pl   |      3     |          4172          |
+-------------------------------+------------+------------------------+
|       Broadway & E 22 St      |      5     |          6723          |
+-------------------------------+------------+------------------------+
|        W 41 St & 8 Ave        |      5     |          5994          |
+-------------------------------+------------+------------------------+
|        W 31 St & 7 Ave        |      5     |          5093          |
+-------------------------------+------------+------------------------+
|        8 Ave & W 33 St        |      5     |          5026          |
+-------------------------------+------------+------------------------+
|        8 Ave & W 31 St        |      5     |          4914          |
+-------------------------------+------------+------------------------+
|     West St & Chambers St     |      5     |          4542          |
+-------------------------------+------------+------------------------+
|       Broadway & W 60 St      |      5     |          4284          |
+-------------------------------+------------+------------------------+
|       Carmine St & 6 Ave      |      5     |          3884          |
+-------------------------------+------------+------------------------+
|     Central Park S & 6 Ave    |      7     |          4516          |
+-------------------------------+------------+------------------------+

*/



----------- PEAK USAGE BY DAY OF THE WEEK ------------


WITH popular_stations AS (
  SELECT
    start_station_name, 
    start_station_id,
    COUNT(*) AS number_trips
  FROM
     `bigquery-public-data.new_york_citibike.citibike_trips` 
  WHERE 
    starttime >= '2018-01-01T00:00:00' -- Defining Time Frame of the analysis
  GROUP BY
    1,2
  ORDER BY 3 DESC
  LIMIT 20
),

popular_stations_daily AS (
-- INNER JOIN TO OBTAIN MOST POPULAR STATIONS BY DAY
    
    SELECT 
      all_trips.start_station_name,
      extract (DAYOFWEEK from starttime) as date_start ,
--       cast(starttime as TIME) as date_start, -- Number of tips
      COUNT(*) AS number_trips 
    FROM 
      `bigquery-public-data.new_york_citibike.citibike_trips` as all_trips
    INNER JOIN 
      popular_stations  -- Inner join popular stations
    USING (start_station_id) -- By station ID
    WHERE cast(starttime as DATE) >= '2018-01-01'
    GROUP BY 
      1,2
    ORDER BY 3 DESC)




SELECT -- Getting the dates of each station's peak day
  a.start_station_name,
  date_start,
  max_number_daily_trips
FROM popular_stations_daily as a

INNER JOIN (

  SELECT -- getting the biggest number of daily trips
    DISTINCT start_station_name as individual_station_name, -- Distinct to get the individual station names
    max(number_trips) OVER (PARTITION BY start_station_name) AS max_number_daily_trips -- Getting the maximum number of trips per station
  FROM
     popular_stations_daily 
  ORDER by 2 desc
)

ON max_number_daily_trips = number_trips and a.start_station_name = individual_station_name -- Joining to get non-aggregated values

order by 3 DESC ;



----------- PEAK USAGE BY HOUR ------------

WITH popular_stations AS (
	  SELECT
	    start_station_name, 
	    start_station_id,
	    COUNT(*) AS number_trips
	  FROM
	     `bigquery-public-data.new_york_citibike.citibike_trips` 
	  WHERE 
	    starttime >= '2018-01-01T00:00:00' -- Defining Time Frame of the analysis
	  GROUP BY
	    1,2
	  ORDER BY 3 DESC
	  LIMIT 20
	),



	popular_stations_hourly AS (
	-- INNER JOIN TO OBTAIN MOST POPULAR STATIONS BY DAY
	    
	    SELECT 
	      all_trips.start_station_name,
	      extract (HOUR from cast(starttime as TIME)) as time_start, -- Number of tips
	      COUNT(*) AS number_trips 
	    FROM 
	      `bigquery-public-data.new_york_citibike.citibike_trips` as all_trips
	    INNER JOIN 
	      popular_stations  -- Inner join popular stations
	    USING (start_station_id) -- By station ID
	    WHERE cast(starttime as DATE) >= '2018-01-01'
	    GROUP BY 
	      1,2
	    ORDER BY 3 DESC)    
    
    
SELECT -- Getting the hour of each station's peak hour
  a.start_station_name,
  time_start,
  max_number_hourly_trips
FROM popular_stations_hourly as a

INNER JOIN (

  SELECT -- getting the biggest number of trips per hour
    DISTINCT start_station_name as individual_station_name, -- Distinct to get the individual station names
    max(number_trips) OVER (PARTITION BY start_station_name) AS max_number_hourly_trips -- Getting the maximum number of trips per station
  FROM
     popular_stations_hourly  
  ORDER by 2 desc
)

ON max_number_hourly_trips = number_trips and a.start_station_name = individual_station_name -- Joining to get non-aggregated values

order by 3 DESC ;

/*
+-------------------------------+------------+-------------------------+
|       start_station_name      | time_start | max_number_hourly_trips |
+-------------------------------+------------+-------------------------+
|        8 Ave & W 31 St        |      6     |           4969          |
+-------------------------------+------------+-------------------------+
|        W 33 St & 7 Ave        |      6     |           3586          |
+-------------------------------+------------+-------------------------+
| Christopher St & Greenwich St |      8     |           2526          |
+-------------------------------+------------+-------------------------+
|     Pershing Square North     |     17     |           8841          |
+-------------------------------+------------+-------------------------+
|       E 47 St & Park Ave      |     17     |           7086          |
+-------------------------------+------------+-------------------------+
|       E 17 St & Broadway      |     17     |           4361          |
+-------------------------------+------------+-------------------------+
|     Central Park S & 6 Ave    |     17     |           3045          |
+-------------------------------+------------+-------------------------+
|       Broadway & E 22 St      |     18     |           6823          |
+-------------------------------+------------+-------------------------+
|        W 21 St & 6 Ave        |     18     |           4393          |
+-------------------------------+------------+-------------------------+
|        W 41 St & 8 Ave        |     18     |           4204          |
+-------------------------------+------------+-------------------------+
|     West St & Chambers St     |     18     |           3705          |
+-------------------------------+------------+-------------------------+
|        6 Ave & W 33 St        |     18     |           3549          |
+-------------------------------+------------+-------------------------+
|        W 31 St & 7 Ave        |     18     |           3259          |
+-------------------------------+------------+-------------------------+
|       Broadway & E 14 St      |     18     |           3244          |
+-------------------------------+------------+-------------------------+
|        8 Ave & W 33 St        |     18     |           2877          |
+-------------------------------+------------+-------------------------+
|       Broadway & W 60 St      |     18     |           2875          |
+-------------------------------+------------+-------------------------+
|     Lafayette St & E 8 St     |     18     |           2741          |
+-------------------------------+------------+-------------------------+
|         Great Jones St        |     18     |           2565          |
+-------------------------------+------------+-------------------------+
|    Cooper Square & Astor Pl   |     18     |           2347          |
+-------------------------------+------------+-------------------------+
|       Carmine St & 6 Ave      |     18     |           2184          |
+-------------------------------+------------+-------------------------+


*/


-- Viewing Least popular Stations
-- 

WITH least_popular_stations AS (SELECT
  start_station_name,
  COUNT(*) AS number_trips
FROM
  `bigquery-public-data.new_york.citibike_trips`
GROUP BY
  1
ORDER BY
  number_trips asc
LIMIT
  20)
  
SELECT 
  name,
  capacity,
  number_trips 
FROM 
  least_popular_stations  
INNER JOIN 
  `bigquery-public-data.new_york_citibike.citibike_stations` 
ON name = start_station_name
order by 3 asc


------- AVERAGE USAGE PER STATION --------



WITH popular_stations AS (
  SELECT
    start_station_name, 
    start_station_id,
    COUNT(*) AS number_trips
  FROM
     `bigquery-public-data.new_york_citibike.citibike_trips` 
  WHERE 
    starttime >= '2018-01-01T00:00:00' -- Defining Time Frame of the analysis
  GROUP BY
    1,2
  ORDER BY 3 DESC
  LIMIT 20
),

popular_stations_daily AS (
-- INNER JOIN TO OBTAIN MOST POPULAR STATIONS BY DAY
    
    SELECT 
      all_trips.start_station_name,
      CAST(starttime as DATE) as date_start ,
--       cast(starttime as TIME) as date_start, -- Number of tips
      COUNT(*) AS number_trips 
    FROM 
      `bigquery-public-data.new_york_citibike.citibike_trips` as all_trips
    INNER JOIN 
      popular_stations  -- Inner join popular stations
    USING (start_station_id) -- By station ID
    WHERE cast(starttime as DATE) >= '2018-01-01'
    GROUP BY 
      1,2
    ORDER BY 3 DESC)

SELECT -- getting the averge number of daily trips
  DISTINCT start_station_name as individual_station_name, -- Distinct to get the individual station names
  round(avg(number_trips) OVER (PARTITION BY start_station_name),0) AS avg_number_daily_trips -- Getting the maximum number of trips per station
FROM
   popular_stations_daily 
ORDER by 2 desc


/*

+-------------------------------+------------------------+
|    individual_station_name    | avg_number_daily_trips |
+-------------------------------+------------------------+
|     Pershing Square North     |          371.0         |
+-------------------------------+------------------------+
|        W 21 St & 6 Ave        |          250.0         |
+-------------------------------+------------------------+
|       Broadway & E 22 St      |          243.0         |
+-------------------------------+------------------------+
|       E 17 St & Broadway      |          237.0         |
+-------------------------------+------------------------+
|       Broadway & E 14 St      |          208.0         |
+-------------------------------+------------------------+
|        W 41 St & 8 Ave        |          208.0         |
+-------------------------------+------------------------+
|        8 Ave & W 31 St        |          203.0         |
+-------------------------------+------------------------+
|        8 Ave & W 33 St        |          193.0         |
+-------------------------------+------------------------+
|        W 33 St & 7 Ave        |          190.0         |
+-------------------------------+------------------------+
|       Broadway & W 60 St      |          185.0         |
+-------------------------------+------------------------+
|     West St & Chambers St     |          185.0         |
+-------------------------------+------------------------+
|     Lafayette St & E 8 St     |          178.0         |
+-------------------------------+------------------------+
|        W 31 St & 7 Ave        |          177.0         |
+-------------------------------+------------------------+
|       E 47 St & Park Ave      |          175.0         |
+-------------------------------+------------------------+
| Christopher St & Greenwich St |          170.0         |
+-------------------------------+------------------------+
|       Carmine St & 6 Ave      |          168.0         |
+-------------------------------+------------------------+
|         Great Jones St        |          167.0         |
+-------------------------------+------------------------+
|     Central Park S & 6 Ave    |          166.0         |
+-------------------------------+------------------------+
|        6 Ave & W 33 St        |          165.0         |
+-------------------------------+------------------------+
|    Cooper Square & Astor Pl   |          165.0         |
+-------------------------------+------------------------+

*/