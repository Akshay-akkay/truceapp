import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const socketURL = 'wss://coral-app-xuy44.ondigitalocean.app/ws';

void main() {
  print('Connecting to socket $socketURL');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel channel;
  int? _counter;
  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse(socketURL),
    );

    // channel.stream.listen((message) {
    //   debugPrint('Received message: $message');
    // });

    channel.stream.listen((message) {
      setState(() {
        _counter = int.parse(message);
      });
    });
  }

  void _sendIncrementCommand() {
    channel.sink.add('increment');
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:\n And socker url is\n\n $socketURL',
            ),
            Text(
              _counter?.toString() ?? '?',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendIncrementCommand,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
