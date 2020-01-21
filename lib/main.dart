import 'package:flutter/material.dart';
import 'package:flutter_moor_basic/ui/home_page.dart';
import 'package:provider/provider.dart';

import 'data/moor_database.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider(
      builder: (_) => AppDatabase().taskDao,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage(),
      ),
    );
  }
}
