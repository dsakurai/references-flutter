import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';

Middleware _cors() {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*', // Allow from browser
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  };

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response(204, headers: corsHeaders);
      }
      final resp = await innerHandler(request);
      return resp.change(headers: corsHeaders);
    };
  };
}

Future<void> main(List<String> args) async {
  final router = Router();

  // All API requests go through /api
  router.get('/api', (Request request) async {
    return Response.ok('API is up');
  });

  router.get('/api/new', (Request request) async {
    final settings = ConnectionSettings(
      host: 'db',
      port: 3306,
      user: 'appuser',
      password: 'devpass',
      db: 'appdb',
    );

    try {
      final db = await MySqlConnection.connect(settings);
      final res = await db.query(
        "INSERT INTO `References` (title, authors) VALUES (?, ?)",
        ['Sample Title', 'Author One, Author Two'],
      );
      await db.close();
      return Response.ok('${res.insertId!}');
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  });

  final handler = const Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server listening on localhost:${server.port}/api');
}