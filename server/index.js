import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { Configuration, PlaidApi, PlaidEnvironments } from 'plaid';

const app = express();
app.use(cors());
app.use(express.json());

const config = new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV || 'sandbox'],
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET': process.env.PLAID_SECRET,
    },
  },
});
const plaid = new PlaidApi(config);

// naive in-memory store per-demo (replace with DB if needed)
let ACCESS_TOKEN = null;

app.post('/link_token', async (req, res) => {
  try {
    const { userId = 'demo-user-123' } = req.body || {};
    const r = await plaid.linkTokenCreate({
      user: { client_user_id: userId },
      client_name: 'Blue Budget',
      products: ['transactions'],
      country_codes: ['US'],
      language: 'en',
    });
    res.json({ link_token: r.data.link_token });
  } catch (e) {
    console.error(e.response?.data || e);
    res.status(500).json({ error: 'link_token_failed' });
  }
});

app.post('/exchange_public_token', async (req, res) => {
  try {
    const { public_token } = req.body;
    const r = await plaid.itemPublicTokenExchange({ public_token });
    ACCESS_TOKEN = r.data.access_token;
    res.json({ access_token: ACCESS_TOKEN });
  } catch (e) {
    console.error(e.response?.data || e);
    res.status(500).json({ error: 'exchange_failed' });
  }
});

app.get('/transactions', async (req, res) => {
  try {
    if (!ACCESS_TOKEN) return res.status(400).json({ error: 'no_access_token' });

    const end = new Date();
    const start = new Date();
    start.setMonth(end.getMonth() - 1);

    const r = await plaid.transactionsGet({
      access_token: ACCESS_TOKEN,
      start_date: start.toISOString().slice(0, 10),
      end_date: end.toISOString().slice(0, 10),
      options: { count: 250 },
    });
    res.json(r.data);
  } catch (e) {
    console.error(e.response?.data || e);
    res.status(500).json({ error: 'transactions_failed' });
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Plaid server listening on ${port}`));
