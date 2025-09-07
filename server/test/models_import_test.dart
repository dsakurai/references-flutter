import 'package:references_models/models/reference_item.dart';
import 'package:test/test.dart';

void main() {
  test('ReferenceItem can be constructed; actual testing is done in the webapp package', () {
    final item = ReferenceItem(id: 7, title: 'A', authors: 'B');
    expect(item.id, 7);
    expect(item.title.value, 'A');
    expect(item.title.isModified, false);
    expect(item.authors.value, 'B');
    expect(item.authors.isModified, false);
  });
}
