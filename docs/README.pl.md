<div align="center">
  <img src="../assets/icon/png/moesync-icon.png" alt="Ikona aplikacji MoeSync" width="112" />
  <h1>MoeSync</h1>
  <p><strong>Listy anime i mang w jednym miejscu.</strong></p>
  <p>Śledź swoją bibliotekę, porównuj serwisy i synchronizuj zmiany w jednej aplikacji Flutter.</p>
  <p><strong>Aplikacja tworzona przede wszystkim z myślą o Androidzie, Windowsie i Linuksie.</strong></p>
  <p><a href="../README.md">English</a> · <a href="README.es.md">Español</a></p>
</div>

---

## Opis

MoeSync łączy serwisy do śledzenia anime i mang w jednej bibliotece. Przeglądaj listy, wybieraj źródła informacji, sprawdzaj różnice między serwisami i decyduj, które zmiany zsynchronizować.

## Funkcje

- **Wspólna biblioteka** — przeglądaj anime i mangę z połączonych serwisów w jednym miejscu.
- **Synchronizacja między serwisami** — porównuj listy z serwisem głównym, przeglądaj oczekujące dodania i aktualizacje, a następnie zastosuj wybrane zmiany.
- **Elastyczne źródła informacji** — osobno wybieraj domyślne źródła informacji, opisów i synchronizacji dla anime oraz mangi.
- **Szczegóły tytułów** — przeglądaj opisy, oceny, rankingi, statystyki, powiązane tytuły, rekomendacje, ekipę, postacie i — jeśli są dostępne — utwory muzyczne z anime.
- **Personalizacja wyglądu** — wybieraj widok siatki lub listy, motyw oraz niezależnie język aplikacji i wyświetlanych tytułów.
- **Lokalna pamięć biblioteki** — zachowaj wcześniej wczytane listy pomiędzy odświeżeniami.

## Obsługiwane serwisy

| Serwis | Anime | Manga |
| --- | :---: | :---: |
| MyAnimeList | ✓ | ✓ |
| AniList | ✓ | ✓ |
| Kitsu | ✓ | ✓ |
| Shikimori | ✓ | ✓ |
| Simkl | ✓ | — |
| MangaBaka | — | ✓ |
| MangaUpdates | — | ✓ |

Zakres funkcji może być różny. Dostępność tytułów, opisów, metadanych i operacji na koncie zależy od serwisu oraz jego API.

## Pobieranie

Dostępne wersje MoeSync pobierzesz ze strony [GitHub Releases](https://github.com/THR3ATB3AR/moesync/releases). Wydania są przeznaczone przede wszystkim na **Androida, Windowsa i Linuksa**.

## Pierwsze kroki

### Wymagania

- Flutter SDK oraz Dart SDK zgodny z ograniczeniem wersji w [`pubspec.yaml`](../pubspec.yaml)
- Środowisko Android, Windows lub Linux skonfigurowane do pracy z Flutterem

### Uruchomienie lub zbudowanie wersji release lokalnie

```bash
git clone https://github.com/THR3ATB3AR/moesync.git
cd moesync
flutter pub get
python3 scripts/prepare_dart_defines.py
flutter run --release --build-name 1.2.3 --build-number <numer-buildu> \
  --dart-define-from-file=.dart-defines.json
```

Przed uruchomieniem utwórz `.env` na podstawie `.env.example` i skonfiguruj
wartości. Skrypt konwertuje plik dotenv do formatu JSON wymaganego przez Fluttera
w opcji `--dart-define-from-file`. Oba pliki są ignorowane przez Git. Nie
dodawaj ich do repozytorium ani nie udostępniaj danych logowania, kluczy API
lub sekretów.

Polecenie uruchamia aplikację w trybie release na wybranym urządzeniu lub celu Fluttera. Flutter musi być skonfigurowany dla wybranej platformy.

Połącz serwisy w **Ustawienia → Śledzenie i konta**. Domyślne źródła informacji dla anime i mangi wybierzesz w **Ustawienia → Źródła danych i synchronizacja**.

### Obsługiwane platformy

MoeSync jest rozwijany przede wszystkim z myślą o **Androidzie, Windowsie i Linuksie**. Inne platformy Fluttera nie są głównym celem i mogą być obsługiwane w ograniczonym zakresie lub nie być obsługiwane.

## Języki

Interfejs MoeSync jest dostępny po angielsku, polsku i hiszpańsku. Język aplikacji może być ustawiony zgodnie z systemem albo wybrany niezależnie. Dla wyświetlanych tytułów można preferować nazwę ze źródła, angielską, japońską lub rōmaji. Jeśli serwis nie udostępnia wybranego wariantu, MoeSync używa dostępnego tytułu.

MoeSync planuje używać [Weblate](https://weblate.org/) do koordynowania tłumaczeń, gdy projekt będzie kwalifikował się do bezpłatnego hostingu i uzyska jego zatwierdzenie. Do tego czasu tłumaczenia można współtworzyć w publicznym repozytorium, w katalogu [`lib/l10n/`](../lib/l10n/). Kod źródłowy MoeSync jest wydany na licencji GPL-3.0-or-later, a tłumaczenia znajdują się razem z kodem.

## Rozwój

Pliki lokalizacji Fluttera znajdują się w [`lib/l10n/`](../lib/l10n/). Po edycji plików ARB wygeneruj klasy lokalizacji:

```bash
flutter gen-l10n
```

Analizę statyczną i testy uruchomisz poleceniami:

```bash
flutter analyze
flutter test
```

## Dane i dostawcy usług

MoeSync łączy się z zewnętrznymi serwisami w imieniu użytkownika. Za ich dostępność, API i warunki odpowiadają poszczególni dostawcy. Dane kont i preferencje są przechowywane lokalnie przez aplikację. Nie umieszczaj danych logowania, sekretów API ani tokenów w repozytorium.

## Licencja

Oryginalny kod źródłowy MoeSync jest objęty licencją **GNU GPL-3.0-or-later**. Tekst GPL w wersji 3 znajduje się w pliku [`LICENSE`](../LICENSE), a informacja o stosowaniu wersji 3 lub nowszej w [`COPYRIGHT`](../COPYRIGHT). Zależności i grafiki stron trzecich zachowują własne licencje; licencje pakietów znajdziesz w aplikacji w **Ustawienia → Informacje → Licencje open source**. Informacje o rozpoznanych grafikach i logo serwisów są w [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).
