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

class App extends StatefulWidget {
  const App({super.key, required this.db});
  final FirebaseFirestore db;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Map settings = {
    'appearance': {'darkMode': true}
  };
  @override
  void initState() {
    print('DATA');
    if (FirebaseAuth.instance.currentUser?.uid.isEmpty ?? true) {
      return;
    }
    print(FirebaseAuth.instance.currentUser?.uid);
    print('USER EXISTS');
    // db
    //     .collection("users")
    //     .doc(FirebaseAuth.instance.currentUser?.uid)
    //     .get()
    //     .then((event) {
    //   setState(() {
    //     settings = event.data()?['settings'];
    //     print(settings);
    //   });
    // });
    db
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .listen((event) {
      setState(() {
        if (event.data()?['settings'] != null) {
          settings = event.data()?['settings'];
        }
      });
    });
    super.initState();
  }

  FlexScheme? getTheme() {
    for (var t in FlexScheme.values) {
      if (t.toString().replaceAll('FlexScheme.', '') ==
          settings['appearance']['theme']) {
        return t;
      }
    }
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oneline',
      theme: FlexThemeData.light(
        scheme: FlexScheme.flutterDash,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
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
        scheme: settings['appearance']['theme'] != null
            ? getTheme()
            : FlexScheme.flutterDash,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 15,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        // To use the Playground font, add GoogleFonts package and uncomment
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      themeMode:
          settings['appearance']['darkMode'] ? ThemeMode.dark : ThemeMode.light,
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
  Map settings = {
    'appearance': {'darkMode': true}
  };
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
        .set(user, SetOptions(merge: true))
        .onError((e, _) => debugPrint("Error writing document: $e"));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PwaUpdateListener(
      onReady: () {
        showDialog(
            context: context,
            builder: ((context) {
              return AlertDialog(
                title: const Text('Update Available'),
                content: const Text('A new update is ready'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Reload'),
                    onPressed: () {
                      reloadPwa();
                    },
                  ),
                  TextButton(
                    child: const Text('Later'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }));
      },
      child: Row(
        children: <Widget>[
          Expanded(
              flex: 2500,
              child: Container(
                  color: Theme.of(context).backgroundColor,
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
                          },
                        );
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
  const AuthGate({super.key});
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
