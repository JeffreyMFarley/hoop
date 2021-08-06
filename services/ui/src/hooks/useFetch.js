import { useEffect, useState } from 'react';

export const MODE_LOADING = 'MODE_LOADING';
export const MODE_ERROR = 'MODE_ERROR';
export const MODE_SUCCESS = 'MODE_SUCCESS';

export default function useFetch(url, opts) {
  const [ response, setResponse ] = useState(null)
  const [ mode, setMode ] = useState(MODE_LOADING)
  const [ error, setError ] = useState(null)

  async function callOnce(_url, _opts) {
    try {
      const resp = await fetch(_url, _opts)
      if ( resp.ok ) {
        const data = await resp.json()
        setResponse(data)
        setMode(MODE_SUCCESS)
      } else {
        setError(`HTTP error ${ resp.status } - ${ resp.statusText }`)
        setMode(MODE_ERROR)
      }
    } catch (ex) {
      setError(ex.message)
      setMode(MODE_ERROR)
    }
  }

  useEffect(() => {
    if (url) {
      callOnce(url, opts)
    }
  }, [ url, opts ])

  return { response, mode, error, callOnce }
}
