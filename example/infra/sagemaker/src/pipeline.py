import argparse  # Import argparse
import os

import boto3
import sagemaker
from sagemaker.processing import ProcessingInput, ScriptProcessor
from sagemaker.workflow.parameters import ParameterString
from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import ProcessingStep

# --- Configuration (Base names, can be overridden by args) ---
BASE_JOB_PREFIX = "awa-batch-template-pipeline"
# Default pipeline name, can be overridden by --pipeline-name arg
DEFAULT_PIPELINE_NAME = f"{BASE_JOB_PREFIX}-sample1"


# --- Helper function to get session ---
def get_sagemaker_session(region):
    """Gets the SageMaker session based on the region."""
    boto_session = boto3.Session(region_name=region)
    return sagemaker.Session(boto_session=boto_session)


# --- Define Pipeline Parameters (Now required at pipeline execution) ---
def define_parameters():
    """Defines SageMaker Pipeline parameters (without defaults)."""
    processing_instance_type = ParameterString(
        name="ProcessingInstanceType"  # Default removed
    )
    processing_instance_count = ParameterString(
        name="ProcessingInstanceCount"  # Default removed
    )
    input_data_uri = ParameterString( # Keep InputData for potential future use or consistency, even if not used in step
        name="InputData" # Default removed
    )
    # Remove single OutputData and ConfigFile, replace with specific ones for each step
    # output_data_uri = ParameterString(
    #     name="OutputData" # Default removed
    # )
    # config_file_uri = ParameterString(
    #     name="ConfigFile" # Default removed
    # )
    config_file_uri_1 = ParameterString(
        name="ConfigFile1" # Config for first run
    )
    config_file_uri_2 = ParameterString(
        name="ConfigFile2" # Config for second run
    )
    output_data_uri_1 = ParameterString(
        name="OutputData1" # Output for first run
    )
    output_data_uri_2 = ParameterString(
        name="OutputData2" # Output for second run
    )
    image_uri = ParameterString(
        name="ProcessingImageUri"  # Default removed
    )
    role_arn = ParameterString(  # This is the role the *pipeline step* will use
        name="ExecutionRoleArn"  # Default removed
    )
    return {
        "instance_type": processing_instance_type,
        "instance_count": processing_instance_count,
        "input_data": input_data_uri, # Keep for consistency
        # "output_data": output_data_uri, # Removed
        # "config_file": config_file_uri, # Removed
        "config_file1": config_file_uri_1,
        "config_file2": config_file_uri_2,
        "output_data1": output_data_uri_1,
        "output_data2": output_data_uri_2,
        "image_uri": image_uri,
        "role_arn": role_arn,
    }


# --- Define Pipeline Steps ---
def define_steps(params):
    """Defines the steps for the SageMaker Pipeline."""

    # Define the ScriptProcessor
    # Note: instance_count and instance_type now come from pipeline parameters at runtime
    script_processor = ScriptProcessor(
        command=["python"],  # Execute python script
        image_uri=params["image_uri"],  # Use pipeline parameter
        role=params["role_arn"],  # Use pipeline parameter
        instance_count=1,  # Placeholder, will be overridden by pipeline parameter value at runtime if needed by framework
        instance_type=params["instance_type"],  # Use pipeline parameter
        base_job_name=f"{BASE_JOB_PREFIX}-process",
        # instance_count needs special handling if passed directly, often set via parameters
    )

    # Define a single ProcessingStep to run both commands sequentially
    step_process = ProcessingStep(
        name="ProcessSample1Twice", # Step name reflects combined action
        processor=script_processor,
        inputs=[
            # Provide both config files as input
            ProcessingInput(
                source=params["config_file1"], destination="/opt/ml/processing/config1"
            ),
             ProcessingInput(
                source=params["config_file2"], destination="/opt/ml/processing/config2"
            ),
        ],
        outputs=[], # Define outputs if the combined process generates final output to S3
        code="infra/sagemaker/run_all_samples.py", # Use the new script
        # Pass both config directories to the script
        arguments=[
            "--config-dir1", "/opt/ml/processing/config1",
            "--config-dir2", "/opt/ml/processing/config2",
            # Add argument for intermediate output dir if needed by run_all_samples.py
            # "--intermediate-output-dir", "/opt/ml/processing/intermediate"
        ],
    )

    # Return the single combined step
    return [step_process]


# --- Define and Upsert Pipeline ---
def main():
    """Defines and upserts the SageMaker Pipeline using command-line arguments."""

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--pipeline-name",
        type=str,
        default=DEFAULT_PIPELINE_NAME,
        help="Name of the SageMaker Pipeline.",
    )
    parser.add_argument(
        "--role-arn",
        type=str,
        required=True,
        help="IAM Role ARN for pipeline execution/upsert.",
    )
    parser.add_argument(
        "--region",
        type=str,
        default=os.environ.get("AWS_REGION", "us-east-1"),
        help="AWS Region.",
    )
    # Add other arguments if needed for script execution context, but pipeline parameters handle runtime config
    args = parser.parse_args()

    sagemaker_session = get_sagemaker_session(args.region)

    # Define pipeline parameters (these are now required when *starting* the pipeline)
    parameters = define_parameters()
    # Define steps using these parameter objects
    steps = define_steps(parameters)

    pipeline = Pipeline(
        name=args.pipeline_name,
        parameters=list(parameters.values()),  # Pass the parameter objects
        steps=steps,
        sagemaker_session=sagemaker_session,
    )

    print(f"Upserting pipeline: {args.pipeline_name} in region {args.region}")
    # Use the role ARN provided via command line for the upsert operation
    pipeline.upsert(role_arn=args.role_arn)
    print("Pipeline upsert complete.")
    print(
        "Note: Pipeline parameters (Image URI, S3 paths, Instance Type/Count, ExecutionRoleArn for steps) must be provided when starting a pipeline run."
    )
