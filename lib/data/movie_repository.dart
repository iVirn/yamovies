import 'package:movie_network/movie_network.dart';

import '../domain/movie.dart';
import '../domain/movie_details.dart';
import '../domain/tmdb_responses.dart';
import 'tmdb_api.dart';

abstract interface class MovieRepository {
  const MovieRepository();

  Future<MoviesPageResponse> getMovies();

  Future<MovieGenresResponse> getGenres();

  Future<MovieDetails> getMovieDetails(int id);

  Future<List<CastMember>> getMovieCast(int id);

  Future<List<Movie>> getSimilarMovies(int id);

  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken});
}

/// Единственная точка правды для экранов: отдаёт доменные модели и ничего
/// не знает о том, что под ней dio.
final class MovieRepositoryImpl implements MovieRepository {
  const MovieRepositoryImpl({required this.api});

  final TmdbApi api;

  @override
  Future<MoviesPageResponse> getMovies() => api.topRated();

  @override
  Future<MovieGenresResponse> getGenres() => api.genres();

  @override
  Future<MovieDetails> getMovieDetails(int id) => api.movieDetails(id);

  @override
  Future<List<CastMember>> getMovieCast(int id) => api.movieCredits(id);

  @override
  Future<List<Movie>> getSimilarMovies(int id) => api.similarMovies(id);

  @override
  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken}) =>
      api.search(query, cancelToken: cancelToken);
}

/// Запасной репозиторий: работает без ключа TMDB и без сети.
///
/// Задержки не украшение — без них демо «три запроса разом» показывать нечего:
/// разница между суммой ожиданий и самым долгим из них видна только тогда,
/// когда ожидание вообще есть.
final class MovieRepositoryMock implements MovieRepository {
  const MovieRepositoryMock({this.latency = const Duration(milliseconds: 800)});

  final Duration latency;

  @override
  Future<MoviesPageResponse> getMovies() => Future<MoviesPageResponse>.delayed(
    latency,
    () => _mockTopRatedMoviesResponse,
  );

  @override
  Future<MovieGenresResponse> getGenres() =>
      Future<MovieGenresResponse>.delayed(
        latency,
        () => _mockMovieGenresResponse,
      );

  @override
  Future<MovieDetails> getMovieDetails(int id) =>
      Future<MovieDetails>.delayed(latency, () {
        final Movie movie = _movieById(id);

        return MovieDetails(
          id: movie.id,
          title: movie.title,
          overview: movie.overview,
          tagline: 'Offline fixture, no TMDB key provided',
          runtimeMinutes: 120 + movie.id % 40,
          status: 'Released',
          genres: <Genre>[
            for (final Genre genre in _mockMovieGenresResponse.genres)
              if (movie.genreIds.contains(genre.id)) genre,
          ],
          voteAverage: movie.voteAverage,
          voteCount: movie.voteCount,
          releaseDate: movie.releaseDate,
          posterPath: movie.posterPath,
        );
      });

  @override
  Future<List<CastMember>> getMovieCast(int id) =>
      Future<List<CastMember>>.delayed(latency, () {
        final Movie movie = _movieById(id);

        return <CastMember>[
          for (int index = 0; index < 6; index++)
            CastMember(
              id: movie.id * 100 + index,
              name: 'Fixture Actor ${index + 1}',
              character: 'Character ${index + 1}',
              profilePath: null,
            ),
        ];
      });

  @override
  Future<List<Movie>> getSimilarMovies(int id) =>
      Future<List<Movie>>.delayed(latency, () {
        return <Movie>[
          for (final Movie movie in _mockTopRatedMoviesResponse.results)
            if (movie.id != id) movie,
        ];
      });

  @override
  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken}) {
    // Короткий запрос отвечает дольше: так и рождается гонка ответов —
    // «Fal» приезжает уже после «Falcon» и затирает его.
    final Duration delay =
        latency +
        Duration(milliseconds: (800 - query.length * 120).clamp(0, 800));

    return Future<List<Movie>>.delayed(delay, () {
      final String needle = query.toLowerCase();

      return <Movie>[
        for (final Movie movie in _mockTopRatedMoviesResponse.results)
          if (movie.title.toLowerCase().contains(needle)) movie,
      ];
    });
  }

  Movie _movieById(int id) => _mockTopRatedMoviesResponse.results.firstWhere(
    (Movie movie) => movie.id == id,
    orElse: () => throw ApiException(statusCode: 404, path: 'movie/$id'),
  );
}

