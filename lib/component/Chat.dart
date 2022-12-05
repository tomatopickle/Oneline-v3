import 'package:flutter/material.dart';
import 'package:ezanimation/ezanimation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:oneline/main.dart';
import 'package:skeletons/skeletons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class Chat extends StatefulWidget {
  Chat(
      {super.key,
      required this.data,
      required this.user,
      required this.onClose});
  final Map data;
  final Map user;
  final Function onClose;
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final messageInputController = TextEditingController();
  final messageInputFocusNode = FocusNode();
  EzAnimation fabRevealAnimation =
      EzAnimation(0, 1, const Duration(milliseconds: 200));
  final messagesScrollController = ScrollController();
  bool textMessage = false;
  List messages = [];
  Map members = {};
  bool newMessage = false;
  bool oldMsgsLoading = false;
  int numberOfMessages = 35;
  bool showScrollDownBtn = false;

  @override
  void initState() {
    loadMessages();
    super.initState();
  }

  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    // In case props change
    loadMessages();
  }

  void loadMessages() {
    setState(() {
      messages = [];
    });
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
              .limitToLast(numberOfMessages)
              .snapshots()
              .listen(
            (event) {
              setState(() {
                messages = event.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  messagesScrollController.jumpTo(
                      messagesScrollController.position.maxScrollExtent);
                });

                messagesScrollController.addListener(() {
                  if (messagesScrollController.position.pixels < 500 &&
                      !oldMsgsLoading &&
                      messagesScrollController.position.userScrollDirection ==
                          ScrollDirection.forward) {
                    setState(() {
                      oldMsgsLoading = true;
                      numberOfMessages += 35;
                    });
                    db
                        .collection('chats')
                        .doc(widget.data['id'])
                        .collection('msgs')
                        .orderBy('time')
                        .limitToLast(numberOfMessages)
                        .get()
                        .then((value) {
                      setState(() {
                        oldMsgsLoading = false;
                        messages = value.docs;
                      });
                    });
                  }

                  if (messagesScrollController.offset <
                      (messagesScrollController.position.maxScrollExtent -
                          15)) {
                    setState(() {
                      showScrollDownBtn = true;
                    });
                  } else if (showScrollDownBtn == true) {
                    setState(() {
                      showScrollDownBtn = false;
                    });
                  }
                });
              });
            },
            onError: (error) => print("Listen failed: $error"),
          );
        });
      });
    });
  }

  void sendMessage() {
    if (messageInputController.text.isEmpty) {
      return;
    }
    int time = DateTime.now().millisecondsSinceEpoch;
    db.collection("chats").doc(widget.data['id']).collection('msgs').add({
      'type': 'text',
      'text': messageInputController.text,
      'time': time,
      'sender': widget.user['uid']
    });
    messageInputController.clear();
  }

  Widget build(BuildContext context) {
    fabRevealAnimation.start();
    Map chatData = {
      'name': widget.data['otherUserData']['displayName'] ??
          widget.data['otherUserData']['email'],
      'photoURL': widget.data['otherUserData']['photoURL'] ??
          'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
    };
    bool mobile = false;

    if (MediaQuery.of(context).size.width < 600) {
      if (!mobile) {
        setState(() {
          mobile = true;
        });
      }
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                widget.onClose();
              },
              icon: Icon(Icons.info)),
        ],
        leading: Row(children: [
          if (mobile == true)
            IconButton(
                onPressed: () {
                  widget.onClose();
                },
                icon: Icon(Icons.arrow_back_rounded)),
          SizedBox(
              width: 50,
              height: 42.5,
              child: CircleAvatar(
                  radius: 130,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(
                        chatData['photoURL'],
                        fit: BoxFit.cover,
                        height: 42.5,
                        scale: 0.25,
                      ))))
        ]),
        leadingWidth: mobile == true ? 100 : 50,
        title: Text(chatData['name']),
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: messages.isNotEmpty == true
            ? SingleChildScrollView(
                controller: messagesScrollController,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: renderMessages(
                        context, members, messages, oldMsgsLoading)))
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
      bottomNavigationBar: BottomAppBar(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              child: Row(children: [
                Expanded(
                    child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): () {
                      sendMessage();
                    },
                  },
                  child: TextField(
                    controller: messageInputController,
                    focusNode: messageInputFocusNode,
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
                    autofocus: true,
                    decoration: InputDecoration(
                        filled: true, hintText: "Message " + chatData['name']),
                  ),
                )),
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
                                sendMessage();
                              },
                              child: Icon(Icons.send_rounded),
                            ));
                      })
              ]))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedScale(
        duration: Duration(milliseconds: 250),
        scale: showScrollDownBtn ? 1.0 : 0.0,
        child: ElevatedButton.icon(
          onPressed: () {
            messagesScrollController.animateTo(
                messagesScrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn);
          },
          label: Text('Jump to bottom'),
          icon: Icon(Icons.arrow_downward_rounded),
        ),
      ),
    );
  }
}

