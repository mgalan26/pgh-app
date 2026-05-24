const https = require('https');

const PROJECT_REF  = process.env.SUPABASE_PROJECT_REF  || 'fuurjqyffurckxwsnzeq';
const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';

// ─── Plantilla de invitación (usuario nuevo o reenvío sin cuenta) ─────────────
const inviteContent = `<div style="background-color:#0D0D0D; padding:40px 20px; font-family:Georgia,serif;">
  <div style="max-width:520px; margin:0 auto; background-color:#111111; border-radius:8px; overflow:hidden; border:1px solid #1e1e1e;">

    <!-- Cabecera -->
    <div style="background:linear-gradient(135deg,#1a1a1a,#0d0d0d); padding:32px; text-align:center; border-bottom:1px solid #C9A84C;">
      <div style="width:56px; height:56px; background:linear-gradient(135deg,#C9A84C,#8B6914); border-radius:50%; margin:0 auto 16px; line-height:56px; text-align:center;">
        <span style="color:#0D0D0D; font-size:28px; font-weight:bold;">P</span>
      </div>
      <p style="color:#C9A84C; font-size:11px; letter-spacing:3px; margin:0; text-transform:uppercase;">Parlamento Global Hispano</p>
    </div>

    <!-- Contenido -->
    <div style="padding:32px;">
      <h1 style="color:#F0E8D8; font-size:22px; font-weight:bold; margin:0 0 16px;">Le han invitado a gestionar eventos</h1>
      <p style="color:#AAAAAA; font-size:15px; line-height:1.7; margin:0 0 16px;">
        Le han invitado a administrar los eventos de la entidad
        <strong style="color:#F0E8D8;">{{ index .Data "entidad_nombre" }}</strong>.
      </p>
      <p style="color:#AAAAAA; font-size:15px; line-height:1.7; margin:0 0 32px;">
        Active su cuenta para empezar a publicar eventos en
        <strong style="color:#F0E8D8;">agenda.appgh.net</strong>
      </p>

      <!-- Botón -->
      <div style="text-align:center; margin:0 0 32px;">
        <a href="{{ .ConfirmationURL }}"
           style="background:#C9A84C; color:#0D0D0D; padding:14px 32px; border-radius:6px; text-decoration:none; font-weight:bold; font-size:15px; display:inline-block;">
          Activar mi cuenta
        </a>
      </div>

      <p style="color:#555555; font-size:12px; line-height:1.6; margin:0; border-top:1px solid #1e1e1e; padding-top:24px;">
        Si no esperaba esta invitaci&oacute;n puede ignorar este email. El enlace expira en 24&nbsp;horas.
      </p>
    </div>

    <!-- Footer -->
    <div style="background:#0D0D0D; padding:16px 32px; text-align:center; border-top:1px solid #1e1e1e;">
      <p style="color:#444444; font-size:11px; letter-spacing:2px; margin:0; text-transform:uppercase;">agenda.appgh.net</p>
    </div>

  </div>
</div>`;

// ─── Plantilla de magic link (usuario con cuenta activa, acceso restaurado) ──
const magicLinkContent = `<div style="background-color:#0D0D0D; padding:40px 20px; font-family:Georgia,serif;">
  <div style="max-width:520px; margin:0 auto; background-color:#111111; border-radius:8px; overflow:hidden; border:1px solid #1e1e1e;">

    <!-- Cabecera -->
    <div style="background:linear-gradient(135deg,#1a1a1a,#0d0d0d); padding:32px; text-align:center; border-bottom:1px solid #C9A84C;">
      <div style="width:56px; height:56px; background:linear-gradient(135deg,#C9A84C,#8B6914); border-radius:50%; margin:0 auto 16px; line-height:56px; text-align:center;">
        <span style="color:#0D0D0D; font-size:28px; font-weight:bold;">P</span>
      </div>
      <p style="color:#C9A84C; font-size:11px; letter-spacing:3px; margin:0; text-transform:uppercase;">Parlamento Global Hispano</p>
    </div>

    <!-- Contenido -->
    <div style="padding:32px;">
      <h1 style="color:#F0E8D8; font-size:22px; font-weight:bold; margin:0 0 16px;">Acceso restaurado</h1>
      <p style="color:#AAAAAA; font-size:15px; line-height:1.7; margin:0 0 16px;">
        Se le ha restaurado el acceso para administrar los eventos de la entidad
        <strong style="color:#F0E8D8;">{{ index .Data "entidad_nombre" }}</strong>.
      </p>
      <p style="color:#AAAAAA; font-size:15px; line-height:1.7; margin:0 0 32px;">
        Haga clic en el bot&oacute;n para acceder directamente a su panel en
        <strong style="color:#F0E8D8;">agenda.appgh.net</strong>
      </p>

      <!-- Botón -->
      <div style="text-align:center; margin:0 0 32px;">
        <a href="{{ .ConfirmationURL }}"
           style="background:#C9A84C; color:#0D0D0D; padding:14px 32px; border-radius:6px; text-decoration:none; font-weight:bold; font-size:15px; display:inline-block;">
          Acceder a mi panel
        </a>
      </div>

      <p style="color:#555555; font-size:12px; line-height:1.6; margin:0; border-top:1px solid #1e1e1e; padding-top:24px;">
        Si no esperaba este email puede ignorarlo. El enlace expira en 24&nbsp;horas.
      </p>
    </div>

    <!-- Footer -->
    <div style="background:#0D0D0D; padding:16px 32px; text-align:center; border-top:1px solid #1e1e1e;">
      <p style="color:#444444; font-size:11px; letter-spacing:2px; margin:0; text-transform:uppercase;">agenda.appgh.net</p>
    </div>

  </div>
</div>`;

const body = JSON.stringify({
  mailer_templates_invite_content:     inviteContent,
  mailer_templates_magic_link_content: magicLinkContent,
});

const options = {
  hostname: 'api.supabase.com',
  path:     `/v1/projects/${PROJECT_REF}/config/auth`,
  method:   'PATCH',
  headers: {
    'Authorization': `Bearer ${ACCESS_TOKEN}`,
    'Content-Type':  'application/json',
    'Content-Length': Buffer.byteLength(body),
  },
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('Plantillas actualizadas correctamente.');
    } else {
      console.error(`Error ${res.statusCode}:`, data.slice(0, 400));
    }
  });
});

req.on('error', e => console.error('Error de red:', e.message));
req.write(body);
req.end();
