const express = require('express')
const Joi = require('joi')
const { insertItem, getItems, updateQuantity } = require('./db')

const router = express.Router()

const itemSchema = Joi.object().keys({
  name: Joi.string(),
  quantity: Joi.number().integer().min(0)
})

// Express 5 forwards errors thrown in async handlers to the error handler;
// the try/catch blocks below keep the empty 500 responses of this example.

router.post('/item', async (req, res) => {
  // Express 5 leaves req.body undefined when no JSON body was sent
  const item = req.body ?? {}
  console.log(item)
  const result = itemSchema.validate(item)
  if (result.error) {
    console.log(result.error)
    res.status(400).end()
    return
  }
  try {
    await insertItem(item)
    res.status(200).end()
  } catch (err) {
    console.log(err)
    res.status(500).end()
  }
})

router.get('/items', async (req, res) => {
  try {
    const items = await getItems()
    res.json(items.map((item) => ({
      id: item._id,
      name: item.name,
      quantity: item.quantity
    })))
  } catch (err) {
    console.log(err)
    res.status(500).end()
  }
})

router.put('/item/:id/quantity/:quantity', async (req, res) => {
  const { id, quantity } = req.params
  try {
    await updateQuantity(id, parseInt(quantity))
    res.status(200).end()
  } catch (err) {
    console.log(err)
    res.status(500).end()
  }
})

module.exports = router
