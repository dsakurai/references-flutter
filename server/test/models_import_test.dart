import 'package:references_models/models/reference_item.dart';
import 'package:test/test.dart';

void main() {
  test('ReferenceItem can be constructed; actual testing is done in the webapp package', () {
    final item = ReferenceItem(title: 'A', authors: 'B');
    expect(item.title, 'A');
    expect(item.authors, 'B');
  });
}
