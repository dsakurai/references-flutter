import 'package:references_models/models/reference_item.dart';
import 'package:test/test.dart';

void main() {
  test('ReferenceItem can be constructed; actual testing is done in the webapp package', () {
    final item = ReferenceItem(7, title: 'A', authors: 'B');
    expect(item.id.value, 7);
    expect(item.title.value, 'A');

    // Modify the value
    item.title.value = 'B';
    expect(item.title.value, 'B');

    expect(item.authors.value, 'B');
  });
}
