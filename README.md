# Base Chess

An mobile application that allows users to play live chess and set up realtime tournaments. Built with Flutter for the framework, Firebase for authentication and Cloud Firestore, and Challonge API to set up the tournaments. To create the chessboard, I reused code from the FlutterChess library by Deven98 (https://github.com/deven98/FlutterChess).

The user logs in with Google which grants access to the Cloud Firestore database. In the database, there is a collection for users who are currently online, and these users show up in the list at the home screen. And then, after the user taps someone he/she wants to challenge, a prompt shows up for the time control. There are 3 options: 10|0, 5|5, and 3|2.

_Known "bug": Users with the same display name will be indistinguishable_ 

| | |
|:------------------------------------: | :----------------------------------------------:|
|![Home Screen](/images/HomeScreen.jpg) | ![Challenge Screen](/images/ChallengeScreen.jpg)|

After sending the challenge, the user is shown the chess board screen while waiting for the opponent to accept or decline. The opponent's screen will show a dialog with the challenge information where he/she can accept the challenge and start the game.

| | |
|:------------------------------------: | :----------------------------------------------:|
|![Waiting Screen](/images/WaitingScreen.jpg) | ![Challenged Screen](/images/ChallengedScreen.jpg)|
