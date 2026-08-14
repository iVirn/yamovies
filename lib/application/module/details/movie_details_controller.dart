// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../controller.dart';

class MovieDetailsController extends Controller {
  MovieDetailsController({
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
  }) : _isFavorite = isFavorite,
       _onFavoriteTap = onFavoriteTap;

  bool _isFavorite;
  final VoidCallback _onFavoriteTap;

  bool get isFavorite => _isFavorite;

  void toggleFavorite() {
    _onFavoriteTap();
    _isFavorite = !_isFavorite;
    notifyListeners();
  }
}
