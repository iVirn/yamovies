import 'movie.dart';
import 'tmdb_responses.dart';

const MoviesPageResponse mockTopRatedMoviesResponse = MoviesPageResponse(
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

const MovieGenresResponse mockMovieGenresResponse = MovieGenresResponse(
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
