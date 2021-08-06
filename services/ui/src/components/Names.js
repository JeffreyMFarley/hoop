import React from 'react';
import { Grid } from '@trussworks/react-uswds'
import useFetch, {
  MODE_ERROR, MODE_LOADING, MODE_SUCCESS
} from '../hooks/useFetch'

export const apiMap = {
  brute: 'Brutethink Words',
  easy: 'Good for Server Names',
  name: 'People Names',
  star: 'Brightest Stars',
  noun: 'Nouns',
  verb: 'Verbs'
}

export function renderNames( response, mode, err, kind ) {
  switch ( mode ) {
    case MODE_LOADING:
      return <p>Loading...</p>;

    case MODE_ERROR:
      return <div><p>Error</p><p>{err}</p></div>

    case MODE_SUCCESS:
      return (<>
        <Grid tablet={{ col: 1 }}>
          <h3>{apiMap[kind]}</h3>
        </Grid>
        <Grid tablet={{ col: 11 }}>
          <ul>{
            response.map((name, i) =>
              <li key={i}>{name}</li>
            )
          }</ul>
        </Grid>
      </>)
  }

  return <p>Unknown Mode: {mode}</p>
}

export default function Names(props) {
  // eslint-disable-next-line no-undef
  const { response, mode, err } = useFetch(URL_NAMES + props.kind);

  return (
    <section className="grid-container usa-section">
        <Grid row gap>
          {renderNames(response, mode, err, props.kind)}
        </Grid>
      </section>
  )
}
