import express from 'express'
import cors from 'cors'

const app = express()
app.use(cors())

app.get('/', function (req, res) {
  res.send('<div style="padding: 2rem; font-family: system-ui, sans-serif;"><h1 style="color: #68a063; font-size: 2rem; font-weight: bold;">Express.js - It works!</h1><p style="margin-top: 1rem; color: #666;">Your Express.js application is running successfully.</p></div>')
})

app.get('/test', function (req, res, next) {
  res.json({msg: 'This is CORS-enabled for all origins!'})
})

export default app;
