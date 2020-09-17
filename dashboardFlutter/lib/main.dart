import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyDashboardState createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyHomePage> {
  var testTopic = [];

  var isMqttConnected = false;

  static const CARRO_TOPIC =
      "channels/1117472/publish/fields/field1/8NCUJ7OGZ0KS1Q5F";
  static const ARDUINO_TOPIC = "channels/1117472/subscribe/json";
  static const PROMEDIOS_TOPIC = "channels/1135979/subscribe/json";
  static const PETICIONES_TOPIC = "channels/1135982/subscribe/json";

  final amISubscribedTo = {"channels/1117472/subscribe/fields/field1": false};

  final mqttChannels = {
    ARDUINO_TOPIC: {"conectado": false, "nombre": "arduino"},
    PROMEDIOS_TOPIC: {"conectado": false, "nombre": "promedios"},
    PETICIONES_TOPIC: {"conectado": false, "nombre": "peticiones"},
  };

  static const MQTT_SERVER = "mqtt.thingspeak.com";
  static const MQTT_CLIENT_ID = "movil_client";
  static const MQTT_USER = "movil_user";
  static const MQTT_KEY = "RXRMKFZ36GMDVRGB";

  static const MQTT_CANALES = {
    "DatosArduino": {
      "channelId": 1117472,
      "writeKey": "8NCUJ7OGZ0KS1Q5F",
      "readKey": "IREIF7337EH8HWYL",
    },
    "Promedios": {
      "channelId": 1135979,
      "writeKey": "AQ0XIG183CO29RDF",
      "readKey": "AG9TYKD91EIYP061",
    },
    "Peticiones": {
      "channelId": 1135982,
      "writeKey": "3ACLO7AQWY0ZJMOX",
      "readKey": "XED0552B491ZSGXY",
    }
  };

  MqttServerClient client =
      MqttServerClient.withPort(MQTT_SERVER, MQTT_CLIENT_ID, 1883);

  var carritoEncendido = false;

  bool get isConnected => client == null
      ? false
      : client.connectionStatus.state == MqttConnectionState.connected;

  MqttConnectionState get connectionState => client == null
      ? MqttConnectionState.disconnected
      : client.connectionStatus.state;

  List<Text> get textMessages => testTopic.map<Text>((e) => Text(e));

  FlutterLocalNotificationsPlugin noti;

  Future showNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await noti.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  Future onSelectNotification(String payload) {
    return showDialog(
        context: this.context,
        builder: (context) => new AlertDialog(
              title: Text("dd"),
              content: Text(payload),
            ));
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) {
    //   return NewScreen(
    //     payload: payload,
    //   );
    // }));
  }

  @override
  void initState() {
    super.initState();
    var androidSettings =
        new AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosSettings = new IOSInitializationSettings();
    var settings = new InitializationSettings(androidSettings, iosSettings);

    noti = FlutterLocalNotificationsPlugin();
    noti.initialize(settings, onSelectNotification: this.onSelectNotification);
  }

  void onMqttConnected() {
    print("mqtt connected");

    setState(() {
      isMqttConnected = true;
    });
  }

  void onMqttDisconnected() {
    print("mqtt disconnected");
    setState(() {
      isMqttConnected = false;
    });
  }

  void onMqttSubscribed(to) {
    setState(() {
      this.mqttChannels[to]["conectado"] = true;
    });
  }

  void onMqttUnsubscribed(to) {
    setState(() {
      this.mqttChannels[to]["conectado"] = false;
    });
  }

  void onMqttSubscribeFailed(to) {
    print(to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grupo #16"),
      ),
      body: Container(
        child: Column(
          children: [
            Row(
              children: [
                Switch(
                    value: this.isMqttConnected,
                    onChanged: (to) async {
                      try {
                        if (to) {
                          // client.logging(on: true);

                          client.onConnected = this.onMqttConnected;
                          client.onDisconnected = this.onMqttDisconnected;
                          client.onSubscribed = this.onMqttSubscribed;
                          client.onSubscribeFail = this.onMqttSubscribeFailed;
                          client.onUnsubscribed = this.onMqttUnsubscribed;
                          final connMesage = MqttConnectMessage()
                              .authenticateAs(MQTT_USER, MQTT_KEY)
                              .withClientIdentifier(MQTT_CLIENT_ID)
                              .startClean();

                          client.connectionMessage = connMesage;

                          print("mqtt connecting...");
                          await client.connect();
                          // print(status);

                          client.updates.listen(
                              (List<MqttReceivedMessage<MqttMessage>> c) {
                            final MqttPublishMessage message = c[0].payload;
                            final payload =
                                MqttPublishPayload.bytesToStringAsString(
                                    message.payload.message);

                            // this.showNotification("title", payload);

                            final topicName =
                                this.mqttChannels[c[0].topic]["nombre"];

                            final dd = json.decode(payload);

                            setState(() {
                              testTopic.add("$topicName: $dd");
                            });
                          });
                        } else {
                          client.disconnect();
                        }
                      } catch (e) {
                        print(e.toString());
                      }
                    }),
                Text("Mqtt"),
                Switch(
                  value: false,
                  onChanged: (val) {
                    final builder = MqttClientPayloadBuilder();
                    builder.addString(val ? "encender" : "apagar");

                    this.client.publishMessage(
                        CARRO_TOPIC, MqttQos.atMostOnce, builder.payload);
                  },
                ),
                Text("Carro")
              ],
            ),
            Row(
              children: [
                Switch(
                    value: this.mqttChannels[ARDUINO_TOPIC]["conectado"],
                    onChanged: (val) {
                      if (val) {
                        this
                            .client
                            .subscribe(ARDUINO_TOPIC, MqttQos.atMostOnce);
                      } else {
                        this.client.unsubscribe(ARDUINO_TOPIC);
                      }
                    }),
                Text("ARD"),
                Switch(
                    value: this.mqttChannels[PROMEDIOS_TOPIC]["conectado"],
                    onChanged: (val) {
                      if (val) {
                        this
                            .client
                            .subscribe(PROMEDIOS_TOPIC, MqttQos.atMostOnce);
                      } else {
                        this.client.unsubscribe(PROMEDIOS_TOPIC);
                      }
                    }),
                Text("PRO"),
                Switch(
                    value: this.mqttChannels[PETICIONES_TOPIC]["conectado"],
                    onChanged: (val) {
                      if (val) {
                        this
                            .client
                            .subscribe(PETICIONES_TOPIC, MqttQos.atMostOnce);
                      } else {
                        this.client.unsubscribe(PETICIONES_TOPIC);
                      }
                    }),
                Text("PET")
              ],
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: testTopic.length,
                    itemBuilder: (context, index) {
                      return Text(testTopic[index]);
                    }))
          ],
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  var testTopic = [];

  void onConnected() {
    print("connected");
  }

  void onDisconnected() {
    print("disconnected");
  }

  void _incrementCounter() async {
    MqttServerClient client =
        MqttServerClient.withPort('104.131.116.187', 'cesar', 1883);
    // client.logging(on: true);
    // client.onDisconnected = onDisconnected;
    // client.onConnected = onConnected;

    // final connMessage = MqttConnectMessage()
    //     .authenticateAs('', '')
    //     .keepAliveFor(60)
    //     .withWillTopic('')
    //     .withWillMessage('')
    //     .startClean()
    //     .withWillQos(MqttQos.atLeastOnce);
    // client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.subscribe("test", MqttQos.atLeastOnce);
      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);

        testTopic.add(payload);
        // print('Received message:$payload from topic: ${c[0].topic}>');
      });
    } catch (e) {
      print(e.toString());
      client.disconnect();
    }

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
