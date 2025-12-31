# How to Verify Your Supabase API Key

## Quick Check

The "signature verification failed" error means Supabase is rejecting your API key. Here's how to fix it:

## Step 1: Get Your Correct Anon Key

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project: **xtexiiaubrolnjptphnl**
3. Click **Settings** (gear icon) in the left sidebar
4. Click **API** in the settings menu
5. Find the **"Project API keys"** section
6. Look for the **`anon` `public`** key
7. Click the **copy icon** (📋) next to it

## Step 2: Verify the Key Format

Your anon key should:
- ✅ Start with `eyJ` (it's a JWT token)
- ✅ Be very long (hundreds of characters)
- ✅ Look like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0ZXhpaWF1YnJvbG5qcHRwaG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzMjg5MTksImV4cCI6MjA4MDkwNDkxOX0.wV5Uz41GF_xeOrA6Y4A8gv3zfqxdzKfhuth4I3NL0aIa`

## Step 3: Update Your Config

1. Open `lib/services/supabase_config.dart`
2. Replace the `supabaseAnonKey` value with the key you just copied
3. Make sure to keep the quotes: `'YOUR_KEY_HERE'`
4. Save the file

## Step 4: Verify Your Policy

Also check your Storage policy:
1. Go to **Storage** → **post-images** bucket → **Policies** tab
2. Make sure your INSERT policy has:
   - **Target roles**: `public` (NOT `authenticated`)
   - **WITH CHECK expression** should allow files in the `public/` folder
   - Should allow `.jpg` files (or remove the extension restriction)

## Step 5: Restart Your App

After updating the key:
1. **Stop** your Flutter app completely
2. **Restart** it (not just hot reload)
3. Try uploading an image again

## Still Not Working?

If you still get "signature verification failed":
1. Double-check you copied the **entire** key (it's very long)
2. Make sure there are no extra spaces or line breaks
3. Verify the key in your Supabase dashboard matches exactly what's in your code
4. Try generating a new anon key in Supabase (though this shouldn't be necessary)

## Current Key in Your Config

Your current key starts with: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

If this matches what you see in your Supabase dashboard, the key is correct and the issue might be with the policy or request format.