const MoviesPageResponse _mockTopRatedMoviesResponse = MoviesPageResponse(
  page: 1,
  results: <Movie>[
    Movie(
      adult: false,
      backdropPath: '/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg',
      genreIds: <int>[18, 80],
      id: 278,
      originalLanguage: 'en',
      originalTitle: 'The Shawshank Redemption',
      overview:
          'A banker sentenced to life in Shawshank prison builds an enduring '
          'friendship and quietly holds on to hope.',
      popularity: 73.8924,
      posterPath: '/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg',
      releaseDate: '1994-09-23',
      title: 'The Shawshank Redemption',
      video: false,
      voteAverage: 8.721,
      voteCount: 30412,
    ),
    Movie(
      adult: false,
      backdropPath: '/tmU7GeKVybMWFButWEGl2M4GeiP.jpg',
      genreIds: <int>[18, 80],
      id: 238,
      originalLanguage: 'en',
      originalTitle: 'The Godfather',
      overview:
          'The aging head of the Corleone crime family prepares to transfer '
          'power while his reluctant son is drawn into the family business.',
      popularity: 47.8459,
      posterPath: '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
      releaseDate: '1972-03-14',
      title: 'The Godfather',
      video: false,
      voteAverage: 8.687,
      voteCount: 22950,
    ),
    Movie(
      adult: false,
      backdropPath: '/kGzFbGhp99zva6oZODW5atUtnqi.jpg',
      genreIds: <int>[18, 80],
      id: 240,
      originalLanguage: 'en',
      originalTitle: 'The Godfather Part II',
      overview:
          "Michael expands the Corleone empire as the film traces young Vito's "
          'rise in Sicily and New York.',
      popularity: 29.3618,
      posterPath: '/hek3koDUyRQk7FIhPXsa6mT2Zc3.jpg',
      releaseDate: '1974-12-20',
      title: 'The Godfather Part II',
      video: false,
      voteAverage: 8.571,
      voteCount: 13911,
    ),
    Movie(
      adult: false,
      backdropPath: '/zb6fM1CX41D9rF9hdgclu0peUmy.jpg',
      genreIds: <int>[18, 36, 10752],
      id: 424,
      originalLanguage: 'en',
      originalTitle: "Schindler's List",
      overview:
          'German industrialist Oskar Schindler gradually risks his fortune '
          'and safety to protect Jewish workers during the Holocaust.',
      popularity: 30.7355,
      posterPath: '/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg',
      releaseDate: '1993-12-15',
      title: "Schindler's List",
      video: false,
      voteAverage: 8.569,
      voteCount: 17459,
    ),
    Movie(
      adult: false,
      backdropPath: null,
      genreIds: <int>[18],
      id: 389,
      originalLanguage: 'en',
      originalTitle: '12 Angry Men',
      overview:
          'A dissenting juror challenges an apparently simple murder case, '
          'forcing eleven others to reexamine the evidence and their '
          'prejudices.',
      popularity: 23.1122,
      posterPath: '/ow3wq89wM8qd5X7hWKxiRfsFf9C.jpg',
      releaseDate: '1957-04-10',
      title: '12 Angry Men',
      video: false,
      voteAverage: 8.561,
      voteCount: 9984,
    ),
    Movie(
      adult: false,
      backdropPath: '/6oaL4DP75yABrd5EbC4H2zq5ghc.jpg',
      genreIds: <int>[16, 10751, 14],
      id: 129,
      originalLanguage: 'ja',
      originalTitle: '千と千尋の神隠し',
      overview:
          'Ten-year-old Chihiro enters a spirit world and must find the courage '
          'to save her parents and return home.',
      popularity: 35.9329,
      posterPath: '/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
      releaseDate: '2001-07-20',
      title: 'Spirited Away',
      video: false,
      voteAverage: 8.5,
      voteCount: 18317,
    ),
  ],
  totalPages: 1,
  totalResults: 6,
);

const MovieGenresResponse _mockMovieGenresResponse = MovieGenresResponse(
  genres: <Genre>[
    Genre(id: 14, name: 'Fantasy'),
    Genre(id: 16, name: 'Animation'),
    Genre(id: 18, name: 'Drama'),
    Genre(id: 36, name: 'History'),
    Genre(id: 80, name: 'Crime'),
    Genre(id: 10751, name: 'Family'),
    Genre(id: 10752, name: 'War'),
  ],
);
