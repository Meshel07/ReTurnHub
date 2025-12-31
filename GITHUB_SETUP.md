# How to Upload Your App to GitHub

Follow these steps to upload your ReTurnHub app to GitHub.

## ⚠️ IMPORTANT: Before You Start

**Your app contains sensitive information:**
- Firebase API keys in `google-services.json` and `firebase_options.dart`
- Supabase API keys in `lib/services/supabase_config.dart`

**Options:**
1. **Remove sensitive data** before pushing (recommended for public repos)
2. **Use environment variables** for sensitive data
3. **Make the repository private** if you need to keep the keys

## Step 1: Install Git (if not already installed)

1. Download Git from: https://git-scm.com/download/win
2. Install it with default settings
3. Restart your terminal/PowerShell

## Step 2: Initialize Git Repository

Open PowerShell in your project directory and run:

```powershell
# Navigate to your project directory (if not already there)
cd "C:\Users\waqui\OneDrive\Desktop\ReTurnHub-C2 - Copynew\appfinal"

# Initialize git repository
git init

# Check git status
git status
```

## Step 3: Configure Git (First Time Only)

```powershell
# Set your name and email (replace with your GitHub username and email)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Step 4: Add Files to Git

```powershell
# Add all files to staging
git add .

# Check what will be committed
git status

# Create your first commit
git commit -m "Initial commit: ReTurnHub app"
```

## Step 5: Create a GitHub Repository

1. Go to [GitHub.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name**: `ReTurnHub` (or any name you prefer)
   - **Description**: "Lost and Found Items App"
   - **Visibility**: Choose **Private** (recommended) or **Public**
   - **DO NOT** check "Initialize with README" (you already have files)
5. Click **"Create repository"**

## Step 6: Connect Local Repository to GitHub

After creating the repository, GitHub will show you commands. Use these:

```powershell
# Add the remote repository (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/ReTurnHub.git

# Verify the remote was added
git remote -v
```

## Step 7: Push Your Code to GitHub

```powershell
# Push to GitHub (first time)
git branch -M main
git push -u origin main
```

You'll be prompted for your GitHub username and password (or personal access token).

## Step 8: Set Up Authentication (if needed)

If you get authentication errors:

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Click "Generate new token (classic)"
3. Give it a name and select scopes: `repo`
4. Copy the token
5. Use the token as your password when pushing

Or use GitHub Desktop (easier option):
- Download from: https://desktop.github.com/
- Sign in and use the GUI to push your code

## Step 9: Verify Upload

1. Go to your GitHub repository page
2. You should see all your files
3. Check that sensitive files are NOT visible (if you added them to .gitignore)

## Future Updates

To push future changes:

```powershell
# Check what changed
git status

# Add changed files
git add .

# Commit changes
git commit -m "Description of your changes"

# Push to GitHub
git push
```

## Protecting Sensitive Data

If you accidentally committed sensitive files:

1. **Remove sensitive files from Git history:**
   ```powershell
   # Remove file from Git but keep local copy
   git rm --cached google-services.json
   git rm --cached lib/services/supabase_config.dart
   
   # Commit the removal
   git commit -m "Remove sensitive files"
   
   # Push changes
   git push
   ```

2. **Add to .gitignore** (already done)
3. **Regenerate API keys** in Firebase/Supabase (old keys are now public)

## Alternative: Using GitHub Desktop

If you prefer a GUI:

1. Download [GitHub Desktop](https://desktop.github.com/)
2. Sign in with your GitHub account
3. Click "File" → "Add Local Repository"
4. Select your project folder
5. Click "Publish repository"
6. Choose name and visibility
7. Click "Publish repository"

## Troubleshooting

**Error: "fatal: not a git repository"**
- Make sure you're in the project directory
- Run `git init` first

**Error: "Authentication failed"**
- Use a Personal Access Token instead of password
- Or use GitHub Desktop

**Error: "remote origin already exists"**
- Remove it: `git remote remove origin`
- Add again: `git remote add origin https://github.com/YOUR_USERNAME/ReTurnHub.git`

**Want to exclude more files?**
- Edit `.gitignore` file
- Add file patterns you want to ignore

## Next Steps

After uploading:
- Add a README.md with project description
- Add screenshots of your app
- Set up GitHub Actions for CI/CD (optional)
- Add license file (optional)

