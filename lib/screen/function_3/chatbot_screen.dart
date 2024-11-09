import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:animate_do/animate_do.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];
  bool _isTyping = false;
  String? userImageUrl;
  String? dogId; // To store the fetched dog ID

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user image URL
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        userImageUrl = userDoc['image_url'];

        // Fetch the dog ID from the user's 'petids' collection
        final QuerySnapshot petIdsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('petids')
            .get();

        if (petIdsSnapshot.docs.isNotEmpty) {
          // Assuming the first document in 'petids' collection is the one we need
          dogId = petIdsSnapshot.docs.first.id;
        }

        setState(() {});
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty || dogId == null) return;

    String userMessage = _controller.text;

    setState(() {
      _messages.add({'sender': 'user', 'message': userMessage});
      _isTyping = true;
    });

    _controller.clear();

    try {
      final response = await sendQuestionToMlModel(userMessage, dogId!);
      if (response != null) {
        setState(() {
          _messages.add({'sender': 'bot', 'message': response});
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'message':
                'Sorry, I couldn\'t process your request. Please try again.'
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': 'An error occurred. Please try again later.'
        });
        _isTyping = false;
      });
    }
  }

  Future<String?> sendQuestionToMlModel(String question, String dogId) async {
    final url = Uri.parse('http://$mlIP:8006/query');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'questions': [question],
      'dog_id': dogId, // Use the fetched dog ID
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 307) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectedResponse = await http.post(
            Uri.parse(redirectUrl),
            headers: headers,
            body: body,
          );
          if (redirectedResponse.statusCode == 200) {
            final jsonResponse = jsonDecode(redirectedResponse.body);
            final answer = jsonResponse['results'][0]['answer'];
            return answer;
          } else {
            print(
                'Failed to get response after redirect: ${redirectedResponse.statusCode}');
            return null;
          }
        } else {
          print('No redirect location found.');
          return null;
        }
      } else if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final answer = jsonResponse['results'][0]['answer'];
        return answer;
      } else {
        print('Failed to get response from ML Model: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending data to ML Model: $e');
      return null;
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: FadeIn(
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) _buildAvatar('assets/images/bot.png'),
            SizedBox(width: 8.0),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(12.0),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Text(
                message['message'] ?? '',
                style: TextStyle(color: isUser ? Colors.white : Colors.black),
              ),
            ),
            SizedBox(width: 8.0),
            if (isUser) _buildAvatar(userImageUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imagePath) {
    return CircleAvatar(
      radius: 16.0,
      backgroundImage: imagePath != null
          ? (imagePath.startsWith('http')
              ? NetworkImage(imagePath)
              : AssetImage(imagePath) as ImageProvider)
          : AssetImage('assets/images/default_avatar.png')
              as ImageProvider<Object>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'PoochPaw Chatbot',
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.pop(context);
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(), // Makes the blur cover the entire screen
          ),
          Padding(
            padding: const EdgeInsets.only(top: 90.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SpinKitThreeBounce(
                            color: Color(nav),
                            size: 20.0,
                          ),
                        );
                      }
                      final message = _messages[index];
                      return _buildMessage(message);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Ask from chatbot...',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.6)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
