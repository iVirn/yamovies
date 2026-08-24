// ignore_for_file: prefer_initializing_formals

import '../../../data/favorites_service.dart';
import '../../controller.dart';

/// Контроллер экрана фильма больше не хранит «в избранном или нет».
///
/// Он лишь показывает на общий источник: `Future` тут не годится — состояние
/// меняется и с ленты, и с этого экрана, и жить оно должно дольше одного ответа.
class MovieDetailsController extends Controller {
  MovieDetailsController({
    required FavoritesService favoritesService,
    required int movieId,
  }) : _favoritesService = favoritesService,
       _movieId = movieId;

  final FavoritesService _favoritesService;
  final int _movieId;

  /// Значение «прямо сейчас» — для `initialData`, чтобы кнопка не мигала.
  bool get isFavoriteNow => _favoritesService.isFavorite(_movieId);

  Stream<bool> get isFavoriteChanges =>
      _favoritesService.watchIsFavorite(_movieId);

  void toggleFavorite() => _favoritesService.toggle(_movieId);
}
