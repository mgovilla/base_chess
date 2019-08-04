import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/developer_details_page.dart';
import 'pages/login_page.dart';
import 'pages/play_game_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Base',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(title: "Chess Base",),
      // home: PlayGamePage(),
      routes: {
        '/home_page': (context) => HomePage(),
        '/login_page': (context) => LoginPage(),
        //'/openings_page': (context) => OpeningsPage(),
        '/play_game_page': (context) => PlayGamePage(),
        '/developer_details_page': (context) => DeveloperDetailsPage(),
      },
    );
  }
}