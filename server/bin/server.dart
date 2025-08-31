import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';

Future<void> main(List<String> args) async {
  final router = Router();

  // All API requests go through /api
  router.get('/api', (Request request) async {
    final settings = ConnectionSettings(
      host: 'db',
      port: 3306,
      user: 'appuser',
      password: 'devpass',
      db: 'appdb',
    );

    try {
      final conn = await MySqlConnection.connect(settings);
      await conn.query(
        "INSERT INTO `References` (title, authors) VALUES (?, ?)",
        ['Sample Title', 'Author One, Author Two'],
      );
      await conn.close();
      return Response.ok('Inserted stub row into References table.');
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server listening on localhost:${server.port}/api');
}