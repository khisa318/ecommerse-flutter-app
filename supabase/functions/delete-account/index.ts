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

  if (req.method !== "POST") {
    return jsonResponse({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getServiceRoleClient();

    const tableCleanup = [
      supabase.from("reviews").delete().eq("user_id", user.id),
      supabase.from("wishlist").delete().eq("user_id", user.id),
      supabase.from("cart_items").delete().eq("user_id", user.id),
      supabase.from("addresses").delete().eq("user_id", user.id),
      supabase.from("inbox_messages").delete().eq("user_id", user.id),
      supabase.from("profiles").delete().eq("id", user.id),
    ];

    const cleanupResults = await Promise.allSettled(tableCleanup);
    const failedCleanup = cleanupResults.find(
      (result) => result.status === "rejected",
    );

    if (failedCleanup?.status === "rejected") {
      throw failedCleanup.reason;
    }

    const { error: deleteUserError } = await supabase.auth.admin.deleteUser(
      user.id,
    );

    if (deleteUserError) {
      throw deleteUserError;
    }

    return jsonResponse({
      success: true,
      message: "Account deleted successfully",
    });
  } catch (error) {
    return jsonResponse(
      {
        success: false,
        error: error instanceof Error ? error.message : "Unknown deletion error",
      },
      500,
    );
  }
});
