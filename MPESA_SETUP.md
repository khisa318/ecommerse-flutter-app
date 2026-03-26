# M-Pesa Backend API Setup

This project uses Supabase Edge Functions as the backend API for Safaricom Daraja STK Push.

## Endpoints

- `POST /functions/v1/stkpush`
- `POST /functions/v1/callback`
- `GET /functions/v1/payment-status?order_id=<id>`

## Request body for `POST /stkpush`

```json
{
  "phone_number": "0712345678",
  "amount": 1500,
  "order_id": 23
}
```

## Daraja request sent by the backend

```json
{
  "BusinessShortCode": "174379",
  "Password": "<BASE64(shortcode + passkey + timestamp)>",
  "Timestamp": "20260326095018",
  "Amount": 1,
  "PartyA": "254703444377",
  "PartyB": "174379",
  "TransactionType": "CustomerPayBillOnline",
  "PhoneNumber": "254703444377",
  "TransactionDesc": "Cyberspex order 23",
  "AccountReference": "ORDER-23",
  "CallBackURL": "https://<your-project-ref>.supabase.co/functions/v1/callback"
}
```

The backend sends that payload to:

- Sandbox: `https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest`
- Production: `https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest`

It gets the OAuth token from:

- Sandbox: `https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials`
- Production: `https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials`

## Example success response from `POST /stkpush`

```json
{
  "success": true,
  "message": "STK Push initiated successfully",
  "order_id": 23,
  "checkout_request_id": "ws_CO_123456789",
  "customer_message": "Success. Request accepted for processing",
  "payment_status": "pending"
}
```

## Example callback success response

```json
{
  "success": true,
  "message": "Callback processed successfully",
  "result_code": 0,
  "order_id": 23,
  "payment_status": "paid",
  "mpesa_receipt_number": "T123ABC456",
  "amount": 1500,
  "phone_number": "254712345678"
}
```

## Environment variables

Set these secrets in Supabase:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`
- `MPESA_ENV`
- `MPESA_CONSUMER_KEY`
- `MPESA_CONSUMER_SECRET`
- `MPESA_SHORTCODE`
- `MPESA_PASSKEY`
- `MPESA_CALLBACK_SECRET`

Recommended:

- `MPESA_ENV=sandbox`
- use `MPESA_ENV=production` only with live Daraja credentials

`MPESA_CALLBACK_SECRET` is optional, but recommended if you want to validate callback requests with a shared secret.

## SQL setup

Run:

- `supabase_mpesa_setup.sql`

This creates:

- `payments`
- `payment_logs`

It also adds indexes, RLS policies, and an `updated_at` trigger.

## Deploy functions

```bash
supabase functions deploy stkpush
supabase functions deploy callback
supabase functions deploy payment-status
```

## Notes

1. The frontend should only call `stkpush`.
2. Daraja credentials stay on the server only.
3. `callback` updates `payments` and `orders`.
4. Duplicate active payments are blocked.
5. Paid orders are protected from being charged again.
6. The callback URL should be your deployed Supabase function, not a placeholder domain.
