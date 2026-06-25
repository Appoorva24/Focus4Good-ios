-- Create the email_otps table
CREATE TABLE IF NOT EXISTS public.email_otps (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL,
    otp text NOT NULL,
    expires_at timestamptz NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS (Row Level Security) but allow Service Role (Edge Functions) to bypass it
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

-- Clients should not be able to read/write this table directly.
-- All interaction happens through Edge Functions.
CREATE POLICY "Deny all client access" ON public.email_otps
    FOR ALL
    TO authenticated, anon
    USING (false);
