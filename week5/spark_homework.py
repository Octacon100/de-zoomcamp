import pyspark
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

spark = SparkSession.builder \
    .master("local[*]") \
    .appName('test') \
    .getOrCreate()

df = spark.read \
    .option("header", "true") \
    .csv('fhvhv_tripdata_2021-06.csv.gz')

#partitioning
#df = df.repartition(12)
#df.write.parquet('fhvhv_tripdata_2021-06_files/')

# Default Spark Session website is 4040.

#Adding date columns
df_tranformed = df \
    .withColumn('pickup_date_timestamp', F.to_timestamp(df.pickup_datetime)) \
    .withColumn('dropoff_date_timestamp', F.to_timestamp(df.dropoff_datetime)) \
    .withColumn('duration', F.unix_timestamp(df.dropoff_datetime) - F.unix_timestamp(df.pickup_datetime))

df_tranformed.printSchema()

df_tranformed.show()

# Schema details:
# root
#  |-- dispatching_base_num: string (nullable = true)
#  |-- pickup_datetime: string (nullable = true)
#  |-- dropoff_datetime: string (nullable = true)
#  |-- PULocationID: string (nullable = true)
#  |-- DOLocationID: string (nullable = true)
#  |-- SR_Flag: string (nullable = true)
#  |-- Affiliated_base_number: string (nullable = true)

#df_tranformed.registerTempTable('trips_data')
df_tranformed.createOrReplaceTempView('trips_data')

# spark.sql("""
# select COUNT(*) as num_of_trips
# from trips_data
# WHERE pickup_date_timestamp BETWEEN cast('2021-06-15' as timestamp) AND cast('2021-06-16' as timestamp)
# """).show()

# +------------+
# |num_of_trips|
# +------------+
# |      452474|
# +------------+

# spark.sql("""
# select 
#     CAST(MAX(duration) AS INT) as longest_trip_in_secs,
#     CAST(MAX(duration) / 60 / 60 AS INT) as longest_trip_in_hours
# from trips_data
# """).show()

# +--------------------+---------------------+
# |longest_trip_in_secs|longest_trip_in_hours|
# +--------------------+---------------------+
# |              240764|                   66|
# +--------------------+---------------------+

# spark.sql("""
# select 
#     CAST(MAX(duration) AS INT) as longest_trip_in_secs,
#     CAST(MAX(duration) / 60 / 60 AS INT) as longest_trip_in_hours
# from trips_data
# """).show()

df_zones = spark.read \
    .option("header", "true") \
    .csv('taxi_zone_lookup.csv')

df_zones.printSchema()

df_zones.show()

df_zones.createOrReplaceTempView('zones_data')

spark.sql("""
select 
    td.PULocationID,
    zd.Zone,
    count(*)
from trips_data td
INNER JOIN zones_data zd
on td.PULocationID = zd.LocationID
GROUP BY td.PULocationID,
    zd.Zone
ORDER BY count(*)  DESC
""").show()