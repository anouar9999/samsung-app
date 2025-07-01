import 'package:flutter/material.dart';

class soufleurPage extends StatefulWidget {

  @override
  _ImageFramePageState createState() => _ImageFramePageState();
}

class _ImageFramePageState extends State<soufleurPage> {
  @override
  void initState() {
    super.initState();
    navigateToSecondRouteAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child:  Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "BERED W NTA3CH",
                      style: TextStyle(
                          fontSize: 55,
                          fontWeight: FontWeight.w900,
                          color: Colors.green),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "M3A",
                          style: TextStyle(
                              fontSize: 55,
                              fontWeight: FontWeight.w700,
                              color: Colors.green),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Image.asset(
                          "assets/Sprite-Logo-removebg-preview (2).png",
                          width: 300,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
         
      ) );
  }

  Future navigateToSecondRouteAfterDelay() async {
    // Return to first route after a delay
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pop(context);
    });
  }
}
