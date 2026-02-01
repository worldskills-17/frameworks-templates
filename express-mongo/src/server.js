require('dotenv').config()
const { init } = require('./db')
const app = require('./app')

const port = process.env.PORT || 80

init().then(() => {
  console.log(`Listening on http://localhost:${port}`)
  app.listen(port, '0.0.0.0')
})
