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

  // ── Parse body ────────────────────────────────────────────────────────────
  let body: { email?: string; entidad_id?: string } = {}
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Body JSON inválido' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { email, entidad_id } = body
  if (!email || !entidad_id) {
    return new Response(
      JSON.stringify({ error: 'email y entidad_id son requeridos' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    // ── Obtener nombre de la entidad ──────────────────────────────────────
    const { data: entidadData } = await supabase
      .from('entidades')
      .select('nombre')
      .eq('id', entidad_id)
      .maybeSingle()
    const entidadNombre: string = entidadData?.nombre ?? ''

    // ── Paso 1: invitar o localizar usuario ───────────────────────────────
    let userId: string
    let invited: boolean

    const { data: inviteData, error: inviteError } =
      await supabase.auth.admin.inviteUserByEmail(email, {
        redirectTo: 'https://agenda.appgh.net/auth/callback',
        data: { entidad_nombre: entidadNombre },
      })

    if (!inviteError) {
      // Usuario nuevo — invitación enviada correctamente
      invited = true
      userId  = inviteData.user!.id
    } else {
      // Comprobar si el error es "usuario ya registrado"
      const msg = (inviteError.message ?? '').toLowerCase()
      const alreadyExists =
        msg.includes('already registered') ||
        msg.includes('already been invited') ||
        msg.includes('already exists') ||
        (inviteError as unknown as { status?: number }).status === 422

      if (!alreadyExists) throw inviteError

      // Usuario existente — buscar su UUID
      const { data: listData, error: listError } =
        await supabase.auth.admin.listUsers({ perPage: 1000 })
      if (listError) throw listError

      const existing = listData.users.find((u) => u.email === email)
      if (!existing) throw new Error(`No se encontró usuario con email: ${email}`)
      userId = existing.id

      // Reenviar email según el estado de la cuenta:
      //   - Sin confirmar → nueva invitación para que establezca contraseña
      //   - Confirmada    → magic link para acceso rápido al panel restaurado
      const isConfirmed = !!existing.email_confirmed_at
      const linkType = isConfirmed ? 'magiclink' : 'invite'
      const { error: linkError } = await supabase.auth.admin.generateLink({
        type: linkType,
        email,
        options: {
          redirectTo: 'https://agenda.appgh.net/auth/callback',
          data: { entidad_nombre: entidadNombre },
        },
      })
      invited = !linkError
    }

    // ── Paso 2: crear perfil en usuarios si aún no existe ────────────────
    // El registro se crea en el momento de la invitación; el usuario
    // lo completará (nombre, apellido, etc.) cuando entre por primera vez.
    const { data: usuarioExistente } = await supabase
      .from('usuarios')
      .select('id')
      .eq('id', userId)
      .maybeSingle()

    if (!usuarioExistente) {
      const { error: usuarioError } = await supabase
        .from('usuarios')
        .insert({
          id:                    userId,
          email,
          nombre:                '',
          apellido:              '',
          activo:                true,
          email_verificado:      false,
          acepta_comunicaciones: false,
        })
      if (usuarioError) throw usuarioError
    }

    // ── Paso 3: upsert en usuarios_autorizados ────────────────────────────
    const { data: autorizadoExistente } = await supabase
      .from('usuarios_autorizados')
      .select('id')
      .eq('usuario_id', userId)
      .eq('entidad_id', entidad_id)
      .maybeSingle()

    if (autorizadoExistente) {
      const { error } = await supabase
        .from('usuarios_autorizados')
        .update({ estado: 'activo', email })
        .eq('id', autorizadoExistente.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('usuarios_autorizados')
        .insert({ usuario_id: userId, entidad_id, email, estado: 'activo' })
      if (error) throw error
    }

    // ── Respuesta ─────────────────────────────────────────────────────────
    return new Response(JSON.stringify({ ok: true, invited }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
