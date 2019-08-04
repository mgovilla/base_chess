import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;

class Tournament {
  var apikey, username;
  Map<String, String> headers = {"Content-type": "application/json"};

  Tournament(String a, String u) {
    this.apikey = a;
    this.username = u;
  }

  void addParticipant(String tournament) async { // String Name 
    var url = Uri.parse('https://$username:$apikey@api.challonge.com/v1/tournaments/$tournament/participants.json');
    var client = new http.Client();

    String n = _generateRandomURL();
    String tParticipant = '{"participant":' + aParticipantJson(n).toString() + '}';
    print(tParticipant);

    try {
      var response = await http.post(url, headers: headers, body: tParticipant);

      String body = response.body;
      print(body);

    } finally {
      client.close();
    }
  }

  void startTournament(String tournament) async {
    var url = Uri.parse('https://$username:$apikey@api.challonge.com/v1/tournaments/$tournament/start.json');
    var client = new http.Client();

    try {
      var response = await http.post(url);

      String body = response.body;
      print(body);
      
    } finally {
      client.close();
    }

  }

  void createTournament(int p) async {
    //List<String>
    var url = Uri.parse('https://$username:$apikey@api.challonge.com/v1/tournaments.json');
    var client = new http.Client();

    String n = _generateRandomURL();
    String tParams = '{"tournament":' + tCreateJson(n, p).toString() + '}';
    print(tParams);

    try {
      var response = await http.post(url, headers: headers, body: tParams);

      String body = response.body;
      print(body);

    } finally {
      client.close();
    }
  }

  Map<String, String> tCreateJson(String n, int p) => {
        '"name"': '"' + n + '"',
        '"tournament_type"': '"single elimination"',
        '"hold_third_place_match"': '"true"',
        '"participants_count"': '"' + p.toString() + '"',
        '"game_name"': '"Chess"',
        '"url"': '"' + n + '"'
      };

  Map<String, String> aParticipantJson(String name) => {
        '"name"': '"' + name + '"'
      };

  String _generateRandomURL() {
    var temp = "";
    const String alpha_numeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    for(int i = 0; i < 10; i++) {
      var rand = Random();
      var index = rand.nextInt(35);
      temp += alpha_numeric.substring(index, index + 1);
    }

    return temp;
  }
}
