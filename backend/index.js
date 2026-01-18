const express = require("express");
const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.send("Zenith backend running 🚀");
});

app.listen(5000, () => {
  console.log("Backend running on port 5000");
});
