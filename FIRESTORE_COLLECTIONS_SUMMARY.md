# Firestore Collections Summary

This document provides a quick reference for all Firestore collections (tables) needed in your ReTurnHub app.

## 📊 Collections Overview

| Collection Name | Description | Document ID |
|----------------|-------------|-------------|
| `users` | User profiles and authentication data | User's Firebase Auth UID |
| `posts` | User posts (lost/found items) | Auto-generated |
| `comments` | Comments on posts | Auto-generated |
| `likes` | Post likes/reactions | Auto-generated |
| `chats` | Chat conversations between users | Auto-generated or composite |
| `messages` | Messages within chats | Auto-generated (subcollection) |

---

## 1. **users** Collection

**Path**: `users/{userId}`

**Fields**:
```
id: string
name: string
email: string
profileImage: string? (optional)
role: string ("user" or "admin")
createdAt: timestamp
```

**Example Document**:
```json
{
  "id": "abc123xyz",
  "name": "John Doe",
  "email": "john@example.com",
  "profileImage": "https://storage.googleapis.com/...",
  "role": "user",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**Status**: ✅ Already implemented in `AuthService`

---

## 2. **posts** Collection

**Path**: `posts/{postId}`

**Fields**:
```
id: string
userId: string
userName: string
userAvatar: string?
content: string
imageUrl: string? (optional)
createdAt: timestamp
updatedAt: timestamp
likesCount: number
commentsCount: number
type: string? ("lost" or "found")
location: string? (optional)
contact: string? (optional)
```

**Example Document**:
```json
{
  "id": "post123",
  "userId": "abc123xyz",
  "userName": "John Doe",
  "userAvatar": "https://storage.googleapis.com/...",
  "content": "Lost my keys near Central Park",
  "imageUrl": "https://storage.googleapis.com/...",
  "createdAt": "2024-01-20T14:30:00Z",
  "updatedAt": "2024-01-20T14:30:00Z",
  "likesCount": 5,
  "commentsCount": 2,
  "type": "lost",
  "location": "Central Park",
  "contact": "john@example.com"
}
```

**Service**: ✅ `PostService` - Ready to use

---

## 3. **comments** Collection

**Path**: `comments/{commentId}`

**Fields**:
```
id: string
postId: string
userId: string
userName: string
userAvatar: string?
content: string
createdAt: timestamp
```

**Example Document**:
```json
{
  "id": "comment456",
  "postId": "post123",
  "userId": "xyz789",
  "userName": "Jane Smith",
  "userAvatar": "https://storage.googleapis.com/...",
  "content": "I think I saw something similar!",
  "createdAt": "2024-01-20T15:00:00Z"
}
```

**Service**: ✅ `CommentService` - Ready to use

**Query Pattern**: Query by `postId` to get all comments for a post

---

## 4. **likes** Collection

**Path**: `likes/{likeId}`

**Fields**:
```
id: string
postId: string
userId: string
createdAt: timestamp
```

**Example Document**:
```json
{
  "id": "like789",
  "postId": "post123",
  "userId": "xyz789",
  "createdAt": "2024-01-20T16:00:00Z"
}
```

**Service**: ✅ `LikeService` - Ready to use

**Query Pattern**: 
- Query by `postId` to get all likes for a post
- Query by `postId` + `userId` to check if user liked a post

**Note**: Consider using composite document ID `{postId}_{userId}` to prevent duplicate likes

---

## 5. **chats** Collection

**Path**: `chats/{chatId}`

**Fields**:
```
id: string
participants: array<string>
participantNames: array<string>
participantAvatars: array<string?>
lastMessage: string?
lastMessageTime: timestamp?
lastMessageSenderId: string?
createdAt: timestamp
updatedAt: timestamp
```

**Example Document**:
```json
{
  "id": "chat123",
  "participants": ["abc123xyz", "xyz789"],
  "participantNames": ["John Doe", "Jane Smith"],
  "participantAvatars": ["https://...", "https://..."],
  "lastMessage": "Thanks for the help!",
  "lastMessageTime": "2024-01-20T17:00:00Z",
  "lastMessageSenderId": "xyz789",
  "createdAt": "2024-01-20T10:00:00Z",
  "updatedAt": "2024-01-20T17:00:00Z"
}
```

**Subcollection**: `messages` (see below)

**Service**: ✅ `ChatService` - Ready to use

**Query Pattern**: Query by `participants` array-contains to find chats for a user

---

## 6. **messages** Subcollection

**Path**: `chats/{chatId}/messages/{messageId}`

**Fields**:
```
id: string
senderId: string
senderName: string
senderAvatar: string?
content: string
timestamp: timestamp
```

**Example Document**:
```json
{
  "id": "msg456",
  "senderId": "abc123xyz",
  "senderName": "John Doe",
  "senderAvatar": "https://storage.googleapis.com/...",
  "content": "Hello, I found your item!",
  "timestamp": "2024-01-20T17:00:00Z"
}
```

**Service**: ✅ `ChatService` - Ready to use

**Query Pattern**: Query by `timestamp` to get messages in chronological order

---

## 🔍 Required Indexes

Create these indexes in Firebase Console → Firestore → Indexes:

1. **Comments by Post**
   - Collection: `comments`
   - Fields: `postId` (Ascending), `createdAt` (Ascending)

2. **Likes by Post**
   - Collection: `likes`
   - Fields: `postId` (Ascending), `createdAt` (Descending)

3. **Likes by User and Post**
   - Collection: `likes`
   - Fields: `userId` (Ascending), `postId` (Ascending)

4. **Chats by Participant**
   - Collection: `chats`
   - Fields: `participants` (Array), `updatedAt` (Descending)

5. **Posts by Date**
   - Collection: `posts`
   - Fields: `createdAt` (Descending)

---

## 🔐 Security Rules Summary

All collections require authentication (`request.auth != null`):

- **users**: Read any, write own
- **posts**: Read any, write own
- **comments**: Read any, write own
- **likes**: Read any, write own
- **chats**: Read/write if participant
- **messages**: Read/write if chat participant

See `FIRESTORE_INTEGRATION_GUIDE.md` for complete security rules.

---

## 📝 Quick Reference

### Create a Post
```dart
final postService = PostService();
await postService.createPost(post);
```

### Get Posts
```dart
final posts = await postService.getPosts();
// Or real-time:
postService.getPostsStream().listen((posts) { ... });
```

### Add Comment
```dart
final commentService = CommentService();
await commentService.addComment(
  postId: 'post123',
  userId: userId,
  userName: userName,
  content: 'Great post!',
);
```

### Like/Unlike Post
```dart
final likeService = LikeService();
final isLiked = await likeService.toggleLike('post123');
```

### Send Message
```dart
final chatService = ChatService();
await chatService.sendMessage(
  chatId: 'chat123',
  senderId: userId,
  senderName: userName,
  content: 'Hello!',
);
```

---

## ✅ Implementation Status

| Collection | Model | Service | Status |
|-----------|-------|---------|--------|
| users | ✅ UserModel | ✅ AuthService | ✅ Complete |
| posts | ✅ Post | ✅ PostService | ✅ Complete |
| comments | ✅ Comment | ✅ CommentService | ✅ Complete |
| likes | N/A | ✅ LikeService | ✅ Complete |
| chats | N/A | ✅ ChatService | ✅ Complete |
| messages | ✅ Message | ✅ ChatService | ✅ Complete |

---

## 🚀 Next Steps

1. Enable Firestore in Firebase Console
2. Set up security rules
3. Create required indexes
4. Update your UI pages to use the new services
5. Test all CRUD operations

See `FIRESTORE_SETUP_STEPS.md` for detailed setup instructions.

