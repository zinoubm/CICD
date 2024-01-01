import os
import boto3
import uuid
import json
from dotenv import load_dotenv

load_dotenv()
global AWS_ACCESS_KEY
global AWS_SECRET_KEY
global AWS_REGION

AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY", None)
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY", None)
AWS_REGION = os.getenv("AWS_REGION", None)
JOB_QUEUE = os.getenv("JOB_QUEUE")
JOB_DEFINITION = os.getenv("JOB_DEFINITION")


class AwsBatch():
    def __init__(self) -> None:
        self.job_queue = JOB_QUEUE
        self.job_definition = JOB_DEFINITION
        self.client = boto3.client("batch",
                                   aws_access_key_id=AWS_ACCESS_KEY,
                                   aws_secret_access_key=AWS_SECRET_KEY,
                                   region_name=AWS_REGION)
        

    def run(self, job_name='test_job', worker_file_path='woker.py', payload={"user_id":"1", 
                                                                             "document_id":"1", 
                                                                             "s3_document_path":"doc-1.pdf"}):
        try:
            response = self.client.submit_job(
            jobName=job_name,
            jobQueue=self.job_queue,
            jobDefinition=self.job_definition,
            containerOverrides={
                # "command":[
                #     "python",
                #     worker_file_path,
                #     json.dumps(payload)
                # ]
                "command":["echo", "test"]
            }
        )
                        
        except Exception as e:
            return {"status":0, "error":e}

        return response
    

if __name__ == "__main__":
    my_batch = AwsBatch()
    res = my_batch.run(job_name="first_run")
    print(res)