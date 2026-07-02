import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamovies/main.dart';
import 'package:yamovies/tmdb_attribution.dart';

void main() {
  testWidgets('app shell shows the title and greeting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovieApp());

    expect(find.text('Top Rated Movies'), findsOneWidget);
    expect(find.text('Hello Flutter'), findsOneWidget);
    expect(find.byType(TmdbAttributionButton), findsOneWidget);
  });

  testWidgets('About and credits contains the TMDB attribution', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovieApp());

    await tester.tap(find.byTooltip('About and credits'));
    await tester.pumpAndSettle();

    final AboutDialog dialog = tester.widget<AboutDialog>(
      find.byType(AboutDialog),
    );
    expect(dialog.applicationName, 'YaMovies');
    expect(dialog.applicationIcon, isA<Image>());
    expect(find.text(tmdbAttributionNotice), findsOneWidget);
  });
}
