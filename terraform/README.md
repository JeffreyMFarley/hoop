# Running the Infrastructure

This project uses Terraform to provision and maintain the state of the application in AWS.

### Setting Up Your Workstation

1. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/certification-associate-tutorials#install-terraform)
1. Clone this repo
1. `cd terraform`
1. `terraform login`
1. `terraform init`
    ```
    Initializing modules...

    Initializing the backend...

    Initializing provider plugins...
    - Reusing previous version of hashicorp/random from the dependency lock file
    - Reusing previous version of hashicorp/aws from the dependency lock file
    - Using previously-installed hashicorp/random v3.1.0
    - Using previously-installed hashicorp/aws v3.42.0

    Terraform has been successfully initialized!
    ```

### Create a new AWS account

1. Create a new CI user in AWS
    1. Start with Admin, but use CloudTrail to audit permissions and then make the correct policy
    2. [Here are the ones I found for the Fargate version](https://github.com/JeffreyMFarley/hoop/wiki/CI-permissions)
    3. Generate a token for the new user
1. Update the AWS variables
    1. In GitHub Secrets
    1. IN a local `.env` file

### Create the Route 53 Hosted Zone

[Details here](https://github.com/JeffreyMFarley/hoop/wiki/Route53)

### Run `terraform`

As of now, we are not able to simply run `terraform apply` to create everything.
It has to be run several times before it is complete.

What follows is the most recent steps I have had to use

1. Perform the initial apply to create the buckets and image repositories
    ```
    $ terraform apply -target=module.image_repo
    $ terraform apply -target=module.www_buckets
    ```
1.  Use the GitHub actions to
    1. Deploy the website
    1. Deploy any service images to ECR
1. If there are errors using the GitHub actions to deploy the images
    ```
    cd services
    docker-compose build
    <set your AWS credentials>
    aws ecr get-login-password | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
    docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fortunes
    docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/heroes
    docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/names
    ```
1. Perform a second apply
    ```
    $ terraform apply

    ...
    POSTGRES_DB = "main"
    POSTGRES_HOST = "main.foobar.us-east-1.rds.amazonaws.com"
    POSTGRES_USER = "postgres"
    cloudfront_id = "FOOBAR"
    image_repo_fortunes = "<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fortunes"
    image_repo_heroes = "<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/heroes"
    image_repo_names = "<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/names"
    static_web_bucket = "www.esotericsoftware.com"
    url_api = "https://api.esotericsoftware.com/"
    url_static_web = "https://www.esotericsoftware.com/"    
    ```
