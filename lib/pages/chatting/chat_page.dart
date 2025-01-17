import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting
import 'package:image_picker/image_picker.dart';

import '../../services/authentication/auth_service.dart';
import '../../services/chat/chat_service.dart';
import '../../components/message_bubble.dart';
import '../User/login_page.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ChatPage extends StatefulWidget {
  final String recieverEmail;
  final String receiverID;
  final String firstName; // Add this parameter
  final String lastName; // Add this parameter
  final String fullName;
  final String userType;

  ChatPage({
    super.key,
    required this.recieverEmail,
    required this.receiverID,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.userType,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ImagePicker _picker =
      ImagePicker(); // Create an instance of ImagePicker

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        print("Image selected: ${pickedFile.path}");

        // Upload image to Firebase Storage
        File file = File(pickedFile.path);
        String fileName = path.basename(pickedFile.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images/${widget.receiverID}/$fileName');

        final uploadTask = storageRef.putFile(file);

        // Get the image URL after upload
        final snapshot = await uploadTask.whenComplete(() {});
        String imageUrl = await snapshot.ref.getDownloadURL();

        print("Image uploaded: $imageUrl");

        // Save image URL as a chat message
        await _chatService.sendMessage(widget.receiverID, imageUrl,
            isImage: true);
        _scrollToBottom(); // Scroll to the bottom
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Failed to pick an image: $e");
    }
  }

  // Text controller
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;

  // Chat and auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // To store the receiver's profile details
  String receiverFirstName = '';
  String receiverLastName = '';
  String recieverFullName = '';
  String receiverProfileImage =
      'https://picsum.photos/400/400'; // Default placeholder

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        // Check if the text field is not empty
        _isTyping = _messageController.text.isNotEmpty;
      });
    });
    receiverFirstName = widget.firstName;
    receiverLastName = widget.lastName;
    print(widget.userType);
    if (widget.userType == 'S') {
      recieverFullName = widget.fullName;
    } else {
      recieverFullName = '$receiverFirstName $receiverLastName';
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? capturedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (capturedFile != null) {
        print("Image captured: ${capturedFile.path}");

        // Upload image to Firebase Storage
        File file = File(capturedFile.path);
        String fileName = path.basename(capturedFile.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images/${widget.receiverID}/$fileName');

        final uploadTask = storageRef.putFile(file);

        // Get the image URL after upload
        final snapshot = await uploadTask.whenComplete(() {});
        String imageUrl = await snapshot.ref.getDownloadURL();

        print("Image uploaded: $imageUrl");

        // Save image URL as a chat message
        await _chatService.sendMessage(widget.receiverID, imageUrl,
            isImage: true);
        _scrollToBottom(); // Scroll to the bottom
      } else {
        print("No image captured.");
      }
    } catch (e) {
      print("Failed to capture an image: $e");
    }
  }

  // Fetch receiver details from Firestore
  void _fetchReceiverDetails() async {
    try {
      print("im here0");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverID) // Get user by receiver's ID
          .get();
      print("im here1");
      if (userDoc.exists) {
        print("im here2");

        final userData = userDoc.data()!;
        setState(() {
          receiverFirstName = userData['firstName'] ?? 'Unknown';
          receiverLastName = userData['lastName'] ?? 'User';
          recieverFullName = widget.fullName;
          receiverProfileImage = userData['profilePicture'] ??
              'https://picsum.photos/400/400'; // Default placeholder
        });
      } else
        print("user does not exist");
    } catch (e) {
      print("Failed to fetch user details: $e");
    }
  }

  // Send message
  void _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        print(
            "Sending message to receiverID: ${widget.receiverID}"); // Debug log
        await _chatService.sendMessage(widget.receiverID, message);
        _messageController.clear(); // Clear after sending
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom(); // Scroll to the bottom after sending a message
      } catch (e) {
        print("Failed to send message: $e");
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Build message list
// Build message list
  Widget _buildMessageList() {
    // String senderID = _authService.getCurrentUser()!.uid;
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      print("Error: No authenticated user found.");
    }
    String senderID = currentUser!.uid;

    return StreamBuilder(
      stream: _chatService.getMessages(senderID, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages."));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            _isTyping == false) {
          return const Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> docs = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        DateTime? lastMessageDate;

        for (var doc in docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Check if the timestamp is valid
          Timestamp? timestamp = data['timestamp'];
          if (timestamp != null) {
            DateTime messageDate = timestamp.toDate();
            String formattedDate =
                DateFormat('EEEE, MMM d').format(messageDate);

            // Check if it's a new day
            if (lastMessageDate == null ||
                lastMessageDate.day != messageDate.day ||
                lastMessageDate.month != messageDate.month ||
                lastMessageDate.year != messageDate.year) {
              // Add a date widget
              messageWidgets.add(
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }

            // Update the last message date
            lastMessageDate = messageDate;
          }

          // Add the message widget
          messageWidgets.add(_buildMessageItem(doc));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(); // Auto-scroll when messages update
        });

        return ListView(
          controller: _scrollController, // Attach the scroll controller
          children: messageWidgets,
        );
      },
    );
  }

