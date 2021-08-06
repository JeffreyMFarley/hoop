import 'whatwg-fetch'
import * as React from 'react'
import { act } from 'react-test-renderer'
import fetchMock from 'fetch-mock'
import { renderHook } from '@testing-library/react-hooks'
import useFetch, {
  MODE_ERROR, MODE_LOADING, MODE_SUCCESS
} from '../useFetch'

// ----------------------------------------------------------------------------
// Fixtures

const FIXTURE_URL = 'http://www.example.org'
const FIXTURE_PAYLOAD = {
  returnedData: 'foo'
}

// ----------------------------------------------------------------------------
// Tests

describe('hooks::useFetch', () => {
  // let target = null

  beforeAll(() => {
    global.fetch = fetch
    fetchMock.config.warnOnFallback = false
  })

  afterAll(() => {
    fetchMock.restore()
  })

  it('begins in loading mode', async () => {
    const { result } = renderHook(() => useFetch(FIXTURE_URL, {}))

    expect(result.current.mode).toEqual(MODE_LOADING)
    expect(result.current.response).toBe(null)
    expect(result.current.error).toBe(null)
  })

  it('should return data with a successful request', async () => {
    fetchMock.mock(FIXTURE_URL, FIXTURE_PAYLOAD)

    const { result } = renderHook(() => useFetch())

    await act(async () => {
      result.current.callOnce(FIXTURE_URL)
    })

    expect(result.current.mode).toEqual(MODE_SUCCESS)
    expect(result.current.response).toEqual(FIXTURE_PAYLOAD)
    expect(result.current.error).toBe(null)
    fetchMock.done()
  })

  it('handles HTTP errors', async () => {
    fetchMock.mock(FIXTURE_URL + '/not-there', 404)

    const { result } = renderHook(() => useFetch())

    await act(async () => {
      result.current.callOnce(FIXTURE_URL + '/not-there')
    })

    expect(result.current.mode).toEqual(MODE_ERROR)
    expect(result.current.response).toBe(null)
    expect(result.current.error).toEqual('HTTP error 404 - Not Found')
  })

  it('handles system errors', async () => {
    const { result } = renderHook(() => useFetch())

    await act(async () => {
      result.current.callOnce('/not/the/path')
    })

    expect(result.current.mode).toEqual(MODE_ERROR)
    expect(result.current.response).toBe(null)
    expect(result.current.error).toEqual(
      'fetch-mock: No fallback response defined for GET to /not/the/path'
    )
  })
})
