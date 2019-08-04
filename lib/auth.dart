import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;
  
  Observable<FirebaseUser> user;
  Observable<Map<String, dynamic>> profile;
  PublishSubject loading = PublishSubject();

  FirebaseUser currentUser;

  // Constructor
  AuthService() {
    user = Observable(_auth.onAuthStateChanged);

    profile = user.switchMap((FirebaseUser u) {
      if (u != null) {
        print('user is already logged in, currentUser is probably null');
        return _db
            .collection('users')
            .document(u.uid)
            .snapshots()
            .map((snap) => snap.data);
      } else {
        print('user is not logged in');
        return Observable.just({});
      }
    });
  }

  Future<FirebaseUser> googleSignIn() async {
    loading.add(true);
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    FirebaseUser user = await _auth.signInWithCredential(
        GoogleAuthProvider.getCredential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken));

    updateUserData(user);

    print("Signed in: " + user.displayName);
    loading.add(false);

    return user;
  }

  void updateUserData(FirebaseUser u) async {
    DocumentReference ref = _db.collection('users').document(u.uid);

    return ref.setData({
      'uid': u.uid,
      'email': u.email,
      'photoURL': u.photoUrl,
      'displayName': u.displayName,
      'lastSeen': DateTime.now()
    }, merge: true);
  }

  Future<void> postOnline() async { // I am not sure if this needs to be a Future or not
    _db.runTransaction((transaction) async {
      DocumentReference record =
          _db.collection('online').document(currentUser?.uid);

      await transaction
          .set(record, {'Name': currentUser?.displayName});
    });
  }

  Future<void> postOffline() async { // I am not sure if this needs to be a Future or not
    _db.runTransaction((transaction) async {
      DocumentReference record =
          _db.collection('online').document(currentUser?.uid);

      await transaction.delete(record);
    });
  }

  Future<void> issueChallenge(String to, String timeControl) async { // I am not sure if this needs to be a Future or not
    _db.runTransaction((transaction) async {
      DocumentReference record =
          _db.collection('challenges').document(to);

      await transaction.set(record, {'issued': currentUser?.displayName, 'control': timeControl});
    });
  }

  void signOut() {
    postOffline();
    _auth.signOut();
  }
}

final AuthService authService = new AuthService();
String gameID = '';