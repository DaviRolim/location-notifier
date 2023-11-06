import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wife Notifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<String> events = [];

  @override
  void initState() {
    super.initState();

    ////
    // (See docs for all 12 available events).
    //

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
      setState(() {
        events.add('providerchange');
        events.add(event.toString());
      });
    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: false, // Remove sounds
            logLevel: bg.Config.LOG_LEVEL_OFF))
        .then((bg.State state) {
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
      }
    });

    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      print('[geofence] - $event');
      setState(() {
        events.add('geofence');
        events.add(event.toString());
      });
      if (event.action == "ENTER" && event.identifier == "Home") {
        _sendMessage("I'm Home");
      }
      if (event.action == "EXIT" && event.identifier == "Home") {
        _sendMessage("Leaving Home");
      }
      if (event.action == "ENTER" && event.identifier == "LiveBox") {
        _sendMessage("Cheguei no cross");
      }
      if (event.action == "EXIT" && event.identifier == "LiveBox") {
        _sendMessage("Saindo agora do cross");
      }
    });

    bg.BackgroundGeolocation.addGeofence(
      bg.Geofence(
          identifier: "Home",
          radius: 100.0, // Radius in meters
          latitude: -7.113277,
          longitude: -34.8465357,
          notifyOnEntry: true,
          notifyOnDwell: true),
    );

    bg.BackgroundGeolocation.addGeofence(
      bg.Geofence(
          identifier: "LiveBox",
          radius: 80.0, // Radius in meters
          latitude: -7.115562525375726,
          longitude: -34.84152292795953,
          notifyOnEntry: true,
          notifyOnDwell: true,
          notifyOnExit: true),
    );
  }

  Future<Map<String, dynamic>> _getInstanceInfo() async {
    events.add('_getInstanceInfo');
    var url = Uri.parse(
        'https://whatsapp-api-8ins.onrender.com/instance/info?key=yetanother');
    var response = await http.get(url);
    events.add(response.statusCode.toString());
    events.add(response.body);
    return jsonDecode(response.body);
  }

  Future<void> _initInstance() async {
    events.add("initializing whataspp instance");
    var url = Uri.parse(
        'https://whatsapp-api-8ins.onrender.com/instance/init?key=yetanother&webhook=true&webhookUrl=https://webhook.site/d7114704-97f6-4562-9a47-dcf66b07266d');
    var response = await http.get(url);
    print(response.statusCode);
    if (response.statusCode == 200) {
      events.add(response.body);
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Future<void> _restoreInstance() async {
    events.add("restoring whataspp instance");
    var url =
        Uri.parse('https://whatsapp-api-8ins.onrender.com/instance/restore');
    var response = await http.get(url);
    print(response.statusCode);
    if (response.statusCode == 200) {
      events.add(response.body);
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Future<void> _sendMessage(String message) async {
    // Map<String, dynamic> infoResponse = await _getInstanceInfo();
    // if (infoResponse['instance_data']['phone_connected'] == false) {
    //   await _initInstance();
    //   // rest of your code
    // }
    try {
      // await _restoreInstance();
      setState(() {
        events.add('sending message');
      });
      var response = await http.post(
        Uri.parse(
            'https://whatsapp-api-8ins.onrender.com/message/text?key=yetanother'),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'id': '558399763846',
          'message': message,
        },
      );
      // TODO check if body has error key and if it is {"error":true,"message":"invalid key supplied"} if it is call -Init...
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (responseBody.containsKey('error') && responseBody['error'] == true) {
        if (responseBody['message'] == 'invalid key supplied') {
          await _initInstance();
          response = await http.post(
            Uri.parse(
                'https://whatsapp-api-8ins.onrender.com/message/text?key=yetanother'),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{
              'id': '558399763846',
              'message': message,
            },
          );
        }
      }
      setState(() {
        events.add(response.statusCode.toString());
        events.add(response.body);
      });
    } catch (e) {
      setState(() {
        events.add(e.toString());
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ...events.map((event) => Text(event)).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _sendMessage('Button Clicked'),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
