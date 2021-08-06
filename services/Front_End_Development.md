# Front End Development

The front end uses React with [USWDS components](https://github.com/trussworks/react-uswds) to deliver its experience

### Prerequisites

The solution uses Node v14 for compatibility with the USWDS components.
The version is included in the `.nvmrc` for those that use `nvm` to maintain versions

### Optional - Working with local services

If you are developing against API code that has not been deployed, you can redirect the API calls to the services running in Docker.

The following environment variables should be set before building or running:

Environment Variable | Applies to | Likely value
---|---|---
URL_FORTUNES|Fortune service|http://localhost:9000
URL_NAMES|Names service|http://localhost:5000

The definitive list of names is in the `webpack.config` file

### Building

```
npm install
npm run build
```

### Executing

```
npm start
```

The application should be available at http://localhost:8080

### Code Quality

- We use [ESLint](https://eslint.org/) to ensure Javascript standards

### Testing

- We use [Jest](https://jestjs.io/) to run the unit tests
