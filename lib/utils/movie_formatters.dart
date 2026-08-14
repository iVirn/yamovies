import '../domain/movie.dart';

String releaseYear(Movie movie) {
  final String? releaseDate = movie.releaseDate;
  if (releaseDate == null) {
    return '—';
  }

  return DateTime.tryParse(releaseDate)?.year.toString() ?? '—';
}

String formatGenreNames(List<String> genreNames) {
  if (genreNames.isEmpty) {
    return 'Unknown';
  }

  return genreNames.join(', ');
}

String detailsOverview(Movie movie) {
  return '${movie.overview}\n\n'
      'This movie is part of a small local catalogue used in the lecture demo. '
      'The details screen keeps the synopsis, poster, rating, genres, and '
      'favorite action together to show how a complex layout is still composed '
      'from small widgets. The longer text also makes the overview state '
      'visible: collapsed state shows only a short preview, while expanded '
      'state reveals the full description.';
}
