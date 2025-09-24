import React from "react";
import ProductList from "./components/ProductList";

export default function App() {
  return (
    <div className="min-h-screen bg-gray-100">
      <h1 className="text-3xl font-bold text-center py-6">WHMCS Clone Shop</h1>
      <ProductList />
    </div>
  );
}
