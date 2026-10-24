require('dotenv').config({ quiet: true })
const { init } = require('./db')
const app = require('./app')

const port = process.env.PORT || 80

init().then(() => {
  // Express 5 passes listen errors (e.g. EADDRINUSE) to this callback
  app.listen(port, '0.0.0.0', (error) => {
    if (error) {
      throw error
    }
    console.log(`Listening on http://localhost:${port}`)
  })
})
