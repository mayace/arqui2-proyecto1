import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:intl/intl.dart';

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

  static const DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";

  static const CARRO_TOPIC =
      "channels/1135982/publish/fields/field1/3ACLO7AQWY0ZJMOX";
  static const ARDUINO_TOPIC = "channels/1117472/subscribe/json";
  static const PROMEDIOS_TOPIC = "channels/1135979/subscribe/json";
  static const PETICIONES_TOPIC = "channels/1135982/subscribe/json";

  static const CARRO_UBICACION_TOPIC =
      "channels/1117472/subscribe/fields/field1";
  static const CARRO_ESTADO_TOPIC = "channels/1117472/subscribe/fields/field2";
  static const CARRO_PAQUETES_TOPIC =
      "channels/1117472/subscribe/fields/field3";
  static const CARRO_OBSTACULOS_TOPIC =
      "channels/1117472/subscribe/fields/field4";
  static const CARRO_PESO_TOPIC = "channels/1117472/subscribe/fields/field5";

  final amISubscribedTo = {"channels/1117472/subscribe/fields/field1": false};

  final mqttChannels = {
    ARDUINO_TOPIC: {
      "conectado": false,
      "nombre": "ARDUINO",
      "campos": [
        {"nombre": "Created at", "key": "created_at", "valor": null},
        {"nombre": "Ubicación", "key": "field1", "valor": null},
        {"nombre": "Estado", "key": "field2", "valor": null},
        {"nombre": "Paquetes entregados", "key": "field3", "valor": 0},
        {"nombre": "Obstaculos", "key": "field4", "valor": 0},
        {"nombre": "Peso", "key": "field5", "valor": 0},
        {"nombre": "Tiempo de entrega", "key": "field6", "valor": null},
        {"nombre": "Tiempo de retorno", "key": "field7", "valor": null},
      ],
      "valor": null
    },
    PROMEDIOS_TOPIC: {"conectado": false, "nombre": "promedios"},
    PETICIONES_TOPIC: {"conectado": false, "nombre": "peticiones"},
    CARRO_UBICACION_TOPIC: {
      "conectado": false,
      "nombre": "Ubicación",
      "valor": "No data.",
    },
    CARRO_ESTADO_TOPIC: {
      "conectado": false,
      "nombre": "Estado",
      "valor": "No data.",
    },
    CARRO_PAQUETES_TOPIC: {
      "conectado": false,
      "nombre": "Paquetes entregados",
      "valor": "No data.",
    },
    CARRO_OBSTACULOS_TOPIC: {
      "conectado": false,
      "nombre": "Obstáculos",
      "valor": "No data.",
    },
    CARRO_PESO_TOPIC: {
      "conectado": false,
      "nombre": "Peso paquete",
      "valor": "No data.",
    }
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
      payload: "[$title] $body",
    );
  }

  Future onSelectNotification(String payload) {
    return showDialog(
        context: this.context,
        builder: (context) => new AlertDialog(
              title: Text("Detalle"),
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

  Function(bool) mqttTopicSubscription(String topic) {
    return (val) {
      if (val) {
        this.client.subscribe(topic, MqttQos.atMostOnce);
      } else {
        this.client.unsubscribe(topic);
      }
    };
  }

  void onMqttMessageReceived(List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage message = c[0].payload;
    final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

    // this.showNotification("title", payload);

    final topic = c[0].topic;
    final localTopic = this.mqttChannels[topic];

    switch (topic) {
      case ARDUINO_TOPIC:
        final dy = json.decode(payload);
        final campos = localTopic["campos"] as List;
        var notificarLlegada = false;
        var notificarRetorno = false;

        for (Map item in campos) {
          final key = item["key"];
          var valorNuevo = dy[key];
          var valorActual = item["valor"];

          switch (key) {

            // paquetes entregados;
            case "field3":
              if (valorNuevo == null) {
                valorNuevo = 0;
              }
              valorNuevo = int.parse(valorActual.toString()) +
                  int.parse(valorNuevo.toString());
              if (int.parse(valorNuevo.toString()) > 0) {
                notificarLlegada = true;
              }
              break;
            // obstaculos;
            case "field4":
              if (valorNuevo == null) {
                valorNuevo = 0;
              }
              valorNuevo = int.parse(valorActual.toString()) +
                  int.parse(valorNuevo.toString());

              break;
            // peso
            case "field5":
              if (valorNuevo != null) {
                this.showNotification("Nuevo paquete",
                    "Con peso $valorNuevo a las ${formatearFecha(DateTime.now(), DATE_FORMAT)}.");
              }
              break;
            // tiempo en retornar
            case "field7":
              if (valorNuevo != null) {
                notificarRetorno = true;
              }
              break;
            default:
              if (valorNuevo == null) {
                valorNuevo = valorActual;
              }
          }

          setState(() {
            item["valor"] = valorNuevo;
          });
        }

        if (notificarLlegada) {
          this.showNotification("Paquete entregado",
              "Con peso 1, 2 obstaculos encontrados a las ${formatearFecha(DateTime.now(), DATE_FORMAT)} ");
        }
        if (notificarRetorno) {
          this.showNotification("Esperando paquete",
              "El carro retorno al punto de inicio a las ${formatearFecha(DateTime.now(), DATE_FORMAT)}, 10 obstaculos encontrados,");
        }

        break;
      default:
        print("${localTopic["nombre"]}: $payload");
    }

    setState(() {
      localTopic["valor"] = payload;
    });

    // final dd = json.decode(payload);
    // (localTopic["procesar"] as void Function(
    //     String))(payload);

    // setState(() {
    // testTopic.add("$topicName: $payload");
    // this.mqttChannels[localTopic]["valor"] = payload;
    // });
  }

  String formatCreatedAt(dynamic json) {
    final createdAt = json["created_at"];
    if (createdAt == null) {
      return null;
    }
    return formatearFecha(DateTime.parse(createdAt), "yyy-MM-dd hh:mm:ss");
  }

  String formatearFecha(DateTime fecha, String format) {
    if (fecha == null) {
      return null;
    }

    return DateFormat(format).format(fecha);
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

                          client.updates.listen(onMqttMessageReceived);
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
                    builder.addString(val ? "1" : "0");

                    print(CARRO_TOPIC);
                    this.client.publishMessage(
                        CARRO_TOPIC, MqttQos.atMostOnce, builder.payload);
                  },
                ),
                Text("Carro")
              ],
            ),
            Row(children: [
              Switch(
                  value: this.mqttChannels[ARDUINO_TOPIC]["conectado"],
                  onChanged: this.mqttTopicSubscription(ARDUINO_TOPIC)),
              Text("ARDUINO "),
            ]),
            Expanded(
                child: ListView.builder(
                    itemCount:
                        (this.mqttChannels[ARDUINO_TOPIC]["campos"] as List)
                            .length,
                    itemBuilder: (context, index) {
                      final canal = mqttChannels[ARDUINO_TOPIC];
                      final List campos = canal["campos"];
                      final item = campos[index];
                      final key = item["key"];
                      var valor = item["valor"];
                      if (valor != null && key == "created_at") {
                        valor =
                            formatearFecha(DateTime.parse(valor), DATE_FORMAT);
                      }
                      return Text("${item["nombre"]}: $valor");
                    }))
          ],
        ),
      ),
    );
  }
}
