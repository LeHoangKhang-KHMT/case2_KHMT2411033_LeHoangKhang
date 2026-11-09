require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/database');
const reminderService = require('./services/reminderService');

const PORT = process.env.PORT || 3000;

connectDB()
  .then(() => {
    app.listen(PORT, () => console.log(`API chay tai http://localhost:${PORT}`));
    reminderService.start();
  })
  .catch((err) => { console.error('Loi ket noi MongoDB:', err.message); process.exit(1); });