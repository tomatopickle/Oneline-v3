import 'dart:async';

// import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:fancy_avatar/fancy_avatar.dart';
import 'package:ezanimation/ezanimation.dart';
import 'package:uuid/uuid.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class NewChat extends StatefulWidget {
  const NewChat({super.key, required this.userData});
  final Map userData;
  @override
  State<StatefulWidget> createState() {
    return _NewChatState();
  }
}

class _NewChatState extends State<NewChat> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).dialogBackgroundColor,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Chat',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(
                  height: 15,
                ),
                DefaultTabController(
                    length: 2,
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height - 88,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(icon: Icon(Icons.person), text: 'Personal'),
                                Tab(
                                  icon: Icon(Icons.people),
                                  text: 'Group',
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Expanded(
                                child: TabBarView(
                              children: [
                                NewPersonalChat(userData: widget.userData),
                                const Center(
                                  child: Text('Coming soon'),
                                )
                              ],
                            )),
                          ],
                        ))),
                const SizedBox(
                  height: 15,
                ),
              ],
            )));
  }
}

class NewPersonalChat extends StatefulWidget {
  const NewPersonalChat({super.key, required this.userData});
  final Map userData;

  @override
  State<StatefulWidget> createState() {
    return _NewPersonalChatState();
  }
}

class _NewPersonalChatState extends State<NewPersonalChat> {
  final userSearchInputController = TextEditingController();
  List userSearchResults = [];
  bool loading = false;
  bool chatAlrExists = false;
  Map selectedUser = {};
  EzAnimation fabRevealAnimation =
      EzAnimation(0, 1, const Duration(milliseconds: 150));
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: userSearchInputController,
                onChanged: (value) {
                  setState(() {
                    userSearchResults = [];
                    chatAlrExists = false;
                  });
                },
                decoration: !chatAlrExists
                    ? InputDecoration(hintText: "Search for a user")
                    : InputDecoration(
                        hintText: "Search for a user",
                        errorStyle: TextStyle(),
                        errorText: 'Chat already exists'),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: chatAlrExists ? 25 : 0), // To fix a positional error
              child: FloatingActionButton(
                onPressed: () {
                  userSearchResults = [];
                  debugPrint(userSearchInputController.text);
                  setState(() {
                    loading = true;
                  });
                  db
                      .collection("users")
                      .where("meta_displayName",
                          isGreaterThanOrEqualTo:
                              userSearchInputController.text.toLowerCase())
                      .where("meta_displayName",
                          isLessThanOrEqualTo: "mi\uF7FF")
                      .get()
                      .then(
                    (res) {
                      for (var el in res.docs) {
                        userSearchResults.add(el.data());
                      }
                      setState(() {
                        loading = false;
                      });
                    },
                  );
                },
                child: const Icon(Icons.search),
              ),
            )
          ],
        ),
        const SizedBox(
          height: 25,
        ),
        if (loading)
          const LoadingIndicator(size: 40, borderWidth: 2)
        else if (userSearchInputController.text != '')
          Flexible(
              child: ListView.builder(
                  itemCount: userSearchResults.length,
                  itemBuilder: (context, index) {
                    Map user = userSearchResults[index];
                    return Material(
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: () {
                              setState(() {
                                int i = 0;
                                fabRevealAnimation.reset();

                                userSearchResults.forEach((element) {
                                  if (index != i) {
                                    userSearchResults[i]['selected'] = false;
                                  }
                                  selectedUser = userSearchResults[index];
                                  i++;
                                  fabRevealAnimation.start();
                                });

                                userSearchResults[index]['selected'] =
                                    userSearchResults[index]['selected'] == null
                                        ? true
                                        : !userSearchResults[index]['selected'];
                                if (userSearchResults[index]['selected'] ==
                                    false) {
                                  setState(() {
                                    selectedUser = {};
                                    chatAlrExists = false;
                                  });
                                }
                              });
                            },
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7.5),
                                child: ListTile(
                                  leading: SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: checkIfUserSelected(user),
                                  ),
                                  title: Text(
                                      user['displayName'] ?? user['email']),
                                ))));
                  }))
        else
          const Text(
            "Search with the user's username, email id, and phone number",
            textAlign: TextAlign.center,
          ),
        const Spacer(),
        if (selectedUser['meta_displayName'] !=
            null) // To check if a user is selected
          AnimatedBuilder(
              animation: fabRevealAnimation,
              builder: (context, snapshot) {
                return Transform.scale(
                    scale: fabRevealAnimation.value,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        print(widget.userData.toString());
                        db
                            .collection('users')
                            .doc(widget.userData['uid'])
                            .collection('chats')
                            .get()
                            .then((value) {
                          for (var e in value.docs) {
                            if (e['type'] != 'dm') {
                              return;
                            }
                            e.data()['members'].forEach((e) {
                              if (e == selectedUser['uid']) {
                                setState(() {
                                  chatAlrExists = true;
                                });
                              }
                            });
                          }
                        });
                        return;
                        var id = Uuid().v1();
                        int time = DateTime.now().millisecondsSinceEpoch;
                        Map<String, dynamic> chatData = {
                          'id': id,
                          'type': 'dm',
                          'members': <String>[
                            selectedUser['uid'],
                            widget.userData['uid']
                          ],
                          'creation_time': time
                        };
                        db
                            .collection("chats")
                            .doc(id)
                            .collection('data')
                            .doc('chatData')
                            .set(chatData);
                        db.collection("chats").doc(id).collection('msgs').add({
                          'type': 'meta',
                          'text': 'New chat created',
                          'time': time,
                          'meta_type': 'server_info'
                        });
                        chatData['members'].forEach((uid) {
                          db
                              .collection('users')
                              .doc(uid)
                              .collection('chats')
                              .doc(id)
                              .set(chatData);
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Chat'),
                    ));
              })
      ],
    );
  }
}

List searchUsers(q) {
  return [];
}

class NewGroupChat extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NewGroupChatState();
  }
}

class _NewGroupChatState extends State<NewGroupChat> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}

Widget checkIfUserSelected(user) {
  bool selected = user['selected'] ?? false;
  if (selected == false) {
    return CircleAvatar(
        radius: 130,
        child: ClipOval(
            child: Image.network(
          user['photoURL'] ??
              'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
          fit: BoxFit.contain,
          height: 50,
        )));
  } else {
    EzAnimation ezAnimation =
        EzAnimation(0, 1, const Duration(milliseconds: 150));
    ezAnimation.start();
    return AnimatedBuilder(
        animation: ezAnimation,
        builder: (context, snapshot) {
          return Transform.scale(
              scale: ezAnimation.value,
              child: const CircleAvatar(
                  radius: 130, child: ClipOval(child: Icon(Icons.check))));
        });
  }
}
