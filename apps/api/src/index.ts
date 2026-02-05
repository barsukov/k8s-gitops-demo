import express, { Request, Response } from 'express'

const app = express()
const port = process.env.PORT || 3000

// Middleware
app.use(express.json())

// Health check endpoint
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  })
})

// Main API endpoint
app.get('/api/hello', (_req: Request, res: Response) => {
  res.json({
    message: 'Hello from the API!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  })
})

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Not found' })
})

// Start server
app.listen(port, () => {
  console.log(`API server running on port ${port}`)
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`)
})
