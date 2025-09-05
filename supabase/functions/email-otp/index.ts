// functions/email-otp/index.ts
// Deno Edge Function for sending and verifying email OTPs via Resend
// Endpoint: POST /email-otp  { action: "send" | "verify", email, code? }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const RESEND_FROM = Deno.env.get("RESEND_FROM")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function isValidEmail(email: string) {
  return /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(email);
}

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6 digits
}

async function sendEmail(to: string, code: string) {
  const subject = "Your ChatAI verification code";
  const text = ;
  const html = ;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": ,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      from: RESEND_FROM,
      to: [to],
      subject,
      text,
      html
    })
  });
  if (!res.ok) {
    const msg = await res.text();
    throw new Error();
  }
}

async function handleSend(email: string) {
  if (!isValidEmail(email)) {
    return new Response("Invalid email", { status: 400 });
  }

  const code = generateCode();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 10 * 60 * 1000); // 10 minutes

  const { error: upsertErr } = await supabaseAdmin
    .from("email_otps")
    .upsert({
      email,
      code,
      created_at: now.toISOString(),
      expires_at: expiresAt.toISOString(),
      consumed: false
    }, { onConflict: "email" });

  if (upsertErr) {
    return new Response(, { status: 500 });
  }

  try {
    await sendEmail(email, code);
  } catch (e) {
    return new Response((e as Error).message, { status: 502 });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" }
  });
}

async function handleVerify(email: string, code: string) {
  if (!isValidEmail(email) || !code) {
    return new Response("Invalid input", { status: 400 });
  }

  const { data, error } = await supabaseAdmin
    .from("email_otps")
    .select("*")
    .eq("email", email)
    .eq("code", code)
    .eq("consumed", false)
    .limit(1)
    .maybeSingle();

  if (error) {
    return new Response(, { status: 500 });
  }
  if (!data) {
    return new Response("Invalid code", { status: 400 });
  }

  const now = new Date();
  const expires = new Date(data.expires_at);
  if (now > expires) {
    return new Response("Code expired", { status: 400 });
  }

  const { error: updErr } = await supabaseAdmin
    .from("email_otps")
    .update({ consumed: true })
    .eq("email", email)
    .eq("code", code);

  if (updErr) {
    return new Response(, { status: 500 });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" }
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }
  const action = body?.action;
  const email = (body?.email || "").toString().trim();
  const code = (body?.code || "").toString().trim();

  try {
    if (action === "send") {
      return await handleSend(email);
    } else if (action === "verify") {
      return await handleVerify(email, code);
    } else {
      return new Response("Unknown action", { status: 400 });
    }
  } catch (e) {
    return new Response((e as Error).message, { status: 500 });
  }
});
