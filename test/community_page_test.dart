import 'package:flutter_test/flutter_test.dart';
import 'package:sqi_chess_club/core/repositories/community_repository.dart';

void main() {
  test('community page maps only persisted page fields', () {
    final page = CommunityPage.fromMap({
      'id': 'page-1',
      'title': 'Openings',
      'description': 'Opening discussion',
    });

    expect(page.id, 'page-1');
    expect(page.title, 'Openings');
    expect(page.description, 'Opening discussion');
  });

  test('missing page description uses an empty value', () {
    final page = CommunityPage.fromMap({'id': 'page-2', 'title': 'Tactics'});

    expect(page.description, isEmpty);
  });
}
