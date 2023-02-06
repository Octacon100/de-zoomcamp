from etl_gcs_to_bg import etl_gcs_to_bg
from prefect.deployments import Deployment
from prefect.filesystems import GitHub

github_block = GitHub.load("github-de-zoomcourse-code")

deployment = Deployment.build_from_flow(
    flow=etl_gcs_to_bg,
    name="de_course_bq_upload",
    version="1",
    tags=["demo"],
    storage=github_block,
)
deployment.apply()