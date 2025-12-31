# How to Get Your Correct Supabase API Key

## The Problem

The error "Invalid Compact JWS" means your Supabase API key format is incorrect. Supabase anon keys are JWT tokens (they look like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`), not keys starting with `sb_publishable_`.

## How to Get Your Correct Supabase Anon Key

1. **Go to your Supabase Dashboard**
   - Visit [https://app.supabase.com](https://app.supabase.com)
   - Log in and select your project

2. **Navigate to Settings → API**
   - Click on **Settings** in the left sidebar
   - Click on **API** in the settings menu

3. **Find Your Keys**
   - Look for the **"Project API keys"** section
   - You'll see two keys:
     - **`anon` `public`** - This is the one you need (the publishable key)
     - **`service_role` `secret`** - Don't use this one (it's private)

4. **Copy the `anon` `public` Key**
   - The key should look like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0ZXhpaWF1YnJvbG5qcHRwaG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE...`
   - It's a long string starting with `eyJ`
   - Click the **copy icon** next to it

5. **Update Your Config File**
   - Open `lib/services/supabase_config.dart`
   - Replace the `supabaseAnonKey` value with your actual anon key
   - Make sure to keep the quotes: `static const String supabaseAnonKey = 'YOUR_ACTUAL_KEY_HERE';`

## Example

**Before (Wrong):**
```dart
static const String supabaseAnonKey = 'sb_publishable_F6GwuGpr2Y0ouqU8gXCwjw_LVu0NKAh';
```

**After (Correct):**
```dart
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0ZXhpaWF1YnJvbG5qcHRwaG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE...';
```

## Important Notes

- ✅ Use the **`anon` `public`** key (not the service_role key)
- ✅ The key should be a JWT token starting with `eyJ`
- ✅ Keep it in quotes in your code
- ❌ Don't share your `service_role` key (it's secret)
- ❌ Don't commit your keys to public repositories (use environment variables in production)

## After Updating

1. Save the file
2. Hot restart your app (not just hot reload)
3. Try uploading an image again

The upload should work now!

