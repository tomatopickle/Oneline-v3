import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fancy_avatar/fancy_avatar.dart';
import 'package:jiffy/jiffy.dart';
import 'package:side_sheet/side_sheet.dart';
import 'NewChat.dart';
import 'package:ezanimation/ezanimation.dart';
import 'package:skeletons/skeletons.dart';
import './SettingsDialog.dart';
import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase rDb = FirebaseDatabase.instance;

Widget UserInfo(context, User? user) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Expanded(
          flex: 2,
          child: Transform.scale(
              scale: .75,
              child: FittedBox(
                  fit: BoxFit.cover,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(130),
                      onTap: () {},
                      child: FancyAvatar(
                        radius: 130,
                        shadowColor: Colors.transparent,
                        userImage: Image.network(
                          fit: BoxFit.cover,
                          user?.photoURL ??
                              'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
                        ),
                        avatarBackgroundColor: Colors.black54,
                      ))))),
      const SizedBox(
        width: 5,
      ),
      Expanded(
        flex: 9,
        child: Text(
          user?.displayName ?? user?.email ?? '',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
      ),
      Opacity(
        opacity: 0.5,
        child: IconButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (_) {
                  return SettingsDialog(user: user);
                });
          },
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      )
    ],
  );
}

Widget ChatHeader(context, List contacts, User? user) {
  return Row(children: [
    Text(
      'Chats',
      style: Theme.of(context).textTheme.headline6,
    )
  ]);
}

class ChatLists extends StatefulWidget {
  const ChatLists(
      {super.key,
      required this.user,
      required this.userData,
      required this.data,
      required this.openChat});
  final User? user;
  final Map userData;
  final List? data;
  final Function? openChat;
  @override
  State<ChatLists> createState() => _ChatListsState();
}

class _ChatListsState extends State<ChatLists> {
  
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool chatsEmpty = widget.data?.isEmpty ?? true;
    List data = widget.data ?? [];
    bool mobile = false;

    if (MediaQuery.of(context).size.width < 600) {
      if (!mobile) {
        setState(() {
          mobile = true;
        });
      }
    }
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Image.asset('./images/logos/noBg.png',
                    height: 25,
                    opacity: const AlwaysStoppedAnimation<double>(0.5)),
                const SizedBox(width: 7.5),
                Text(
                  'Oneline',
                  style: Theme.of(context).textTheme.subtitle1,
                )
              ]),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 7.5),
              child: ChatHeader(context, [], widget.user),
            ),
            if (chatsEmpty) const Spacer(),
            if (chatsEmpty) const Text('No Chats'),
            if (chatsEmpty) const Spacer(),
            if (!chatsEmpty)
              Expanded(
                  child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 7.5),
                          child: FutureBuilder(
                            future: getDmUser(
                                widget.user?.uid ?? '', data[index]['members']),
                            builder: (_, snapshot) {
                              if (snapshot.hasData) {
                                var userData = snapshot.data!.data();
                                var chatName = userData!['displayName'] ??
                                    userData['email'] ??
                                    'No Name';
                                return Material(
                                    child: ListTile(
                                  onTap: () {
                                    var chat = data[index].data();
                                    chat['otherUserData'] = userData;
                                    widget.openChat!(chat);
                                  },
                                  leading: SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Stack(children: [
                                        FancyAvatar(
                                          radius: 130,
                                          shadowColor: Colors.transparent,
                                          ringWidth: 0,
                                          ringColor: Colors.transparent,
                                          userImage: Image.network(
                                            userData['photoURL'] ??
                                                'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
                                            fit: BoxFit.cover,
                                          ),
                                          avatarBackgroundColor:
                                              Colors.transparent,
                                        ),
                                        StreamBuilder(
                                            stream: rDb
                                                .ref(
                                                    'status/' + userData['uid'])
                                                .onValue,
                                            builder: (_, snapshot) {
                                              if (snapshot.hasData &&
                                                  (snapshot.data?.snapshot
                                                          .value !=
                                                      null)) {
                                                var e = snapshot.data?.snapshot
                                                    .value as dynamic;
                                                return Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: AnimatedScale(
                                                        scale: e['status'] ==
                                                                'online'
                                                            ? 1
                                                            : 0,
                                                        duration: Duration(
                                                            milliseconds: 100),
                                                        child: Container(
                                                            padding: EdgeInsets
                                                                .all(1),
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .cardColor,
                                                                  width: 1.5,
                                                                  strokeAlign:
                                                                      StrokeAlign
                                                                          .outside),
                                                              color:
                                                                  Colors.green,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            constraints:
                                                                BoxConstraints(
                                                              minHeight: 13,
                                                              minWidth: 13,
                                                            ),
                                                            child:
                                                                SizedBox())));
                                              } else {
                                                return SizedBox();
                                              }
                                            }),
                                      ])),
                                  title: Text(chatName),
                                ));
                              }
                              return ListTile(
                                leading: CircularProgressIndicator(),
                                title: LinearProgressIndicator(),
                              );
                            },
                          ),
                        );
                      })),
            UserInfo(context, widget.user),
          ],
        ),
        Positioned(
          bottom: 60,
          right: 7.5,
          child: FloatingActionButton.extended(
            onPressed: () {
              SideSheet.left(
                  width: mobile == true
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 4,
                  body: NewChat(userData: widget.userData),
                  context: context);
            },
            label: Text('New Chat'),
            icon: const Icon(Icons.add),
            isExtended: true,
          ),
        )
      ],
    );
  }
}

// Just here for reference to make new widgets with classes
class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({super.key});
  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  final int _favoriteCount = 41;
  @override
  Widget build(BuildContext context) {
    return Text('Simple example $_favoriteCount');
  }
}

Future getDmUser(String userUid, List members) {
  String uid = '';
  members.forEach((element) {
    if (userUid != element) {
      uid = element;
    }
  });

  return db.collection('users').doc(uid).get();
}

Future getLastMessage(String chatId) {
  return db
      .collection('chats')
      .doc(chatId)
      .collection('data')
      .doc('lastMessage')
      .get();
}

String getLocalTime(int item) {
  var dateObj = DateTime.fromMillisecondsSinceEpoch(item);
  var time = DateTime.now().difference(dateObj).inDays > 0
      ? (dateObj.toLocal().day.toString() +
          '/' +
          dateObj.toLocal().month.toString() +
          '/' +
          dateObj.toLocal().year.toString())
      : (dateObj.hour < 13
              ? dateObj.hour.toString()
              : (dateObj.hour - 12).toString()) +
          ':' +
          ((dateObj.minute != 0) ? dateObj.minute.toString() : '00') +
          ' ' +
          (dateObj.hour < 13 ? 'AM' : 'PM');
  return time;
}
