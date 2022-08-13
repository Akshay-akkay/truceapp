import 'dart:io';

import 'package:redis/redis.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _clients = <WebSocketChannel>[];

// Initialize the redis client.
late final RedisConnection conn;
late final Command command;

late final RedisConnection pubsubConn;
late final Command pubsubCommand;
late final PubSub pubsub;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/ws', webSocketHandler(_handler));

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void _handler(WebSocketChannel webSocket) {
  _clients.add(webSocket);
  command.send_object(['GET', 'counter']).then((value) {
    webSocket.sink.add(value.toString());
  });

  stdout.writeln('[CONNECTED] $webSocket');
  webSocket.stream.listen(
    (message) async {
      stdout.writeln('[RECEIVED] $message');
      if (message == 'increment') {
        final newCounterVal = await command.send_object(['INCR', 'counter']);
        command.send_object(['PUBLISH', 'counterUpdate', 'counter']);
        for (var client in _clients) {
          client.sink.add(newCounterVal.toString());
        }
      }
    },
    onDone: () => _clients.remove(webSocket),
  );
}

void main(List<String> args) async {
  /// Initialize the redis client.
  conn = RedisConnection();
  command = await conn.connect(
      'private-db-redis-blr1-45204-do-user-9760959-0.b.db.ondigitalocean.com',
      25061);

  pubsubConn = RedisConnection();
  pubsubCommand = await pubsubConn.connect(
      'private-db-redis-blr1-45204-do-user-9760959-0.b.db.ondigitalocean.com',
      25061);
  pubsub = PubSub(pubsubCommand);

  pubsub.subscribe(['counterUpdate']);

  pubsub //
      .getStream()
      .handleError((error) => print('[ERROR] $error'))
      .listen((message) async {
    print('[PUBSUB] $message');

    final newVal = await command.send_object(['GET', 'counter']);
    for (var client in _clients) {
      client.sink.add(newVal.toString());
    }
  });

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline() //
      // .addMiddleware(logRequests())
      .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  withHotreload(() async {
    final server = await serve(handler, ip, port);
    print('Server listening on port ${server.port}');
    return server;
  });
}
