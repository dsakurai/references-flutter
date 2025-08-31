import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main(List<String> args) async {
  final router = Router();

  // All API requests go through /api
  router.get('/api', (Request request) {
    return Response.ok('Hello World');
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server listening on localhost:${server.port}/api');
}