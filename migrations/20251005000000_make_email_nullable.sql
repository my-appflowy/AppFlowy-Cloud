-- Make email field nullable to support phone-only registration
-- This migration allows users to register with either email OR phone number

-- Drop the existing unique constraint on email
ALTER TABLE af_user DROP CONSTRAINT IF EXISTS af_user_email_key;

-- Make email column nullable
ALTER TABLE af_user ALTER COLUMN email DROP NOT NULL;

-- Create a partial unique index for email (only when email is not null and not empty)
-- This ensures each email can only be associated with one account, but allows NULL/empty values
CREATE UNIQUE INDEX IF NOT EXISTS af_user_email_key 
ON af_user (email) 
WHERE email IS NOT NULL AND email != '';

-- Add index for faster email-based lookups
CREATE INDEX IF NOT EXISTS af_user_email_idx 
ON af_user (email) 
WHERE email IS NOT NULL AND email != '';

-- Add comment explaining the updated logic
COMMENT ON COLUMN af_user.email IS 'User email address. Nullable to support phone-only registration. Unique when not null/empty.';

-- Drop the constraint if it already exists (to make migration idempotent)
ALTER TABLE af_user DROP CONSTRAINT IF EXISTS af_user_email_or_phone_check;

-- Add a check constraint to ensure at least one of email or phone is provided
ALTER TABLE af_user ADD CONSTRAINT af_user_email_or_phone_check 
CHECK (
    (email IS NOT NULL AND email != '') OR 
    (phone IS NOT NULL AND phone != '')
);

COMMENT ON CONSTRAINT af_user_email_or_phone_check ON af_user IS 'Ensures that each user has at least one contact method (email or phone)';
