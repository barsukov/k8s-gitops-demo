import { useState, useEffect } from 'react'

interface ApiResponse {
  message: string
  timestamp: string
  environment: string
}

function App() {
  const [data, setData] = useState<ApiResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/hello')
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json()
      })
      .then((data: ApiResponse) => {
        setData(data)
        setLoading(false)
      })
      .catch((err) => {
        setError(err.message)
        setLoading(false)
      })
  }, [])

  return (
    <div className="container">
      <h1>K8s GitOps Demo</h1>
      <div className="card">
        <h2>API Response</h2>
        {loading && <p className="loading">Loading...</p>}
        {error && <p className="error">Error: {error}</p>}
        {data && (
          <div className="response">
            <p><strong>Message:</strong> {data.message}</p>
            <p><strong>Environment:</strong> {data.environment}</p>
            <p><strong>Timestamp:</strong> {data.timestamp}</p>
          </div>
        )}
      </div>
      <footer>
        <p>Deployed with ArgoCD</p>
      </footer>
    </div>
  )
}

export default App
