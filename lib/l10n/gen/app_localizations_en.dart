// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get noAccountsConnected => 'No Accounts Connected';

  @override
  String get noAnimeFound => 'No anime found';

  @override
  String
  get connectYourMyanimelistAnilistKitsuShikimoriOrSimklAccountInSettingsToViewYourAnime =>
      'Connect your MyAnimeList, AniList, Kitsu, Shikimori, or Simkl account in Settings to view your anime.';

  @override
  String get tryAdjustingTheSearchOrFilterSettings =>
      'Try adjusting the search or filter settings';

  @override
  String get addAnime => 'Add Anime';

  @override
  String get allServices => 'All Services';

  @override
  String get allServicesUnified => 'All Services (Unified)';

  @override
  String get filterByService => 'Filter by Service';

  @override
  String get searchAnimeTitles => 'Search anime titles...';

  @override
  String get refresh => 'Refresh';

  @override
  String get searchAddAnime => 'Search & Add Anime';

  @override
  String get switchToListView => 'Switch to List View';

  @override
  String get switchToGridView => 'Switch to Grid View';

  @override
  String get animeCollection => 'Anime Collection';

  @override
  String get connectAccountsInSettings => 'Connect Accounts in Settings';

  @override
  String get watching => 'Watching';

  @override
  String get done => 'Done';

  @override
  String get dropped => 'Dropped';

  @override
  String get onHold => 'On Hold';

  @override
  String get planToWatch => 'Plan to Watch';

  @override
  String detectedServiceErrors(Object count) {
    return 'Detected service errors ($count)';
  }

  @override
  String sortLabel(Object label) {
    return 'Sort: $label';
  }

  @override
  String get reading => 'Reading';

  @override
  String get planToRead => 'Plan to Read';

  @override
  String get completed => 'Completed';

  @override
  String get all => 'All';

  @override
  String get mangaCollection => 'Manga Collection';

  @override
  String get searchAddManga => 'Search & Add Manga';

  @override
  String get searchMangaTitles => 'Search manga titles...';

  @override
  String get addManga => 'Add Manga';

  @override
  String get noMangaFound => 'No manga found';

  @override
  String
  get connectYourMyanimelistAnilistKitsuOrShikimoriAccountInSettingsToViewYourManga =>
      'Connect your MyAnimeList, AniList, Kitsu, or Shikimori account in Settings to view your manga.';

  @override
  String get text => 'Text';

  @override
  String get title => 'Title';

  @override
  String get score => 'Score';

  @override
  String get progress => 'Progress';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get createdAt => 'Created At';

  @override
  String get startDate => 'Start date';

  @override
  String get finishDate => 'Finish Date';

  @override
  String get repeats => 'Repeats';

  @override
  String get priority => 'Priority';

  @override
  String characterShared(Object characterName) {
    return 'Character shared: $characterName';
  }

  @override
  String get back => 'Back';

  @override
  String get favorites => 'Favorites';

  @override
  String get share => 'Share';

  @override
  String get information => 'Information';

  @override
  String get appearances => 'Appearances';

  @override
  String get voiceActors => 'Voice Actors';

  @override
  String get biographyDescription => 'Biography / Description';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get unknown => 'Unknown';

  @override
  String get noRelatedProductions => 'No related productions';

  @override
  String personShared(Object personName) {
    return 'Person shared: $personName';
  }

  @override
  String get characters => 'Characters';

  @override
  String get performancesAndProductions => 'Performances and productions';

  @override
  String get website => 'Website';

  @override
  String get voiceActor => 'Voice Actor';

  @override
  String get birthday => 'Birthday';

  @override
  String get deathday => 'Deathday';

  @override
  String get yearsActive => 'Years Active';

  @override
  String get hometown => 'Hometown';

  @override
  String get occupations => 'Occupations';

  @override
  String get onMyList => 'On my list';

  @override
  String get anime => 'Anime';

  @override
  String get noProductionsForSelectedFilter =>
      'No productions for selected filter';

  @override
  String get noCharactersForSelectedFilter =>
      'No characters for selected filter';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get allInOneUnifiedAnimeManga => 'All-in-One Unified Anime & Manga';

  @override
  String get refreshLibrary => 'Refresh Library';

  @override
  String get settingsAccounts => 'Settings & Accounts';

  @override
  String get welcomeToMoeSync => 'Welcome to MoeSync';

  @override
  String
  get connectAtLeastOneServiceAccountMyanimelistAnilistKitsuShikimoriOrSimklToDisplayAndSynchronizeYourAnimeMangaLists =>
      'Connect at least one service account (MyAnimeList, AniList, Kitsu, Shikimori, or Simkl) to display and synchronize your anime & manga lists.';

  @override
  String get configureAccounts => 'Configure Accounts';

  @override
  String get continueWatching => 'Continue Watching';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get pendingcountPendingUpdates => '\$pendingCount Pending Updates';

  @override
  String get listsFullySynchronized => 'Lists Fully Synchronized';

  @override
  String get connectYourListServicesInSettingsToStartSynchronizing =>
      'Connect your list services in Settings to start synchronizing';

  @override
  String differencesDetectedAgainstPrimaryservice(Object primaryService) {
    return 'Differences detected against $primaryService';
  }

  @override
  String get allYourConnectedServicesAreUpToDate =>
      'All your connected services are up to date';

  @override
  String get reviewDiffs => 'Review Diffs';

  @override
  String get syncAll => 'Sync All';

  @override
  String get scanLists => 'Scan Lists';

  @override
  String get manage => 'Manage';

  @override
  String get connectedServices => 'Connected Services';

  @override
  String serviceConnected(Object serviceName) {
    return '\$$serviceName (Connected)';
  }

  @override
  String serviceNotConnected(Object serviceName) {
    return '\$$serviceName (Not Connected)';
  }

  @override
  String get viewAll => 'View All';

  @override
  String get addToList => 'Add to list';

  @override
  String get notOnList => 'Not on list';

  @override
  String get episodes => 'Episodes';

  @override
  String get chapters => 'Chapters';

  @override
  String get watchedEpisodes => 'Watched episodes';

  @override
  String get readChapters => 'Read chapters';

  @override
  String get scoreOutOfTen => 'Score (0–10)';

  @override
  String get saveAndSync => 'Save & Sync';

  @override
  String removedFromConnectedServices(Object title) {
    return '\"$title\" removed from connected services';
  }

  @override
  String updatedOnConnectedServices(Object title) {
    return 'Updated \"$title\" on connected services';
  }

  @override
  String couldNotUpdateConnectedServices(Object error) {
    return 'Could not update connected services: $error';
  }

  @override
  String failedToSearch(Object error) {
    return 'Failed to search: $error';
  }

  @override
  String get enterTitleExample => 'Enter a title (e.g. Frieren, Berserk)...';

  @override
  String get typeNameAndPressSearch => 'Type a name and press search';

  @override
  String get ongoing => 'Ongoing';

  @override
  String addedToConnectedServices(Object title) {
    return 'Added \"$title\" to connected services';
  }

  @override
  String couldNotAddToConnectedServices(Object error) {
    return 'Could not add to connected services: $error';
  }

  @override
  String get openBrowserManually =>
      'Could not open the system browser automatically. Please open the URL manually.';

  @override
  String failedToInitiateAuthorization(Object error) {
    return 'Failed to initiate authorization: $error';
  }

  @override
  String get enterCodeOrUrl => 'Please enter or paste the code or URL';

  @override
  String get openLoginPageFirst => 'Please open the login page first';

  @override
  String get enterEmailUsernamePassword =>
      'Please enter both email/username and password';

  @override
  String get enterUsernamePassword => 'Please enter both username and password';

  @override
  String savedDeveloperCredentials(Object serviceName) {
    return 'Saved developer credentials for $serviceName';
  }

  @override
  String get tokenCannotBeEmpty => 'Token cannot be empty';

  @override
  String successfullyConnectedToService(Object serviceName) {
    return 'Successfully connected to $serviceName!';
  }

  @override
  String successfullyConnectedToServiceAs(Object serviceName, Object username) {
    return 'Successfully connected to $serviceName as $username!';
  }

  @override
  String connectService(Object serviceName) {
    return 'Connect $serviceName';
  }

  @override
  String connectionError(Object error) {
    return 'Connection error: $error';
  }

  @override
  String connectedAsUser(Object username) {
    return 'Connected as $username';
  }

  @override
  String get loginToSyncLists => 'Log in to sync your anime and manga lists';

  @override
  String get advancedConfigurationManualEntry =>
      'Advanced configuration & manual entry';

  @override
  String get customClientIdOptional => 'Custom client ID (optional override)';

  @override
  String get configuredInEnvByDefault => 'Configured in .env by default';

  @override
  String get customClientSecretOptional =>
      'Custom client secret (optional override)';

  @override
  String get saveCustomClientCredentials => 'Save custom client ID/secret';

  @override
  String get accessToken => 'Access token';

  @override
  String get pasteToken => 'Paste token here';

  @override
  String get usernameOptional => 'Username (optional)';

  @override
  String get exampleUsername => 'e.g. username';

  @override
  String get saveManualToken => 'Save manual token';

  @override
  String loggedOutFromService(Object serviceName) {
    return 'Logged out from $serviceName';
  }

  @override
  String logoutService(Object serviceName) {
    return 'Log out of $serviceName';
  }

  @override
  String logoutFromServiceTooltip(Object serviceName) {
    return 'Log out of $serviceName';
  }

  @override
  String logoutFromServiceQuestion(Object serviceName) {
    return 'Log out of $serviceName?';
  }

  @override
  String confirmDisconnectService(Object serviceName) {
    return 'Are you sure you want to disconnect $serviceName?';
  }

  @override
  String get notConnectedTapToConfigure => 'Not connected (tap to configure)';

  @override
  String get connectedWithToken => 'Connected with token';

  @override
  String reopenServiceInBrowser(Object serviceName) {
    return 'Re-open $serviceName in browser';
  }

  @override
  String get openLoginPageInBrowser => '1. Open login page in browser';

  @override
  String get copiedAuthorizationLink =>
      'Copied authorization link to clipboard!';

  @override
  String get copyAuthLink => 'Copy auth link';

  @override
  String get howToConnect => 'How to connect:';

  @override
  String get clickToLoginOnShikimori => 'Click above to log in on Shikimori.';

  @override
  String get allowOnAuthorizationPage =>
      'Click \"Allow\" on the authorization page.';

  @override
  String get shikimoriDisplayCode =>
      'Shikimori will display your code. Copy and paste it below.';

  @override
  String get clickLoginApproveBrowser =>
      'Click above to log in and approve access in your browser.';

  @override
  String get redirectLocalhostExpected =>
      'You will be redirected to localhost (the page might say \"Cannot connect\"; that is expected).';

  @override
  String get copyEntireUrlOrCode =>
      'Copy the entire URL from your browser address bar (or just the code) and paste it below.';

  @override
  String get pasteAuthorizationCodeOrRedirectUrl =>
      '2. Paste authorization code or redirect URL:';

  @override
  String get exampleAuthorizationCode => 'e.g. 783ab29... or code';

  @override
  String get localhostCodeExample => 'http://localhost/?code=... or raw code';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get completeConnection => 'Complete connection';

  @override
  String get loginWithKitsuCredentials =>
      'Log in with your Kitsu email/username and password:';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get password => 'Password';

  @override
  String get loginToKitsu => 'Log in to Kitsu';

  @override
  String get loginWithMangaUpdatesCredentials =>
      'Log in with your MangaUpdates username and password:';

  @override
  String get username => 'Username';

  @override
  String get loginToMangaUpdates => 'Log in to MangaUpdates';

  @override
  String get serviceLoadErrorsTitle => 'Errors loading services';

  @override
  String get antiPhantomProtectionDescription =>
      'Anti-phantom protection is active: services with errors have been excluded from comparison to prevent empty data from overwriting your lists.';

  @override
  String get close => 'Close';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get displayStyle => 'Display style';

  @override
  String get setDisplayStyleForCollections =>
      'Set the display style for anime and manga collections';

  @override
  String get iconStyle => 'Icon';

  @override
  String get monoIconStyle => 'Mono icon';

  @override
  String get livePreview => 'Live preview:';

  @override
  String get setLayoutStyleForCollections =>
      'Set the layout style for anime and manga collections';

  @override
  String get gridView => 'Grid';

  @override
  String get listView => 'List';

  @override
  String get colorTheme => 'Color theme';

  @override
  String get dynamicFromWallpaper => 'Dynamic from wallpaper';

  @override
  String get dynamicFromWallpaperMaterialYou =>
      'Dynamic from wallpaper (Material You)';

  @override
  String get material3Variant => 'Material 3 variant';

  @override
  String get material3VariantDescription =>
      'Controls the tone and contrast generation algorithm';

  @override
  String get variantTonalSpot => 'Tonal Spot';

  @override
  String get variantFidelity => 'Fidelity';

  @override
  String get variantVibrant => 'Vibrant';

  @override
  String get variantExpressive => 'Expressive';

  @override
  String get variantNeutral => 'Neutral';

  @override
  String get variantMonochrome => 'Monochrome';

  @override
  String get variantFruitSalad => 'Fruit Salad';

  @override
  String get variantRainbow => 'Rainbow';

  @override
  String get variantContent => 'Content';

  @override
  String get colorPurpleM3 => 'Purple (M3)';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorLime => 'Lime';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorDeepOrange => 'Deep Orange';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorSakuraRose => 'Sakura Rose';

  @override
  String get colorDeepPurple => 'Deep Purple';

  @override
  String get colorBlueGrey => 'Blue Grey';

  @override
  String get colorBrown => 'Brown';

  @override
  String get searchSettingsPlaceholder => 'Search settings...';

  @override
  String serviceErrorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get themeModeDescription => 'Light, dark, or system';

  @override
  String get user => 'User';

  @override
  String get retry => 'Retry';

  @override
  String watchingProgressTotal(Object progress, Object total) {
    return 'Watching ($progress/$total)';
  }

  @override
  String watchingProgress(Object progress) {
    return 'Watching ($progress)';
  }

  @override
  String readingProgressTotal(Object progress, Object total) {
    return 'Reading ($progress/$total)';
  }

  @override
  String readingProgress(Object progress) {
    return 'Reading ($progress)';
  }

  @override
  String get edit => 'Edit';

  @override
  String mediaLinkShared(Object liveItemTitle) {
    return 'Media Link shared: $liveItemTitle';
  }

  @override
  String openOnSelectedservice(Object selectedService) {
    return 'Open on $selectedService';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String failedToLoadDetailsFromService(Object selectedService) {
    return 'Failed to load details from $selectedService';
  }

  @override
  String dataChaptersChapters(Object count) {
    return '$count chapters';
  }

  @override
  String dataEpisodesEpisodes(Object count) {
    return '$count episodes';
  }

  @override
  String dataVolumesVolumes(Object count) {
    return '$count volumes';
  }

  @override
  String get inProgress => 'In progress';

  @override
  String get tv => 'Tv';

  @override
  String get manga => 'Manga';

  @override
  String get serviceScores => 'Service Scores';

  @override
  String dataScoresServiceWithData(
    Object servicesWithData,
    Object supportedServices,
  ) {
    return '$servicesWithData of $supportedServices services';
  }

  @override
  String get available => 'Available';

  @override
  String get noData => 'No data';

  @override
  String get descriptionSummary => 'Description / Summary';

  @override
  String swipeHorizontallyDescriptionsCount(
    Object currentDescPage,
    Object totalDescriptions,
  ) {
    return 'Swipe horizontally ($currentDescPage/$totalDescriptions)';
  }

  @override
  String descriptionFromService(Object service) {
    return 'Description from $service';
  }

  @override
  String copyDescriptionFromService(Object service) {
    return 'Copy description from $service';
  }

  @override
  String descriptionFromServiceCopiedToClipboard(Object service) {
    return 'Description from $service copied to clipboard';
  }

  @override
  String get swipeLeftRightToCompareDescriptions =>
      'Swipe left/right to compare descriptions';

  @override
  String get shrinkDescription => 'Shrink description';

  @override
  String get expandDescription => 'Expand description';

  @override
  String get stats => 'Stats';

  @override
  String get ranking => 'Ranking';

  @override
  String get popularity => 'Popularity';

  @override
  String get trending => 'Trending';

  @override
  String get duration => 'Duration';

  @override
  String get endDate => 'End date';

  @override
  String get season => 'Season';

  @override
  String get broadcast => 'Broadcast';

  @override
  String get source => 'Source';

  @override
  String get studios => 'Studios';

  @override
  String get synonyms => 'Synonyms';

  @override
  String get japanese => 'Japanese';

  @override
  String get roman => 'Roman';

  @override
  String get english => 'English';

  @override
  String get moreInformation => 'More information';

  @override
  String get staff => 'Staff';

  @override
  String voiceActorsCName(Object name) {
    return 'Voice actors ($name)';
  }

  @override
  String voiceActorsCharacterName(Object characterName) {
    return 'Voice actors: $characterName';
  }

  @override
  String get noVoiceActorInformationAvailableForThisCharacter =>
      'No voice actor information available for this character';

  @override
  String get rankings => 'Rankings';

  @override
  String get statusDistribution => 'Status distribution';

  @override
  String get scoreDistribution => 'Score distribution';

  @override
  String get current => 'Current';

  @override
  String get planning => 'Planning';

  @override
  String totalCount(Object count) {
    return 'Total: $count';
  }

  @override
  String get openingThemes => 'Opening themes';

  @override
  String get endingThemes => 'Ending themes';

  @override
  String get inLibrary => 'In library';

  @override
  String get add => 'Add';

  @override
  String get recommended => 'Recommended';

  @override
  String recommendationsCount(Object count) {
    return 'Recommendations ($count)';
  }

  @override
  String relatedCount(Object count) {
    return 'Related ($count)';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get m3Variant => 'M3 Variant';

  @override
  String get displayBadges => 'Display & badges';

  @override
  String get animeDataSourcesSynchronization =>
      'Anime - Data sources & synchronization';

  @override
  String get mangaDataSourcesSynchronization =>
      'Manga - Data sources & synchronization';

  @override
  String get databaseIdMapping => 'Database & ID mapping';

  @override
  String get animeApiDatabase => 'AnimeApi Cross-Platform Database';

  @override
  String get animeApiDatabaseNotDownloaded =>
      'Local database is not downloaded yet';

  @override
  String animeApiRecordCount(Object count) {
    return '$count anime records available';
  }

  @override
  String animeApiBuiltAt(Object date) {
    return 'Source database built: $date';
  }

  @override
  String animeApiDownloadedAt(Object date) {
    return 'Downloaded locally: $date';
  }

  @override
  String get animeApiAutoRefreshDaily => 'Automatically refreshes daily';

  @override
  String get animeApiSource =>
      'Source: nattadasu/animeApi v3, including Fribb and Anime Offline Database';

  @override
  String get animeApiLicense => 'Data licenses: ODbL 1.0 and DbCL 1.0';

  @override
  String get downloadingAnimeApiDatabase => 'Downloading AnimeApi database...';

  @override
  String get successfullyUpdatedMappingDatabase =>
      'Successfully updated mapping database!';

  @override
  String get failedToDownloadMappingUsingLocalCache =>
      'Failed to download mapping. Using local cache.';

  @override
  String get failedToDownloadMappingNoLocalDatabase =>
      'Failed to download mapping, and no local database is available.';

  @override
  String get sourcesDatabase => 'Sources & Database';

  @override
  String get updateMappingDatabase => 'Update Mapping Database';

  @override
  String get cattleDatabase => 'Cattle Database';

  @override
  String countCrossReferencedMangaTitlesCachedMalMangaupdatesAnilistKitsu(
    Object count,
  ) {
    return '$count cross-referenced manga titles cached (MAL, MangaUpdates, AniList, Kitsu)';
  }

  @override
  String get animePreferences => 'Anime preferences';

  @override
  String get mangaPreferences => 'Manga preferences';

  @override
  String get defaultSourceForInformationDescriptionAndSynchronization =>
      'Default source for information, description and synchronization';

  @override
  String get defaultInformationSource => 'Default information source';

  @override
  String get usedAsTheFirstSourceWhenOpeningDetailsOf =>
      'Used as the first source when opening details of';

  @override
  String get defaultDescriptionSource => 'Default description source';

  @override
  String get selectTheServiceWhoseDescriptionShouldBeDisplayedFirst =>
      'Select the service whose description should be displayed first';

  @override
  String get automaticSameAsInfoSource => 'Automatic (same as info source)';

  @override
  String get defaultSynchronizationSource => 'Default synchronization source';

  @override
  String get defaultPrimaryServiceDuringSynchronizationOf =>
      'Default primary service during synchronization of';

  @override
  String get about => 'About';

  @override
  String get aboutMoeSync => 'About MoeSync';

  @override
  String get accounts => 'Accounts';

  @override
  String get serviceAccounts => 'Service accounts';

  @override
  String get logoutFromAllServices => 'Logout from all services?';

  @override
  String get areYouSureYouWantToDisconnectAllConnectedServiceAccounts =>
      'Are you sure you want to disconnect all connected service accounts?';

  @override
  String get cancel => 'Cancel';

  @override
  String get logOut => 'Log Out';

  @override
  String get loggedOutOfAllServices => '✓ Logged out of all services';

  @override
  String logoutFromAllServicesCount(Object count) {
    return 'Logout from all services (\$$count)';
  }

  @override
  String get tapToViewDetailsOrRetryOperations =>
      'Tap to view details or retry operations';

  @override
  String get appearanceTrackingAccounts => 'Appearance, Tracking & Accounts';

  @override
  String get listSynchronization => 'List Synchronization';

  @override
  String get rescanDifferences => 'Rescan differences';

  @override
  String get primarySourceOfTruth => 'Primary Source of Truth';

  @override
  String get searchPendingSyncTitles => 'Search pending sync titles...';

  @override
  String get filterByTargetService => 'Filter by Target Service';

  @override
  String get allTargets => 'All Targets';

  @override
  String toAddCountActions(Object pendingActionsAddCount) {
    return 'To Add ($pendingActionsAddCount)';
  }

  @override
  String toUpdateCountActions(Object pendingActionsUpdateCount) {
    return 'To Update ($pendingActionsUpdateCount)';
  }

  @override
  String filteredCountOfSyncPendingActions(
    Object countOfSync,
    Object syncPendingActions,
  ) {
    return '$countOfSync of $syncPendingActions';
  }

  @override
  String pendingActionsCount(Object count) {
    return '$count Pending Actions';
  }

  @override
  String get selectFiltered => 'Select Filtered';

  @override
  String get selectAll => 'Select All';

  @override
  String get none => 'None';

  @override
  String get analyzingDiffsAcrossYourServices =>
      'Analyzing diffs across your services...';

  @override
  String get connectAtLeast2Services => 'Connect at Least 2 Services';

  @override
  String
  get connectYourListAccountsInSettingsToStartSynchronizingAnimeAndManga =>
      'Connect your list accounts in Settings to start synchronizing anime and manga.';

  @override
  String get connectAtLeastOneMoreServiceInSettingsToCompareAndSyncYourLists =>
      'Connect at least one more service in Settings to compare and sync your lists.';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get everythingIsInSync => 'Everything is in Sync!';

  @override
  String noDifferencesDetectedWithPrimaryservice(Object primaryService) {
    return 'No differences detected with $primaryService';
  }

  @override
  String get noActionsMatchActiveFilters => 'No actions match active filters';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String applyingChangesSyncCountSyncTotalToSync(
    Object syncCount,
    Object syncTotalToSync,
  ) {
    return 'Applying changes... ($syncCount/$syncTotalToSync)';
  }

  @override
  String get syncingInProgress => 'Syncing in Progress...';

  @override
  String get scanningDifferences => 'Scanning differences...';

  @override
  String applyChangesToTargetServices(Object selectedCount) {
    return 'Apply Changes to Target Services ($selectedCount)';
  }

  @override
  String get update => 'Update';

  @override
  String get episodesShort => 'Ep';

  @override
  String get status => 'Status';

  @override
  String get differenceShort => 'Diff';

  @override
  String get noMusicServicesFound => 'No music services found';

  @override
  String get home => 'Home';

  @override
  String get sync => 'Sync';

  @override
  String get more => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get searchSettings => 'Search settings';

  @override
  String get themeDisplayModeBadgeStyle => 'Theme, display mode, badge style';

  @override
  String get themeDisplayModeBadgeStyleLivePreview =>
      'Theme, display mode, badge style & live preview';

  @override
  String get dataSourcesSync => 'Data sources & sync';

  @override
  String get defaultInformationDescriptionSyncSourceForAnimeManga =>
      'Default information, description & sync source for anime & manga';

  @override
  String get trackingAccounts => 'Tracking & Accounts';

  @override
  String get myanimelistAnilistKitsuShikimoriSimkl =>
      'MyAnimeList, AniList, Kitsu, Shikimori, Simkl';

  @override
  String get dataAndStorage => 'Data and storage';

  @override
  String get moesyncInfo => 'MoeSync Info';

  @override
  String get layoutStyle => 'Layout style';

  @override
  String get gridOrListViewForAnimeAndManga =>
      'Grid or list view for anime and manga';

  @override
  String get displayStyleBadges => 'Display style & Badges';

  @override
  String get pillTextOrIconBadgesWithLivePreview =>
      'Pill, text, or icon badges with live preview';

  @override
  String get defaultInformationDescriptionAndSyncServices =>
      'Default information, description and sync services';

  @override
  String get animeDataSourceDescription => 'Anime data source & description';

  @override
  String get chooseDefaultInfoSynopsisAndSyncSourceForAnime =>
      'Choose default info, synopsis and sync source for anime';

  @override
  String get mangaDataSourceDescription => 'Manga data source & description';

  @override
  String get chooseDefaultInfoSynopsisAndSyncSourceForManga =>
      'Choose default info, synopsis and sync source for manga';

  @override
  String get syncServicesAndAccountConnections =>
      'Sync services and account connections';

  @override
  String get connectAndManageMalCredentials =>
      'Connect and manage MAL credentials';

  @override
  String get connectAndManageAnilistToken => 'Connect and manage AniList token';

  @override
  String get connectAndManageKitsuCredentials =>
      'Connect and manage Kitsu credentials';

  @override
  String get connectAndManageShikimoriToken =>
      'Connect and manage Shikimori token';

  @override
  String get connectAndManageSimklOauth => 'Connect and manage Simkl OAuth';

  @override
  String get crossPlatformAnimeAndMangaIdMapping =>
      'Cross-platform anime and manga ID mapping';

  @override
  String get aboutMoesync => 'About MoeSync';

  @override
  String get aboutMoesyncDescription =>
      'Your anime and manga lists, together in one place.';

  @override
  String appVersionPlatform(Object platform, Object version) {
    return 'Version $version · $platform';
  }

  @override
  String appBuildNumber(Object buildNumber) {
    return 'Build $buildNumber';
  }

  @override
  String get appCreatedBy => 'Created by THR3ATB3AR';

  @override
  String get versionUnavailable => 'Version information unavailable';

  @override
  String get socialLinks => 'Socials';

  @override
  String get github => 'GitHub';

  @override
  String get errorLogs => 'Error logs';

  @override
  String get noServiceErrors => 'There are no current service errors.';

  @override
  String get releaseNotesAndUpdates => 'Release notes & updates';

  @override
  String get updateCheckFrequency => 'Check for updates';

  @override
  String get updateCheckManual => 'Manually';

  @override
  String get updateCheckDaily => 'Once a day';

  @override
  String get updateCheckOnAppOpen => 'Every time the app opens';

  @override
  String get checkForUpdatesNow => 'Check now';

  @override
  String get latestVersion => 'Latest version';

  @override
  String get currentVersion => 'Current version';

  @override
  String get updateAvailable => 'An update is available';

  @override
  String get updateLater => 'Later';

  @override
  String get appIsUpToDate => 'You\'re up to date';

  @override
  String get releaseChangelog => 'What\'s changed';

  @override
  String get noReleaseChangelog =>
      'No changelog was provided for this release.';

  @override
  String get releaseDownloads => 'Download';

  @override
  String get noReleasesAvailable => 'No releases are available yet.';

  @override
  String releaseLoadFailed(Object error) {
    return 'Couldn\'t load release notes: $error';
  }

  @override
  String get noDownloadForThisDevice =>
      'No download is available for this device.';

  @override
  String get preRelease => 'Pre-release';

  @override
  String publishedOn(Object date) {
    return 'Published $date';
  }

  @override
  String get couldNotOpenLink => 'Could not open this link.';

  @override
  String couldNotOpenLinkWithError(Object error) {
    return 'Could not open this link: $error';
  }

  @override
  String get versionArchitectureLicenses => 'Version, architecture & licenses';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get moesyncGplLicense =>
      'MoeSync original code is licensed under GNU GPL v3 or later.';

  @override
  String get noMatchingSettingsFound => 'No matching settings found';

  @override
  String get languageSettings => 'Language';

  @override
  String get languageSettingsDescription =>
      'App language and anime & manga title display';

  @override
  String get appLanguage => 'App language';

  @override
  String get appLanguageDescription =>
      'Choose the language used throughout the app';

  @override
  String get titleLanguage => 'Title language';

  @override
  String get titleLanguageDescription =>
      'Preferred language for anime and manga titles';

  @override
  String get useSystemLanguage => 'System default';

  @override
  String get englishLanguage => 'English';

  @override
  String get polishLanguage => 'Polish';

  @override
  String get spanishLanguage => 'Spanish';

  @override
  String get titleLanguageSource => 'As provided by the service';

  @override
  String get titleLanguageEnglish => 'English';

  @override
  String get titleLanguageJapanese => 'Japanese';

  @override
  String get titleLanguageRomaji => 'Romaji';

  @override
  String get moesyncNewestReleasesAndMore =>
      'MoeSync, Newest releases, and more.';
}
