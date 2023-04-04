from prefect.filesystems import Azure
bp="$container_name"
ascs="$AZURE_STORAGE_CONNECTION_STRING"
block = Azure(bucket_path=bp, azure_storage_connection_string=ascs)
block.save("code-block")