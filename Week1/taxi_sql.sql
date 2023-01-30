select count(*) 
FROM trips_2019
where 
	(lpep_pickup_datetime between '20190115' AND '20190116')
	and (lpep_dropoff_datetime between '20190115' AND '20190116')
limit 100 

select * 
FROM trips_2019
limit 100 

Select cast(lpep_pickup_datetime as DATE), max(trip_distance)
FROM trips_2019
where cast(lpep_pickup_datetime as DATE) in ('20190118', '20190128', '20190115', '20190110')
GROUP BY cast(lpep_pickup_datetime as DATE)

Select cast(lpep_pickup_datetime as DATE), passenger_count, COUNT(*)
FROM trips_2019
where cast(lpep_pickup_datetime as DATE) in ('20190101')
GROUP BY cast(lpep_pickup_datetime as DATE), passenger_count

SELECT pu_zone."Zone", do_zone."Zone", MAX(t.tip_amount) as tip_amount
from trips_2019 as t
JOIN zones_2019 pu_zone
on t."PULocationID" = pu_zone."LocationID"
join zones_2019 do_zone
on t."DOLocationID" = do_zone."LocationID"
where pu_zone."Zone" = 'Astoria'
group by pu_zone."Zone", do_zone."Zone"
order by MAX(t.tip_amount) desc
limit 100 

select *
FROM yellow_taxi_trips
where 
	tpep_pickup_datetime > '20190115' 
	and tpep_pickup_datetime < '20190116' 
	--AND '20190116'
	order by tpep_pickup_datetime asc
limit 100 


select *
FROM yellow_taxi_trips
where tpep_pickup_datetime between '20210115' AND '20210116'
limit 100 

select min(tpep_pickup_datetime), max(tpep_pickup_datetime)
FROM yellow_taxi_trips
where tpep_pickup_datetime between '20210115' AND '20210116'
limit 100 




SELECT
    lpep_pickup_datetime,
    lpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", '/', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", '/', zdo."Zone") AS "dropoff_loc"
FROM
    trips_2019 t JOIN zones_2019 zpu
        ON t."PULocationID" = zpu."LocationID"
    JOIN zones_2019 zdo
        ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;