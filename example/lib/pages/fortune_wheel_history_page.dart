import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpinScreen extends StatefulWidget {
  SpinScreen({Key? key}) : super(key: key);

  @override
  _SpinScreenState createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
 _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    totalSpins = prefs.getInt('totalSpins') ?? 0;
    totalWins = prefs.getInt('totalWins') ?? 0;
    totalLosses = prefs.getInt('totalLosses') ?? 0;
}

  @override
  void initState() {
    super.initState();
    _loadData();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios,color: Colors.green,)),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Total spins: ',
                style: TextStyle(fontSize: 50, color: Colors.green),
              ),
            ),
            Text(
              '$totalSpins',
              style: TextStyle(
                fontSize: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Total wins: ',
                style: TextStyle(fontSize: 50, color: Colors.green),
              ),
            ),
            Text(
              '$totalWins',
              style: TextStyle(
                fontSize: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Total losses: ',
                style: TextStyle(fontSize: 50, color: Colors.green),
              ),
            ),
            Text(
              '$totalLosses',
              style: TextStyle(
                fontSize: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
