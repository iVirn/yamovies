import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamovies/features/movies/mock_tmdb_data.dart';
import 'package:yamovies/features/movies/movie.dart';
import 'package:yamovies/features/movies/movie_card.dart';
import 'package:yamovies/features/movies/movie_list_screen.dart';
import 'package:yamovies/features/movies/movie_poster_assets.dart';
import 'package:yamovies/main.dart';
import 'package:yamovies/tmdb_attribution.dart';

void main() {
  testWidgets('screen shows the first movie card without overflow at 320 px', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MovieApp());

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
    expect(find.byType(TmdbAttributionButton), findsOneWidget);
    expect(find.byType(MovieCard), findsOneWidget);
    expect(find.text('The Shawshank Redemption'), findsOneWidget);
    expect(find.text('1994'), findsOneWidget);
    expect(find.text('8.7'), findsOneWidget);
    expect(find.text('Drama, Crime'), findsOneWidget);
    final Image poster = tester.widget<Image>(find.byType(Image));
    expect(
      (poster.image as AssetImage).assetName,
      moviePosterAssets[mockTopRatedMoviesResponse.results.first.id],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('movie card shows fallbacks for missing presentation data', (
    WidgetTester tester,
  ) async {
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
    final List<String> genreNames = resolveMovieGenres(
      movie,
      mockMovieGenresResponse.genres,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: MovieCard(
              movie: movie,
              genreNames: genreNames,
              posterAssetPath: null,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
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
