import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterfire_ui/auth.dart';
import 'component/ChatsList.dart';
import 'component/Chat.dart';
import 'package:pwa_update_listener/pwa_update_listener.dart';

FirebaseFirestore db = FirebaseFirestore.instance;
Map<String, dynamic> userDbData = {};
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kReleaseMode) {
    db.settings = const Settings(persistenceEnabled: true);
    await db
        .enablePersistence(const PersistenceSettings(synchronizeTabs: true));
  }
  runApp(App(db: db));
}

class App extends StatelessWidget {
  const App({super.key, required this.db});
  final FirebaseFirestore db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oneline',
// This theme was made for FlexColorScheme version 6.1.1. Make sure
// you use same or higher version, but still same major version. If
// you use a lower version, some properties may not be supported. In
// that case you can also remove them after copying the theme to your app.
      theme: FlexThemeData.light(
        scheme: FlexScheme.flutterDash,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 9,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        // To use the playground font, add GoogleFonts package and uncomment
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.flutterDash,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 15,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        // To use the Playground font, add GoogleFonts package and uncomment
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),

      routes: {
        '/': (context) => AuthGate(),
        '/auth': (context) => AuthGate(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final User? user;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List messages = [];
  Map chatData = {};
  @override
  void initState() {
    debugPrint(widget.user.toString());
    User? userData = widget.user;

    Map<String, dynamic> user = {
      'email': userData?.email,
      'displayName': userData?.displayName,
      'meta_displayName': userData?.displayName != null
          ? userData?.displayName?.toLowerCase()
          : userData?.email?.replaceAll('@', 'at'),
      'photoURL': userData?.photoURL,
      'phoneNumber': userData?.phoneNumber,
      'uid': userData?.uid,
      'metaData': {
        'creationTime': userData?.metadata.creationTime,
        'lastSignInTime': userData?.metadata.lastSignInTime,
      }
    };

    db
        .collection("users")
        .doc(widget.user?.uid)
        .set(user)
        .onError((e, _) => debugPrint("Error writing document: $e"));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PwaUpdateListener(
      onReady: () {
        /// Show a snackbar to get users to reload into a newer version
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('A new update is ready')),
                TextButton(
                  onPressed: () {
                    reloadPwa();
                  },
                  child: Text('UPDATE'),
                ),
              ],
            ),
            duration: Duration(days: 365),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Row(
        children: <Widget>[
          Expanded(
              flex: 2500,
              child: Container(
                  color: Colors.black45,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: db
                        .collection('users')
                        .doc(widget.user?.uid)
                        .collection('chats')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ChatLists(
                            user: widget.user,
                            userData: userDbData,
                            data: snapshot.data?.docs ?? [],
                            openChat: (data) {
                              print('Chat opened');
                              setState(() {
                                chatData = data;
                              });
                            });
                      }

                      if (snapshot.hasError) {
                        return Text('Error');
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ))),
          if (chatData.isEmpty)
            Expanded(
                flex: 7500,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  child: Text(
                    textAlign: TextAlign.center,
                    'Pick a chat from the left',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ))
          else
            Expanded(
                flex: 7500,
                child: Chat(
                  data: chatData,
                  user: userDbData,
                )),
        ],
      ),
    ));
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // User is not signed in
            if (!snapshot.hasData) {
              return const SignInScreen(providerConfigs: [
                EmailProviderConfiguration(),
                GoogleProviderConfiguration(
                  clientId:
                      '227786802933-cgduhj8mkmulnorm9947n42tn6s60gp7.apps.googleusercontent.com',
                ),
              ]);
            }
            User? userData = snapshot.data;
            userDbData = {
              'email': userData?.email,
              'displayName': userData?.displayName,
              'meta_displayName': userData?.displayName != null
                  ? userData?.displayName?.toLowerCase()
                  : userData?.email?.replaceAll('@', 'at'),
              'photoURL': userData?.photoURL,
              'phoneNumber': userData?.phoneNumber,
              'uid': userData?.uid,
              'metaData': {
                'creationTime': userData?.metadata.creationTime,
                'lastSignInTime': userData?.metadata.lastSignInTime,
              }
            };

            return HomePage(user: snapshot.data);
          },
        );
      },
    );
  }
}
