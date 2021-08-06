import React from 'react';
import { Grid } from '@trussworks/react-uswds'
import useFetch, {
  MODE_ERROR, MODE_LOADING, MODE_SUCCESS
} from '../hooks/useFetch'

export function renderFortune( response, mode, err ) {
  switch ( mode ) {
    case MODE_LOADING:
      return <p>Loading...</p>;

    case MODE_ERROR:
      return <div><p>Error</p><p>{err}</p></div>

    case MODE_SUCCESS:
      return <p>{response.content}</p>
  }

  return <p>Unknown Mode: {mode}</p>
}

export default function Fortune() {
  // eslint-disable-next-line no-undef
  const { response, mode, err } = useFetch(URL_FORTUNES);

  return (
    <section className="grid-container usa-section">
        <Grid row gap>
          <Grid tablet={{ col: 4 }}>
            <h2 className="font-heading-xl margin-top-0 tablet:margin-bottom-0">
              Today's words of wisdom
            </h2>
          </Grid>
          <Grid tablet={{ col: 8 }} className="usa-prose">
            { renderFortune(response, mode, err) }
          </Grid>
        </Grid>
      </section>
  )
}
