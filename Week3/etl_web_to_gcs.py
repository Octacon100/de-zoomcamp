from pathlib import Path
import pandas as pd
from prefect import flow, task, get_run_logger
from prefect_gcp.cloud_storage import GcsBucket
from random import randint
import os

@task(retries=1)
def fetch(dataset_url: str) -> pd.DataFrame:
    """Read taxi data from web into pandas DataFrame"""
    # if randint(0, 1) > 0:
    #     raise Exception
    logger = get_run_logger()
    logger.info(f"Pulling down {dataset_url}.")
    df = pd.read_csv(dataset_url)
    logger.info(f"Pulled down {dataset_url}.")
    return df


@task(log_prints=True)
def clean(df: pd.DataFrame) -> pd.DataFrame:
    """Fix dtype issues"""
    # df["tpep_pickup_datetime"] = pd.to_datetime(df["tpep_pickup_datetime"])
    # df["tpep_dropoff_datetime"] = pd.to_datetime(df["tpep_dropoff_datetime"])
    print(df.head(2))
    print(f"columns: {df.dtypes}")
    print(f"rows: {len(df)}")
    return df


@task()
def write_local(df: pd.DataFrame, dataset_file: str) -> Path:
    """Write DataFrame out locally as parquet file"""
    directory = "data"
    path = Path(f"{directory}/{dataset_file}.csv")
    logger = get_run_logger()
    logger.info(f"Writing to {path.name}.")
    if not os.path.exists(directory):
        os.makedirs(directory)
    df.to_csv(path)
    return path


@task()
def write_gcs(path: Path) -> None:
    """Upload local parquet file to GCS"""
    gcs_block = GcsBucket.load("zoom-gcs-bucket")
    gcs_block.upload_from_path(from_path=path, to_path=path)
    return


@flow()
def etl_web_to_gcs(input_year:int, input_month: int) -> None:
    """The main ETL function"""
    # color = "green"
    year = input_year
    month = input_month
    # dataset_file = f"{color}_tripdata_{year}-{month:02}"
    dataset_file = f"fhv_tripdata_{year}-{month:02}"
    # https://github.com/DataTalksClub/nyc-tlc-data/releases/download/fhv/fhv_tripdata_2019-01.csv.gz
    dataset_url = f"https://github.com/DataTalksClub/nyc-tlc-data/releases/download/fhv/{dataset_file}.csv.gz"
    # dataset_url = f"https://github.com/DataTalksClub/nyc-tlc-data/releases/download/{color}/{dataset_file}.csv.gz"
    

    df = fetch(dataset_url)
    df_clean = clean(df)
    path = write_local(df_clean, dataset_file)
    write_gcs(path)


if __name__ == "__main__":
    for month in range(1,12):
        etl_web_to_gcs(input_year=2019, input_month=month)
    #etl_web_to_gcs(input_year=2019, input_month=12)

