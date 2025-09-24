import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLIC_KEY);

export default function ProductList() {
  const [loading, setLoading] = useState(false);

  const products = [
    { id: 1, name: "VPS Basic", type: "vps", price: 5, planId: 1 },
    { id: 2, name: "Game Server Small", type: "game", price: 10, planId: 2 }
  ];

  const handleCheckout = async (product) => {
    setLoading(true);
    try {
      const res = await fetch("/api/create-checkout-session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productId: product.id,
          type: product.type,
          planId: product.planId,
          hostname: `user-${Math.floor(Math.random() * 10000)}`
        })
      });
      const session = await res.json();
      const stripe = await stripePromise;
      await stripe.redirectToCheckout({ sessionId: session.id });
    } catch (err) {
      alert("Er is een fout opgetreden bij Stripe Checkout");
    }
    setLoading(false);
  };

  return (
    <div className="p-8 grid gap-4 md:grid-cols-2">
      {products.map((p) => (
        <div key={p.id} className="border rounded p-4 shadow hover:shadow-lg transition">
          <h2 className="text-xl font-bold mb-2">{p.name}</h2>
          <p>Prijs: ${p.price}/maand</p>
          <button
            onClick={() => handleCheckout(p)}
            disabled={loading}
            className="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
          >
            {loading ? "Verwerken..." : "Bestellen"}
          </button>
        </div>
      ))}
    </div>
  );
}
