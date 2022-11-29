import 'package:flutter/material.dart';
import 'package:ezanimation/ezanimation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneline/main.dart';
import 'package:skeletons/skeletons.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class Chat extends StatefulWidget {
  Chat({super.key, required this.data, required this.user});
  final Map data;
  final Map user;
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final messageInputController = TextEditingController();
  EzAnimation fabRevealAnimation =
      EzAnimation(0, 1, const Duration(milliseconds: 200));
  final messagesScrollController = ScrollController();
  bool textMessage = false;
  List messages = [];
  Map members = {};
  bool newMessage = false;
  @override
  void initState() {
    db
        .collection("chats")
        .doc(widget.data['id'])
        .collection('data')
        .doc('chatData')
        .get()
        .then((value) {
      value.data()!['members'].forEach((member) {
        db.collection("users").doc(member).get().then((value) {
          members[member] = value.data();
          db
              .collection('chats')
              .doc(widget.data['id'])
              .collection('msgs')
              .orderBy('time')
              .get()
              .then((value) {
            setState(() {
              messages = value.docs;
            });
            print('MEMBERS');
            print(members);
            db
                .collection('chats')
                .doc(widget.data['id'])
                .collection('msgs')
                .orderBy('time')
                .snapshots()
                .listen(
              (event) {
                setState(() {
                  messages = event.docs;
                  messagesScrollController.jumpTo(
                      messagesScrollController.position.maxScrollExtent + 100);
                });
              },
              onError: (error) => print("Listen failed: $error"),
            );
          });
        });
      });
    });

    super.initState();
  }

  Widget build(BuildContext context) {
    fabRevealAnimation.start();
    Map chatData = {
      'name': widget.data['otherUserData']['displayName'] ??
          widget.data['otherUserData']['email']
    };
    return Scaffold(
        appBar: AppBar(
          title: Text(chatData['name']),
          backgroundColor: Theme.of(context).backgroundColor,
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: messages.isNotEmpty == true
              ? SingleChildScrollView(
                  controller: messagesScrollController,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (var item in messages)
                      if (item['type'] == 'meta')
                        Center(
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(75),
                                  color: Theme.of(context).canvasColor,
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                child: Text(item.data()['text'])))
                      else
                        Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 42.5,
                                    height: 42.5,
                                    child: CircleAvatar(
                                        radius: 130,
                                        backgroundColor: Colors.transparent,
                                        child: ClipOval(
                                            clipBehavior: Clip.hardEdge,
                                            child: Image.network(
                                              members[item.data()['sender']]
                                                      ['photoURL'] ??
                                                  'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
                                              fit: BoxFit.cover,
                                              height: 42.5,
                                              scale: 0.25,
                                            )))),
                                SizedBox(
                                  width: 15,
                                ),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Opacity(
                                        opacity: 0.5,
                                        child: SelectableText(
                                          members[item.data()['sender']]
                                                  ['displayName'] ??
                                              members[item.data()['sender']]
                                                  ['email'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                      ),
                                      SelectableText(item.data()['text']),
                                    ]))
                              ],
                            ))
                  ]))
              : Column(
                  children: [
                    for (var i in List.filled(5, ''))
                      Row(
                        children: [
                          SkeletonAvatar(
                              style: SkeletonAvatarStyle(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(130)))),
                          SizedBox(
                            width: 15,
                            height: 75,
                          ),
                          SkeletonLine(
                            style: SkeletonLineStyle(
                                height: 25,
                                width: MediaQuery.of(context).size.width - 450,
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ],
                      )
                  ],
                ),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: messageInputController,
                      onChanged: ((value) {
                        setState(() {});
                        if (messageInputController.text.isNotEmpty) {
                          if (textMessage == false) {
                            fabRevealAnimation.reset();
                            fabRevealAnimation.start();
                          }
                          textMessage = true;
                        } else {
                          if (textMessage == true) {
                            fabRevealAnimation.reset();
                            fabRevealAnimation.start();
                          }
                          textMessage = false;
                        }
                      }),
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                          hintText: "Message " + chatData['name']),
                    ),
                  ),
                  SizedBox(width: 10),
                  if (messageInputController.text.isEmpty == true)
                    AnimatedBuilder(
                        animation: fabRevealAnimation,
                        builder: (context, snapshot) {
                          return Transform.scale(
                              scale: fabRevealAnimation.value,
                              child: FloatingActionButton(
                                onPressed: () {},
                                child: Icon(Icons.mic_rounded),
                              ));
                        })
                  else
                    AnimatedBuilder(
                        animation: fabRevealAnimation,
                        builder: (context, snapshot) {
                          return Transform.scale(
                              scale: fabRevealAnimation.value,
                              child: FloatingActionButton(
                                onPressed: () {
                                  int time =
                                      DateTime.now().millisecondsSinceEpoch;
                                  db
                                      .collection("chats")
                                      .doc(widget.data['id'])
                                      .collection('msgs')
                                      .add({
                                    'type': 'text',
                                    'text': messageInputController.text,
                                    'time': time,
                                    'sender': widget.user['uid']
                                  });
                                  messageInputController.clear();
                                },
                                child: Icon(Icons.send_rounded),
                              ));
                        })
                ]))));
  }
}
