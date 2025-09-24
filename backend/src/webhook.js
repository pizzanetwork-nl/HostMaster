const express = require("express");
const bodyParser = require("body-parser");
const Stripe = require("stripe");
const Redis = require("ioredis");
require("dotenv").config();

const stripe = Stripe(process.env.STRIPE_SECRET);
const redis = new Redis(process.env.REDIS_URL);

const app = express();
app.post("/", bodyParser.raw({ type: "application/json" }), async (req, res) => {
  const sig = req.headers["stripe-signature"];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const task = {
      id: session.id,
      type: session.metadata.type,
      user: session.customer_email,
      planId: session.metadata.planId,
      hostname: session.metadata.hostname,
      serverData: session.metadata.serverData ? JSON.parse(session.metadata.serverData) : {}
    };
    await redis.rpush("provision_queue", JSON.stringify(task));
  }

  res.json({ received: true });
});

module.exports = app;
