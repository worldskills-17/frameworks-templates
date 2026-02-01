const { MongoClient, ObjectId } = require('mongodb')

const connectionUrl = process.env.MONGO_URI || 'mongodb://localhost:27017'
const dbName = process.env.MONGO_DB || 'store'

let db

const init = () =>
  MongoClient.connect(connectionUrl).then((client) => {
    db = client.db(dbName)
  })

const insertItem = (item) => {
  const collection = db.collection('items')
  return collection.insertOne(item)
}

const getItems = () => {
  const collection = db.collection('items')
  return collection.find({}).toArray()
}

const updateQuantity = (id, quantity) => {
  const collection = db.collection('items')
  return collection.updateOne({ _id: new ObjectId(id) }, { $inc: { quantity } })
}

module.exports = { init, insertItem, getItems, updateQuantity }