// Build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    // Extract and format the timestamp
    Timestamp? timestamp = data['timestamp'];
    String formattedTime = '';
    if (timestamp != null) {
      DateTime dateTime = timestamp.toDate();
      formattedTime =
          DateFormat('hh:mm a').format(dateTime); // Format as 12-hour time
    }

    // Handle cases where message or imageUrl might be null
    String? message = data['message'] as String?;
    String? imageUrl = data['imageUrl'] as String?;

    return MessageBubble(
      message: message ?? '', // Use an empty string if the message is null
      isSent: isCurrentUser,
      senderID: data['senderID'],
      currentUserID: _authService.getCurrentUser()!.uid,
      timestamp: formattedTime, // Pass the formatted timestamp to MessageBubble
      imageUrl: imageUrl, // Pass the image URL if available
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 200, 191, 207),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20, // Make the back button smaller
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18, // Make the profile picture slightly smaller
              backgroundImage: NetworkImage(receiverProfileImage),
            ),
            const SizedBox(width: 8), // Adjust spacing between avatar and text
            Expanded(
              child: Text(
                '$recieverFullName',
                style: const TextStyle(
                  color: myColor,
                  fontSize: 16, // Slightly smaller font size
                  fontWeight:
                      FontWeight.w500, // Adjust weight for compact appearance
                ),
                overflow: TextOverflow.ellipsis, // Handle long names gracefully
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.call,
              color: myColor,
              size: 20, // Make the voice call icon smaller
            ),
            onPressed: () {
              print("Voice call pressed");
            },
          ),
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: myColor,
              size: 20, // Make the video call icon smaller
            ),
            onPressed: () {
              print("Video call pressed");
            },
          ),
          const SizedBox(width: 8), // Add a little padding at the end
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/craftsBackground.jpg'), // Add your image to assets
            fit: BoxFit.cover, // Ensures the image covers the entire screen
            colorFilter:
                ColorFilter.mode(myColor.withOpacity(0.1), BlendMode.dstATop),
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.grey[700]),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isTyping =
                                value.isNotEmpty; // Update the typing state
                          });
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.grey[700]),
                    onPressed: () {
                      _captureImage();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_outward,
                        color: _isTyping ? myColor : Colors.grey),
                    onPressed: _isTyping
                        ? () async {
                            final message = _messageController.text.trim();
                            if (message.isNotEmpty) {
                              await _chatService.sendMessage(
                                  widget.receiverID, message);
                              _messageController
                                  .clear(); // Clear the input field
                              setState(() {
                                _isTyping = false; // Reset typing state
                              });
                            }
                          }
                        : null, // Disable if not typing
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
