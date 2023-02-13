CREATE OR REPLACE EXTERNAL TABLE `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script`
(
  dispatching_base_num STRING
  , pickup_datetime STRING
  , dropOff_datetime STRING
  , PUlocationID STRING
  , DOlocationID STRING
  , SR_Flag STRING
  , Affiliated_base_number STRING
)
OPTIONS (
  format=PARQUET,
uris = ['gs://dtc_data_lake_dtc-de-course-375402/de_zoom/data\\fhv_tripdata_2019-*.parquet']
);



SELECT count(*) FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script` 
--43,244,696


SELECT COUNT(DISTINCT(dispatching_base_num)) FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script`;
--0 bytes when run

--really having issues with parquet, tryign csv
CREATE OR REPLACE EXTERNAL TABLE `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_csv`
OPTIONS (
  format=CSV,
uris = ['gs://dtc_data_lake_dtc-de-course-375402/de_zoom/data\\fhv_tripdata_2019-*.csv'],
decimal_target_types = ['NUMERIC']
);

SELECT COUNT(DISTINCT(dispatching_base_num)) FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_csv`;

-- Make the table material
CREATE OR REPLACE TABLE `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material`
AS SELECT 
dispatching_base_num
, pickup_datetime
, dropOff_datetime
,CAST(PUlocationID as INT) as PUlocationID
,CAST(DOlocationID as INT) as DOlocationID
,CAST(SR_Flag as INT) as SR_Flag
,Affiliated_base_number
 FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script`;


--Using csv had much more luck:
CREATE OR REPLACE TABLE `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material`
AS SELECT 
-- dispatching_base_num
-- , pickup_datetime
-- , dropOff_datetime
-- ,CAST(PUlocationID as INT64) as PUlocationID
-- ,CAST(DOlocationID as INT64) as DOlocationID
-- ,CAST(SR_Flag as INT64) as SR_Flag
-- ,Affiliated_base_number
*
 FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_csv`;

SELECT COUNT(DISTINCT(dispatching_base_num)) FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material`;
--336.71

select count(*) from `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_csv`
where PUlocationID IS NULL and DOlocationID IS NULL
--717748


select distinct Affiliated_base_number from `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material`
where pickup_datetime BETWEEN '2019-03-01' and '2019-03-31'
--647.87

--PARTITION table creation
CREATE OR REPLACE TABLE `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material_part`
PARTITION BY DATETIME_TRUNC(pickup_datetime, DAY)
cluster by Affiliated_base_number
AS SELECT 
-- dispatching_base_num
-- , pickup_datetime
-- , dropOff_datetime
-- ,CAST(PUlocationID as INT64) as PUlocationID
-- ,CAST(DOlocationID as INT64) as DOlocationID
-- ,CAST(SR_Flag as INT64) as SR_Flag
-- ,Affiliated_base_number
*
 FROM `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material`


select distinct Affiliated_base_number from `dtc-de-course-375402.us_east4_de_data_source.fhv_tripdata_2019_01_script_material_part`
where pickup_datetime BETWEEN '2019-03-01' and '2019-03-31'
--23.05


CREATE OR REPLACE TABLE `taxi-rides-ny.nytaxi.fhv_nonpartitioned_tripdata`
AS SELECT * FROM `taxi-rides-ny.nytaxi.fhv_tripdata`;

CREATE OR REPLACE TABLE `taxi-rides-ny.nytaxi.fhv_partitioned_tripdata`
PARTITION BY DATE(dropoff_datetime)
CLUSTER BY dispatching_base_num AS (
  SELECT * FROM `taxi-rides-ny.nytaxi.fhv_tripdata`
);

SELECT count(*) FROM  `taxi-rides-ny.nytaxi.fhv_nonpartitioned_tripdata`
WHERE dropoff_datetime BETWEEN '2019-01-01' AND '2019-03-31'
  AND dispatching_base_num IN ('B00987', 'B02279', 'B02060');


SELECT count(*) FROM `taxi-rides-ny.nytaxi.fhv_partitioned_tripdata`
WHERE dropoff_datetime BETWEEN '2019-01-01' AND '2019-03-31'
  AND dispatching_base_num IN ('B00987', 'B02279', 'B02060');
