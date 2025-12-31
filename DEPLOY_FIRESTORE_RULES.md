# How to Deploy Firestore Rules

## Option 1: Deploy via Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on **Firestore Database** in the left sidebar
4. Click on the **Rules** tab at the top
5. Copy the entire contents of `firestore.rules` file
6. Paste it into the rules editor in the Firebase Console
7. Click **Publish** button
8. Wait for the deployment to complete (usually takes a few seconds)

## Option 2: Deploy via Firebase CLI

If you have Firebase CLI installed:

```bash
firebase deploy --only firestore:rules
```

## Verify Deployment

After deploying:
1. Refresh your app
2. Try clicking the message icon again
3. The permission errors should be resolved

## Important Notes

- Rules deployment is immediate but may take a few seconds to propagate
- Make sure you're logged in to the app when testing
- If errors persist, check the browser/app console for more specific error messages

## Troubleshooting

If you still get permission errors after deploying:

1. **Check if user document exists**: Make sure your user document exists in the `users` collection with your user ID
2. **Check authentication**: Ensure you're logged in (check `request.auth.uid` is not null)
3. **Check composite index**: The query `where('participants', arrayContains: userId).orderBy('updatedAt')` might need a composite index. If you get an index error, Firebase will provide a link to create it automatically.

