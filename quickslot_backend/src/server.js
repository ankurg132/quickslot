const app = require('./app');
const { initDb } = require('./config/db');

const PORT = process.env.PORT || 3000;

// Initialize database schema and then start Express server
initDb()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`QuickSlot backend server is running on http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.error('Failed to initialize database. Server shutting down.', err);
    process.exit(1);
  });
