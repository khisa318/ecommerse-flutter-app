import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";
import type { Database, Json, TablesInsert } from "./database.types.ts";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-callback-secret",
};

export type MpesaConfig = {
  baseUrl: string;
  consumerKey: string;
  consumerSecret: string;
  shortcode: string;
  passkey: string;
  callbackSecret: string | null;
};

export function getServiceRoleClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Missing Supabase server credentials");
  }

  return createClient<Database>(supabaseUrl, serviceRoleKey);
}

export async function getAuthenticatedUser(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const authHeader = req.headers.get("Authorization") ?? "";

  if (!supabaseUrl || !anonKey) {
    throw new Error("Missing Supabase auth validation configuration");
  }

  if (!authHeader.startsWith("Bearer ")) {
    throw new Error("Missing bearer token");
  }

  const token = authHeader.replace("Bearer ", "").trim();
  const supabase = createClient<Database>(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  });

  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    throw new Error("Unauthorized request");
  }

  return data.user;
}

export function getMpesaConfig(): MpesaConfig {
  const environment = (Deno.env.get("MPESA_ENV") ?? "sandbox").toLowerCase();
  const baseUrl = environment === "production"
    ? "https://api.safaricom.co.ke"
    : "https://sandbox.safaricom.co.ke";

  const consumerKey = Deno.env.get("MPESA_CONSUMER_KEY") ?? "";
  const consumerSecret = Deno.env.get("MPESA_CONSUMER_SECRET") ?? "";
  const shortcode = Deno.env.get("MPESA_SHORTCODE") ?? "";
  const passkey = Deno.env.get("MPESA_PASSKEY") ?? "";
  const callbackSecret = Deno.env.get("MPESA_CALLBACK_SECRET");

  if (!consumerKey || !consumerSecret || !shortcode || !passkey) {
    throw new Error("Missing one or more M-Pesa environment variables");
  }

  return {
    baseUrl,
    consumerKey,
    consumerSecret,
    shortcode,
    passkey,
    callbackSecret: callbackSecret ?? null,
  };
}

export async function generateAccessToken(config: MpesaConfig) {
  const credentials = btoa(`${config.consumerKey}:${config.consumerSecret}`);

  const response = await fetch(
    `${config.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    {
      headers: {
        Authorization: `Basic ${credentials}`,
      },
    },
  );

  const data = await response.json();
  if (!response.ok || !data.access_token) {
    throw new Error("Could not generate M-Pesa access token");
  }

  return data.access_token as string;
}

export function generateTimestamp() {
  const now = new Date();
  const yyyy = now.getFullYear().toString();
  const mm = `${now.getMonth() + 1}`.padStart(2, "0");
  const dd = `${now.getDate()}`.padStart(2, "0");
  const hh = `${now.getHours()}`.padStart(2, "0");
  const min = `${now.getMinutes()}`.padStart(2, "0");
  const ss = `${now.getSeconds()}`.padStart(2, "0");
  return `${yyyy}${mm}${dd}${hh}${min}${ss}`;
}

export function normalizePhoneNumber(phoneNumber: string) {
  const digitsOnly = phoneNumber.replace(/\D/g, "");

  if (/^254\d{9}$/.test(digitsOnly)) {
    return digitsOnly;
  }

  if (/^0\d{9}$/.test(digitsOnly)) {
    return `254${digitsOnly.slice(1)}`;
  }

  if (/^\d{9}$/.test(digitsOnly)) {
    return `254${digitsOnly}`;
  }

  throw new Error("Phone number must be a valid Kenyan M-Pesa line");
}

export function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export async function logPaymentEvent(
  supabase: SupabaseClient<Database>,
  {
    paymentId,
    orderId,
    eventType,
    eventPayload,
  }: {
    paymentId?: number | null;
    orderId: number;
    eventType: string;
    eventPayload: Json;
  },
) {
  const payload: TablesInsert<"payment_logs"> = {
    payment_id: paymentId ?? null,
    order_id: orderId,
    event_type: eventType,
    event_payload: eventPayload,
  };

  await supabase.from("payment_logs").insert(payload);
}
