// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for nl (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Clinical Guidelines';

  @override
  String get initializationFailed => 'Initialisatie mislukt';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get back => 'Terug';

  @override
  String get you => 'Jij';

  @override
  String get loadingProfile => 'Profiel laden...';

  @override
  String get unableToLoadProfile => 'Kan profiel niet laden';

  @override
  String get pleaseCheckConnection => 'Controleer je verbinding en probeer het opnieuw';

  @override
  String get connectionIssueTitle => 'Kan je server niet bereiken';

  @override
  String get connectionIssueSubtitle =>
      'Maak opnieuw verbinding om door te gaan of log uit om een andere server te kiezen.';

  @override
  String get stillOfflineMessage =>
      'We kunnen de server nog steeds niet bereiken. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get account => 'Account';

  @override
  String get supportConduit => 'Ondersteun Clinical Guidelines';

  @override
  String get supportConduitSubtitle =>
      'Houd Clinical Guidelines onafhankelijk door doorlopende ontwikkeling te financieren.';

  @override
  String get githubSponsorsTitle => 'GitHub Sponsors';

  @override
  String get githubSponsorsSubtitle =>
      'Word een terugkerende sponsor om roadmap-items te financieren.';

  @override
  String get buyMeACoffeeTitle => 'Buy Me a Coffee';

  @override
  String get buyMeACoffeeSubtitle => 'Doe een eenmalige donatie om bedankt te zeggen.';

  @override
  String get signOut => 'Uitloggen';

  @override
  String get endYourSession => 'Beëindig je sessie';

  @override
  String get defaultModel => 'Standaardmodel';

  @override
  String get autoSelect => 'Automatisch selecteren';

  @override
  String get loadingModels => 'Modellen laden...';

  @override
  String get failedToLoadModels => 'Kan modellen niet laden';

  @override
  String get availableModels => 'Beschikbare modellen';

  @override
  String get noResults => 'Geen resultaten';

  @override
  String get searchModels => 'Modellen zoeken...';

  @override
  String get errorMessage => 'Er is iets misgegaan. Probeer het opnieuw.';

  @override
  String get loginButton => 'Inloggen';

  @override
  String get menuItem => 'Instellingen';

  @override
  String dynamicContentWithPlaceholder(String name) {
    return 'Welkom, ${name}!';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 item',
      other: '${count} items',
      zero: 'Geen items',
    );
    return '$_temp0';
  }

  @override
  String get closeButtonSemantic => 'Sluiten';

  @override
  String get loadingContent => 'Inhoud laden';

  @override
  String get noItems => 'Geen items';

  @override
  String get noItemsToDisplay => 'Geen items om weer te geven';

  @override
  String get loadMore => 'Meer laden';

  @override
  String get workspace => 'Werkruimte';

  @override
  String get recentFiles => 'Recente bestanden';

  @override
  String get knowledgeBase => 'Kennisbank';

  @override
  String get noFilesYet => 'Nog geen bestanden';

  @override
  String get uploadDocsPrompt =>
      'Upload documenten om te gebruiken in je gesprekken met Clinical Guidelines';

  @override
  String get uploadFirstFile => 'Upload je eerste bestand';

  @override
  String get attachments => 'Bijlagen';

  @override
  String get knowledgeBaseEmpty => 'Kennisbank is leeg';

  @override
  String get createCollectionsPrompt =>
      'Maak verzamelingen van gerelateerde documenten voor eenvoudige verwijzing';

  @override
  String get chooseSourcePhoto => 'Kies je bron';

  @override
  String get takePhoto => 'Foto maken';

  @override
  String get chooseFromGallery => 'Kies uit je foto\'s';

  @override
  String get document => 'Document';

  @override
  String get documentHint => 'PDF, Word of tekstbestand';

  @override
  String get uploadFileTitle => 'Bestand uploaden';

  @override
  String fileUploadComingSoon(String type) {
    return 'Bestand uploaden voor ${type} komt binnenkort!';
  }

  @override
  String get kbCreationComingSoon => 'Kennisbank aanmaken komt binnenkort!';

  @override
  String get backToServerSetup => 'Terug naar serverinstelling';

  @override
  String get connectedToServer => 'Verbonden met server';

  @override
  String get signIn => 'Inloggen';

  @override
  String get enterCredentials =>
      'Voer je inloggegevens in om toegang te krijgen tot je AI-gesprekken';

  @override
  String get credentials => 'Inloggegevens';

  @override
  String get apiKey => 'API-sleutel';

  @override
  String get usernameOrEmail => 'Gebruikersnaam of e-mail';

  @override
  String get password => 'Wachtwoord';

  @override
  String get signInWithApiKey => 'Inloggen met API-sleutel';

  @override
  String get connectToServer => 'Verbinden met server';

  @override
  String get enterServerAddress => 'Voer je Open-WebUI serveradres in om te beginnen';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverUrlHint => 'https://jouw-server.com';

  @override
  String get enterServerUrlSemantic => 'Voer je server-URL of IP-adres in';

  @override
  String get headerName => 'Header-naam';

  @override
  String get headerValue => 'Header-waarde';

  @override
  String get headerValueHint => 'api-key-123 of Bearer token';

  @override
  String get addHeader => 'Header toevoegen';

  @override
  String get maximumHeadersReached => 'Maximum aantal headers bereikt';

  @override
  String get removeHeader => 'Header verwijderen';

  @override
  String get connecting => 'Verbinden...';

  @override
  String get connectToServerButton => 'Verbinden met server';

  @override
  String get demoModeActive => 'Demomodus actief';

  @override
  String get skipServerSetupTryDemo => 'Serverinstelling overslaan en demo proberen';

  @override
  String get enterDemo => 'Demo starten';

  @override
  String get demoBadge => 'Demo';

  @override
  String get serverNotOpenWebUI => 'Dit lijkt geen Open-WebUI server te zijn.';

  @override
  String get serverUrlEmpty => 'Server-URL mag niet leeg zijn';

  @override
  String get invalidUrlFormat => 'Ongeldig URL-formaat. Controleer je invoer.';

  @override
  String get onlyHttpHttps => 'Alleen HTTP- en HTTPS-protocollen worden ondersteund.';

  @override
  String get serverAddressRequired => 'Serveradres is vereist (bijv. 192.168.1.10 of example.com).';

  @override
  String get portRange => 'Poort moet tussen 1 en 65535 zijn.';

  @override
  String get invalidIpFormat =>
      'Ongeldig IP-adresformaat. Gebruik een formaat zoals 192.168.1.10.';

  @override
  String get couldNotConnectGeneric =>
      'Kan geen verbinding maken. Controleer het adres en probeer het opnieuw.';

  @override
  String get weCouldntReachServer =>
      'We konden de server niet bereiken. Controleer je verbinding en of de server actief is.';

  @override
  String get connectionTimedOut =>
      'Verbinding time-out. De server is mogelijk druk of geblokkeerd door een firewall.';

  @override
  String get useHttpOrHttpsOnly => 'Gebruik alleen http:// of https://.';

  @override
  String get loginFailed => 'Inloggen mislukt';

  @override
  String get invalidCredentials => 'Ongeldige gebruikersnaam of wachtwoord. Probeer het opnieuw.';

  @override
  String get serverRedirectingHttps =>
      'De server leidt verzoeken om. Controleer de HTTPS-configuratie van je server.';

  @override
  String get unableToConnectServer =>
      'Kan geen verbinding maken met server. Controleer je verbinding.';

  @override
  String get requestTimedOut => 'Het verzoek is verlopen. Probeer het opnieuw.';

  @override
  String get genericSignInFailed =>
      'We konden je niet inloggen. Controleer je inloggegevens en serverinstellingen.';

  @override
  String get skip => 'Overslaan';

  @override
  String get next => 'Volgende';

  @override
  String get done => 'Klaar';

  @override
  String onboardStartTitle(String username) {
    return 'Hallo, ${username}';
  }

  @override
  String get onboardStartSubtitle =>
      'Kies een model om te beginnen. Tik op Nieuwe chat wanneer je maar wilt.';

  @override
  String get onboardStartBullet1 => 'Tik op de modelnaam in de bovenbalk om van model te wisselen';

  @override
  String get onboardStartBullet2 => 'Gebruik Nieuwe chat om de context te resetten';

  @override
  String get onboardAttachTitle => 'Context toevoegen';

  @override
  String get onboardAttachSubtitle =>
      'Onderbouw antwoorden met inhoud uit de werkruimte of foto\'s.';

  @override
  String get onboardAttachBullet1 => 'Werkruimte: PDF\'s, documenten, datasets';

  @override
  String get onboardAttachBullet2 => 'Foto\'s: camera of galerij';

  @override
  String get onboardSpeakTitle => 'Spreek natuurlijk';

  @override
  String get onboardSpeakSubtitle =>
      'Tik op de microfoon om te dicteren met live golfvormfeedback.';

  @override
  String get onboardSpeakBullet1 => 'Stop op elk moment; gedeeltelijke tekst wordt bewaard';

  @override
  String get onboardSpeakBullet2 => 'Geweldig voor snelle notities of lange prompts';

  @override
  String get onboardQuickTitle => 'Snelle acties';

  @override
  String get onboardQuickSubtitle =>
      'Open het menu om te schakelen tussen Chats, Werkruimte en Profiel.';

  @override
  String get onboardQuickBullet1 => 'Tik op het menu voor toegang tot Chats, Werkruimte, Profiel';

  @override
  String get onboardQuickBullet2 => 'Start Nieuwe chat of beheer modellen vanuit de bovenbalk';

  @override
  String get addAttachment => 'Bijlage toevoegen';

  @override
  String get attachmentLabel => 'Bijlage';

  @override
  String get tools => 'Hulpmiddelen';

  @override
  String get voiceInput => 'Spraakinvoer';

  @override
  String get voice => 'Stem';

  @override
  String get voiceStatusListening => 'Luisteren...';

  @override
  String get voiceStatusRecording => 'Opnemen...';

  @override
  String get voiceHoldToTalk => 'Houd ingedrukt om te praten';

  @override
  String get voiceAutoSend => 'Automatisch verzenden';

  @override
  String get voiceTranscript => 'Transcriptie';

  @override
  String get voicePromptSpeakNow => 'Spreek nu...';

  @override
  String get voicePromptTapStart => 'Tik op Start om te beginnen';

  @override
  String get voiceActionStop => 'Stop';

  @override
  String get voiceActionStart => 'Start';

  @override
  String get messageInputLabel => 'Berichtinvoer';

  @override
  String get messageInputHint => 'Typ je bericht';

  @override
  String get messageHintText => 'Bericht...';

  @override
  String get stopGenerating => 'Stop met genereren';

  @override
  String get codeCopiedToClipboard => 'Code gekopieerd naar klembord.';

  @override
  String get send => 'Verzenden';

  @override
  String get sendMessage => 'Bericht verzenden';

  @override
  String get file => 'Bestand';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Camera';

  @override
  String get apiUnavailable => 'API-service niet beschikbaar';

  @override
  String get unableToLoadImage => 'Kan afbeelding niet laden';

  @override
  String notAnImageFile(String fileName) {
    return 'Geen afbeeldingsbestand: ${fileName}';
  }

  @override
  String failedToLoadImage(String error) {
    return 'Kan afbeelding niet laden: ${error}';
  }

  @override
  String get invalidDataUrl => 'Ongeldig data-URL-formaat';

  @override
  String get failedToDecodeImage => 'Kan afbeelding niet decoderen';

  @override
  String get invalidImageFormat => 'Ongeldig afbeeldingsformaat';

  @override
  String get emptyImageData => 'Lege afbeeldingsgegevens';

  @override
  String get featureRequiresInternet => 'Deze functie vereist een internetverbinding';

  @override
  String get messagesWillSendWhenOnline => 'Berichten worden verzonden wanneer je weer online bent';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get ok => 'OK';

  @override
  String get inputField => 'Invoerveld';

  @override
  String get captureDocumentOrImage => 'Document of afbeelding vastleggen';

  @override
  String get checkConnection => 'Verbinding controleren';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get chooseDifferentFile => 'Ander bestand kiezen';

  @override
  String get goBack => 'Terug';

  @override
  String get technicalDetails => 'Technische details';

  @override
  String get save => 'Opslaan';

  @override
  String get chooseModel => 'Model kiezen';

  @override
  String get reviewerMode => 'BEOORDELAARSMODUS';

  @override
  String get selectLanguage => 'Taal selecteren';

  @override
  String get newFolder => 'Nieuwe map';

  @override
  String get folderName => 'Mapnaam';

  @override
  String get newChat => 'Nieuwe chat';

  @override
  String get more => 'Meer';

  @override
  String get clear => 'Wissen';

  @override
  String get searchHint => 'Zoeken...';

  @override
  String get searchConversations => 'Gesprekken zoeken...';

  @override
  String get create => 'Aanmaken';

  @override
  String get folderCreated => 'Map aangemaakt';

  @override
  String get failedToCreateFolder => 'Kan map niet aanmaken';

  @override
  String movedChatToFolder(String title, String folder) {
    return '\'${title}\' verplaatst naar \'${folder}\'';
  }

  @override
  String get failedToMoveChat => 'Kan chat niet verplaatsen';

  @override
  String get failedToLoadChats => 'Kan chats niet laden';

  @override
  String get failedToUpdatePin => 'Kan vastpinning niet bijwerken';

  @override
  String get failedToDeleteChat => 'Kan chat niet verwijderen';

  @override
  String get manage => 'Beheren';

  @override
  String get rename => 'Hernoemen';

  @override
  String get delete => 'Verwijderen';

  @override
  String get renameChat => 'Chat hernoemen';

  @override
  String get enterChatName => 'Chatnaam invoeren';

  @override
  String get failedToRenameChat => 'Kan chat niet hernoemen';

  @override
  String get failedToUpdateArchive => 'Kan archief niet bijwerken';

  @override
  String get unarchive => 'Uit archief halen';

  @override
  String get archive => 'Archiveren';

  @override
  String get pin => 'Vastpinnen';

  @override
  String get unpin => 'Losmaken';

  @override
  String get recent => 'Recent';

  @override
  String get system => 'Systeem';

  @override
  String get english => 'English';

  @override
  String get deutsch => 'Deutsch';

  @override
  String get francais => 'Français';

  @override
  String get italiano => 'Italiano';

  @override
  String get espanol => 'Español';

  @override
  String get nederlands => 'Nederlands';

  @override
  String get russian => 'Русский';

  @override
  String get chinese => '中文';

  @override
  String get deleteMessagesTitle => 'Berichten verwijderen';

  @override
  String deleteMessagesMessage(int count) {
    return '${count} berichten verwijderen?';
  }

  @override
  String routeNotFound(String routeName) {
    return 'Route niet gevonden: ${routeName}';
  }

  @override
  String get deleteChatTitle => 'Chat verwijderen';

  @override
  String get deleteChatMessage => 'Deze chat wordt permanent verwijderd.';

  @override
  String get deleteFolderTitle => 'Map verwijderen';

  @override
  String get deleteFolderMessage => 'Deze map en zijn toewijzingen worden verwijderd.';

  @override
  String get failedToDeleteFolder => 'Kan map niet verwijderen';

  @override
  String get aboutApp => 'Over de app';

  @override
  String get aboutAppSubtitle => 'Clinical Guidelines-informatie en links';

  @override
  String get web => 'Web';

  @override
  String get imageGen => 'Afbeeldingsgeneratie';

  @override
  String get pinned => 'Vastgepind';

  @override
  String get folders => 'Mappen';

  @override
  String get archived => 'Gearchiveerd';

  @override
  String get appLanguage => 'App-taal';

  @override
  String get darkMode => 'Donkere modus';

  @override
  String get webSearch => 'Webzoekopdracht';

  @override
  String get webSearchDescription => 'Doorzoek het web en citeer bronnen in antwoorden.';

  @override
  String get imageGeneration => 'Afbeeldingsgeneratie';

  @override
  String get imageGenerationDescription => 'Maak afbeeldingen van je prompts.';

  @override
  String get copy => 'Kopiëren';

  @override
  String get ttsListen => 'Luisteren';

  @override
  String get ttsStop => 'Stoppen';

  @override
  String get edit => 'Bewerken';

  @override
  String get regenerate => 'Opnieuw genereren';

  @override
  String get noConversationsYet => 'Nog geen gesprekken';

  @override
  String get usernameOrEmailHint => 'Voer je gebruikersnaam of e-mail in';

  @override
  String get passwordHint => 'Voer je wachtwoord in';

  @override
  String get enterApiKey => 'Voer je API-sleutel in';

  @override
  String get signingIn => 'Inloggen...';

  @override
  String get advancedSettings => 'Geavanceerde instellingen';

  @override
  String get customHeaders => 'Aangepaste headers';

  @override
  String get customHeadersDescription =>
      'Voeg aangepaste HTTP-headers toe voor authenticatie, API-sleutels of speciale serververeisten.';

  @override
  String get allowSelfSignedCertificates => 'Vertrouw zelfondertekende certificaten';

  @override
  String get allowSelfSignedCertificatesDescription =>
      'Accepteer het TLS-certificaat van deze server, zelfs als het zelfondertekend is. Schakel dit alleen in voor servers die je vertrouwt.';

  @override
  String get headerNameEmpty => 'Header-naam mag niet leeg zijn';

  @override
  String get headerNameTooLong => 'Header-naam te lang (max 64 tekens)';

  @override
  String get headerNameInvalidChars =>
      'Ongeldige header-naam. Gebruik alleen letters, cijfers en deze symbolen: !#\$&-^_`|~';

  @override
  String headerNameReserved(String key) {
    return 'Kan gereserveerde header \'${key}\' niet overschrijven';
  }

  @override
  String get headerValueEmpty => 'Header-waarde mag niet leeg zijn';

  @override
  String get headerValueTooLong => 'Header-waarde te lang (max 1024 tekens)';

  @override
  String get headerValueInvalidChars =>
      'Header-waarde bevat ongeldige tekens. Gebruik alleen afdrukbare ASCII.';

  @override
  String get headerValueUnsafe => 'Header-waarde lijkt mogelijk onveilige inhoud te bevatten';

  @override
  String headerAlreadyExists(String key) {
    return
        'Header \'${key}\' bestaat al. Verwijder deze eerst om bij te werken.';
  }

  @override
  String get maxHeadersReachedDetail =>
      'Maximaal 10 aangepaste headers toegestaan. Verwijder er enkele om meer toe te voegen.';

  @override
  String get editMessage => 'Bericht bewerken';

  @override
  String get noModelsAvailable => 'Geen modellen beschikbaar';

  @override
  String followingSystem(String theme) {
    return 'Volgt systeem: ${theme}';
  }

  @override
  String get themeDark => 'Donker';

  @override
  String get themePalette => 'Accentpalet';

  @override
  String get themePaletteDescription =>
      'Kies de accentkleuren voor knoppen, kaarten en chatballonnen.';

  @override
  String get themeLight => 'Licht';

  @override
  String get currentlyUsingDarkTheme => 'Momenteel donker thema in gebruik';

  @override
  String get currentlyUsingLightTheme => 'Momenteel licht thema in gebruik';

  @override
  String get aboutConduit => 'Over Clinical Guidelines';

  @override
  String versionLabel(String version, String build) {
    return 'Versie: ${version} (${build})';
  }

  @override
  String get githubRepository => 'GitHub-repository';

  @override
  String get unableToLoadAppInfo => 'Kan app-info niet laden';

  @override
  String get thinking => 'Denken...';

  @override
  String get thoughts => 'Gedachten';

  @override
  String thoughtForDuration(String duration) {
    return 'Dacht ${duration}';
  }

  @override
  String get appCustomization => 'App-aanpassing';

  @override
  String get appCustomizationSubtitle => 'Personaliseer hoe namen en UI worden weergegeven';

  @override
  String get quickActionsDescription =>
      'Kies maximaal twee snelkoppelingen om vast te pinnen bij de composer';

  @override
  String get chatSettings => 'Chat';

  @override
  String get sendOnEnter => 'Verzenden met Enter';

  @override
  String get sendOnEnterDescription =>
      'Enter verzendt (softtoetsenbord). Cmd/Ctrl+Enter ook beschikbaar';

  @override
  String get display => 'Weergave';

  @override
  String get realtime => 'Realtime';

  @override
  String get transportMode => 'Transportmodus';

  @override
  String get transportModeDescription => 'Kies hoe de app verbindt voor realtime updates.';

  @override
  String get mode => 'Modus';

  @override
  String get transportModeAuto => 'Automatisch (Polling + WebSocket)';

  @override
  String get transportModeWs => 'Alleen WebSocket';

  @override
  String get transportModeAutoInfo =>
      'Robuuster op beperkende netwerken. Upgrade naar WebSocket indien mogelijk.';

  @override
  String get transportModeWsInfo =>
      'Lagere overhead, maar kan mislukken achter strikte proxies/firewalls.';

}
