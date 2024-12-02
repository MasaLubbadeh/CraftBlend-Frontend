import 'package:craft_blend_project/services/authentication/auth_service.dart';

import '../../pages/chatting/chat_page.dart';

import '../../services/chat/chat_service.dart';
import 'package:flutter/material.dart';
import '../../components/user_tile.dart';

class AllChats extends StatelessWidget {
  AllChats({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Page'),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        const Text("currently at the all chats page");
        //error
        if (snapshot.hasError) {
          return const Text("error");
          //loading
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }
        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No users found.");
        }
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

//build individual user
  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    //display all users except current user
    //  if (userData["email"] != _authService.getCurrrentUser()!.email) {
    return UserTile(
        text: userData["email"],
        onTap: () {
          //tapped on user -> go to chat page
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  recieverEmail: userData["email"],
                  receiverID: userData["uid"],
                ),
              ));
        });
    /* } else {
      return Container();
    }*/
  }
}
