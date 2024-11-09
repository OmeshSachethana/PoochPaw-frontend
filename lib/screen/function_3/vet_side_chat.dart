import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/function_2/widget/appbar.dart';

class ClientChatScreen extends StatefulWidget {
  const ClientChatScreen({Key? key}) : super(key: key);

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Stream<List<DocumentSnapshot>> _getClientsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      // Extract participant IDs from the chat documents
      Set<String> clientIds = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['vetId'] == currentUserId) {
          clientIds.add(data['clientId']);
        } else {
          clientIds.add(data['vetId']);
        }
      }

      // Fetch the client details from the users collection
      var clientsSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: clientIds.toList())
          .get();

      return clientsSnapshot.docs;
    });
  }

  void _navigateToChatHistory(String clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHistoryScreen(
          clientId: clientId,
          vetId: currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Client Chats',
        actionImage: null,
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
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: _getClientsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('An error occurred'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No clients available'));
                    }

                    final clients = snapshot.data!;

                    return ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];

                        return GestureDetector(
                          onTap: () => _navigateToChatHistory(
                              client.id), // Use document ID as clientId
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
                                      NetworkImage(client['image_url']),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${client['name']} ${client['lastName']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
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
  final String clientId; // The current client's ID
  final String vetId; // The vet's ID

  ChatHistoryScreen({Key? key, required this.clientId, required this.vetId})
      : super(key: key);

  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser!.uid;
  Map<String, dynamic> clientData = {};
  Map<String, dynamic> vetData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Fetch client and vet user data from Firestore
    var clientSnapshot =
        await _firestore.collection('users').doc(widget.clientId).get();
    var vetSnapshot =
        await _firestore.collection('users').doc(widget.vetId).get();

    setState(() {
      clientData = clientSnapshot.data() ?? {};
      vetData = vetSnapshot.data() ?? {};
    });
  }

  Stream<QuerySnapshot> _getMessagesStream() {
    return _firestore
        .collection('chats')
        .where('vetId', isEqualTo: widget.vetId) // Match vetId
        .where('clientId', isEqualTo: widget.clientId) // Match clientId
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      print("Error fetching messages: $error");
    });
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _firestore.collection('chats').add({
        'vetId': currentUserId,
        'clientId':
            widget.clientId, // Corrected to use clientId for the receiver
        'participants': [
          currentUserId,
          widget.clientId
        ], // Corrected to use clientId
        'message': message,
        'sentBy': 'vet',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '',
        onActionPressed: () => print("Action icon pressed"),
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
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
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
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

                        // Determine if the message is sent by the vet
                        var isSentByVet = messageData['sentBy'] == 'vet' &&
                            messageData['vetId'] == currentUserId;

                        // Show the corresponding user's profile image
                        var userImage = isSentByVet
                            ? vetData['image_url'] // Vet's image
                            : clientData['image_url']; // Client's image

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: isSentByVet
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isSentByVet)
                                CircleAvatar(
                                  backgroundImage: userImage != null
                                      ? NetworkImage(userImage)
                                      : AssetImage('assets/default_user.png')
                                          as ImageProvider, // Default image if null
                                ),
                              SizedBox(width: 8),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                margin: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSentByVet
                                      ? Color(nav) // Replace with your color
                                      : Color(cards), // Replace with your color
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  messageData['message'],
                                  style: isSentByVet
                                      ? TextStyle(
                                          color: Colors.white, fontSize: 16)
                                      : TextStyle(
                                          color: Colors.black, fontSize: 16),
                                ),
                              ),
                              SizedBox(width: 8),
                              if (isSentByVet)
                                CircleAvatar(
                                  backgroundImage: userImage != null
                                      ? NetworkImage(userImage)
                                      : AssetImage('assets/default_user.png')
                                          as ImageProvider, // Default image if null
                                ),
                            ],
                          ),
                        );
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
