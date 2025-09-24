const express = require("express");
const bodyParser = require("body-parser");
const routes = require("./routes");
const webhook = require("./webhook");
require("dotenv").config();

const app = express();

app.use(bodyParser.json());
app.use("/api", routes);
app.use("/api/webhook", webhook);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Backend draait op poort ${PORT}`);
});
