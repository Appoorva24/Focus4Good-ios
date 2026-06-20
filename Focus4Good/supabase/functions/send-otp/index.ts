import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import nodemailer from "npm:nodemailer"

// Initialize Supabase Client with SERVICE_ROLE key to bypass RLS for inserting OTP
const supabaseUrl = Deno.env.get('PROJECT_URL') ?? Deno.env.get('SUPABASE_URL') as string
const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY') as string
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// Initialize Nodemailer Transport
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: Deno.env.get('GMAIL_USER'),     // Aapki Gmail ID
    pass: Deno.env.get('GMAIL_APP_PASS')  // Aapka 16-digit App Password
  }
})

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
    const { email } = await req.json()
    if (!email) throw new Error("Email is required")

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString()
    
    // Hash OTP before storing
    const hashedOtp = await hashOTP(otp)
    
    // Set expiry to 5 minutes from now
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString()

    // Delete any old OTPs for this email first
    await supabase.from("email_otps").delete().eq("email", email)

    // Save hashed OTP in Database
    const { error: dbError } = await supabase
      .from("email_otps")
      .insert({
        email,
        otp: hashedOtp,
        expires_at: expiresAt
      })

    if (dbError) throw dbError

    // Send Email using Nodemailer
    await transporter.sendMail({
      from: `"Focus4Good" <${Deno.env.get('GMAIL_USER')}>`,
      to: email,
      subject: "Your Focus4Good Login Code",
      html: `
        <div style="font-family: sans-serif; text-align: center; padding: 20px;">
          <h2>Authentication Code</h2>
          <p>Please use the following 6-digit code to complete your login:</p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #ff6b00; margin: 20px 0;">
            ${otp}
          </div>
          <p style="color: #666; font-size: 12px;">This code will expire in 5 minutes.</p>
        </div>
      `
    })

    return new Response(
      JSON.stringify({ message: "OTP sent successfully" }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { "Content-Type": "application/json" }, status: 400 }
    )
  }
})
