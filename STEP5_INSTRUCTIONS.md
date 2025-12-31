# Step 5: Connect to GitHub and Push

## After creating your GitHub repository, run these commands:

### 1. Add the remote repository
Replace `YOUR_USERNAME` with your actual GitHub username:

```powershell
git remote add origin https://github.com/YOUR_USERNAME/ReTurnHub.git
```

**Example:** If your username is `johnsmith`, the command would be:
```powershell
git remote add origin https://github.com/johnsmith/ReTurnHub.git
```

### 2. Verify the remote was added
```powershell
git remote -v
```

You should see:
```
origin  https://github.com/YOUR_USERNAME/ReTurnHub.git (fetch)
origin  https://github.com/YOUR_USERNAME/ReTurnHub.git (push)
```

### 3. Rename branch to main (if needed)
```powershell
git branch -M main
```

### 4. Push your code to GitHub
```powershell
git push -u origin main
```

**Note:** You'll be prompted for:
- **Username:** Your GitHub username
- **Password:** Use a Personal Access Token (NOT your GitHub password)

### 5. If you need a Personal Access Token:

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name: "ReTurnHub Upload"
4. Select scope: Check `repo` (this gives full repository access)
5. Click "Generate token"
6. **COPY THE TOKEN IMMEDIATELY** (you won't see it again!)
7. Use this token as your password when pushing

## Troubleshooting

**Error: "remote origin already exists"**
```powershell
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/ReTurnHub.git
```

**Error: "Authentication failed"**
- Make sure you're using a Personal Access Token, not your password
- The token must have `repo` scope checked

**Error: "repository not found"**
- Check that you spelled your username correctly
- Make sure the repository name matches exactly

