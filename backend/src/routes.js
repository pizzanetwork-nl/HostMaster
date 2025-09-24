const express = require("express");
const router = express.Router();
const Stripe = require("stripe");
require("dotenv").config();

const stripe = Stripe(process.env.STRIPE_SECRET);

router.post("/create-checkout-session", async (req, res) => {
  const { productId, type, planId, hostname } = req.body;
  const session = await stripe.checkout.sessions.create({
    payment_method_types: ["card"],
    mode: "subscription",
    line_items: [
      {
        price_data: {
          currency: "usd",
          product_data: { name: type === "vps" ? `VPS ${planId}` : `Game Server ${planId}` },
          unit_amount: type === "vps" ? 500 : 1000
        },
        quantity: 1
      }
    ],
    metadata: { type, planId, hostname, serverData: JSON.stringify({}) },
    success_url: `${process.env.PUBLIC_URL}/success`,
    cancel_url: `${process.env.PUBLIC_URL}/cancel`
  });
  res.json({ id: session.id });
});

module.exports = router;
