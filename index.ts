import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function getSecretKey() {
  const modern = Deno.env.get("SUPABASE_SECRET_KEYS");

  if (modern) {
    try {
      const parsed = JSON.parse(modern);
      if (parsed.default) return parsed.default;
      const first = Object.values(parsed)[0];
      if (typeof first === "string") return first;
    } catch (_) {}
  }

  return (
    Deno.env.get("SUPABASE_SECRET_KEY") ||
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    ""
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ ok: false, message: "Method not allowed." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
  const secretKey = getSecretKey();
  const resendApiKey = Deno.env.get("RESEND_API_KEY") || "";
  const fromEmail = Deno.env.get("CAPTAIN_FROM_EMAIL") || "";
  const siteUrl =
    Deno.env.get("SITE_URL") ||
    "https://dboyarsk-git.github.io/ONE_WAY_Vball_Tourney/";

  if (!supabaseUrl || !secretKey) {
    return json(
      { ok: false, message: "Supabase server credentials are unavailable." },
      500,
    );
  }

  if (!resendApiKey || !fromEmail) {
    return json(
      {
        ok: false,
        message:
          "Captain email is not configured yet. Add RESEND_API_KEY and CAPTAIN_FROM_EMAIL to the Edge Function secrets.",
      },
      503,
    );
  }

  let body;

  try {
    body = await req.json();
  } catch (_) {
    return json({ ok: false, message: "Invalid request body." }, 400);
  }

  const registrationId = String(body?.registration_id || "").trim();
  const confirmationToken = String(body?.confirmation_token || "").trim();

  if (!registrationId || !confirmationToken) {
    return json(
      { ok: false, message: "Registration ID and confirmation token are required." },
      400,
    );
  }

  const admin = createClient(supabaseUrl, secretKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  // The caller must possess the exact confirmation token created
  // for this registration. This prevents the public endpoint from
  // being used to send arbitrary email.
  const { data: secretRow, error: secretError } = await admin
    .from("registration_secrets")
    .select("registration_id,confirmation_token")
    .eq("registration_id", registrationId)
    .eq("confirmation_token", confirmationToken)
    .maybeSingle();

  if (secretError || !secretRow) {
    return json({ ok: false, message: "Invalid registration confirmation." }, 403);
  }

  const [
    registrationResult,
    contactResult,
    playersResult,
    adminResult,
  ] = await Promise.all([
    admin
      .from("team_registrations")
      .select("id,team_name,status,reserved_slot")
      .eq("id", registrationId)
      .maybeSingle(),

    admin
      .from("registration_contacts")
      .select("captain_name,captain_email")
      .eq("registration_id", registrationId)
      .maybeSingle(),

    admin
      .from("registration_players")
      .select("player_number,full_name")
      .eq("registration_id", registrationId)
      .order("player_number"),

    admin
      .from("registration_admin")
      .select("captain_email_sent_at")
      .eq("registration_id", registrationId)
      .maybeSingle(),
  ]);

  if (
    registrationResult.error ||
    contactResult.error ||
    playersResult.error ||
    adminResult.error ||
    !registrationResult.data ||
    !contactResult.data
  ) {
    console.error(
      registrationResult.error,
      contactResult.error,
      playersResult.error,
      adminResult.error,
    );

    return json(
      { ok: false, message: "Unable to load registration email details." },
      500,
    );
  }

  if (adminResult.data?.captain_email_sent_at) {
    return json({ ok: true, already_sent: true });
  }

  const registration = registrationResult.data;
  const contact = contactResult.data;
  const players = playersResult.data || [];

  // Atomically claim the one automatic email for this registration.
  // A second request receives zero updated rows and will not send again.
  const claimedAt = new Date().toISOString();

  const { data: claimRows, error: claimError } = await admin
    .from("registration_admin")
    .update({
      captain_email_sent_at: claimedAt,
      captain_email_last_error: null,
    })
    .eq("registration_id", registrationId)
    .is("captain_email_sent_at", null)
    .select("registration_id");

  if (claimError) {
    console.error(claimError);
    return json({ ok: false, message: "Unable to start email delivery." }, 500);
  }

  if (!claimRows || claimRows.length === 0) {
    return json({ ok: true, already_sent: true });
  }

  const confirmationUrl = new URL(siteUrl);
  confirmationUrl.searchParams.set("confirm", confirmationToken);

  const statusText =
    registration.status === "waitlisted"
      ? "Your team is currently on the waitlist."
      : "Your team spot has been received and is awaiting all four player confirmations.";

  const rosterHtml = players
    .map(
      (player) =>
        `<li style="margin:4px 0">${escapeHtml(player.full_name)}</li>`,
    )
    .join("");

  const captainName = escapeHtml(contact.captain_name);
  const teamName = escapeHtml(registration.team_name);
  const link = escapeHtml(confirmationUrl.toString());

  const emailHtml = `
    <div style="font-family:Arial,Helvetica,sans-serif;max-width:620px;margin:0 auto;color:#202528;line-height:1.55">
      <div style="background:#f26a2e;color:white;padding:20px 22px;border-radius:16px 16px 0 0">
        <div style="font-size:13px;font-weight:700;letter-spacing:.08em;text-transform:uppercase">ONE WAY Conference</div>
        <div style="font-size:26px;font-weight:900;margin-top:3px">Grass 4s Volleyball</div>
      </div>

      <div style="background:#fffaf2;border:1px solid #eadfd2;border-top:0;padding:24px 22px;border-radius:0 0 16px 16px">
        <h2 style="margin:0 0 12px">Thanks for registering, ${captainName}!</h2>

        <p>
          We received the registration for <strong>${teamName}</strong>.
          ${escapeHtml(statusText)}
        </p>

        <p>
          Please send the button/link below to <strong>all four players</strong>.
          Each teammate must open the link, select their own name, agree to the tournament rules,
          and confirm their spot.
        </p>

        <div style="margin:20px 0">
          <a href="${link}"
             style="display:inline-block;background:#f26a2e;color:#ffffff;text-decoration:none;font-weight:800;padding:12px 18px;border-radius:10px">
            Confirm Team Players
          </a>
        </div>

        <p style="font-size:13px;color:#5f666a;overflow-wrap:anywhere">
          If the button does not work, copy this link:<br>
          <a href="${link}">${link}</a>
        </p>

        <h3 style="margin:22px 0 8px">Submitted roster</h3>
        <ol style="padding-left:22px;margin-top:0">
          ${rosterHtml}
        </ol>

        <p style="margin-top:22px">
          Thank you for being part of ONE WAY Grass 4s. We’re looking forward to seeing your team on the court!
        </p>

        <p style="font-size:13px;color:#697176;margin-bottom:0">
          Church of New Hope • Charlotte, NC
        </p>
      </div>
    </div>
  `;

  const subject =
    registration.status === "waitlisted"
      ? `ONE WAY Grass 4s — ${registration.team_name} Registration / Waitlist`
      : `ONE WAY Grass 4s — ${registration.team_name} Registration Received`;

  const resendResponse = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": `oneway-registration-${registrationId}`,
    },
    body: JSON.stringify({
      from: fromEmail,
      to: [contact.captain_email],
      subject,
      html: emailHtml,
    }),
  });

  if (!resendResponse.ok) {
    const errorText = await resendResponse.text();
    console.error("Resend:", resendResponse.status, errorText);

    // Release the claim so the captain/admin can retry later.
    await admin
      .from("registration_admin")
      .update({
        captain_email_sent_at: null,
        captain_email_last_error: errorText.slice(0, 1000),
      })
      .eq("registration_id", registrationId)
      .eq("captain_email_sent_at", claimedAt);

    return json(
      {
        ok: false,
        message:
          "Registration was saved, but the captain confirmation email could not be delivered.",
      },
      502,
    );
  }

  await admin
    .from("registration_admin")
    .update({
      captain_email_last_error: null,
    })
    .eq("registration_id", registrationId);

  return json({ ok: true, already_sent: false });
});
