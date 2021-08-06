# Installing the Project

## Prerequisites

1. [AWS credentials configured](https://boto3.amazonaws.com/v1/documentation/api/1.9.42/guide/quickstart.html#configuration)
1. [Docker](https://www.docker.com/get-started)
1. [Terraform](https://www.terraform.io/) (if you are on the Infrastructure Team)

## Download and install

#### Download

```
git clone <this_repo>
```

#### Run the backend

```
cd services
docker-compose up
```

#### Run the Frontend

```
cd services/ui
npm install
npm start
```

## Validating the Install

http://localhost:8080/
