import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pl'),
  ];

  /// No description provided for @noAccountsConnected.
  ///
  /// In en, this message translates to:
  /// **'No Accounts Connected'**
  String get noAccountsConnected;

  /// No description provided for @noAnimeFound.
  ///
  /// In en, this message translates to:
  /// **'No anime found'**
  String get noAnimeFound;

  /// No description provided for @connectYourMyanimelistAnilistKitsuShikimoriOrSimklAccountInSettingsToViewYourAnime.
  ///
  /// In en, this message translates to:
  /// **'Connect your MyAnimeList, AniList, Kitsu, Shikimori, or Simkl account in Settings to view your anime.'**
  String
  get connectYourMyanimelistAnilistKitsuShikimoriOrSimklAccountInSettingsToViewYourAnime;

  /// No description provided for @tryAdjustingTheSearchOrFilterSettings.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting the search or filter settings'**
  String get tryAdjustingTheSearchOrFilterSettings;

  /// No description provided for @addAnime.
  ///
  /// In en, this message translates to:
  /// **'Add Anime'**
  String get addAnime;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @allServicesUnified.
  ///
  /// In en, this message translates to:
  /// **'All Services (Unified)'**
  String get allServicesUnified;

  /// No description provided for @filterByService.
  ///
  /// In en, this message translates to:
  /// **'Filter by Service'**
  String get filterByService;

  /// No description provided for @searchAnimeTitles.
  ///
  /// In en, this message translates to:
  /// **'Search anime titles...'**
  String get searchAnimeTitles;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @searchAddAnime.
  ///
  /// In en, this message translates to:
  /// **'Search & Add Anime'**
  String get searchAddAnime;

  /// No description provided for @switchToListView.
  ///
  /// In en, this message translates to:
  /// **'Switch to List View'**
  String get switchToListView;

  /// No description provided for @switchToGridView.
  ///
  /// In en, this message translates to:
  /// **'Switch to Grid View'**
  String get switchToGridView;

  /// No description provided for @animeCollection.
  ///
  /// In en, this message translates to:
  /// **'Anime Collection'**
  String get animeCollection;

  /// No description provided for @connectAccountsInSettings.
  ///
  /// In en, this message translates to:
  /// **'Connect Accounts in Settings'**
  String get connectAccountsInSettings;

  /// No description provided for @watching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watching;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get dropped;

  /// No description provided for @onHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get onHold;

  /// No description provided for @planToWatch.
  ///
  /// In en, this message translates to:
  /// **'Plan to Watch'**
  String get planToWatch;

  /// No description provided for @detectedServiceErrors.
  ///
  /// In en, this message translates to:
  /// **'Detected service errors ({count})'**
  String detectedServiceErrors(Object count);

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {label}'**
  String sortLabel(Object label);

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @planToRead.
  ///
  /// In en, this message translates to:
  /// **'Plan to Read'**
  String get planToRead;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @mangaCollection.
  ///
  /// In en, this message translates to:
  /// **'Manga Collection'**
  String get mangaCollection;

  /// No description provided for @searchAddManga.
  ///
  /// In en, this message translates to:
  /// **'Search & Add Manga'**
  String get searchAddManga;

  /// No description provided for @searchMangaTitles.
  ///
  /// In en, this message translates to:
  /// **'Search manga titles...'**
  String get searchMangaTitles;

  /// No description provided for @addManga.
  ///
  /// In en, this message translates to:
  /// **'Add Manga'**
  String get addManga;

  /// No description provided for @noMangaFound.
  ///
  /// In en, this message translates to:
  /// **'No manga found'**
  String get noMangaFound;

  /// No description provided for @connectYourMyanimelistAnilistKitsuOrShikimoriAccountInSettingsToViewYourManga.
  ///
  /// In en, this message translates to:
  /// **'Connect your MyAnimeList, AniList, Kitsu, or Shikimori account in Settings to view your manga.'**
  String
  get connectYourMyanimelistAnilistKitsuOrShikimoriAccountInSettingsToViewYourManga;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @finishDate.
  ///
  /// In en, this message translates to:
  /// **'Finish Date'**
  String get finishDate;

  /// No description provided for @repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeats;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @characterShared.
  ///
  /// In en, this message translates to:
  /// **'Character shared: {characterName}'**
  String characterShared(Object characterName);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @appearances.
  ///
  /// In en, this message translates to:
  /// **'Appearances'**
  String get appearances;

  /// No description provided for @voiceActors.
  ///
  /// In en, this message translates to:
  /// **'Voice Actors'**
  String get voiceActors;

  /// No description provided for @biographyDescription.
  ///
  /// In en, this message translates to:
  /// **'Biography / Description'**
  String get biographyDescription;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noRelatedProductions.
  ///
  /// In en, this message translates to:
  /// **'No related productions'**
  String get noRelatedProductions;

  /// No description provided for @personShared.
  ///
  /// In en, this message translates to:
  /// **'Person shared: {personName}'**
  String personShared(Object personName);

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @performancesAndProductions.
  ///
  /// In en, this message translates to:
  /// **'Performances and productions'**
  String get performancesAndProductions;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @voiceActor.
  ///
  /// In en, this message translates to:
  /// **'Voice Actor'**
  String get voiceActor;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @deathday.
  ///
  /// In en, this message translates to:
  /// **'Deathday'**
  String get deathday;

  /// No description provided for @yearsActive.
  ///
  /// In en, this message translates to:
  /// **'Years Active'**
  String get yearsActive;

  /// No description provided for @hometown.
  ///
  /// In en, this message translates to:
  /// **'Hometown'**
  String get hometown;

  /// No description provided for @occupations.
  ///
  /// In en, this message translates to:
  /// **'Occupations'**
  String get occupations;

  /// No description provided for @onMyList.
  ///
  /// In en, this message translates to:
  /// **'On my list'**
  String get onMyList;

  /// No description provided for @anime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get anime;

  /// No description provided for @noProductionsForSelectedFilter.
  ///
  /// In en, this message translates to:
  /// **'No productions for selected filter'**
  String get noProductionsForSelectedFilter;

  /// No description provided for @noCharactersForSelectedFilter.
  ///
  /// In en, this message translates to:
  /// **'No characters for selected filter'**
  String get noCharactersForSelectedFilter;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @allInOneUnifiedAnimeManga.
  ///
  /// In en, this message translates to:
  /// **'All-in-One Unified Anime & Manga'**
  String get allInOneUnifiedAnimeManga;

  /// No description provided for @refreshLibrary.
  ///
  /// In en, this message translates to:
  /// **'Refresh Library'**
  String get refreshLibrary;

  /// No description provided for @settingsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Settings & Accounts'**
  String get settingsAccounts;

  /// No description provided for @welcomeToMoeSync.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MoeSync'**
  String get welcomeToMoeSync;

  /// No description provided for @connectAtLeastOneServiceAccountMyanimelistAnilistKitsuShikimoriOrSimklToDisplayAndSynchronizeYourAnimeMangaLists.
  ///
  /// In en, this message translates to:
  /// **'Connect at least one service account (MyAnimeList, AniList, Kitsu, Shikimori, or Simkl) to display and synchronize your anime & manga lists.'**
  String
  get connectAtLeastOneServiceAccountMyanimelistAnilistKitsuShikimoriOrSimklToDisplayAndSynchronizeYourAnimeMangaLists;

  /// No description provided for @configureAccounts.
  ///
  /// In en, this message translates to:
  /// **'Configure Accounts'**
  String get configureAccounts;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @pendingcountPendingUpdates.
  ///
  /// In en, this message translates to:
  /// **'\$pendingCount Pending Updates'**
  String get pendingcountPendingUpdates;

  /// No description provided for @listsFullySynchronized.
  ///
  /// In en, this message translates to:
  /// **'Lists Fully Synchronized'**
  String get listsFullySynchronized;

  /// No description provided for @connectYourListServicesInSettingsToStartSynchronizing.
  ///
  /// In en, this message translates to:
  /// **'Connect your list services in Settings to start synchronizing'**
  String get connectYourListServicesInSettingsToStartSynchronizing;

  /// No description provided for @differencesDetectedAgainstPrimaryservice.
  ///
  /// In en, this message translates to:
  /// **'Differences detected against {primaryService}'**
  String differencesDetectedAgainstPrimaryservice(Object primaryService);

  /// No description provided for @allYourConnectedServicesAreUpToDate.
  ///
  /// In en, this message translates to:
  /// **'All your connected services are up to date'**
  String get allYourConnectedServicesAreUpToDate;

  /// No description provided for @reviewDiffs.
  ///
  /// In en, this message translates to:
  /// **'Review Diffs'**
  String get reviewDiffs;

  /// No description provided for @syncAll.
  ///
  /// In en, this message translates to:
  /// **'Sync All'**
  String get syncAll;

  /// No description provided for @scanLists.
  ///
  /// In en, this message translates to:
  /// **'Scan Lists'**
  String get scanLists;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @connectedServices.
  ///
  /// In en, this message translates to:
  /// **'Connected Services'**
  String get connectedServices;

  /// No description provided for @serviceConnected.
  ///
  /// In en, this message translates to:
  /// **'\${serviceName} (Connected)'**
  String serviceConnected(Object serviceName);

  /// No description provided for @serviceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'\${serviceName} (Not Connected)'**
  String serviceNotConnected(Object serviceName);

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addToList;

  /// No description provided for @notOnList.
  ///
  /// In en, this message translates to:
  /// **'Not on list'**
  String get notOnList;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @watchedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Watched episodes'**
  String get watchedEpisodes;

  /// No description provided for @readChapters.
  ///
  /// In en, this message translates to:
  /// **'Read chapters'**
  String get readChapters;

  /// No description provided for @scoreOutOfTen.
  ///
  /// In en, this message translates to:
  /// **'Score (0–10)'**
  String get scoreOutOfTen;

  /// No description provided for @saveAndSync.
  ///
  /// In en, this message translates to:
  /// **'Save & Sync'**
  String get saveAndSync;

  /// No description provided for @removedFromConnectedServices.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed from connected services'**
  String removedFromConnectedServices(Object title);

  /// No description provided for @updatedOnConnectedServices.
  ///
  /// In en, this message translates to:
  /// **'Updated \"{title}\" on connected services'**
  String updatedOnConnectedServices(Object title);

  /// No description provided for @couldNotUpdateConnectedServices.
  ///
  /// In en, this message translates to:
  /// **'Could not update connected services: {error}'**
  String couldNotUpdateConnectedServices(Object error);

  /// No description provided for @failedToSearch.
  ///
  /// In en, this message translates to:
  /// **'Failed to search: {error}'**
  String failedToSearch(Object error);

  /// No description provided for @enterTitleExample.
  ///
  /// In en, this message translates to:
  /// **'Enter a title (e.g. Frieren, Berserk)...'**
  String get enterTitleExample;

  /// No description provided for @typeNameAndPressSearch.
  ///
  /// In en, this message translates to:
  /// **'Type a name and press search'**
  String get typeNameAndPressSearch;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @addedToConnectedServices.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to connected services'**
  String addedToConnectedServices(Object title);

  /// No description provided for @couldNotAddToConnectedServices.
  ///
  /// In en, this message translates to:
  /// **'Could not add to connected services: {error}'**
  String couldNotAddToConnectedServices(Object error);

  /// No description provided for @openBrowserManually.
  ///
  /// In en, this message translates to:
  /// **'Could not open the system browser automatically. Please open the URL manually.'**
  String get openBrowserManually;

  /// No description provided for @failedToInitiateAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate authorization: {error}'**
  String failedToInitiateAuthorization(Object error);

  /// No description provided for @enterCodeOrUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter or paste the code or URL'**
  String get enterCodeOrUrl;

  /// No description provided for @openLoginPageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please open the login page first'**
  String get openLoginPageFirst;

  /// No description provided for @enterEmailUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email/username and password'**
  String get enterEmailUsernamePassword;

  /// No description provided for @enterUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both username and password'**
  String get enterUsernamePassword;

  /// No description provided for @savedDeveloperCredentials.
  ///
  /// In en, this message translates to:
  /// **'Saved developer credentials for {serviceName}'**
  String savedDeveloperCredentials(Object serviceName);

  /// No description provided for @tokenCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Token cannot be empty'**
  String get tokenCannotBeEmpty;

  /// No description provided for @successfullyConnectedToService.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected to {serviceName}!'**
  String successfullyConnectedToService(Object serviceName);

  /// No description provided for @successfullyConnectedToServiceAs.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected to {serviceName} as {username}!'**
  String successfullyConnectedToServiceAs(Object serviceName, Object username);

  /// No description provided for @connectService.
  ///
  /// In en, this message translates to:
  /// **'Connect {serviceName}'**
  String connectService(Object serviceName);

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {error}'**
  String connectionError(Object error);

  /// No description provided for @connectedAsUser.
  ///
  /// In en, this message translates to:
  /// **'Connected as {username}'**
  String connectedAsUser(Object username);

  /// No description provided for @loginToSyncLists.
  ///
  /// In en, this message translates to:
  /// **'Log in to sync your anime and manga lists'**
  String get loginToSyncLists;

  /// No description provided for @advancedConfigurationManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Advanced configuration & manual entry'**
  String get advancedConfigurationManualEntry;

  /// No description provided for @customClientIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Custom client ID (optional override)'**
  String get customClientIdOptional;

  /// No description provided for @configuredInEnvByDefault.
  ///
  /// In en, this message translates to:
  /// **'Configured in .env by default'**
  String get configuredInEnvByDefault;

  /// No description provided for @customClientSecretOptional.
  ///
  /// In en, this message translates to:
  /// **'Custom client secret (optional override)'**
  String get customClientSecretOptional;

  /// No description provided for @saveCustomClientCredentials.
  ///
  /// In en, this message translates to:
  /// **'Save custom client ID/secret'**
  String get saveCustomClientCredentials;

  /// No description provided for @accessToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get accessToken;

  /// No description provided for @pasteToken.
  ///
  /// In en, this message translates to:
  /// **'Paste token here'**
  String get pasteToken;

  /// No description provided for @usernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get usernameOptional;

  /// No description provided for @exampleUsername.
  ///
  /// In en, this message translates to:
  /// **'e.g. username'**
  String get exampleUsername;

  /// No description provided for @saveManualToken.
  ///
  /// In en, this message translates to:
  /// **'Save manual token'**
  String get saveManualToken;

  /// No description provided for @loggedOutFromService.
  ///
  /// In en, this message translates to:
  /// **'Logged out from {serviceName}'**
  String loggedOutFromService(Object serviceName);

  /// No description provided for @logoutService.
  ///
  /// In en, this message translates to:
  /// **'Log out of {serviceName}'**
  String logoutService(Object serviceName);

  /// No description provided for @logoutFromServiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log out of {serviceName}'**
  String logoutFromServiceTooltip(Object serviceName);

  /// No description provided for @logoutFromServiceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out of {serviceName}?'**
  String logoutFromServiceQuestion(Object serviceName);

  /// No description provided for @confirmDisconnectService.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect {serviceName}?'**
  String confirmDisconnectService(Object serviceName);

  /// No description provided for @notConnectedTapToConfigure.
  ///
  /// In en, this message translates to:
  /// **'Not connected (tap to configure)'**
  String get notConnectedTapToConfigure;

  /// No description provided for @connectedWithToken.
  ///
  /// In en, this message translates to:
  /// **'Connected with token'**
  String get connectedWithToken;

  /// No description provided for @reopenServiceInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Re-open {serviceName} in browser'**
  String reopenServiceInBrowser(Object serviceName);

  /// No description provided for @openLoginPageInBrowser.
  ///
  /// In en, this message translates to:
  /// **'1. Open login page in browser'**
  String get openLoginPageInBrowser;

  /// No description provided for @copiedAuthorizationLink.
  ///
  /// In en, this message translates to:
  /// **'Copied authorization link to clipboard!'**
  String get copiedAuthorizationLink;

  /// No description provided for @copyAuthLink.
  ///
  /// In en, this message translates to:
  /// **'Copy auth link'**
  String get copyAuthLink;

  /// No description provided for @howToConnect.
  ///
  /// In en, this message translates to:
  /// **'How to connect:'**
  String get howToConnect;

  /// No description provided for @clickToLoginOnShikimori.
  ///
  /// In en, this message translates to:
  /// **'Click above to log in on Shikimori.'**
  String get clickToLoginOnShikimori;

  /// No description provided for @allowOnAuthorizationPage.
  ///
  /// In en, this message translates to:
  /// **'Click \"Allow\" on the authorization page.'**
  String get allowOnAuthorizationPage;

  /// No description provided for @shikimoriDisplayCode.
  ///
  /// In en, this message translates to:
  /// **'Shikimori will display your code. Copy and paste it below.'**
  String get shikimoriDisplayCode;

  /// No description provided for @clickLoginApproveBrowser.
  ///
  /// In en, this message translates to:
  /// **'Click above to log in and approve access in your browser.'**
  String get clickLoginApproveBrowser;

  /// No description provided for @redirectLocalhostExpected.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to localhost (the page might say \"Cannot connect\"; that is expected).'**
  String get redirectLocalhostExpected;

  /// No description provided for @copyEntireUrlOrCode.
  ///
  /// In en, this message translates to:
  /// **'Copy the entire URL from your browser address bar (or just the code) and paste it below.'**
  String get copyEntireUrlOrCode;

  /// No description provided for @pasteAuthorizationCodeOrRedirectUrl.
  ///
  /// In en, this message translates to:
  /// **'2. Paste authorization code or redirect URL:'**
  String get pasteAuthorizationCodeOrRedirectUrl;

  /// No description provided for @exampleAuthorizationCode.
  ///
  /// In en, this message translates to:
  /// **'e.g. 783ab29... or code'**
  String get exampleAuthorizationCode;

  /// No description provided for @localhostCodeExample.
  ///
  /// In en, this message translates to:
  /// **'http://localhost/?code=... or raw code'**
  String get localhostCodeExample;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @completeConnection.
  ///
  /// In en, this message translates to:
  /// **'Complete connection'**
  String get completeConnection;

  /// No description provided for @loginWithKitsuCredentials.
  ///
  /// In en, this message translates to:
  /// **'Log in with your Kitsu email/username and password:'**
  String get loginWithKitsuCredentials;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginToKitsu.
  ///
  /// In en, this message translates to:
  /// **'Log in to Kitsu'**
  String get loginToKitsu;

  /// No description provided for @loginWithMangaUpdatesCredentials.
  ///
  /// In en, this message translates to:
  /// **'Log in with your MangaUpdates username and password:'**
  String get loginWithMangaUpdatesCredentials;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @loginToMangaUpdates.
  ///
  /// In en, this message translates to:
  /// **'Log in to MangaUpdates'**
  String get loginToMangaUpdates;

  /// No description provided for @serviceLoadErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Errors loading services'**
  String get serviceLoadErrorsTitle;

  /// No description provided for @antiPhantomProtectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Anti-phantom protection is active: services with errors have been excluded from comparison to prevent empty data from overwriting your lists.'**
  String get antiPhantomProtectionDescription;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @displayStyle.
  ///
  /// In en, this message translates to:
  /// **'Display style'**
  String get displayStyle;

  /// No description provided for @setDisplayStyleForCollections.
  ///
  /// In en, this message translates to:
  /// **'Set the display style for anime and manga collections'**
  String get setDisplayStyleForCollections;

  /// No description provided for @iconStyle.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconStyle;

  /// No description provided for @monoIconStyle.
  ///
  /// In en, this message translates to:
  /// **'Mono icon'**
  String get monoIconStyle;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'Live preview:'**
  String get livePreview;

  /// No description provided for @setLayoutStyleForCollections.
  ///
  /// In en, this message translates to:
  /// **'Set the layout style for anime and manga collections'**
  String get setLayoutStyleForCollections;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get colorTheme;

  /// No description provided for @dynamicFromWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Dynamic from wallpaper'**
  String get dynamicFromWallpaper;

  /// No description provided for @dynamicFromWallpaperMaterialYou.
  ///
  /// In en, this message translates to:
  /// **'Dynamic from wallpaper (Material You)'**
  String get dynamicFromWallpaperMaterialYou;

  /// No description provided for @material3Variant.
  ///
  /// In en, this message translates to:
  /// **'Material 3 variant'**
  String get material3Variant;

  /// No description provided for @material3VariantDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls the tone and contrast generation algorithm'**
  String get material3VariantDescription;

  /// No description provided for @variantTonalSpot.
  ///
  /// In en, this message translates to:
  /// **'Tonal Spot'**
  String get variantTonalSpot;

  /// No description provided for @variantFidelity.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get variantFidelity;

  /// No description provided for @variantVibrant.
  ///
  /// In en, this message translates to:
  /// **'Vibrant'**
  String get variantVibrant;

  /// No description provided for @variantExpressive.
  ///
  /// In en, this message translates to:
  /// **'Expressive'**
  String get variantExpressive;

  /// No description provided for @variantNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get variantNeutral;

  /// No description provided for @variantMonochrome.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get variantMonochrome;

  /// No description provided for @variantFruitSalad.
  ///
  /// In en, this message translates to:
  /// **'Fruit Salad'**
  String get variantFruitSalad;

  /// No description provided for @variantRainbow.
  ///
  /// In en, this message translates to:
  /// **'Rainbow'**
  String get variantRainbow;

  /// No description provided for @variantContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get variantContent;

  /// No description provided for @colorPurpleM3.
  ///
  /// In en, this message translates to:
  /// **'Purple (M3)'**
  String get colorPurpleM3;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get colorLime;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorDeepOrange.
  ///
  /// In en, this message translates to:
  /// **'Deep Orange'**
  String get colorDeepOrange;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorSakuraRose.
  ///
  /// In en, this message translates to:
  /// **'Sakura Rose'**
  String get colorSakuraRose;

  /// No description provided for @colorDeepPurple.
  ///
  /// In en, this message translates to:
  /// **'Deep Purple'**
  String get colorDeepPurple;

  /// No description provided for @colorBlueGrey.
  ///
  /// In en, this message translates to:
  /// **'Blue Grey'**
  String get colorBlueGrey;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @searchSettingsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search settings...'**
  String get searchSettingsPlaceholder;

  /// No description provided for @serviceErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String serviceErrorMessage(Object error);

  /// No description provided for @themeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Light, dark, or system'**
  String get themeModeDescription;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @watchingProgressTotal.
  ///
  /// In en, this message translates to:
  /// **'Watching ({progress}/{total})'**
  String watchingProgressTotal(Object progress, Object total);

  /// No description provided for @watchingProgress.
  ///
  /// In en, this message translates to:
  /// **'Watching ({progress})'**
  String watchingProgress(Object progress);

  /// No description provided for @readingProgressTotal.
  ///
  /// In en, this message translates to:
  /// **'Reading ({progress}/{total})'**
  String readingProgressTotal(Object progress, Object total);

  /// No description provided for @readingProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading ({progress})'**
  String readingProgress(Object progress);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @mediaLinkShared.
  ///
  /// In en, this message translates to:
  /// **'Media Link shared: {liveItemTitle}'**
  String mediaLinkShared(Object liveItemTitle);

  /// No description provided for @openOnSelectedservice.
  ///
  /// In en, this message translates to:
  /// **'Open on {selectedService}'**
  String openOnSelectedservice(Object selectedService);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @failedToLoadDetailsFromService.
  ///
  /// In en, this message translates to:
  /// **'Failed to load details from {selectedService}'**
  String failedToLoadDetailsFromService(Object selectedService);

  /// No description provided for @dataChaptersChapters.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String dataChaptersChapters(Object count);

  /// No description provided for @dataEpisodesEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes'**
  String dataEpisodesEpisodes(Object count);

  /// No description provided for @dataVolumesVolumes.
  ///
  /// In en, this message translates to:
  /// **'{count} volumes'**
  String dataVolumesVolumes(Object count);

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @tv.
  ///
  /// In en, this message translates to:
  /// **'Tv'**
  String get tv;

  /// No description provided for @manga.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get manga;

  /// No description provided for @serviceScores.
  ///
  /// In en, this message translates to:
  /// **'Service Scores'**
  String get serviceScores;

  /// No description provided for @dataScoresServiceWithData.
  ///
  /// In en, this message translates to:
  /// **'{servicesWithData} of {supportedServices} services'**
  String dataScoresServiceWithData(
    Object servicesWithData,
    Object supportedServices,
  );

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @descriptionSummary.
  ///
  /// In en, this message translates to:
  /// **'Description / Summary'**
  String get descriptionSummary;

  /// No description provided for @swipeHorizontallyDescriptionsCount.
  ///
  /// In en, this message translates to:
  /// **'Swipe horizontally ({currentDescPage}/{totalDescriptions})'**
  String swipeHorizontallyDescriptionsCount(
    Object currentDescPage,
    Object totalDescriptions,
  );

  /// No description provided for @descriptionFromService.
  ///
  /// In en, this message translates to:
  /// **'Description from {service}'**
  String descriptionFromService(Object service);

  /// No description provided for @copyDescriptionFromService.
  ///
  /// In en, this message translates to:
  /// **'Copy description from {service}'**
  String copyDescriptionFromService(Object service);

  /// No description provided for @descriptionFromServiceCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Description from {service} copied to clipboard'**
  String descriptionFromServiceCopiedToClipboard(Object service);

  /// No description provided for @swipeLeftRightToCompareDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Swipe left/right to compare descriptions'**
  String get swipeLeftRightToCompareDescriptions;

  /// No description provided for @shrinkDescription.
  ///
  /// In en, this message translates to:
  /// **'Shrink description'**
  String get shrinkDescription;

  /// No description provided for @expandDescription.
  ///
  /// In en, this message translates to:
  /// **'Expand description'**
  String get expandDescription;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @popularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @studios.
  ///
  /// In en, this message translates to:
  /// **'Studios'**
  String get studios;

  /// No description provided for @synonyms.
  ///
  /// In en, this message translates to:
  /// **'Synonyms'**
  String get synonyms;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @roman.
  ///
  /// In en, this message translates to:
  /// **'Roman'**
  String get roman;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @moreInformation.
  ///
  /// In en, this message translates to:
  /// **'More information'**
  String get moreInformation;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @voiceActorsCName.
  ///
  /// In en, this message translates to:
  /// **'Voice actors ({name})'**
  String voiceActorsCName(Object name);

  /// No description provided for @voiceActorsCharacterName.
  ///
  /// In en, this message translates to:
  /// **'Voice actors: {characterName}'**
  String voiceActorsCharacterName(Object characterName);

  /// No description provided for @noVoiceActorInformationAvailableForThisCharacter.
  ///
  /// In en, this message translates to:
  /// **'No voice actor information available for this character'**
  String get noVoiceActorInformationAvailableForThisCharacter;

  /// No description provided for @rankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get rankings;

  /// No description provided for @statusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Status distribution'**
  String get statusDistribution;

  /// No description provided for @scoreDistribution.
  ///
  /// In en, this message translates to:
  /// **'Score distribution'**
  String get scoreDistribution;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get planning;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalCount(Object count);

  /// No description provided for @openingThemes.
  ///
  /// In en, this message translates to:
  /// **'Opening themes'**
  String get openingThemes;

  /// No description provided for @endingThemes.
  ///
  /// In en, this message translates to:
  /// **'Ending themes'**
  String get endingThemes;

  /// No description provided for @inLibrary.
  ///
  /// In en, this message translates to:
  /// **'In library'**
  String get inLibrary;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @recommendationsCount.
  ///
  /// In en, this message translates to:
  /// **'Recommendations ({count})'**
  String recommendationsCount(Object count);

  /// No description provided for @relatedCount.
  ///
  /// In en, this message translates to:
  /// **'Related ({count})'**
  String relatedCount(Object count);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @m3Variant.
  ///
  /// In en, this message translates to:
  /// **'M3 Variant'**
  String get m3Variant;

  /// No description provided for @displayBadges.
  ///
  /// In en, this message translates to:
  /// **'Display & badges'**
  String get displayBadges;

  /// No description provided for @animeDataSourcesSynchronization.
  ///
  /// In en, this message translates to:
  /// **'Anime - Data sources & synchronization'**
  String get animeDataSourcesSynchronization;

  /// No description provided for @mangaDataSourcesSynchronization.
  ///
  /// In en, this message translates to:
  /// **'Manga - Data sources & synchronization'**
  String get mangaDataSourcesSynchronization;

  /// No description provided for @databaseIdMapping.
  ///
  /// In en, this message translates to:
  /// **'Database & ID mapping'**
  String get databaseIdMapping;

  /// No description provided for @animeApiDatabase.
  ///
  /// In en, this message translates to:
  /// **'AnimeApi Cross-Platform Database'**
  String get animeApiDatabase;

  /// No description provided for @animeApiDatabaseNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Local database is not downloaded yet'**
  String get animeApiDatabaseNotDownloaded;

  /// No description provided for @animeApiRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} anime records available'**
  String animeApiRecordCount(Object count);

  /// No description provided for @animeApiBuiltAt.
  ///
  /// In en, this message translates to:
  /// **'Source database built: {date}'**
  String animeApiBuiltAt(Object date);

  /// No description provided for @animeApiDownloadedAt.
  ///
  /// In en, this message translates to:
  /// **'Downloaded locally: {date}'**
  String animeApiDownloadedAt(Object date);

  /// No description provided for @animeApiAutoRefreshDaily.
  ///
  /// In en, this message translates to:
  /// **'Automatically refreshes daily'**
  String get animeApiAutoRefreshDaily;

  /// No description provided for @animeApiSource.
  ///
  /// In en, this message translates to:
  /// **'Source: nattadasu/animeApi v3, including Fribb and Anime Offline Database'**
  String get animeApiSource;

  /// No description provided for @animeApiLicense.
  ///
  /// In en, this message translates to:
  /// **'Data licenses: ODbL 1.0 and DbCL 1.0'**
  String get animeApiLicense;

  /// No description provided for @downloadingAnimeApiDatabase.
  ///
  /// In en, this message translates to:
  /// **'Downloading AnimeApi database...'**
  String get downloadingAnimeApiDatabase;

  /// No description provided for @successfullyUpdatedMappingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated mapping database!'**
  String get successfullyUpdatedMappingDatabase;

  /// No description provided for @failedToDownloadMappingUsingLocalCache.
  ///
  /// In en, this message translates to:
  /// **'Failed to download mapping. Using local cache.'**
  String get failedToDownloadMappingUsingLocalCache;

  /// No description provided for @failedToDownloadMappingNoLocalDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to download mapping, and no local database is available.'**
  String get failedToDownloadMappingNoLocalDatabase;

  /// No description provided for @sourcesDatabase.
  ///
  /// In en, this message translates to:
  /// **'Sources & Database'**
  String get sourcesDatabase;

  /// No description provided for @updateMappingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Update Mapping Database'**
  String get updateMappingDatabase;

  /// No description provided for @cattleDatabase.
  ///
  /// In en, this message translates to:
  /// **'Cattle Database'**
  String get cattleDatabase;

  /// No description provided for @countCrossReferencedMangaTitlesCachedMalMangaupdatesAnilistKitsu.
  ///
  /// In en, this message translates to:
  /// **'{count} cross-referenced manga titles cached (MAL, MangaUpdates, AniList, Kitsu)'**
  String countCrossReferencedMangaTitlesCachedMalMangaupdatesAnilistKitsu(
    Object count,
  );

  /// No description provided for @animePreferences.
  ///
  /// In en, this message translates to:
  /// **'Anime preferences'**
  String get animePreferences;

  /// No description provided for @mangaPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manga preferences'**
  String get mangaPreferences;

  /// No description provided for @defaultSourceForInformationDescriptionAndSynchronization.
  ///
  /// In en, this message translates to:
  /// **'Default source for information, description and synchronization'**
  String get defaultSourceForInformationDescriptionAndSynchronization;

  /// No description provided for @defaultInformationSource.
  ///
  /// In en, this message translates to:
  /// **'Default information source'**
  String get defaultInformationSource;

  /// No description provided for @usedAsTheFirstSourceWhenOpeningDetailsOf.
  ///
  /// In en, this message translates to:
  /// **'Used as the first source when opening details of'**
  String get usedAsTheFirstSourceWhenOpeningDetailsOf;

  /// No description provided for @defaultDescriptionSource.
  ///
  /// In en, this message translates to:
  /// **'Default description source'**
  String get defaultDescriptionSource;

  /// No description provided for @selectTheServiceWhoseDescriptionShouldBeDisplayedFirst.
  ///
  /// In en, this message translates to:
  /// **'Select the service whose description should be displayed first'**
  String get selectTheServiceWhoseDescriptionShouldBeDisplayedFirst;

  /// No description provided for @automaticSameAsInfoSource.
  ///
  /// In en, this message translates to:
  /// **'Automatic (same as info source)'**
  String get automaticSameAsInfoSource;

  /// No description provided for @defaultSynchronizationSource.
  ///
  /// In en, this message translates to:
  /// **'Default synchronization source'**
  String get defaultSynchronizationSource;

  /// No description provided for @defaultPrimaryServiceDuringSynchronizationOf.
  ///
  /// In en, this message translates to:
  /// **'Default primary service during synchronization of'**
  String get defaultPrimaryServiceDuringSynchronizationOf;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutMoeSync.
  ///
  /// In en, this message translates to:
  /// **'About MoeSync'**
  String get aboutMoeSync;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @serviceAccounts.
  ///
  /// In en, this message translates to:
  /// **'Service accounts'**
  String get serviceAccounts;

  /// No description provided for @logoutFromAllServices.
  ///
  /// In en, this message translates to:
  /// **'Logout from all services?'**
  String get logoutFromAllServices;

  /// No description provided for @areYouSureYouWantToDisconnectAllConnectedServiceAccounts.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect all connected service accounts?'**
  String get areYouSureYouWantToDisconnectAllConnectedServiceAccounts;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @loggedOutOfAllServices.
  ///
  /// In en, this message translates to:
  /// **'✓ Logged out of all services'**
  String get loggedOutOfAllServices;

  /// No description provided for @logoutFromAllServicesCount.
  ///
  /// In en, this message translates to:
  /// **'Logout from all services (\${count})'**
  String logoutFromAllServicesCount(Object count);

  /// No description provided for @tapToViewDetailsOrRetryOperations.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details or retry operations'**
  String get tapToViewDetailsOrRetryOperations;

  /// No description provided for @appearanceTrackingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Appearance, Tracking & Accounts'**
  String get appearanceTrackingAccounts;

  /// No description provided for @listSynchronization.
  ///
  /// In en, this message translates to:
  /// **'List Synchronization'**
  String get listSynchronization;

  /// No description provided for @rescanDifferences.
  ///
  /// In en, this message translates to:
  /// **'Rescan differences'**
  String get rescanDifferences;

  /// No description provided for @primarySourceOfTruth.
  ///
  /// In en, this message translates to:
  /// **'Primary Source of Truth'**
  String get primarySourceOfTruth;

  /// No description provided for @searchPendingSyncTitles.
  ///
  /// In en, this message translates to:
  /// **'Search pending sync titles...'**
  String get searchPendingSyncTitles;

  /// No description provided for @filterByTargetService.
  ///
  /// In en, this message translates to:
  /// **'Filter by Target Service'**
  String get filterByTargetService;

  /// No description provided for @allTargets.
  ///
  /// In en, this message translates to:
  /// **'All Targets'**
  String get allTargets;

  /// No description provided for @toAddCountActions.
  ///
  /// In en, this message translates to:
  /// **'To Add ({pendingActionsAddCount})'**
  String toAddCountActions(Object pendingActionsAddCount);

  /// No description provided for @toUpdateCountActions.
  ///
  /// In en, this message translates to:
  /// **'To Update ({pendingActionsUpdateCount})'**
  String toUpdateCountActions(Object pendingActionsUpdateCount);

  /// No description provided for @filteredCountOfSyncPendingActions.
  ///
  /// In en, this message translates to:
  /// **'{countOfSync} of {syncPendingActions}'**
  String filteredCountOfSyncPendingActions(
    Object countOfSync,
    Object syncPendingActions,
  );

  /// No description provided for @pendingActionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending Actions'**
  String pendingActionsCount(Object count);

  /// No description provided for @selectFiltered.
  ///
  /// In en, this message translates to:
  /// **'Select Filtered'**
  String get selectFiltered;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @analyzingDiffsAcrossYourServices.
  ///
  /// In en, this message translates to:
  /// **'Analyzing diffs across your services...'**
  String get analyzingDiffsAcrossYourServices;

  /// No description provided for @connectAtLeast2Services.
  ///
  /// In en, this message translates to:
  /// **'Connect at Least 2 Services'**
  String get connectAtLeast2Services;

  /// No description provided for @connectYourListAccountsInSettingsToStartSynchronizingAnimeAndManga.
  ///
  /// In en, this message translates to:
  /// **'Connect your list accounts in Settings to start synchronizing anime and manga.'**
  String get connectYourListAccountsInSettingsToStartSynchronizingAnimeAndManga;

  /// No description provided for @connectAtLeastOneMoreServiceInSettingsToCompareAndSyncYourLists.
  ///
  /// In en, this message translates to:
  /// **'Connect at least one more service in Settings to compare and sync your lists.'**
  String get connectAtLeastOneMoreServiceInSettingsToCompareAndSyncYourLists;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @everythingIsInSync.
  ///
  /// In en, this message translates to:
  /// **'Everything is in Sync!'**
  String get everythingIsInSync;

  /// No description provided for @noDifferencesDetectedWithPrimaryservice.
  ///
  /// In en, this message translates to:
  /// **'No differences detected with {primaryService}'**
  String noDifferencesDetectedWithPrimaryservice(Object primaryService);

  /// No description provided for @noActionsMatchActiveFilters.
  ///
  /// In en, this message translates to:
  /// **'No actions match active filters'**
  String get noActionsMatchActiveFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @applyingChangesSyncCountSyncTotalToSync.
  ///
  /// In en, this message translates to:
  /// **'Applying changes... ({syncCount}/{syncTotalToSync})'**
  String applyingChangesSyncCountSyncTotalToSync(
    Object syncCount,
    Object syncTotalToSync,
  );

  /// No description provided for @syncingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing in Progress...'**
  String get syncingInProgress;

  /// No description provided for @scanningDifferences.
  ///
  /// In en, this message translates to:
  /// **'Scanning differences...'**
  String get scanningDifferences;

  /// No description provided for @applyChangesToTargetServices.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes to Target Services ({selectedCount})'**
  String applyChangesToTargetServices(Object selectedCount);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @episodesShort.
  ///
  /// In en, this message translates to:
  /// **'Ep'**
  String get episodesShort;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @differenceShort.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get differenceShort;

  /// No description provided for @noMusicServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No music services found'**
  String get noMusicServicesFound;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get searchSettings;

  /// No description provided for @themeDisplayModeBadgeStyle.
  ///
  /// In en, this message translates to:
  /// **'Theme, display mode, badge style'**
  String get themeDisplayModeBadgeStyle;

  /// No description provided for @themeDisplayModeBadgeStyleLivePreview.
  ///
  /// In en, this message translates to:
  /// **'Theme, display mode, badge style & live preview'**
  String get themeDisplayModeBadgeStyleLivePreview;

  /// No description provided for @dataSourcesSync.
  ///
  /// In en, this message translates to:
  /// **'Data sources & sync'**
  String get dataSourcesSync;

  /// No description provided for @defaultInformationDescriptionSyncSourceForAnimeManga.
  ///
  /// In en, this message translates to:
  /// **'Default information, description & sync source for anime & manga'**
  String get defaultInformationDescriptionSyncSourceForAnimeManga;

  /// No description provided for @trackingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Tracking & Accounts'**
  String get trackingAccounts;

  /// No description provided for @myanimelistAnilistKitsuShikimoriSimkl.
  ///
  /// In en, this message translates to:
  /// **'MyAnimeList, AniList, Kitsu, Shikimori, Simkl'**
  String get myanimelistAnilistKitsuShikimoriSimkl;

  /// No description provided for @dataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data and storage'**
  String get dataAndStorage;

  /// No description provided for @moesyncInfo.
  ///
  /// In en, this message translates to:
  /// **'MoeSync Info'**
  String get moesyncInfo;

  /// No description provided for @layoutStyle.
  ///
  /// In en, this message translates to:
  /// **'Layout style'**
  String get layoutStyle;

  /// No description provided for @gridOrListViewForAnimeAndManga.
  ///
  /// In en, this message translates to:
  /// **'Grid or list view for anime and manga'**
  String get gridOrListViewForAnimeAndManga;

  /// No description provided for @displayStyleBadges.
  ///
  /// In en, this message translates to:
  /// **'Display style & Badges'**
  String get displayStyleBadges;

  /// No description provided for @pillTextOrIconBadgesWithLivePreview.
  ///
  /// In en, this message translates to:
  /// **'Pill, text, or icon badges with live preview'**
  String get pillTextOrIconBadgesWithLivePreview;

  /// No description provided for @defaultInformationDescriptionAndSyncServices.
  ///
  /// In en, this message translates to:
  /// **'Default information, description and sync services'**
  String get defaultInformationDescriptionAndSyncServices;

  /// No description provided for @animeDataSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'Anime data source & description'**
  String get animeDataSourceDescription;

  /// No description provided for @chooseDefaultInfoSynopsisAndSyncSourceForAnime.
  ///
  /// In en, this message translates to:
  /// **'Choose default info, synopsis and sync source for anime'**
  String get chooseDefaultInfoSynopsisAndSyncSourceForAnime;

  /// No description provided for @mangaDataSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'Manga data source & description'**
  String get mangaDataSourceDescription;

  /// No description provided for @chooseDefaultInfoSynopsisAndSyncSourceForManga.
  ///
  /// In en, this message translates to:
  /// **'Choose default info, synopsis and sync source for manga'**
  String get chooseDefaultInfoSynopsisAndSyncSourceForManga;

  /// No description provided for @syncServicesAndAccountConnections.
  ///
  /// In en, this message translates to:
  /// **'Sync services and account connections'**
  String get syncServicesAndAccountConnections;

  /// No description provided for @connectAndManageMalCredentials.
  ///
  /// In en, this message translates to:
  /// **'Connect and manage MAL credentials'**
  String get connectAndManageMalCredentials;

  /// No description provided for @connectAndManageAnilistToken.
  ///
  /// In en, this message translates to:
  /// **'Connect and manage AniList token'**
  String get connectAndManageAnilistToken;

  /// No description provided for @connectAndManageKitsuCredentials.
  ///
  /// In en, this message translates to:
  /// **'Connect and manage Kitsu credentials'**
  String get connectAndManageKitsuCredentials;

  /// No description provided for @connectAndManageShikimoriToken.
  ///
  /// In en, this message translates to:
  /// **'Connect and manage Shikimori token'**
  String get connectAndManageShikimoriToken;

  /// No description provided for @connectAndManageSimklOauth.
  ///
  /// In en, this message translates to:
  /// **'Connect and manage Simkl OAuth'**
  String get connectAndManageSimklOauth;

  /// No description provided for @crossPlatformAnimeAndMangaIdMapping.
  ///
  /// In en, this message translates to:
  /// **'Cross-platform anime and manga ID mapping'**
  String get crossPlatformAnimeAndMangaIdMapping;

  /// No description provided for @aboutMoesync.
  ///
  /// In en, this message translates to:
  /// **'About MoeSync'**
  String get aboutMoesync;

  /// No description provided for @aboutMoesyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Your anime and manga lists, together in one place.'**
  String get aboutMoesyncDescription;

  /// No description provided for @appVersionPlatform.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {platform}'**
  String appVersionPlatform(Object platform, Object version);

  /// No description provided for @appBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build {buildNumber}'**
  String appBuildNumber(Object buildNumber);

  /// No description provided for @appCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by THR3ATB3AR'**
  String get appCreatedBy;

  /// No description provided for @versionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Version information unavailable'**
  String get versionUnavailable;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Socials'**
  String get socialLinks;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @errorLogs.
  ///
  /// In en, this message translates to:
  /// **'Error logs'**
  String get errorLogs;

  /// No description provided for @noServiceErrors.
  ///
  /// In en, this message translates to:
  /// **'There are no current service errors.'**
  String get noServiceErrors;

  /// No description provided for @releaseNotesAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Release notes & updates'**
  String get releaseNotesAndUpdates;

  /// No description provided for @updateCheckFrequency.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckFrequency;

  /// No description provided for @updateCheckManual.
  ///
  /// In en, this message translates to:
  /// **'Manually'**
  String get updateCheckManual;

  /// No description provided for @updateCheckDaily.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get updateCheckDaily;

  /// No description provided for @updateCheckOnAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Every time the app opens'**
  String get updateCheckOnAppOpen;

  /// No description provided for @checkForUpdatesNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkForUpdatesNow;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get latestVersion;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get currentVersion;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'An update is available'**
  String get updateAvailable;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @appIsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get appIsUpToDate;

  /// No description provided for @releaseChangelog.
  ///
  /// In en, this message translates to:
  /// **'What\'s changed'**
  String get releaseChangelog;

  /// No description provided for @noReleaseChangelog.
  ///
  /// In en, this message translates to:
  /// **'No changelog was provided for this release.'**
  String get noReleaseChangelog;

  /// No description provided for @releaseDownloads.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get releaseDownloads;

  /// No description provided for @noReleasesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No releases are available yet.'**
  String get noReleasesAvailable;

  /// No description provided for @releaseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load release notes: {error}'**
  String releaseLoadFailed(Object error);

  /// No description provided for @noDownloadForThisDevice.
  ///
  /// In en, this message translates to:
  /// **'No download is available for this device.'**
  String get noDownloadForThisDevice;

  /// No description provided for @preRelease.
  ///
  /// In en, this message translates to:
  /// **'Pre-release'**
  String get preRelease;

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String publishedOn(Object date);

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get couldNotOpenLink;

  /// No description provided for @couldNotOpenLinkWithError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link: {error}'**
  String couldNotOpenLinkWithError(Object error);

  /// No description provided for @versionArchitectureLicenses.
  ///
  /// In en, this message translates to:
  /// **'Version, architecture & licenses'**
  String get versionArchitectureLicenses;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @moesyncGplLicense.
  ///
  /// In en, this message translates to:
  /// **'MoeSync original code is licensed under GNU GPL v3 or later.'**
  String get moesyncGplLicense;

  /// No description provided for @noMatchingSettingsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching settings found'**
  String get noMatchingSettingsFound;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @languageSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'App language and anime & manga title display'**
  String get languageSettingsDescription;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @appLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used throughout the app'**
  String get appLanguageDescription;

  /// No description provided for @titleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Title language'**
  String get titleLanguage;

  /// No description provided for @titleLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Preferred language for anime and manga titles'**
  String get titleLanguageDescription;

  /// No description provided for @useSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get useSystemLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @polishLanguage.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get polishLanguage;

  /// No description provided for @spanishLanguage.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanishLanguage;

  /// No description provided for @titleLanguageSource.
  ///
  /// In en, this message translates to:
  /// **'As provided by the service'**
  String get titleLanguageSource;

  /// No description provided for @titleLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get titleLanguageEnglish;

  /// No description provided for @titleLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get titleLanguageJapanese;

  /// No description provided for @titleLanguageRomaji.
  ///
  /// In en, this message translates to:
  /// **'Romaji'**
  String get titleLanguageRomaji;

  /// No description provided for @moesyncNewestReleasesAndMore.
  ///
  /// In en, this message translates to:
  /// **'MoeSync, Newest releases, and more.'**
  String get moesyncNewestReleasesAndMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
