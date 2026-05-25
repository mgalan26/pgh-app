import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, entidad_nombre } = await req.json()

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      },
      body: JSON.stringify({
        from: 'Parlamento Global Hispano <pgh@wenow.io>',
        to: [email],
        subject: 'Invitación para gestionar eventos — Parlamento Global Hispano',
        html: `
<div style="background-color:#0D0D0D;padding:40px 20px;font-family:Georgia,serif;">
  <div style="max-width:520px;margin:0 auto;background-color:#111111;border-radius:8px;overflow:hidden;border:1px solid #1e1e1e;">
    <div style="background:linear-gradient(135deg,#1a1a1a,#0d0d0d);padding:32px;text-align:center;border-bottom:1px solid #C9A84C;">
      <div style="width:56px;height:56px;background:linear-gradient(135deg,#C9A84C,#8B6914);border-radius:50%;margin:0 auto 16px;line-height:56px;text-align:center;">
        <span style="color:#0D0D0D;font-size:28px;font-weight:bold;">P</span>
      </div>
      <p style="color:#C9A84C;font-size:11px;letter-spacing:3px;margin:0;text-transform:uppercase;">Parlamento Global Hispano</p>
    </div>
    <div style="padding:32px;">
      <h1 style="color:#F0E8D8;font-size:22px;font-weight:bold;margin:0 0 16px;">Le han invitado a gestionar eventos</h1>
      <p style="color:#AAAAAA;font-size:15px;line-height:1.7;margin:0 0 16px;">
        Le han invitado a administrar los eventos de la entidad <strong style="color:#F0E8D8;">${entidad_nombre}</strong> en la agenda de eventos del mundo hispanohablante.
      </p>
      <p style="color:#AAAAAA;font-size:15px;line-height:1.7;margin:0 0 32px;">
        Entre en <strong style="color:#F0E8D8;">agenda.appgh.net</strong>, vaya a "Mi Panel" y acepte la invitación pendiente.
      </p>
      <div style="text-align:center;margin:0 0 32px;">
        <a href="https://agenda.appgh.net" style="background:#C9A84C;color:#0D0D0D;padding:14px 32px;border-radius:6px;text-decoration:none;font-weight:bold;font-size:15px;display:inline-block;">
          Ir a la agenda
        </a>
      </div>
      <p style="color:#555555;font-size:12px;line-height:1.6;margin:0;border-top:1px solid #1e1e1e;padding-top:24px;">
        Si no esperaba esta invitación puede ignorar este email.
      </p>
    </div>
    <div style="background:#0D0D0D;padding:16px 32px;text-align:center;border-top:1px solid #1e1e1e;">
      <p style="color:#444444;font-size:11px;letter-spacing:2px;margin:0;text-transform:uppercase;">agenda.appgh.net</p>
    </div>
  </div>
</div>`,
      }),
    })

    if (!res.ok) throw new Error(await res.text())

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
