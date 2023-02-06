import etl_gcs_to_bq
from prefect.deployments import Deployment
from prefect.filesystems import GitHub

github_block = GitHub.load("github-de-zoomcourse-code")

deployment = Deployment.build_from_flow(
    flow=etl_gcs_to_bq.etl_gcs_to_bq,
    name="de_course_bq_upload",
    version="1",
    tags=["demo"],
    parameters={"color": "Green",
     "year" : 2020, 
     "month" : 11},
    storage=github_block,
    #path="de-zoomcamp/github_deployed_code/"
)
deployment.apply()