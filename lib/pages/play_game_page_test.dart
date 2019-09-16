import 'package:base_chess/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flutter_chess_board.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// Idea 1:
// Use ChessBoardController to make each move; wrap the buildChessBoard
// inside of a StreamBuilder:
// if the change was the opponents move, use the controller to makeMove and enableUserMoves
//  and then setState
// else confirm that the move was what the user sent and disable UserMoves
//

// onMove: (function inside the chessboard) setState() {
//    send the move to firebase through transaction
//    enableUserMoves = false;
// }

// Idea 2:
// Rebuild the chessboard every single move, and set the initMoves
// list to be equal to the list of moves that are recorded in firestore
// onMove: (function inside the chessboard) setState() {
//    send the move to firebase through transaction
//    enableUserMoves = false;
// }
class PlayGamePageTest extends StatefulWidget {
  @override
  _PlayGamePageTestState createState() => _PlayGamePageTestState();
}

class _PlayGamePageTestState extends State<PlayGamePageTest> {
  ChessBoardController controller= ChessBoardController();
  List<String> gameMoves = [];
  var flipBoardOnMove = true;
  bool startGame = false;
  bool userTurn = true;
  bool isWhite = true;
  Stream gameMoveStream =
      Firestore.instance.collection('challenges').snapshots();

  DocumentReference movesDocument;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    controller = ChessBoardController();
  }

  @override
  Widget build(BuildContext context) {
    gameID = 'abc'; //for testing purposes

    return WillPopScope(
      onWillPop: () {
        print('are you sure you want to exit');
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
                stream: gameMoveStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    for (DocumentSnapshot doc in snapshot.data.documents) {
                      if (doc.documentID == gameID && !userTurn) {
                        // This will only be true when the gameMoveStream changed, and the chessboard is built
                        movesDocument = doc.reference;

                        String moves = doc['moves'];
                        List<String> moveList = moves.split(',');
                        String toMove =
                            moveList[moveList.length - 1]; // Get the last move

                        controller.makeMoveNot(toMove);
                      }
                    }
                    gameMoveStream =
                        Firestore.instance.collection('games').snapshots();
                    return ListView(
                      children: <Widget>[
                        _buildChessBoard(),
                        _buildNotationAndOptions(),
                      ],
                    );
                  }

                  return Text('An error occured');
                })),
      ),
    );
  }

  Widget _buildChessBoard() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: ChessBoard(
          size: MediaQuery.of(context).size.width,
          onMove: (moveNotation) {
            userTurn = false;
            // Firestore.instance.runTransaction((transaction) async {
            //   DocumentSnapshot freshSnap = await transaction.get(movesDocument);
            //   await transaction.update(freshSnap.reference,
            //       {'moves': freshSnap['moves'] + (moveNotation + ' ')});
            // });
            print(moveNotation);
            setState(() {});
          },
          onCheckMate: (winColor) {
            _showDialog(winColor: winColor);
          },
          onDraw: () {
            _showDialog();
          },
          chessBoardController: controller,
          whiteSideTowardsUser: isWhite,
          enableUserMoves: userTurn,
        ));
  }

  Widget _buildNotationAndOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
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
