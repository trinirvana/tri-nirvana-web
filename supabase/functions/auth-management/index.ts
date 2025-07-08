import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const url = new URL(req.url)
    const action = url.pathname.split('/').pop()

    if (action === 'webhook') {
      // Handle auth webhook from Supabase
      const payload = await req.json()
      
      if (payload.type === 'INSERT') {
        // New user registered
        const user = payload.record
        
        // Track registration event
        await supabaseClient
          .from('analytics_events')
          .insert({
            user_id: user.id,
            event_type: 'user_registered',
            event_data: {
              email: user.email,
              provider: user.app_metadata?.provider || 'email'
            }
          })
      }

      return new Response(
        JSON.stringify({ success: true }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      )
    }

    if (action === 'profile') {
      // Get or update user profile
      const authClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        {
          global: {
            headers: { Authorization: req.headers.get('Authorization')! },
          },
        }
      )

      const { data: user } = await authClient.auth.getUser()
      
      if (!user.user) {
        throw new Error('Not authenticated')
      }

      if (req.method === 'GET') {
        // Get profile
        const { data: profile, error } = await supabaseClient
          .from('profiles')
          .select('*')
          .eq('id', user.user.id)
          .single()

        if (error && error.code !== 'PGRST116') {
          throw error
        }

        return new Response(
          JSON.stringify({
            success: true,
            profile: profile || {
              id: user.user.id,
              email: user.user.email,
              beta_tester: true
            }
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        )
      }

      if (req.method === 'PUT') {
        // Update profile
        const updates = await req.json()
        
        const { data, error } = await supabaseClient
          .from('profiles')
          .upsert({
            id: user.user.id,
            email: user.user.email,
            ...updates,
            updated_at: new Date().toISOString()
          })
          .select()

        if (error) {
          throw error
        }

        return new Response(
          JSON.stringify({
            success: true,
            profile: data[0]
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        )
      }
    }

    throw new Error('Invalid action')

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})