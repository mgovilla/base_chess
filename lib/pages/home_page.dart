import 'package:base_chess/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String dropdownValue =
    '5|5'; // Probably is a better way than making a global variable for this, but it works

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        authService.postOffline();
        break;
      case AppLifecycleState.resumed:
        authService.postOnline();
        break;
      default:
    }
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot doc) {
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              doc['Name'],
              style: Theme.of(context).textTheme.headline,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xffddddff),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Text(
              '+',
              style: Theme.of(context).textTheme.headline,
            ),
          ),
        ],
      ),
      onTap: () {
        _showDialog(doc);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    print(gameID);

    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge Friends Online'),
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (context) {
              List<PopupMenuItem<String>> a = [
                PopupMenuItem(
                  enabled: true,
                  child: Text('Sign out'),
                  value: 's',
                ),
                PopupMenuItem(
                  enabled: true,
                  child: Text('About'),
                  value: 'a',
                )
              ];

              return a;
            },
            onSelected: (value) {
              if (value == 's') {
                authService.signOut();
              } else if (value == 'a') {
                Navigator.pushNamed(context, '/developer_details_page');
              }
            },
          ),
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection('challenges').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _challengeDialog(snapshot.data.documents));
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: new BoxConstraints(
                        minHeight: 35.0,
                        maxHeight: height / 3.0,
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                          stream: Firestore.instance
                              .collection('online')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text('Loading...');
                            }
                            List<DocumentSnapshot> online =
                                snapshot.data.documents;
                            DocumentSnapshot toRemove;
                            for (DocumentSnapshot doc in online) {
                              if (doc['Name'] ==
                                  authService.currentUser.displayName) {
                                toRemove = doc;
                              }
                            }
                            online.remove(toRemove);

                            return ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: online.length,
                                itemBuilder: (context, index) =>
                                    _buildListItem(context, online[index]));
                          }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Join a Tournament',
                      style: Theme.of(context).textTheme.headline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: new BoxConstraints(
                        minHeight: 35.0,
                        maxHeight: height / 3.0,
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                          stream: Firestore.instance
                              .collection('tournaments')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return Text('Loading...');
                            return ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: snapshot.data.documents.length,
                                itemBuilder: (context, index) => _buildListItem(
                                    context, snapshot.data.documents[index]));
                          }),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FlatButton(
                      child: Text('Create a new Tournament'),
                      onPressed: () => print(authService.currentUser
                          .displayName), // Sometimes returns null during debug
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  bool receivedChallenge = false;
  void _challengeDialog(List<DocumentSnapshot> docList) {
    for (DocumentSnapshot doc in docList) {
      if (doc.documentID == authService.currentUser.uid) {
        if (!receivedChallenge) {
          // If the challenge has not been received yet (first time receiving)
          receivedChallenge = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("You've been challenged"),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(doc['issued'] +
                          ' has challenged you to a ' +
                          doc['control'] +
                          ' game'),
                      Text('This will be a live game'),
                    ],
                  ),
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Decline'),
                    onPressed: () {
                      Firestore.instance.runTransaction((transaction) async {
                        await transaction.delete(doc.reference);
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text('Accept'),
                    onPressed: () {
                      Firestore.instance.runTransaction((transaction) async {
                        await transaction.set(doc.reference, {
                          'accepted': 'true',
                          'issued': doc['issued'],
                          'control': doc['control'],
                          'gameID': 'none'
                        });
                      });
                    },
                  )
                ],
              );
            },
          );
        } else {
          // Has received the challenge before, so transfer to the game page when the gameID is established
          if (doc['gameID'] != 'none') {
            gameID = doc['gameID'];
            Firestore.instance.runTransaction((transaction) async {
              await transaction.delete(doc.reference);
            });

            receivedChallenge = false;
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/play_game_page');
          }
        }
      }
    }
  }

  void _showDialog(DocumentSnapshot doc) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Challenge ${doc['Name']}"),
          content: DialogContent(),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Confirm"),
              onPressed: () {
                authService.issueChallenge(doc.documentID, dropdownValue);
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/play_game_page');
              },
            ),
          ],
        );
      },
    );
  }
}

class DialogContent extends StatefulWidget {
  DialogContent({Key key}) : super(key: key);

  @override
  _DialogContentState createState() => new _DialogContentState();
}

class _DialogContentState extends State<DialogContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new DropdownButton<String>(
      value: dropdownValue,
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
        });
      },
      items: <String>['3|2', '5|5', '10|0']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
