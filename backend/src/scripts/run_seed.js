const pool = require("../db");

async function seed() {
  await pool.query(`CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, email TEXT)`);
  console.log("Database seed voltooid");
  process.exit(0);
}

seed();
