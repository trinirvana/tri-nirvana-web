import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FeedbackSubmission {
  rating: number;
  feedback_text?: string;
  page_url?: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { rating, feedback_text, page_url } = await req.json() as FeedbackSubmission
    
    // Validate rating
    if (!rating || rating < 1 || rating > 5) {
      throw new Error('Rating must be between 1 and 5')
    }

    // Get user from auth
    const { data: user } = await supabaseClient.auth.getUser()
    
    // Insert feedback
    const { data, error } = await supabaseClient
      .from('feedback_submissions')
      .insert({
        user_id: user.user?.id || null,
        rating,
        feedback_text,
        page_url
      })

    if (error) {
      throw error
    }

    // Track analytics event
    await supabaseClient
      .from('analytics_events')
      .insert({
        user_id: user.user?.id || null,
        event_type: 'feedback_submitted',
        event_data: {
          rating,
          has_text: !!feedback_text,
          page_url
        }
      })

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Feedback submitted successfully'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

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