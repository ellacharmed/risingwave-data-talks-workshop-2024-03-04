-- qn-1 
-- Create a materialized view to compute the 
-- average, min and max trip time 
-- between each taxi zone.

-- no special functions needed
select (td.tpep_dropoff_datetime - td.tpep_pickup_datetime) AS duration
from trip_data td ;

CREATE MATERIALIZED VIEW mv_trip_times AS
SELECT 
	max(td.tpep_dropoff_datetime - td.tpep_pickup_datetime) as max_trip_time,
	min(td.tpep_dropoff_datetime - td.tpep_pickup_datetime) as min_trip_time,
	avg(td.tpep_dropoff_datetime - td.tpep_pickup_datetime) as avg_trip_time,
	zpu.Zone as pickup_zone, 
	zdo.zone as dropoff_zone
FROM trip_data as td
JOIN taxi_zone as zpu
    ON td.pulocationid = zpu.location_id
JOIN taxi_zone as zdo
    ON td.dolocationid = zdo.location_id
group by pickup_zone,dropoff_zone
;

-- From this MV, find the pair of taxi zones with the highest average trip time.
SELECT 
    pickup_zone,
    dropoff_zone,
    avg_trip_time
FROM 
    mv_trip_times
ORDER BY 
    avg_trip_time DESC
LIMIT 1;
    
/*
pickup_zone   |dropoff_zone|avg_trip_time|
--------------+------------+-------------+
Yorkville East|Steinway    |     23:59:33|
*/

-- qn-2 
-- Recreate the MV(s) in question 1, to also find the **number of trips** 
-- for the pair of taxi zones with the highest average trip time.

select (td.tpep_dropoff_datetime - td.tpep_pickup_datetime) AS duration
from trip_data td ;

CREATE MATERIALIZED VIEW mv_trip_times_with_count AS
SELECT 
	max(td.tpep_dropoff_datetime - td.tpep_pickup_datetime) as max_trip_time,
	min(td.tpep_dropoff_datetime - td.tpep_pickup_datetime) as min_trip_time,
	avg(td.tpep_dropoff_datetime - td.tpep_pickup_datetime) as avg_trip_time,
	zpu.Zone as pickup_zone, 
	zdo.zone as dropoff_zone,
	count(td.vendorid) as trip_count
FROM trip_data as td
JOIN taxi_zone as zpu
    ON td.pulocationid = zpu.location_id
JOIN taxi_zone as zdo
    ON td.dolocationid = zdo.location_id
group by pickup_zone,dropoff_zone
;

-- From this MV, find the pair of taxi zones and
-- trip counts with the highest average trip time

SELECT 
    pickup_zone,
    dropoff_zone,
    avg_trip_time,
    trip_count
FROM 
    mv_trip_times_with_count
ORDER BY 
    avg_trip_time desc
LIMIT 1;
    
/*
pickup_zone   |dropoff_zone|avg_trip_time|trip_count|
--------------+------------+-------------+----------+
Yorkville East|Steinway    |     23:59:33|         1|
*/

-- qn3
/* qn-3
 * From the latest pickup time to 17 hours before, 
 * what are the top 3 busiest zones in terms of number of pickups?
 * For example if the latest pickup time is 2020-01-01 12:00:00,
 * then the query should return the top 3 busiest zones from 
 * 2020-01-01 11:00:00 to 2020-01-01 12:00:00.
 */
 
WITH pickup_window AS (
  SELECT
    MAX(tpep_pickup_datetime) AS max_datetime,
    MAX(tpep_pickup_datetime) - INTERVAL '17 hours' AS window_start
  FROM trip_data
)
SELECT
  tz.zone AS pickup_zone,
  COUNT(*) AS num_pickups
FROM trip_data td
JOIN 
  taxi_zone tz ON td.pulocationid = tz.location_id
WHERE 
  td.tpep_pickup_datetime BETWEEN (
    SELECT window_start FROM pickup_window
  ) AND (
    SELECT max_datetime FROM pickup_window
  )
GROUP BY 
  tz.zone
ORDER BY 
  num_pickups DESC
LIMIT 3;
