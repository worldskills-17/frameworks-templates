const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const routes = require('./routes')

const app = express()
app.use(cors())
app.use(bodyParser.json())

app.get('/', (req, res) => {
  res.send('<div style="padding: 2rem; font-family: system-ui, sans-serif;"><h1 style="color: #4DB33D; font-size: 2rem; font-weight: bold;">Express + MongoDB - It works!</h1><p style="margin-top: 1rem; color: #666;">Your Express + MongoDB application is running successfully.</p></div>')
})

app.use(routes)

module.exports = app
