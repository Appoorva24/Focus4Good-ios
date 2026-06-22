import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('PROJECT_URL') ?? Deno.env.get('SUPABASE_URL') as string
const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY') as string
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// Helper to hash OTP (SHA-256)
async function hashOTP(otp: string) {
  const encoder = new TextEncoder()
  const data = encoder.encode(otp)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

serve(async (req) => {
  try {
    const { email, otp } = await req.json()
    if (!email || !otp) throw new Error("Email and OTP are required")

    const hashedOtp = await hashOTP(otp)

    // Fetch the OTP record for this email
    const { data, error } = await supabase
      .from("email_otps")
      .select("*")
      .eq("email", email)
      .eq("otp", hashedOtp)
      .single()

    if (error || !data) {
      throw new Error("Invalid OTP")
    }

    // Check expiry
    if (new Date(data.expires_at) < new Date()) {
      // OTP Expired, delete it and throw error
      await supabase.from("email_otps").delete().eq("email", email)
      throw new Error("OTP Expired")
    }

    // Verification successful, delete OTP so it can't be reused
    await supabase.from("email_otps").delete().eq("email", email)

    return new Response(
      JSON.stringify({ status: "verified" }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { "Content-Type": "application/json" }, status: 400 }
    )
  }
})
