import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  corsHeaders,
  generateAccessToken,
  generateTimestamp,
  getAuthenticatedUser,
  getMpesaConfig,
  getServiceRoleClient,
  jsonResponse,
  logPaymentEvent,
  normalizePhoneNumber,
} from "../_shared/mpesa.ts";

type StkPushRequest = {
  phone_number?: string;
  amount?: number;
  order_id?: number;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const user = await getAuthenticatedUser(req);
    const body = await req.json() as StkPushRequest;

    const orderId = Number(body.order_id);
    const amount = Number(body.amount);
    const phoneNumber = normalizePhoneNumber(body.phone_number ?? "");

    if (!orderId || !amount || amount < 1) {
      return jsonResponse(
        {
          success: false,
          error: "phone_number, amount and order_id are required",
        },
        400,
      );
    }

    const supabase = getServiceRoleClient();
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, user_id, total_price, status")
      .eq("id", orderId)
      .maybeSingle();

    if (orderError) {
      return jsonResponse({ success: false, error: orderError.message }, 500);
    }

    if (!order) {
      return jsonResponse({ success: false, error: "Order not found" }, 404);
    }

    if (order.user_id !== user.id) {
      return jsonResponse(
        { success: false, error: "You do not have access to this order" },
        403,
      );
    }

    if (Number(order.total_price) !== Math.round(amount)) {
      return jsonResponse(
        { success: false, error: "Amount does not match the order total" },
        400,
      );
    }

    const { data: existingPayment, error: existingPaymentError } = await supabase
      .from("payments")
      .select("id, status, checkout_request_id, customer_message")
      .eq("order_id", orderId)
      .in("status", ["initiated", "pending", "paid"])
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingPaymentError) {
      return jsonResponse(
        { success: false, error: existingPaymentError.message },
        500,
      );
    }

    if (existingPayment?.status === "paid") {
      return jsonResponse(
        {
          success: false,
          error: "Order has already been paid",
          payment_status: existingPayment.status,
        },
        409,
      );
    }

    if (
      existingPayment?.status === "initiated" ||
      existingPayment?.status === "pending"
    ) {
      return jsonResponse(
        {
          success: false,
          error: "A payment request is already in progress for this order",
          payment_status: existingPayment.status,
          checkout_request_id: existingPayment.checkout_request_id,
          customer_message: existingPayment.customer_message,
        },
        409,
      );
    }

    const mpesaConfig = getMpesaConfig();
    const accessToken = await generateAccessToken(mpesaConfig);
    const timestamp = generateTimestamp();
    const password = btoa(
      `${mpesaConfig.shortcode}${mpesaConfig.passkey}${timestamp}`,
    );
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const callbackUrl = `${supabaseUrl}/functions/v1/callback`;

    const stkPayload = {
      BusinessShortCode: mpesaConfig.shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: Math.round(amount),
      PartyA: phoneNumber,
      PartyB: mpesaConfig.shortcode,
      PhoneNumber: phoneNumber,
      CallBackURL: callbackUrl,
      AccountReference: `ORDER-${orderId}`,
      TransactionDesc: `Cyberspex order ${orderId}`,
    };

    const stkResponse = await fetch(
      `${mpesaConfig.baseUrl}/mpesa/stkpush/v1/processrequest`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(stkPayload),
      },
    );

    const stkData = await stkResponse.json();

    if (!stkResponse.ok) {
      await logPaymentEvent(supabase, {
        orderId,
        eventType: "stkpush_failed_http",
        eventPayload: stkData,
      });

      return jsonResponse(
        {
          success: false,
          error: "Safaricom rejected the STK Push request",
          details: stkData,
        },
        400,
      );
    }

    const paymentStatus = stkData.ResponseCode?.toString() === "0"
      ? "pending"
      : "failed";

    const { data: createdPayment, error: paymentError } = await supabase
      .from("payments")
      .insert({
        order_id: orderId,
        user_id: user.id,
        phone_number: phoneNumber,
        amount: Math.round(amount),
        merchant_request_id: stkData.MerchantRequestID?.toString(),
        checkout_request_id: stkData.CheckoutRequestID?.toString(),
        response_code: stkData.ResponseCode?.toString(),
        response_description: stkData.ResponseDescription?.toString(),
        customer_message: stkData.CustomerMessage?.toString(),
        status: paymentStatus,
        raw_request: stkPayload,
        raw_response: stkData,
      })
      .select("id, checkout_request_id, customer_message, status")
      .single();

    if (paymentError) {
      return jsonResponse(
        { success: false, error: paymentError.message },
        500,
      );
    }

    await supabase
      .from("orders")
      .update({
        status: paymentStatus === "pending"
          ? "payment_pending"
          : "payment_failed",
      })
      .eq("id", orderId);

    await logPaymentEvent(supabase, {
      paymentId: createdPayment.id,
      orderId,
      eventType: "stkpush_requested",
      eventPayload: stkData,
    });

    return jsonResponse({
      success: true,
      message: "STK Push initiated successfully",
      order_id: orderId,
      checkout_request_id: createdPayment.checkout_request_id,
      customer_message: createdPayment.customer_message,
      payment_status: createdPayment.status,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error";
    const status = message.toLowerCase().includes("unauthorized") ? 401 : 500;
    return jsonResponse({ success: false, error: message }, status);
  }
});
