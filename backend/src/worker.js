const axios = require("axios");
const Redis = require("ioredis");
require("dotenv").config();

const redis = new Redis(process.env.REDIS_URL);

async function processQueue() {
  console.log("Worker gestart: wacht op taken...");
  while (true) {
    const taskJson = await redis.blpop("provision_queue", 0);
    const task = JSON.parse(taskJson[1]);

    try {
      if (task.type === "vps") await createVPS(task);
      else if (task.type === "game") await createGameServer(task);
      console.log("Taak voltooid:", task.id);
    } catch (err) {
      console.error("Fout bij taak:", task.id, err.message);
    }
  }
}

async function createVPS(task) {
  const params = { key: process.env.VIRT_KEY, action: "create", hostname: task.hostname };
  const response = await axios.post(process.env.VIRT_URL, params);
  console.log("Virtualizor response:", response.data);
}

async function createGameServer(task) {
  const response = await axios.post(
    `${process.env.PTERODACTYL_URL}/api/application/servers`,
    task.serverData,
    {
      headers: {
        Authorization: `Bearer ${process.env.PTERODACTYL_API_KEY}`,
        "Content-Type": "application/json",
        Accept: "Application/vnd.pterodactyl.v1+json"
      }
    }
  );
  console.log("Pterodactyl response:", response.data);
}

processQueue().catch(console.error);
