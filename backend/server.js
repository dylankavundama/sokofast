const express = require('express');
const stripe = require('stripe')('sk_test_YOUR_ACTUAL_TEST_SECRET_KEY'); // <-- Use your test secret key here
const bodyParser = require('body-parser');

const app = express();
const port = 80; // Or any port you prefer

app.use(bodyParser.json());

app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency, paymentMethodId } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      payment_method: paymentMethodId,
      confirm: true,
      return_url: 'stripe://redirect', // Important for 3D Secure redirect (Flutter Stripe handles this)
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Error creating PaymentIntent:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Backend server listening at http://localhost:${port}`);
});