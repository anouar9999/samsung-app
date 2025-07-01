import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: Colors.black,
  fontFamily: 'Gotham',
  scaffoldBackgroundColor: const Color(0xFFC8E6C9),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
      .copyWith(secondary: Colors.green),
);