String getLocalTime(int item) {
  var dateObj = DateTime.fromMillisecondsSinceEpoch(item);
  var time = (dateObj.hour < 13
          ? dateObj.hour.toString()
          : (dateObj.hour - 12).toString()) +
      ':' +
      ((dateObj.minute != 0) ? dateObj.minute.toString() : '00') +
      ' ' +
      (dateObj.hour < 13 ? 'AM' : 'PM');
  return time;
}

List<Widget> renderMessages(context, members, messages, oldMsgsLoading) {
  List<Widget> mesagesEls = !oldMsgsLoading
      ? []
      : [
          Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: CircularProgressIndicator()))
        ];
  Map previousMsg = {};
  for (var item in messages) {
    Widget el;
    Map msgData = item.data();
    if (previousMsg.isNotEmpty &&
        DateTime.fromMillisecondsSinceEpoch(item['time']).day !=
            DateTime.fromMillisecondsSinceEpoch(previousMsg['time']).day) {
      mesagesEls.add(Center(
          child: Container(
              margin: EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(75),
                color: Theme.of(context).canvasColor,
              ),
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: SelectableText(DateFormat.yMEd().format(
                  DateTime.fromMillisecondsSinceEpoch(item['time']))))));
    }

    if (item['type'] == 'meta') {
      el = Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(75),
                    color: Theme.of(context).canvasColor,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Text(msgData['text']))));
    } else {
      el = Padding(
          padding: EdgeInsets.only(
              top: (previousMsg['sender'] == msgData['sender'] ? 0 : 10),
              left: 5,
              right: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previousMsg['sender'] != msgData['sender'])
                SizedBox(
                    width: 42.5,
                    height: 42.5,
                    child: CircleAvatar(
                        radius: 130,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              members[msgData['sender']]['photoURL'] ??
                                  'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
                              fit: BoxFit.cover,
                              height: 42.5,
                              scale: 0.25,
                            ))))
              else
                SizedBox(
                  //Just to get that extra space when avatar is not there
                  width: 42.5,
                  height: 0,
                ),
              SizedBox(
                width: 15,
              ),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (previousMsg['sender'] != msgData['sender'])
                      // The user avatar UI
                      Row(
                        children: [
                          Opacity(
                            opacity: 0.75,
                            child: SelectableText(
                              members[msgData['sender']]['displayName'] ??
                                  members[msgData['sender']]['email'],
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          Opacity(
                            opacity: 0.5,
                            child: SelectableText(
                              getLocalTime(msgData['time']),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        Expanded(
                            child: SelectableText(
                          msgData['text'],
                          style: TextStyle(fontSize: 17.5),
                        )),
                        if ((DateTime.fromMillisecondsSinceEpoch(
                                        msgData['time'])
                                    .difference(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            previousMsg['time']))
                                    .inMinutes >
                                5) &&
                            previousMsg['sender'] == msgData['sender'])
                          Opacity(
                            opacity: 0.5,
                            child: SelectableText(
                              getLocalTime(msgData['time']),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    )
                  ]))
            ],
          ));
    }
    previousMsg = msgData;
    mesagesEls.add(el);
  }
  return mesagesEls;
}
