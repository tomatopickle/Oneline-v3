import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fancy_avatar/fancy_avatar.dart';
import 'package:side_sheet/side_sheet.dart';
import 'NewChat.dart';
import 'package:ezanimation/ezanimation.dart';
import 'package:skeletons/skeletons.dart';

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
          onPressed: () {},
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
      required this.data});
  final User? user;
  final Map userData;
  final List? data;
  @override
  State<ChatLists> createState() => _ChatListsState();
}

class _ChatListsState extends State<ChatLists> {
  @override
  Widget build(BuildContext context) {
    bool chatsEmpty = widget.data?.isEmpty ?? true;
    List data = widget.data ?? [];
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Image.asset('images/logos/noBg.png',
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
                        return Material(
                            color: Colors.transparent,
                            child: InkWell(
                                onTap: () {},
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 7.5),
                                  child: FutureBuilder(
                                    future: getDmUser(widget.user?.uid ?? '',
                                        data[index]['members']),
                                    builder: (_, snapshot) {
                                      if (snapshot.hasData) {
                                        var data = snapshot.data!.data();
                                        var chatName = data!['displayName'] ??
                                            data['email'] ??
                                            'No Name';
                                        return ListTile(
                                            leading: SizedBox(
                                              height: 50,
                                              width: 50,
                                              child: FancyAvatar(
                                                radius: 130,
                                                ringWidth: 0,
                                                ringColor: Colors.transparent,
                                                userImage: Image.network(
                                                  data['photoURL'] ??
                                                      'https://png.pngitem.com/pimgs/s/150-1503945_transparent-user-png-default-user-image-png-png.png',
                                                  fit: BoxFit.cover,
                                                ),
                                                avatarBackgroundColor:
                                                    Colors.transparent,
                                              ),
                                            ),
                                            title: Text(chatName));
                                      }
                                      return ListTile(
                                          leading: const SkeletonAvatar(
                                              style: SkeletonAvatarStyle(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              130)))),
                                          title: SkeletonLine(
                                            style: SkeletonLineStyle(
                                                height: 16,
                                                width: 64,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ));
                                    },
                                  ),
                                )));
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
                  width: MediaQuery.of(context).size.width / 4,
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
      print(uid);
    }
  });

  return db.collection('users').doc(uid).get();
}
