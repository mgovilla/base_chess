import 'package:base_chess/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PlayGamePage extends StatefulWidget {
  @override
  _PlayGamePageState createState() => _PlayGamePageState();
}

class _PlayGamePageState extends State<PlayGamePage> {
  ChessBoardController controller;
  List<String> gameMoves = [];
  var flipBoardOnMove = true;
  bool startGame = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    controller = ChessBoardController();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        startGame = false;
        gameID = '';
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Play with a friend"),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection('challenges').snapshots(),
              builder: (context, snapshot) {
                if (gameID != '') {
                  startGame = true;
                }
                if (!startGame && snapshot.data != null) {
                  for (DocumentSnapshot doc in snapshot.data.documents) {
                    if (doc['issued'] == authService.currentUser.displayName &&
                        doc['accepted'] == 'true') {
                      gameID = _generateRandomURL();
                      Firestore.instance.runTransaction((transaction) async {
                        await transaction.set(doc.reference, {
                          'accepted': 'true',
                          'issued': doc['issued'],
                          'control': doc['control'],
                          'gameID': gameID
                        });
                      });
                      startGame = true;
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => Navigator.of(context).pop());
                    } else {
                      // The document exists, which means the challenged person did not accept or decline yet
                      print('waiting');
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _waitingDialog());
                    }
                  }
                }

                return ListView(
                  children: <Widget>[
                    _buildChessBoard(),
                    _buildNotationAndOptions(),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildChessBoard() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: ChessBoard(
          size: MediaQuery.of(context).size.width,
          onMove: (moveNotation) {
            print(moveNotation);
            gameMoves.add(moveNotation);
            setState(() {});
          },
          onCheckMate: (winColor) {
            _showDialog(winColor: winColor);
          },
          onDraw: () {
            _showDialog();
          },
          chessBoardController: controller,
          whiteSideTowardsUser:
              flipBoardOnMove ? gameMoves.length % 2 == 0 ? true : false : true,
        ));
  }

  Widget _buildNotationAndOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Flip board on move",
                style: TextStyle(fontSize: 18.0),
              ),
              Switch(
                  value: flipBoardOnMove,
                  onChanged: (value) {
                    flipBoardOnMove = value;
                    setState(() {});
                  }),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: () {
                      _resetGame();
                    },
                    child: Text("Reset game"),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: () {
                      _undoMove();
                    },
                    child: Text("Undo Move"),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: _buildMovesList(),
          )
        ],
      ),
    );
  }

  void _waitingDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Waiting for opponent...'),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void _showDialog({String winColor}) {
    winColor != null
        ? showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: new Text("Checkmate!"),
                content: new Text("$winColor wins!"),
                actions: <Widget>[
                  // usually buttons at the bottom of the dialog
                  new FlatButton(
                    child: new Text("Play Again"),
                    onPressed: () {
                      _resetGame();
                      Navigator.of(context).pop();
                    },
                  ),
                  new FlatButton(
                    child: new Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          )
        : showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: new Text("Draw!"),
                content: new Text("The game is a draw!"),
                actions: <Widget>[
                  // usually buttons at the bottom of the dialog
                  new FlatButton(
                    child: new Text("Play Again"),
                    onPressed: () {
                      _resetGame();
                      Navigator.of(context).pop();
                    },
                  ),
                  new FlatButton(
                    child: new Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
  }

  void _resetGame() {
    controller.resetBoard();
    gameMoves.clear();
    setState(() {});
  }

  void _undoMove() {
    controller.game.undo_move();
    if (gameMoves.length != 0) gameMoves.removeLast();
    setState(() {});
  }

  String _generateRandomURL() {
    var temp = "";
    const String alpha_numeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    for (int i = 0; i < 10; i++) {
      var rand = Random();
      var index = rand.nextInt(35);
      temp += alpha_numeric.substring(index, index + 1);
    }

    return temp;
  }

  List<Widget> _buildMovesList() {
    List<Widget> children = [];

    for (int i = 0; i < gameMoves.length; i++) {
      if (i % 2 == 0) {
        children.add(Text(
            "${(i / 2 + 1).toInt()}. ${gameMoves[i]} ${gameMoves.length > (i + 1) ? gameMoves[i + 1] : ""}"));
      } else {}
    }

    return children;
  }
}
