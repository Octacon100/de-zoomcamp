import pandas as pd
from pathlib import Path

directory = "data"
dataset_file = "fhv_tripdata_2019-01"
path = Path(f"{directory}/{dataset_file}.parquet")
df = pd.read_parquet(path)
print(df.head())