import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamovies/application/module/list/movie_list_screen.dart';
import 'package:yamovies/application/movie_app.dart';
import 'package:yamovies/components/poster_fallback.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_scope.dart';
import 'package:yamovies/domain/movie.dart';
import 'package:yamovies/utils/movie_formatters.dart';
import 'package:yamovies/utils/tmdb_attribution.dart';

const MovieRepositoryMock _repository = MovieRepositoryMock();

Widget _appUnderTest() {
  return const DependencyScope(
    container: DependencyContainer(movieRepository: _repository),
    child: MovieApp(),
  );
}

void main() {
  testWidgets('catalog shows six movies at 320 px', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_appUnderTest());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MovieListScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MovieListScreen),
        matching: find.byType(Scaffold),
      ),
      findsOneWidget,
    );
    expect(find.text('Top Rated Movies'), findsOneWidget);
    expect(find.byTooltip('About and credits'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);

    // Each catalog card carries exactly one favorite toggle, so their count is
    // a proxy for the number of rendered cards.
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(6));
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.text('The Shawshank Redemption'), findsWidgets);
    expect(find.text('Spirited Away'), findsWidgets);

    // This exact combined genre string is rendered only by the grid card.
    final Text longGenres = tester.widget<Text>(
      find.text('Drama, History, War'),
    );
    expect(longGenres.maxLines, 1);
    expect(longGenres.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog scrolls without overflow at 320 and 390 px', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final double width in <double>[320, 390]) {
      tester.view.physicalSize = Size(width, 640);
      await tester.pumpWidget(_appUnderTest());
      await tester.pump();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Spirited Away'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('poster fallback shows a movie placeholder icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(width: 220, height: 320, child: PosterFallback())),
      ),
    );

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  });

  test('formatters fall back for missing presentation data', () {
    const Movie movie = Movie(
      adult: false,
      backdropPath: null,
      genreIds: <int>[999],
      id: 999,
      originalLanguage: 'en',
      originalTitle: 'Fixture without presentation data',
      overview: '',
      popularity: 0,
      posterPath: null,
      releaseDate: null,
      title: 'Fixture without presentation data',
      video: false,
      voteAverage: 0,
      voteCount: 0,
    );

    expect(releaseYear(movie), '—');
    expect(formatGenreNames(const <String>[]), 'Unknown');
  });

  testWidgets('favorite state toggles one movie', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_appUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.favorite_border), findsNWidgets(6));

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(6));
  });

  testWidgets('About and credits contains the TMDB attribution', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_appUnderTest());
    await tester.pump();

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
