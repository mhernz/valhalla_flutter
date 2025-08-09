import 'package:flutter/material.dart';
import 'dart:async';

import 'package:valhalla_flutter/valhalla_flutter.dart';
import 'package:valhalla_flutter/valhalla_flutter_bindings_generated.dart'
    show ValhallaAction;
import 'package:valhalla_flutter_example/config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String> routeResult;

  @override
  void initState() {
    super.initState();
    const sfToSac = '''
      {
        "locations": [
          {"lat": 37.7749, "lon": -122.4194, "type": "break"},
          {"lat": 38.5816, "lon": -121.4944, "type": "break"}
        ],
        "costing": "auto",
        "directions_options": {"units": "miles"}
      }
    ''';
    ValhallaActor actor = ValhallaActor(VALHALLA_CONFIG);
    routeResult = Future.value(actor.act(ValhallaAction.ROUTE, sfToSac));
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                FutureBuilder<String>(
                  future: routeResult,
                  builder: (BuildContext context, AsyncSnapshot<String> value) {
                    final displayValue =
                        (value.hasData) ? value.data : 'loading';
                    return Text(
                      'route = $displayValue',
                      style: textStyle,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
