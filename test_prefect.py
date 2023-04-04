from prefect import flow, get_run_logger

@flow(name="Prefect Cloud Quickstart")
def test_prefect():
    logger = get_run_logger()
    logger.warning("Cloud quickstart flow is running!")

if __name__ == "__main__":
    quickstart_flow()