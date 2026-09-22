import 'package:diatar_app/src/core/custom_order/custom_order_set_limit_policy.dart';
import 'package:diatar_app/src/models/custom_order_set.dart';
import 'package:diatar_app/src/services/dtx_order_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const CustomOrderSetLimitPolicy policy = CustomOrderSetLimitPolicy();

  CustomOrderSet set(String id, int lastUsed) {
    return CustomOrderSet(
      id: id,
      name: id,
      entries: const [],
      lastUsed: lastUsed,
    );
  }

  test('does not evict below the configured limit', () {
    expect(
      policy.evictionIndex(<CustomOrderSet>[set('first', 1)], maximumCount: 2),
      -1,
    );
  });

  test('evicts the least recently used slideshow at the limit', () {
    expect(
      policy.evictionIndex(<CustomOrderSet>[
        set('newest', 30),
        set('oldest', 10),
        set('middle', 20),
      ], maximumCount: 3),
      1,
    );
  });

  test('uses stable list order for legacy timestamps', () {
    expect(
      policy.evictionIndex(<CustomOrderSet>[
        set('first', 0),
        set('second', 0),
      ], maximumCount: 2),
      0,
    );
  });

  test('never evicts a slideshow assigned to a hotkey', () {
    expect(
      policy.evictionIndex(
        <CustomOrderSet>[set('protected', 1), set('available', 2)],
        maximumCount: 2,
        protectedIds: const <String>{'protected'},
      ),
      1,
    );
  });

  test('allows exceeding the limit when every slideshow is protected', () {
    expect(
      policy.evictionIndex(
        <CustomOrderSet>[set('first', 1), set('second', 2)],
        maximumCount: 2,
        protectedIds: const <String>{'first', 'second'},
      ),
      -1,
    );
  });

  test('persists and restores last-used order', () {
    const StoredCustomOrderSet stored = StoredCustomOrderSet(
      id: 'set',
      name: 'Set',
      entries: <StoredCustomOrderEntry>[],
      diaFilePath: r'C:\orders\set.dia',
      embedImages: true,
      lastUsed: 1234,
    );

    final StoredCustomOrderSet? restored = StoredCustomOrderSet.fromJson(
      stored.toJson(),
    );
    expect(restored?.lastUsed, 1234);
    expect(restored?.diaFilePath, r'C:\orders\set.dia');
    expect(restored?.embedImages, isTrue);
    expect(
      StoredCustomOrderSet.fromJson(<String, Object?>{
        'id': 'legacy',
        'name': 'Legacy',
        'entries': <Object?>[],
      })?.lastUsed,
      0,
    );
  });
}
