import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PredictionRequest {
  distance: string;
  swimPace?: string;
  bikeSpeed?: number;
  runPace?: string;
  experience: string;
  environmentalFactors?: any;
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

    const { data } = await req.json() as { data: PredictionRequest }
    
    // Get race distance data
    const { data: raceDistance, error: raceError } = await supabaseClient
      .from('race_distances')
      .select('*')
      .eq('name', data.distance)
      .single()

    if (raceError || !raceDistance) {
      throw new Error('Race distance not found')
    }

    // Calculate prediction based on inputs
    let totalTime = 0;
    
    if (raceDistance.category === 'triathlon') {
      // Parse swim pace (mm:ss per 100m)
      const swimPaceMatch = data.swimPace?.match(/(\d+):(\d+)/)
      if (swimPaceMatch) {
        const swimPacePer100m = parseInt(swimPaceMatch[1]) * 60 + parseInt(swimPaceMatch[2])
        const swimDistance = getSwimDistance(data.distance)
        const swimTime = (swimDistance / 100) * swimPacePer100m
        totalTime += swimTime
      }

      // Calculate bike time
      if (data.bikeSpeed) {
        const bikeDistance = getBikeDistance(data.distance)
        const bikeTime = (bikeDistance / data.bikeSpeed) * 3600 // Convert hours to seconds
        totalTime += bikeTime
      }

      // Parse run pace (mm:ss per km)
      const runPaceMatch = data.runPace?.match(/(\d+):(\d+)/)
      if (runPaceMatch) {
        const runPacePerKm = parseInt(runPaceMatch[1]) * 60 + parseInt(runPaceMatch[2])
        const runDistance = getRunDistance(data.distance)
        const runTime = runDistance * runPacePerKm
        totalTime += runTime
      }
    } else if (raceDistance.category === 'running') {
      // Parse run pace (mm:ss per km)
      const runPaceMatch = data.runPace?.match(/(\d+):(\d+)/)
      if (runPaceMatch) {
        const runPacePerKm = parseInt(runPaceMatch[1]) * 60 + parseInt(runPaceMatch[2])
        totalTime = raceDistance.distance_km * runPacePerKm
      }
    }

    // Apply experience level adjustments
    const experienceMultiplier = getExperienceMultiplier(data.experience)
    totalTime *= experienceMultiplier

    // Apply environmental factors if provided
    if (data.environmentalFactors) {
      totalTime *= getEnvironmentalMultiplier(data.environmentalFactors)
    }

    // Format predicted time
    const hours = Math.floor(totalTime / 3600)
    const minutes = Math.floor((totalTime % 3600) / 60)
    const seconds = Math.floor(totalTime % 60)
    const predictedTime = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`

    // Save prediction to database
    const { data: user } = await supabaseClient.auth.getUser()
    
    if (user.user) {
      await supabaseClient
        .from('race_predictions')
        .insert({
          user_id: user.user.id,
          race_distance_id: raceDistance.id,
          predicted_time: `${Math.floor(totalTime / 3600)} hours ${Math.floor((totalTime % 3600) / 60)} minutes`,
          swim_pace: data.swimPace,
          bike_speed: data.bikeSpeed,
          run_pace: data.runPace,
          experience_level: data.experience,
          environmental_factors: data.environmentalFactors
        })

      // Track analytics event
      await supabaseClient
        .from('analytics_events')
        .insert({
          user_id: user.user.id,
          event_type: 'race_prediction_generated',
          event_data: {
            distance: data.distance,
            predicted_time: predictedTime,
            experience: data.experience
          }
        })
    }

    return new Response(
      JSON.stringify({
        success: true,
        prediction: {
          time: predictedTime,
          distance: raceDistance.name,
          breakdown: {
            total_seconds: totalTime,
            hours,
            minutes,
            seconds
          }
        }
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

function getSwimDistance(distance: string): number {
  const distances: { [key: string]: number } = {
    'Sprint Triathlon': 750,
    'Olympic Triathlon': 1500,
    'Half Ironman': 1900,
    'Ironman': 3800
  }
  return distances[distance] || 0
}

function getBikeDistance(distance: string): number {
  const distances: { [key: string]: number } = {
    'Sprint Triathlon': 20,
    'Olympic Triathlon': 40,
    'Half Ironman': 90,
    'Ironman': 180
  }
  return distances[distance] || 0
}

function getRunDistance(distance: string): number {
  const distances: { [key: string]: number } = {
    'Sprint Triathlon': 5,
    'Olympic Triathlon': 10,
    'Half Ironman': 21.1,
    'Ironman': 42.2
  }
  return distances[distance] || 0
}

function getExperienceMultiplier(experience: string): number {
  const multipliers: { [key: string]: number } = {
    'beginner': 1.15,
    'intermediate': 1.0,
    'advanced': 0.92,
    'elite': 0.85
  }
  return multipliers[experience] || 1.0
}

function getEnvironmentalMultiplier(factors: any): number {
  let multiplier = 1.0
  
  if (factors.temperature > 25) multiplier += 0.05
  if (factors.humidity > 70) multiplier += 0.03
  if (factors.wind > 15) multiplier += 0.08
  if (factors.elevation > 500) multiplier += 0.1
  
  return multiplier
}