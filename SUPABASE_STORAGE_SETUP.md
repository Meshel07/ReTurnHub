# Supabase Storage Bucket Setup Guide

This guide will walk you through creating a storage bucket in Supabase for uploading post images.

## Step 1: Access Your Supabase Dashboard

1. Go to [https://supabase.com](https://supabase.com)
2. Log in to your account
3. Select your project (or create a new one if you haven't already)

## Step 2: Navigate to Storage

1. In the left sidebar, click on **"Storage"** (it has a folder icon)
2. You should see the Storage dashboard with tabs: **Buckets**, **Settings**, and **Policies**

## Step 3: Create a New Bucket

1. Click on the **"+ New bucket"** button (usually a green button in the center or top right)
2. A dialog will appear asking for bucket details

## Step 4: Configure the Bucket

Fill in the following information:

- **Name**: Enter `post-images` (this must match exactly what's in the code)
- **Public bucket**: 
  - ✅ **Check this box** if you want images to be publicly accessible (recommended for post images)
  - ❌ Leave unchecked if you want private access (requires authentication to view)
- **File size limit**: 
  - Set a reasonable limit (e.g., 5MB or 10MB) to prevent abuse
  - Leave empty for no limit (not recommended)
- **Allowed MIME types**: 
  - You can restrict to image types: `image/jpeg, image/png, image/gif, image/webp`
  - Or leave empty to allow all types

## Step 5: Create the Bucket

1. Click the **"Create bucket"** button
2. Wait for the bucket to be created (usually instant)

## Step 6: Set Up Storage Policies (Important!)

After creating the bucket, you need to set up policies to control who can upload and read files:

### Option A: Public Bucket with Anon Key Uploads (Recommended for Firebase Auth)

**IMPORTANT**: Since you're using Firebase Auth (not Supabase Auth), you need to allow uploads with the `anon` (public) key:

1. Go to the **"Policies"** tab
2. Click **"New Policy"**
3. Select **"For full customization"**
4. Create an **INSERT** policy for public/anonymous users:
   - Policy name: `Allow public to upload`
   - Allowed operation: `INSERT`
   - Target roles: `public` (NOT authenticated - this is important!)
   - Policy definition: 
     ```sql
     (bucket_id = 'post-images'::text)
     ```
   - Check expression: `true`
   - Click **"Review"** then **"Save policy"**

5. Create a **SELECT** policy for public access:
   - Policy name: `Allow public to read`
   - Allowed operation: `SELECT`
   - Target roles: `public`
   - Policy definition:
     ```sql
     (bucket_id = 'post-images'::text)
     ```
   - Check expression: `true`
   - Click **"Review"** then **"Save policy"**

**Note**: Using `public` role allows uploads with the anon key, which is what you need when using Firebase Auth instead of Supabase Auth.

### Option B: Using the Policy Templates

1. Click **"New Policy"**
2. Select **"Get started quickly"**
3. Choose **"Allow public uploads"** or **"Allow authenticated uploads"** based on your needs
4. The policy will be auto-generated

## Step 7: Verify Your Supabase URL

1. Go to **Settings** → **API** in your Supabase dashboard
2. Copy your **Project URL** (looks like: `https://xxxxx.supabase.co`)
3. Open `lib/services/supabase_config.dart` in your project
4. Replace `'YOUR_SUPABASE_URL'` with your actual Project URL

## Step 8: Test the Upload

1. Run your Flutter app
2. Try creating a post with an image
3. Check the Supabase Storage dashboard to see if the file appears in the `post-images` bucket

## Troubleshooting

### Error: "Bucket not found"
- Make sure the bucket name is exactly `post-images` (case-sensitive)
- Verify the bucket exists in your Supabase dashboard

### Error: "Permission denied", "Policy violation", or "signature verification failed"
- **This is the most common issue!** Check your Storage Policies in the Supabase dashboard
- **IMPORTANT**: Since you're using Firebase Auth (not Supabase Auth), you need:
  - INSERT policy with `public` role (NOT `authenticated`)
  - SELECT policy with `public` role
- The `public` role allows uploads using the anon key
- If you see "signature verification failed", it means your policies are set to `authenticated` but you're using the anon key
- Go to Storage → Policies → Edit your INSERT policy → Change Target roles from `authenticated` to `public`

### Error: "File too large"
- Check your bucket's file size limit
- Increase the limit in bucket settings if needed

### Images not showing
- Verify the bucket is set to **Public** OR
- Ensure you have proper SELECT policies for reading files
- Check that the URL returned by `getPublicUrl()` is accessible

## Additional Notes

- **Bucket Name**: The bucket name `post-images` is hardcoded in the app. If you want to change it, update it in:
  - `lib/services/api_service.dart` (in both upload methods)
  - `lib/services/supabase_config.dart` (in the `storageBucket` constant, though it's not currently used)

- **File Organization**: Files are stored with the path `userId/filename`, so each user's images are organized in their own folder within the bucket.

- **Security**: For production, consider:
  - Using authenticated uploads only
  - Adding file type validation
  - Setting reasonable file size limits
  - Implementing image compression before upload

