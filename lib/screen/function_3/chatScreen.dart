import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:side_sheet/side_sheet.dart';

class VetChatScreen extends StatefulWidget {
  const VetChatScreen({Key? key}) : super(key: key);

  @override
  State<VetChatScreen> createState() => _VetChatScreenState();
}

class _VetChatScreenState extends State<VetChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser!.uid;

  // Stream to get list of vets
  Stream<QuerySnapshot> _getVetsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'Vet')
        .snapshots();
  }

  // Navigate to the chat history screen for the selected vet
  void _navigateToChatHistory(String vetId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHistoryScreen(vetId: vetId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Vet Chats',
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
        onActionPressed: () => print("Action icon pressed"),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getVetsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      return Center(child: Text('No vets available'));
                    }

                    final vets = snapshot.data!.docs;

                    if (vets.isEmpty) {
                      return Center(child: Text('No vets available'));
                    }

                    return ListView.builder(
                      itemCount: vets.length,
                      itemBuilder: (context, index) {
                        final vet = vets[index];

                        return GestureDetector(
                          onTap: () => _navigateToChatHistory(vet.id),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(vet['image_url']),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${vet['name']} ${vet['lastName']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${vet['doctorId']}',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatHistoryScreen extends StatefulWidget {
  final String vetId;

  ChatHistoryScreen({Key? key, required this.vetId}) : super(key: key);

  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser!.uid;

  // Stream to get messages
  Stream<QuerySnapshot> _getMessagesStream() {
    return _firestore
        .collection('chats')
        .where('vetId', isEqualTo: widget.vetId) // Match vetId
        .where('clientId', isEqualTo: currentUserId) // Match clientId
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      print("Error fetching messages: $error");
    });
  }

  // Function to send a message
  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _firestore.collection('chats').add({
        'clientId': currentUserId,
        'vetId': widget.vetId,
        'participants': [currentUserId, widget.vetId],
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'sentBy': 'client',
      });
      _messageController.clear();
    }
  }

  Future<String> _getUserImage(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc['image_url'] ?? ''; // Add a placeholder if no image
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chat History',
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
        onActionPressed: () => print("Action icon pressed"),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getMessagesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Text('No messages yet'));
                    }

                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      if (snapshot.error
                          .toString()
                          .contains('FAILED_PRECONDITION')) {
                        return Center(
                            child: Text(
                                'Index is still building. Please wait a few minutes and try again.'));
                      }
                      return Center(child: Text('An error occurred'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No messages yet'));
                    }

                    var messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var messageData =
                            messages[index].data() as Map<String, dynamic>;

                        // Determine if the message is sent by the client
                        var isSentByClient =
                            messageData['sentBy'] == 'client' &&
                                messageData['clientId'] == currentUserId;

                        // Determine if the message is meant for the current chat
                        bool isMessageForThisChat = messageData['participants']
                                .contains(widget.vetId) &&
                            messageData['participants'].contains(currentUserId);

                        if (isMessageForThisChat) {
                          return FutureBuilder<String>(
                            future: _getUserImage(isSentByClient
                                ? currentUserId
                                : widget.vetId), // Fetch respective images
                            builder: (context, imageSnapshot) {
                              if (!imageSnapshot.hasData) {
                                return SizedBox.shrink(); // Wait for the image
                              }

                              final userImageUrl = imageSnapshot.data!;

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: isSentByClient
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (!isSentByClient)
                                      CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(userImageUrl),
                                      ),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.6,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      margin: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isSentByClient
                                            ? Color(nav)
                                            : Color(cards),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        messageData['message'],
                                        style: isSentByClient
                                            ? TextStyle(
                                                color: Colors.white,
                                                fontSize: 16)
                                            : TextStyle(
                                                color: Colors.black,
                                                fontSize: 16),
                                      ),
                                    ),
                                    if (isSentByClient)
                                      CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(userImageUrl),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          return SizedBox
                              .shrink(); // Hide messages not related to this chat
                        }
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      color: Color(nav),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
