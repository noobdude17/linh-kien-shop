import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/firestore_date.dart';

void main() {
  test('parseFirestoreDate tolerates Timestamp / String / int / junk', () {
    final d = DateTime(2026, 6, 30, 12);
    expect(parseFirestoreDate(Timestamp.fromDate(d)), d);
    expect(parseFirestoreDate('2026-06-30T12:00:00'), d);
    expect(
      parseFirestoreDate(d.millisecondsSinceEpoch),
      d,
    );
    // junk/null -> now (just assert it returns a usable date, not throws)
    expect(parseFirestoreDate(null), isA<DateTime>());
    expect(parseFirestoreDate('not a date'), isA<DateTime>());
  });
}
