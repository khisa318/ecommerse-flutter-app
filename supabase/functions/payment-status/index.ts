import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  corsHeaders,
  getAuthenticatedUser,
  getServiceRoleClient,
  jsonResponse,
} from "../_shared/mpesa.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "GET") {
    return jsonResponse({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const user = await getAuthenticatedUser(req);
    const url = new URL(req.url);
    const orderId = Number(url.searchParams.get("order_id"));

    if (!orderId) {
      return jsonResponse(
        { success: false, error: "order_id query parameter is required" },
        400,
      );
    }

    const supabase = getServiceRoleClient();
    const { data, error } = await supabase
      .from("payments")
      .select(`
        id,
        order_id,
        user_id,
        amount,
        phone_number,
        status,
        customer_message,
        mpesa_receipt_number,
        result_code,
        result_desc,
        checkout_request_id,
        created_at,
        updated_at
      `)
      .eq("order_id", orderId)
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      return jsonResponse({ success: false, error: error.message }, 500);
    }

    if (!data) {
      return jsonResponse({ success: false, error: "Payment not found" }, 404);
    }

    return jsonResponse({ success: true, payment: data });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error";
    const status = message.toLowerCase().includes("unauthorized") ? 401 : 500;
    return jsonResponse({ success: false, error: message }, status);
  }
});
