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
  testWidgets('catalog shows six movies in fixture order at 320 px', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
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
    expect(find.byType(GridView), findsOneWidget);

    final List<MovieCard> cards = tester
        .widgetList<MovieCard>(find.byType(MovieCard))
        .toList();
    expect(cards, hasLength(6));
    expect(
      cards.map((MovieCard card) => card.movie.id),
      mockTopRatedMoviesResponse.results.map((Movie movie) => movie.id),
    );
    expect(
      cards.map((MovieCard card) => card.posterAssetPath),
      mockTopRatedMoviesResponse.results.map(
        (Movie movie) => moviePosterAssets[movie.id],
      ),
    );
    expect(cards.every((MovieCard card) => !card.isFavorite), isTrue);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(6));
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.text('The Shawshank Redemption'), findsOneWidget);
    expect(find.text('Spirited Away'), findsOneWidget);
    final Text longTitle = tester.widget<Text>(
      find.text('The Shawshank Redemption'),
    );
    final Text longGenres = tester.widget<Text>(
      find.text('Drama, History, War'),
    );
    expect(longTitle.maxLines, 2);
    expect(longTitle.overflow, TextOverflow.ellipsis);
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
      await tester.pumpWidget(const MovieApp());

      await tester.drag(find.byType(GridView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Spirited Away'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
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
    final Map<int, String> genreNamesById = <int, String>{
      for (final Genre genre in mockMovieGenresResponse.genres)
        genre.id: genre.name,
    };
    final List<String> genreNames = resolveMovieGenres(movie, genreNamesById);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: MovieCard(
              movie: movie,
              genreNames: genreNames,
              posterAssetPath: null,
              isFavorite: false,
              onFavoriteTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
  });

  testWidgets('favorite state toggles one movie and survives reassemble', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MovieApp());

    Finder firstFavoriteButton() => find.descendant(
      of: find.byType(MovieCard).first,
      matching: find.byType(IconButton),
    );

    expect(tester.getSize(firstFavoriteButton()), const Size(48, 48));

    await tester.tap(firstFavoriteButton());
    await tester.pump();

    List<MovieCard> cards = tester
        .widgetList<MovieCard>(find.byType(MovieCard))
        .toList();
    expect(cards.first.isFavorite, isTrue);
    expect(cards.skip(1).every((MovieCard card) => !card.isFavorite), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(5));

    final StatefulElement movieListElement =
        tester.element(find.byType(MovieListScreen)) as StatefulElement;
    movieListElement.reassemble();
    await tester.pump();

    cards = tester.widgetList<MovieCard>(find.byType(MovieCard)).toList();
    expect(cards.first.isFavorite, isTrue);

    await tester.tap(firstFavoriteButton());
    await tester.pump();

    cards = tester.widgetList<MovieCard>(find.byType(MovieCard)).toList();
    expect(cards.every((MovieCard card) => !card.isFavorite), isTrue);

    await tester.tap(firstFavoriteButton());
    await tester.pump();
    await tester.pumpWidget(MovieApp(key: UniqueKey()));
    await tester.pump();

    cards = tester.widgetList<MovieCard>(find.byType(MovieCard)).toList();
    expect(cards.every((MovieCard card) => !card.isFavorite), isTrue);
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
