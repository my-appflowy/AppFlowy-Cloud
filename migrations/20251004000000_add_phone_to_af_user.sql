-- Add phone field to af_user table
-- This migration adds phone number support for users who sign in with phone/SMS verification

-- Add phone column (nullable, to support both email and phone-based authentication)
ALTER TABLE af_user ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT NULL;

-- Add unique constraint for phone when it's not null
-- This ensures each phone number can only be associated with one account
CREATE UNIQUE INDEX IF NOT EXISTS af_user_phone_key 
ON af_user (phone) 
WHERE phone IS NOT NULL AND phone != '';

-- Add index for faster phone-based lookups
CREATE INDEX IF NOT EXISTS af_user_phone_idx 
ON af_user (phone) 
WHERE phone IS NOT NULL AND phone != '';

-- Add comment explaining the column
COMMENT ON COLUMN af_user.phone IS 'User phone number for SMS-based authentication. Unique when not null. Format should follow E.164 standard (e.g., +8613800138000)';


