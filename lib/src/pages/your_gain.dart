import 'package:flutter/material.dart';

class ImageFramePage extends StatefulWidget {

  @override
  _ImageFramePageState createState() => _ImageFramePageState();
}

class _ImageFramePageState extends State<ImageFramePage> {
  @override
  void initState() {
    super.initState();
    navigateToSecondRouteAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [Color(0xffb9b9b9), Color(0xffffffff)],
              stops: [0, 1],
              begin: Alignment.bottomCenter,
              end: Alignment.bottomCenter,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Container(
                child: Column(
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
                          width: 150,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
           Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Image.asset(
                      "assets/icons/sprite.png",
                      width: 490,
                    ),
                  ),
            Container(
              child: Column(
                children: [
                  Text(
                    "RÉCUPÉRER VOTRE GAIN",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.green),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.green,
                    size: 100,
                    fill: 1,
                    weight: 50,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future navigateToSecondRouteAfterDelay() async {
    // Return to first route after a delay
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pop(context);
    });
  }
}
