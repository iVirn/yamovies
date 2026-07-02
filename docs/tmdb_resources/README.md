# TMDB resources

This directory documents the app-local snapshot used by the lecture demo.
Runtime code and tests never read files outside this repository.

## Snapshot

- Source shape: TMDB API v3 `/3/movie/top_rated`, `language=en-US`.
- Contents: six selected Top Rated movies, not a complete endpoint page.
- Metadata snapshot: 2026-05-28.
- Fixture prepared: 2026-07-01.
- Contract checked against TMDB API v3 documentation: 2026-07-01.

The fixture keeps the endpoint wire shape, including snake_case keys and the
pagination envelope. Its `total_pages` and `total_results` describe only this
curated six-movie set. English overviews are short summaries rather than copied
TMDB descriptions.

## Files in the app

- `test/fixtures/tmdb_top_rated.en-US.json`: canonical movie values.
- `test/fixtures/movie_genres.en.json`: genres used by the six movies.
- `test/fixtures/poster_manifest.json`: movie id, `poster_path`, source URL,
  local filename and checksum mapping.
- `assets/posters/`: unchanged 500×750 JPEG poster files.
- `docs/tmdb_resources/SHA256SUMS`: checksums with paths relative to the app
  repository root.

Verify the copied posters from the repository root:

```bash
shasum -a 256 -c docs/tmdb_resources/SHA256SUMS
```

## Attribution

This product uses the TMDB API but is not endorsed or certified by TMDB.

TMDB requires an approved logo and the notice above in an application's
About/Credits section. See:

- https://developer.themoviedb.org/docs/faq
- https://www.themoviedb.org/about/logos-attribution

The approved blue square logo is stored in `assets/branding/tmdb-logo.png`.
Its provenance and rasterization details are recorded in
`assets/branding/README.md` and `THIRD_PARTY_NOTICES.md`.

## API references

- https://developer.themoviedb.org/reference/movie-top-rated-list
- https://developer.themoviedb.org/reference/genre-movie-list
- https://developer.themoviedb.org/docs/image-basics
- https://developer.themoviedb.org/reference/configuration-details
