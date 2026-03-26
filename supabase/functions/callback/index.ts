import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  corsHeaders,
  getMpesaConfig,
  getServiceRoleClient,
  jsonResponse,
  logPaymentEvent,
} from "../_shared/mpesa.ts";
import type { Json, TablesUpdate } from "../_shared/database.types.ts";

type CallbackMetadataItem = {
  Name?: string;
  Value?: unknown;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const mpesaConfig = getMpesaConfig();
    const callbackSecret = req.headers.get("x-callback-secret");

    if (
      mpesaConfig.callbackSecret &&
      callbackSecret !== mpesaConfig.callbackSecret
    ) {
      return jsonResponse(
        { success: false, error: "Invalid callback secret" },
        401,
      );
    }

    const payload = await req.json();
    const callback = payload?.Body?.stkCallback;

    if (!callback?.CheckoutRequestID) {
      return jsonResponse({ success: false, error: "Invalid callback payload" }, 400);
    }

    const supabase = getServiceRoleClient();
    const checkoutRequestId = callback.CheckoutRequestID.toString();
    const metadataItems: CallbackMetadataItem[] = Array.isArray(
        callback.CallbackMetadata?.Item,
      )
      ? callback.CallbackMetadata.Item
      : [];

    const amount = findMetadataValue(metadataItems, "Amount");
    const mpesaReceiptNumber = findMetadataValue(metadataItems, "MpesaReceiptNumber");
    const phoneNumber = findMetadataValue(metadataItems, "PhoneNumber");
    const transactionDate = findMetadataValue(metadataItems, "TransactionDate");
    const resultCode = Number(callback.ResultCode ?? 1);
    const nextPaymentStatus = resultCode === 0 ? "paid" : "failed";
    const nextOrderStatus = resultCode === 0 ? "paid" : "payment_failed";

    const { data: paymentRecord, error: paymentLookupError } = await supabase
      .from("payments")
      .select("id, order_id, status")
      .eq("checkout_request_id", checkoutRequestId)
      .maybeSingle();

    if (paymentLookupError) {
      return jsonResponse({ success: false, error: paymentLookupError.message }, 500);
    }

    if (!paymentRecord) {
      return jsonResponse({ success: false, error: "Payment record not found" }, 404);
    }

    if (paymentRecord.status === "paid") {
      await logPaymentEvent(supabase, {
        paymentId: paymentRecord.id,
        orderId: Number(paymentRecord.order_id),
        eventType: "callback_duplicate_paid",
        eventPayload: payload as Json,
      });

      return jsonResponse({ success: true, message: "Callback already processed" });
    }

    const paymentUpdate: TablesUpdate<"payments"> = {
      result_code: resultCode,
      result_desc: callback.ResultDesc?.toString(),
      status: nextPaymentStatus,
      mpesa_receipt_number: mpesaReceiptNumber?.toString(),
      phone_number: phoneNumber?.toString(),
      transaction_date: transactionDate?.toString(),
      callback_payload: payload as Json,
    };

    if (amount != null) {
      paymentUpdate.amount = Number(amount);
    }

    const { error: paymentUpdateError } = await supabase
      .from("payments")
      .update(paymentUpdate)
      .eq("id", paymentRecord.id);

    if (paymentUpdateError) {
      return jsonResponse({ success: false, error: paymentUpdateError.message }, 500);
    }

    const { error: orderUpdateError } = await supabase
      .from("orders")
      .update({ status: nextOrderStatus })
      .eq("id", paymentRecord.order_id);

    if (orderUpdateError) {
      return jsonResponse({ success: false, error: orderUpdateError.message }, 500);
    }

    await logPaymentEvent(supabase, {
      paymentId: paymentRecord.id,
      orderId: Number(paymentRecord.order_id),
      eventType: resultCode === 0 ? "callback_paid" : "callback_failed",
      eventPayload: payload as Json,
    });

    if (resultCode === 0) {
      const { data: orderItems, error: orderItemsError } = await supabase
        .from("order_items")
        .select("product_id, quantity")
        .eq("order_id", paymentRecord.order_id);

      if (orderItemsError) {
        return jsonResponse({ success: false, error: orderItemsError.message }, 500);
      }

      for (const item of orderItems ?? []) {
        const { error: stockError } = await supabase.rpc("reduce_stock", {
          product_id: Number(item.product_id),
          qty: Number(item.quantity),
        });

        if (stockError) {
          return jsonResponse({ success: false, error: stockError.message }, 500);
        }
      }
    }

    return jsonResponse({
      success: true,
      message: "Callback processed successfully",
      result_code: resultCode,
      order_id: paymentRecord.order_id,
      payment_status: nextPaymentStatus,
      mpesa_receipt_number: mpesaReceiptNumber?.toString() ?? null,
      amount: amount != null ? Number(amount) : null,
      phone_number: phoneNumber?.toString() ?? null,
    });
  } catch (error) {
    return jsonResponse(
      {
        success: false,
        error: error instanceof Error ? error.message : "Unknown callback error",
      },
      500,
    );
  }
});

function findMetadataValue(items: CallbackMetadataItem[], name: string) {
  return items.find((item) => item.Name === name)?.Value;
}
