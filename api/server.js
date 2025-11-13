import express from "express";

const app = express();
const PORT = process.env.PORT || 3000;

// Health endpoint
app.get("/health", (req, res) => {
    res.json({
        status: "ok",
        timestamp: new Date().toISOString()
    });
});

// Root fallback
app.get("/", (req, res) => {
    res.send("Hello DevOps! Lab 1");
});

app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});