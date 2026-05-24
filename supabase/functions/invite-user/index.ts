import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  console.log('[invite-user] Nueva invocación', { method: req.method, url: req.url })

  let body: { email?: string; entidad_id?: string } = {}
  try {
    body = await req.json()
    console.log('[invite-user] Body recibido', { email: body.email, entidad_id: body.entidad_id })
  } catch (parseError) {
    console.error('[invite-user] Error parseando body:', parseError)
    return new Response(JSON.stringify({ error: 'Body JSON inválido', detail: String(parseError) }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { email, entidad_id } = body

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    console.log('[invite-user] SUPABASE_URL presente:', !!supabaseUrl, '| SERVICE_ROLE_KEY presente:', !!serviceKey)

    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    console.log('[invite-user] Invitando email:', email)
    const { error: inviteError } = await supabase.auth.admin.inviteUserByEmail(email!)
    if (inviteError) {
      console.error('[invite-user] Error inviteUserByEmail:', inviteError.message, inviteError)
      throw inviteError
    }

    const { data: userData, error: listError } = await supabase.auth.admin.listUsers()
    if (listError) {
      console.error('[invite-user] Error listUsers:', listError.message, listError)
      throw listError
    }

    const user = userData.users.find(u => u.email === email)
    console.log('[invite-user] Usuario encontrado tras invite:', !!user, user?.id)

    if (user && entidad_id) {
      const { error: upsertError } = await supabase.from('usuarios_autorizados').upsert({
        usuario_id: user.id,
        entidad_id,
        estado: 'activo',
      })
      if (upsertError) {
        console.error('[invite-user] Error upsert usuarios_autorizados:', upsertError.message, upsertError)
        throw upsertError
      }
    }

    console.log('[invite-user] Éxito')
    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('[invite-user] Error general:', error?.message, error?.stack ?? String(error))
    return new Response(
      JSON.stringify({ error: error?.message ?? String(error), stack: error?.stack }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  }
})
