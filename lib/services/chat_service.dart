import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get chats collection reference
  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats');

  /// Get or create a chat between two users
  Future<String> getOrCreateChat(String otherUserId, String otherUserName, String? otherUserAvatar) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to start a chat');
      }

      final currentUserId = currentUser.uid;
      
      // Get current user data from Firestore, with fallback to Auth data
      String currentUserName;
      String? currentUserAvatar;
      
      try {
        final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (currentUserDoc.exists) {
          final currentUserData = currentUserDoc.data();
          currentUserName = currentUserData?['name'] as String? ?? currentUser.displayName ?? 'Unknown';
          currentUserAvatar = currentUserData?['profileImage'] as String? ?? currentUser.photoURL;
        } else {
          // User document doesn't exist, use Auth data
          currentUserName = currentUser.displayName ?? 'Unknown';
          currentUserAvatar = currentUser.photoURL;
        }
      } catch (e) {
        // If reading fails, use Auth data as fallback
        currentUserName = currentUser.displayName ?? 'Unknown';
        currentUserAvatar = currentUser.photoURL;
      }

      // Create sorted list of user IDs for consistent chat ID
      final participants = [currentUserId, otherUserId]..sort();
      final chatId = participants.join('_');

      // Ensure participant names/avatars align with sorted participant order
      final participantNames = participants.map((id) {
        if (id == currentUserId) {
          return currentUserName;
        }
        return otherUserName;
      }).toList();

      final participantAvatars = participants.map((id) {
        if (id == currentUserId) {
          return currentUserAvatar ?? '';
        }
        return otherUserAvatar ?? '';
      }).toList();

      // Check if chat already exists
      final chatDoc = await _chatsCollection.doc(chatId).get();
      
      if (chatDoc.exists) {
        // Ensure unreadCounts field exists for existing chats
        final chatData = chatDoc.data()!;
        if (!chatData.containsKey('unreadCounts')) {
          final existingParticipants = List<String>.from(chatData['participants'] ?? []);
          final unreadCountsMap = <String, int>{};
          for (var participantId in existingParticipants) {
            unreadCountsMap[participantId] = 0;
          }
          await _chatsCollection.doc(chatId).update({
            'unreadCounts': unreadCountsMap,
          });
        }
        return chatId;
      }

      // Create new chat with unread counts initialized to 0
      try {
        // Verify user is authenticated
        if (currentUser == null) {
          throw Exception('User is not authenticated. Please log in again.');
        }
        
        // Debug: Print what we're trying to create
        print('Creating chat with:');
        print('  chatId: $chatId');
        print('  currentUserId: $currentUserId');
        print('  currentUser.uid: ${currentUser.uid}');
        print('  participants: $participants');
        print('  participants type: ${participants.runtimeType}');
        print('  currentUserId in participants: ${participants.contains(currentUserId)}');
        print('  Auth token exists: ${currentUser.uid.isNotEmpty}');
        
        final chatData = {
          'id': chatId,
          'participants': participants,
          'participantNames': participantNames,
          'participantAvatars': participantAvatars,
          'lastMessage': null,
          'lastMessageTime': null,
          'lastMessageSenderId': null,
          'unreadCounts': {
            currentUserId: 0,
            otherUserId: 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        print('Chat data to be sent: $chatData');
        print('Verifying participants array:');
        print('  - participants is List: ${participants is List}');
        print('  - participants.length: ${participants.length}');
        print('  - Contains currentUserId: ${participants.contains(currentUserId)}');
        
        await _chatsCollection.doc(chatId).set(chatData);
        print('Chat created successfully!');
      } catch (createError) {
        // Check if it's a permission error and provide more details
        final errorStr = createError.toString();
        print('Error creating chat: $errorStr');
        print('Error type: ${createError.runtimeType}');
        
        if (errorStr.contains('permission-denied') || errorStr.contains('PERMISSION_DENIED')) {
          // Verify the participants array is correct
          if (!participants.contains(currentUserId)) {
            throw Exception('Current user ID is not in participants array. This is a bug.');
          }
          
          // Check authentication
          if (currentUser == null) {
            throw Exception('User is not authenticated. Please log out and log back in.');
          }
          
          throw Exception(
            'Permission denied creating chat.\n'
            'Current user ID: $currentUserId\n'
            'Participants: $participants\n'
            'User authenticated: ${currentUser != null}\n\n'
            'Please verify:\n'
            '1. Firestore rules are deployed to Firebase Console\n'
            '2. You are logged in with a valid account\n'
            '3. Your user document exists in the users collection'
          );
        }
        rethrow;
      }

      return chatId;
    } catch (e) {
      // Provide more detailed error message
      final errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        throw Exception('Permission denied. Please check your Firestore security rules allow chat creation. Make sure your user document exists in the users collection.');
      }
      throw Exception('Error getting or creating chat: ${e.toString()}');
    }
  }

  /// Get list of chats for the current user
  Future<List<Map<String, dynamic>>> getChatList(String userId) async {
    try {
      final snapshot = await _chatsCollection
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final chats = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final participantNames = List<String>.from(data['participantNames'] ?? []);
        final participantAvatars = List<String>.from(
          (data['participantAvatars'] ?? [])
              .map((value) => (value as String?) ?? ''),
        );
        
        // Find the other participant
        final otherIndex = participants.indexOf(userId) == 0 ? 1 : 0;
        final otherUserId = participants[otherIndex];
        final otherUserName = participantNames.length > otherIndex 
            ? participantNames[otherIndex] 
            : 'Unknown';
        final otherUserAvatar = participantAvatars.length > otherIndex 
            ? participantAvatars[otherIndex] 
            : null;

        DateTime? parseTimestamp(dynamic value) {
          if (value == null) return null;
          if (value is String) {
            return DateTime.tryParse(value);
          } else if (value is int) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          } else if (value is DateTime) {
            return value;
          } else if (value.toString().contains('Timestamp')) {
            return (value as dynamic).toDate();
          }
          return null;
        }

        // Get unread count for current user
        final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
        final unreadCount = (unreadCounts[userId] as int? ?? 0);

        chats.add({
          'chatId': doc.id,
          'recipientId': otherUserId,
          'recipientName': otherUserName,
          'recipientAvatar': otherUserAvatar,
          'lastMessage': data['lastMessage'],
          'lastMessageTime': parseTimestamp(data['lastMessageTime']),
          'unreadCount': unreadCount,
        });
      }

      return chats;
    } catch (e) {
      throw Exception('Error fetching chat list: ${e.toString()}');
    }
  }

  /// Stream of chat list for real-time updates
  Stream<List<Map<String, dynamic>>> getChatListStream(String userId) {
    try {
      return _chatsCollection
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return [];

        final chats = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          final participantNames = List<String>.from(data['participantNames'] ?? []);
        final participantAvatars = List<String>.from(
          (data['participantAvatars'] ?? [])
              .map((value) => (value as String?) ?? ''),
        );
          
          final otherIndex = participants.indexOf(userId) == 0 ? 1 : 0;
          final otherUserId = participants[otherIndex];
          final otherUserName = participantNames.length > otherIndex 
              ? participantNames[otherIndex] 
              : 'Unknown';
          final otherUserAvatar = participantAvatars.length > otherIndex 
              ? participantAvatars[otherIndex] 
              : null;

          DateTime? parseTimestamp(dynamic value) {
            if (value == null) return null;
            if (value is String) {
              return DateTime.tryParse(value);
            } else if (value is int) {
              return DateTime.fromMillisecondsSinceEpoch(value);
            } else if (value is DateTime) {
              return value;
            } else if (value.toString().contains('Timestamp')) {
              return (value as dynamic).toDate();
            }
            return null;
          }

          // Get unread count for current user
          final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
          final unreadCount = (unreadCounts[userId] as int? ?? 0);

          chats.add({
            'chatId': doc.id,
            'recipientId': otherUserId,
            'recipientName': otherUserName,
            'recipientAvatar': otherUserAvatar,
            'lastMessage': data['lastMessage'],
            'lastMessageTime': parseTimestamp(data['lastMessageTime']),
            'unreadCount': unreadCount,
          });
        }

        return chats;
      });
    } catch (e) {
      throw Exception('Error streaming chat list: ${e.toString()}');
    }
  }

  /// Get messages for a specific chat
  Future<List<Message>> getMessages(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to view messages');
      }

      final snapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromFirestore(
                doc.data(),
                doc.id,
                currentUser.uid,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching messages: ${e.toString()}');
    }
  }

  /// Stream of messages for real-time updates
  Stream<List<Message>> getMessagesStream(String chatId) {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to view messages');
      }

      return _chatsCollection
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Message.fromFirestore(
                    doc.data(),
                    doc.id,
                    currentUser.uid,
                  ))
              .toList());
    } catch (e) {
      throw Exception('Error streaming messages: ${e.toString()}');
    }
  }

  /// Send a message in a chat
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    // Optional post information
    String? postId,
    String? postUserId,
    String? postUserName,
    String? postUserAvatar,
    String? postContent,
    String? postImageUrl,
    String? postType,
    String? postLocation,
    String? postContact,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw Exception('Message text cannot be empty');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to send messages');
      }

      if (senderId != currentUser.uid) {
        throw Exception('Sender ID must match current user');
      }

      // Get chat document to find the recipient
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      
      // Find the recipient (the other participant)
      final recipientId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => senderId, // Fallback, shouldn't happen
      );

      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      // Create message document
      final messageRef = _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc();
      
      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content.trim(),
        'timestamp': timestamp,
        if (postId != null) 'postId': postId,
        if (postUserId != null) 'postUserId': postUserId,
        if (postUserName != null) 'postUserName': postUserName,
        if (postUserAvatar != null) 'postUserAvatar': postUserAvatar,
        if (postContent != null) 'postContent': postContent,
        if (postImageUrl != null) 'postImageUrl': postImageUrl,
        if (postType != null) 'postType': postType,
        if (postLocation != null) 'postLocation': postLocation,
        if (postContact != null) 'postContact': postContact,
      };
      
      batch.set(messageRef, messageData);

      // Get current unread counts
      final unreadCounts = Map<String, dynamic>.from(chatData['unreadCounts'] ?? {});
      final currentUnreadCount = (unreadCounts[recipientId] as int? ?? 0);
      
      // Update chat document with last message info and increment unread count for recipient
      final chatRef = _chatsCollection.doc(chatId);
      batch.update(chatRef, {
        'lastMessage': content.trim(),
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCounts.$recipientId': currentUnreadCount + 1, // Increment recipient's unread count
        'unreadCounts.$senderId': 0, // Reset sender's unread count (they sent it)
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Create notification for recipient (if not messaging themselves)
      if (recipientId != senderId) {
        final notificationService = NotificationService();
        await notificationService.createMessageNotification(
          chatId: chatId,
          recipientId: recipientId,
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          messageContent: content.trim(),
        );
      }

      return Message(
        id: messageRef.id,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content.trim(),
        timestamp: timestamp,
        isSentByMe: true,
        postId: postId,
        postUserId: postUserId,
        postUserName: postUserName,
        postUserAvatar: postUserAvatar,
        postContent: postContent,
        postImageUrl: postImageUrl,
        postType: postType,
        postLocation: postLocation,
        postContact: postContact,
      );
    } catch (e) {
      throw Exception('Error sending message: ${e.toString()}');
    }
  }

  /// Share a post in chat as a reply to the post
  /// This creates a system message indicating "You replied to [username]'s post"
  Future<Message> sharePostInChat({
    required String chatId,
    required String postId,
    required String postUserId,
    required String postUserName,
    String? postUserAvatar,
    required String postContent,
    String? postImageUrl,
    String? postType,
    String? postLocation,
    String? postContact,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to share posts');
      }

      // Verify chat exists and current user is a participant
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      
      if (!participants.contains(currentUser.uid)) {
        throw Exception('You are not a participant in this chat');
      }

      // Verify post author is the other participant
      if (!participants.contains(postUserId)) {
        throw Exception('Post author is not a participant in this chat');
      }

      // Get current user data for the system message
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['name'] as String? ?? currentUser.displayName ?? 'You';

      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      // Create system message document from current user indicating they replied to the post
      final messageRef = _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc();
      
      final messageData = {
        'senderId': currentUser.uid, // From current user
        'senderName': currentUserName,
        'senderAvatar': currentUser.photoURL,
        'content': "You replied to $postUserName's post", // System message text
        'timestamp': timestamp,
        'messageType': 'post_reply', // Mark as system message
        'postId': postId,
        'postUserId': postUserId,
        'postUserName': postUserName,
        'postUserAvatar': postUserAvatar,
        'postContent': postContent,
        if (postImageUrl != null) 'postImageUrl': postImageUrl,
        if (postType != null) 'postType': postType,
        if (postLocation != null) 'postLocation': postLocation,
        if (postContact != null) 'postContact': postContact,
      };
      
      batch.set(messageRef, messageData);

      // Find the recipient (the post author)
      final recipientId = postUserId;
      
      // Get current unread counts
      final unreadCounts = Map<String, dynamic>.from(chatData['unreadCounts'] ?? {});
      final currentUnreadCount = (unreadCounts[recipientId] as int? ?? 0);
      
      // Update chat document with last message info
      final chatRef = _chatsCollection.doc(chatId);
      batch.update(chatRef, {
        'lastMessage': "You replied to $postUserName's post",
        'lastMessageTime': timestamp,
        'lastMessageSenderId': currentUser.uid,
        'unreadCounts.$recipientId': currentUnreadCount + 1, // Increment post author's unread count
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Create notification for post author
      final notificationService = NotificationService();
      await notificationService.createMessageNotification(
        chatId: chatId,
        recipientId: recipientId,
        senderId: currentUser.uid,
        senderName: currentUserName,
        senderAvatar: currentUser.photoURL,
        messageContent: "replied to your post",
      );

      return Message(
        id: messageRef.id,
        senderId: currentUser.uid,
        senderName: currentUserName,
        senderAvatar: currentUser.photoURL,
        content: "You replied to $postUserName's post",
        timestamp: timestamp,
        isSentByMe: true, // From current user
        messageType: 'post_reply',
        postId: postId,
        postUserId: postUserId,
        postUserName: postUserName,
        postUserAvatar: postUserAvatar,
        postContent: postContent,
        postImageUrl: postImageUrl,
        postType: postType,
        postLocation: postLocation,
        postContact: postContact,
      );
    } catch (e) {
      throw Exception('Error sharing post in chat: ${e.toString()}');
    }
  }

  /// Mark chat as read (reset unread count for current user)
  Future<void> markChatAsRead(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to mark chat as read');
      }

      await _chatsCollection.doc(chatId).update({
        'unreadCounts.${currentUser.uid}': 0,
      });
    } catch (e) {
      // Silently fail - this is not critical
      print('Error marking chat as read: ${e.toString()}');
    }
  }

  /// Get total unread message count for current user across all chats
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final snapshot = await _chatsCollection
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
        final unreadCount = (unreadCounts[userId] as int? ?? 0);
        totalUnread += unreadCount;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }

  /// Stream of total unread message count for current user
  Stream<int> getTotalUnreadCountStream(String userId) {
    try {
      return _chatsCollection
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        int totalUnread = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
          final unreadCount = (unreadCounts[userId] as int? ?? 0);
          totalUnread += unreadCount;
        }
        return totalUnread;
      });
    } catch (e) {
      return Stream.value(0);
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to delete messages');
      }

      // Verify ownership
      final messageDoc = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data();
      if (messageData?['senderId'] != currentUser.uid) {
        throw Exception('You can only delete your own messages');
      }

      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting message: ${e.toString()}');
    }
  }

  /// Delete a chat (removes the entire chat document and all messages)
  Future<void> deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to delete chats');
      }

      // Verify the user is a participant in this chat
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      
      if (!participants.contains(currentUser.uid)) {
        throw Exception('You can only delete chats you are part of');
      }

      // Delete all messages in the chat
      final messagesSnapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the chat document
      batch.delete(_chatsCollection.doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting chat: ${e.toString()}');
    }
  }
}
