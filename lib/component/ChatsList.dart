import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fancy_avatar/fancy_avatar.dart';
import 'package:side_sheet/side_sheet.dart';
import 'NewChat.dart';
import 'package:ezanimation/ezanimation.dart';

Widget UserInfo(context, User? user) {
  debugPrint(user?.photoURL ?? 'NO PHOTO');
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

Widget ChatLists(context, List contacts, User? user) {
  if (contacts.isEmpty) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 7.5),
              child: ChatHeader(context, [], user),
            ),
            const Spacer(),
            const Text('No Chats'),
            const Spacer(),
            UserInfo(context, user),
          ],
        ),
        Positioned(
          bottom: 60,
          right: 7.5,
          child: FloatingActionButton.extended(
            onPressed: () {
              SideSheet.left(
                  width: MediaQuery.of(context).size.width / 4,
                  body: NewChat(),
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

  return Column(
    children: [UserInfo(context, user)],
  );
}