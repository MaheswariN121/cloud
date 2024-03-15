#!/bin/bash
# Set the AWS region

export AWS_DEFAULT_REGION="ap-south-1"

# Set HOME environment variable to the home directory of ec2-user
export HOME="/home/ec2-user"

# Function to log errors
log_error() {
    echo "Error: $1" >&2
}

# Function to log messages
log_message() {
    echo "$1"
}

# Update packages using yum
sudo yum update -y || { log_error "Failed to update packages using yum"; exit 1; }

# Change to the directory where the script is located
cd "$(dirname "$0")" || { log_error "Unable to change directory"; exit 1; }

# Check if the project directory exists
if [ ! -d "project" ]; then
    log_error "'project' directory not found"
    exit 1
fi

# Change to the 'project' directory
cd project || { log_error "Unable to change directory to 'project'"; exit 1; }


# Activate virtual environment
source test_env/bin/activate || { log_error "Unable to activate virtual environment"; exit 1; }

# Print the current working directory
current_directory=$(pwd)
log_message "The active directory is: $current_directory"

# Run your Python script
log_message "Running Python script..."
python aws.py || { log_error "Failed to execute Python script"; exit 1; }
EC2_INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2);
log_message $EC2_INSTANCE_ID
# Check if the "Shutdown" tag is set to "True" to determine whether to shut down the instance
Shutdown=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$EC2_INSTANCE_ID" "Name=key,Values=Shutdown" --query 'Tags[*].Value' --output text 2>/dev/null)

# Print the Shutdown tag value
log_message "Shutdown tag value: $Shutdown"

# Print the contents of the AWS credentials file
log_message "Contents of AWS credentials file:"
cat "$HOME/.aws/credentials"

# Check if the value of the "Shutdown" tag is "True"
if [ "$Shutdown" == "True" ]; then
    # Perform actions if the instance is set to shut down
    log_message "The instance is set to shut down."

    # Check if the IAM user or role has permissions to stop EC2 instances
    if ! aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID >/dev/null 2>&1; then
        log_error "Permission denied: Unable to describe EC2 instance"
        exit 1
    fi

    # Shut down the instance
    log_message "Shutting down the instance..."
    if aws ec2 stop-instances --instance-ids $EC2_INSTANCE_ID; then
        log_message "Instance shutdown request successful."
    else
        log_error "Failed to shut down the instance."
        exit 1
    fi
else
    log_message "The instance is not set to shut down."
fi
