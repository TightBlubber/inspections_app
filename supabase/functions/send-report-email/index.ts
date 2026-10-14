import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Payload = {
  emails?: string[];
  subject?: string;
  body?: string;
  filename?: string;
  pdfBase64?: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const resendKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("REPORTS_FROM_EMAIL");

    if (!resendKey || !fromEmail) {
      return new Response(
        JSON.stringify({ error: "Missing RESEND_API_KEY or REPORTS_FROM_EMAIL" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const payload = (await req.json()) as Payload;
    const emails = (payload.emails ?? []).filter((e) => e.includes("@"));

    if (emails.length === 0) {
      return new Response(JSON.stringify({ error: "No valid recipients" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!payload.pdfBase64) {
      return new Response(JSON.stringify({ error: "Missing PDF payload" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: emails,
        subject: payload.subject ?? "Inspection Report",
        text: payload.body ?? "Attached is your requested inspection report.",
        attachments: [
          {
            filename: payload.filename ?? "inspection-report.pdf",
            content: payload.pdfBase64,
          },
        ],
      }),
    });

    const resendJson = await resendResponse.json();
    if (!resendResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Provider error", details: resendJson }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(JSON.stringify({ ok: true, provider: resendJson }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: "Unexpected server error", details: String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
