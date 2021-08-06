# API Development

The initial version of this repo has several examples of an API solution.
None of these services are "sacred", they are there to demonstrate capabilities.

##### `/api`

This is a Java backend generated via JHipster. It is not currently deployed in AWS

##### `/fortunes`

This is an [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html) function written in Python.
When called, it generates a random fortune.
It was created to demonstrate Lambda functions from a Docker image

#### `/heroes`

This is a Flask application, written in Python.
It acts as a basic CRUD application that interacts with the database
It is deployed in [ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html)

#### `/names`

This is a Flask application, written in Python.
Based on the subpath it is called with, it will generate 10 random words of a certain kind.
It is deployed in [ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html)

## Building the images

```
cd services
docker-compose build [service]
```
