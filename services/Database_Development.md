# Database Development

For now, the only schema script is inside the `postgres/sql` directory.

##### `/postgres`

This serves as the "local" version of the database.
It is intended to be used as part of local development before deploying changes to "production"

## Run the database locally

```
cd services
docker-compose up
```

You will be able to access the PostGRES instance at http://localhost:5432.
The username and password are in the `docker-compose.yml` file
