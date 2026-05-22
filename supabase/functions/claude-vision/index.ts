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
    const { base64, mediaType } = await req.json()

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') ?? '',
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-opus-4-5',
        max_tokens: 1024,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: { type: 'base64', media_type: mediaType, data: base64 },
            },
            {
              type: 'text',
              text: `Extrae los datos de este evento y devuelve SOLO un JSON válido sin markdown con estos campos:
{
  "nombre": "nombre del evento",
  "descripcion": "descripción si existe",
  "tipo": "Conferencia|Mesa redonda|Congreso|Networking|Cultural|Académico|Empresarial|Político|Exposición|Otro",
  "fecha_inicio": "YYYY-MM-DD",
  "hora_inicio": "HH:mm",
  "pais": "país en español",
  "ciudad": "ciudad",
  "venue_nombre": "nombre del lugar",
  "es_gratuito": true,
  "enlace_web": "url si existe",
  "ponente_nombre": "nombre completo del ponente principal si existe",
  "imagen_crop": {"x": 0.0, "y": 0.0, "w": 1.0, "h": 1.0}
}
Para imagen_crop: indica la zona de la imagen que contiene la fotografía o ilustración principal del evento (excluyendo textos, logos y fondos de diseño gráfico). Usa fracciones de 0.0 a 1.0 donde x,y es la esquina superior izquierda y w,h son el ancho y alto del recorte. Si toda la imagen es la foto principal usa {"x":0.0,"y":0.0,"w":1.0,"h":1.0}. Si no hay ninguna foto o ilustración principal usa null.
Si algún otro campo no está en la imagen ponlo como null.`
            }
          ]
        }]
      }),
    })

    const data = await response.json()
    const text = data.content[0].text

    return new Response(JSON.stringify({ result: text }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
