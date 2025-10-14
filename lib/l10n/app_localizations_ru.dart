// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for ru (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Clinical Guidelines';

  @override
  String get initializationFailed => 'Ошибка инициализации';

  @override
  String get retry => 'Повторить';

  @override
  String get back => 'Назад';

  @override
  String get you => 'Вы';

  @override
  String get loadingProfile => 'Загрузка профиля...';

  @override
  String get unableToLoadProfile => 'Не удалось загрузить профиль';

  @override
  String get pleaseCheckConnection => 'Пожалуйста, проверьте соединение и повторите попытку';

  @override
  String get connectionIssueTitle => 'Не удается подключиться к серверу';

  @override
  String get connectionIssueSubtitle =>
      'Переподключитесь, чтобы продолжить, или выйдите, чтобы выбрать другой сервер.';

  @override
  String get stillOfflineMessage =>
      'Мы все еще не можем подключиться к серверу. Проверьте соединение и повторите попытку.';

  @override
  String get account => 'Аккаунт';

  @override
  String get supportConduit => 'Поддержать Clinical Guidelines';

  @override
  String get supportConduitSubtitle =>
      'Сохраните независимость Clinical Guidelines, финансируя разработку.';

  @override
  String get githubSponsorsTitle => 'GitHub Sponsors';

  @override
  String get githubSponsorsSubtitle =>
      'Станьте регулярным спонсором для финансирования дорожной карты.';

  @override
  String get buyMeACoffeeTitle => 'Buy Me a Coffee';

  @override
  String get buyMeACoffeeSubtitle => 'Сделайте разовое пожертвование в знак благодарности.';

  @override
  String get signOut => 'Выйти';

  @override
  String get endYourSession => 'Завершить сеанс';

  @override
  String get defaultModel => 'Модель по умолчанию';

  @override
  String get autoSelect => 'Автовыбор';

  @override
  String get loadingModels => 'Загрузка моделей...';

  @override
  String get failedToLoadModels => 'Не удалось загрузить модели';

  @override
  String get availableModels => 'Доступные модели';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get searchModels => 'Поиск моделей...';

  @override
  String get errorMessage => 'Что-то пошло не так. Пожалуйста, попробуйте еще раз.';

  @override
  String get loginButton => 'Войти';

  @override
  String get menuItem => 'Настройки';

  @override
  String dynamicContentWithPlaceholder(String name) {
    return 'Добро пожаловать, ${name}!';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '${count} элемент',
      few: '${count} элемента',
      other: '${count} элементов',
      zero: 'Нет элементов',
    );
    return '$_temp0';
  }

  @override
  String get closeButtonSemantic => 'Закрыть';

  @override
  String get loadingContent => 'Загрузка содержимого';

  @override
  String get noItems => 'Нет элементов';

  @override
  String get noItemsToDisplay => 'Нет элементов для отображения';

  @override
  String get loadMore => 'Загрузить еще';

  @override
  String get workspace => 'Рабочее пространство';

  @override
  String get recentFiles => 'Недавние файлы';

  @override
  String get knowledgeBase => 'База знаний';

  @override
  String get noFilesYet => 'Пока нет файлов';

  @override
  String get uploadDocsPrompt =>
      'Загрузите документы для использования в разговорах с Clinical Guidelines';

  @override
  String get uploadFirstFile => 'Загрузить первый файл';

  @override
  String get attachments => 'Вложения';

  @override
  String get knowledgeBaseEmpty => 'База знаний пуста';

  @override
  String get createCollectionsPrompt => 'Создайте коллекции связанных документов для удобной ссылки';

  @override
  String get chooseSourcePhoto => 'Выберите источник';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get document => 'Документ';

  @override
  String get documentHint => 'PDF, Word или текстовый файл';

  @override
  String get uploadFileTitle => 'Загрузить файл';

  @override
  String fileUploadComingSoon(String type) {
    return 'Загрузка файлов для ${type} скоро появится!';
  }

  @override
  String get kbCreationComingSoon => 'Создание базы знаний скоро появится!';

  @override
  String get backToServerSetup => 'Вернуться к настройке сервера';

  @override
  String get connectedToServer => 'Подключено к серверу';

  @override
  String get signIn => 'Войти';

  @override
  String get enterCredentials =>
      'Введите свои учетные данные для доступа к вашим разговорам с ИИ';

  @override
  String get credentials => 'Учетные данные';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get usernameOrEmail => 'Имя пользователя или email';

  @override
  String get password => 'Пароль';

  @override
  String get signInWithApiKey => 'Войти с помощью API-ключа';

  @override
  String get connectToServer => 'Подключиться к серверу';

  @override
  String get enterServerAddress => 'Введите адрес вашего сервера Open-WebUI для начала';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverUrlHint => 'https://your-server.com';

  @override
  String get enterServerUrlSemantic => 'Введите URL или IP-адрес вашего сервера';

  @override
  String get headerName => 'Имя заголовка';

  @override
  String get headerValue => 'Значение заголовка';

  @override
  String get headerValueHint => 'api-key-123 или Bearer token';

  @override
  String get addHeader => 'Добавить заголовок';

  @override
  String get maximumHeadersReached => 'Достигнуто максимальное количество заголовков';

  @override
  String get removeHeader => 'Удалить заголовок';

  @override
  String get connecting => 'Подключение...';

  @override
  String get connectToServerButton => 'Подключиться к серверу';

  @override
  String get demoModeActive => 'Демо-режим активен';

  @override
  String get skipServerSetupTryDemo => 'Пропустить настройку сервера и попробовать демо';

  @override
  String get enterDemo => 'Войти в демо';

  @override
  String get demoBadge => 'Демо';

  @override
  String get serverNotOpenWebUI => 'Это не похоже на сервер Open-WebUI.';

  @override
  String get serverUrlEmpty => 'URL сервера не может быть пустым';

  @override
  String get invalidUrlFormat => 'Неверный формат URL. Пожалуйста, проверьте ввод.';

  @override
  String get onlyHttpHttps => 'Поддерживаются только протоколы HTTP и HTTPS.';

  @override
  String get serverAddressRequired =>
      'Требуется адрес сервера (например, 192.168.1.10 или example.com).';

  @override
  String get portRange => 'Порт должен быть от 1 до 65535.';

  @override
  String get invalidIpFormat =>
      'Неверный формат IP-адреса. Используйте формат как 192.168.1.10.';

  @override
  String get couldNotConnectGeneric =>
      'Не удалось подключиться. Проверьте адрес и повторите попытку.';

  @override
  String get weCouldntReachServer =>
      'Мы не смогли связаться с сервером. Проверьте подключение и работает ли сервер.';

  @override
  String get connectionTimedOut =>
      'Время ожидания подключения истекло. Сервер может быть занят или заблокирован брандмауэром.';

  @override
  String get useHttpOrHttpsOnly => 'Используйте только http:// или https://.';

  @override
  String get loginFailed => 'Ошибка входа';

  @override
  String get invalidCredentials =>
      'Неверное имя пользователя или пароль. Пожалуйста, попробуйте еще раз.';

  @override
  String get serverRedirectingHttps =>
      'Сервер перенаправляет запросы. Проверьте настройки HTTPS вашего сервера.';

  @override
  String get unableToConnectServer =>
      'Не удается подключиться к серверу. Пожалуйста, проверьте соединение.';

  @override
  String get requestTimedOut =>
      'Время ожидания запроса истекло. Пожалуйста, попробуйте еще раз.';

  @override
  String get genericSignInFailed =>
      'Не удалось войти. Проверьте учетные данные и настройки сервера.';

  @override
  String get skip => 'Пропустить';

  @override
  String get next => 'Далее';

  @override
  String get done => 'Готово';

  @override
  String onboardStartTitle(String username) {
    return 'Здравствуйте, ${username}';
  }

  @override
  String get onboardStartSubtitle =>
      'Выберите модель для начала. Нажмите «Новый чат» в любое время.';

  @override
  String get onboardStartBullet1 =>
      'Нажмите на имя модели в верхней панели для переключения моделей';

  @override
  String get onboardStartBullet2 => 'Используйте «Новый чат» для сброса контекста';

  @override
  String get onboardAttachTitle => 'Добавить контекст';

  @override
  String get onboardAttachSubtitle =>
      'Обоснуйте ответы содержимым из рабочего пространства или фотографиями.';

  @override
  String get onboardAttachBullet1 => 'Рабочее пространство: PDF, документы, наборы данных';

  @override
  String get onboardAttachBullet2 => 'Фотографии: камера или галерея';

  @override
  String get onboardSpeakTitle => 'Говорите естественно';

  @override
  String get onboardSpeakSubtitle =>
      'Нажмите на микрофон для диктовки с визуализацией формы волны в реальном времени.';

  @override
  String get onboardSpeakBullet1 => 'Остановитесь в любое время; частичный текст сохранится';

  @override
  String get onboardSpeakBullet2 => 'Отлично подходит для быстрых заметок или длинных запросов';

  @override
  String get onboardQuickTitle => 'Быстрые действия';

  @override
  String get onboardQuickSubtitle =>
      'Откройте меню для переключения между чатами, рабочим пространством и профилем.';

  @override
  String get onboardQuickBullet1 =>
      'Нажмите на меню для доступа к чатам, рабочему пространству, профилю';

  @override
  String get onboardQuickBullet2 => 'Начните новый чат или управляйте моделями из верхней панели';

  @override
  String get addAttachment => 'Добавить вложение';

  @override
  String get attachmentLabel => 'Вложение';

  @override
  String get tools => 'Инструменты';

  @override
  String get voiceInput => 'Голосовой ввод';

  @override
  String get voice => 'Голос';

  @override
  String get voiceStatusListening => 'Слушаю...';

  @override
  String get voiceStatusRecording => 'Запись...';

  @override
  String get voiceHoldToTalk => 'Удерживайте для разговора';

  @override
  String get voiceAutoSend => 'Автоотправка';

  @override
  String get voiceTranscript => 'Транскрипция';

  @override
  String get voicePromptSpeakNow => 'Говорите сейчас...';

  @override
  String get voicePromptTapStart => 'Нажмите «Начать» для запуска';

  @override
  String get voiceActionStop => 'Стоп';

  @override
  String get voiceActionStart => 'Начать';

  @override
  String get messageInputLabel => 'Ввод сообщения';

  @override
  String get messageInputHint => 'Введите ваше сообщение';

  @override
  String get messageHintText => 'Сообщение...';

  @override
  String get stopGenerating => 'Остановить генерацию';

  @override
  String get codeCopiedToClipboard => 'Код скопирован в буфер обмена.';

  @override
  String get send => 'Отправить';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get file => 'Файл';

  @override
  String get photo => 'Фото';

  @override
  String get camera => 'Камера';

  @override
  String get apiUnavailable => 'Служба API недоступна';

  @override
  String get unableToLoadImage => 'Не удалось загрузить изображение';

  @override
  String notAnImageFile(String fileName) {
    return 'Не является файлом изображения: ${fileName}';
  }

  @override
  String failedToLoadImage(String error) {
    return 'Не удалось загрузить изображение: ${error}';
  }

  @override
  String get invalidDataUrl => 'Неверный формат data URL';

  @override
  String get failedToDecodeImage => 'Не удалось декодировать изображение';

  @override
  String get invalidImageFormat => 'Неверный формат изображения';

  @override
  String get emptyImageData => 'Пустые данные изображения';

  @override
  String get featureRequiresInternet => 'Эта функция требует подключения к интернету';

  @override
  String get messagesWillSendWhenOnline => 'Сообщения будут отправлены, когда вы снова будете онлайн';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String get inputField => 'Поле ввода';

  @override
  String get captureDocumentOrImage => 'Сфотографировать документ или изображение';

  @override
  String get checkConnection => 'Проверить соединение';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get chooseDifferentFile => 'Выбрать другой файл';

  @override
  String get goBack => 'Назад';

  @override
  String get technicalDetails => 'Технические детали';

  @override
  String get save => 'Сохранить';

  @override
  String get chooseModel => 'Выбрать модель';

  @override
  String get reviewerMode => 'РЕЖИМ РЕЦЕНЗЕНТА';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get folderName => 'Имя папки';

  @override
  String get newChat => 'Новый чат';

  @override
  String get more => 'Еще';

  @override
  String get clear => 'Очистить';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get searchConversations => 'Поиск разговоров...';

  @override
  String get create => 'Создать';

  @override
  String get folderCreated => 'Папка создана';

  @override
  String get failedToCreateFolder => 'Не удалось создать папку';

  @override
  String movedChatToFolder(String title, String folder) {
    return 'Перемещено «${title}» в «${folder}»';
  }

  @override
  String get failedToMoveChat => 'Не удалось переместить чат';

  @override
  String get failedToLoadChats => 'Не удалось загрузить чаты';

  @override
  String get failedToUpdatePin => 'Не удалось обновить закрепление';

  @override
  String get failedToDeleteChat => 'Не удалось удалить чат';

  @override
  String get manage => 'Управление';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get renameChat => 'Переименовать чат';

  @override
  String get enterChatName => 'Введите имя чата';

  @override
  String get failedToRenameChat => 'Не удалось переименовать чат';

  @override
  String get failedToUpdateArchive => 'Не удалось обновить архив';

  @override
  String get unarchive => 'Разархивировать';

  @override
  String get archive => 'Архивировать';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get recent => 'Недавние';

  @override
  String get system => 'Системный';

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
  String get deleteMessagesTitle => 'Удалить сообщения';

  @override
  String deleteMessagesMessage(int count) {
    return
        'Удалить {count, plural, one{{count} сообщение} few{count} сообщения} other{count} сообщений}?';
  }

  @override
  String routeNotFound(String routeName) {
    return 'Маршрут не найден: ${routeName}';
  }

  @override
  String get deleteChatTitle => 'Удалить чат';

  @override
  String get deleteChatMessage => 'Этот чат будет удален навсегда.';

  @override
  String get deleteFolderTitle => 'Удалить папку';

  @override
  String get deleteFolderMessage => 'Эта папка и ее ссылки будут удалены.';

  @override
  String get failedToDeleteFolder => 'Не удалось удалить папку';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get aboutAppSubtitle => 'Информация о Clinical Guidelines и ссылки';

  @override
  String get web => 'Веб';

  @override
  String get imageGen => 'Генерация изображений';

  @override
  String get pinned => 'Закреплено';

  @override
  String get folders => 'Папки';

  @override
  String get archived => 'Архивировано';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get darkMode => 'Темный режим';

  @override
  String get webSearch => 'Веб-поиск';

  @override
  String get webSearchDescription => 'Поиск в интернете и цитирование источников в ответах.';

  @override
  String get imageGeneration => 'Генерация изображений';

  @override
  String get imageGenerationDescription => 'Создавайте изображения из ваших запросов.';

  @override
  String get copy => 'Копировать';

  @override
  String get ttsListen => 'Прослушать';

  @override
  String get ttsStop => 'Остановить';

  @override
  String get edit => 'Редактировать';

  @override
  String get regenerate => 'Регенерировать';

  @override
  String get noConversationsYet => 'Пока нет разговоров';

  @override
  String get usernameOrEmailHint => 'Введите ваше имя пользователя или email';

  @override
  String get passwordHint => 'Введите ваш пароль';

  @override
  String get enterApiKey => 'Введите ваш API-ключ';

  @override
  String get signingIn => 'Вход...';

  @override
  String get advancedSettings => 'Расширенные настройки';

  @override
  String get customHeaders => 'Пользовательские заголовки';

  @override
  String get customHeadersDescription =>
      'Добавьте пользовательские HTTP-заголовки для аутентификации, API-ключей или особых требований сервера.';

  @override
  String get allowSelfSignedCertificates => 'Доверять самоподписанным сертификатам';

  @override
  String get allowSelfSignedCertificatesDescription =>
      'Принимать TLS-сертификат этого сервера, даже если он самоподписанный. Включайте только для серверов, которым вы доверяете.';

  @override
  String get headerNameEmpty => 'Имя заголовка не может быть пустым';

  @override
  String get headerNameTooLong => 'Имя заголовка слишком длинное (максимум 64 символа)';

  @override
  String get headerNameInvalidChars =>
      'Недопустимое имя заголовка. Используйте только буквы, цифры и эти символы: !#\$&-^_`|~';

  @override
  String headerNameReserved(String key) {
    return
        'Невозможно переопределить зарезервированный заголовок «${key}»';
  }

  @override
  String get headerValueEmpty => 'Значение заголовка не может быть пустым';

  @override
  String get headerValueTooLong => 'Значение заголовка слишком длинное (максимум 1024 символа)';

  @override
  String get headerValueInvalidChars =>
      'Значение заголовка содержит недопустимые символы. Используйте только печатаемые ASCII.';

  @override
  String get headerValueUnsafe =>
      'Значение заголовка содержит потенциально небезопасное содержимое';

  @override
  String headerAlreadyExists(String key) {
    return
        'Заголовок «${key}» уже существует. Сначала удалите его для обновления.';
  }

  @override
  String get maxHeadersReachedDetail =>
      'Разрешено максимум 10 пользовательских заголовков. Удалите некоторые, чтобы добавить больше.';

  @override
  String get editMessage => 'Редактировать сообщение';

  @override
  String get noModelsAvailable => 'Нет доступных моделей';

  @override
  String followingSystem(String theme) {
    return 'Следует за системой: ${theme}';
  }

  @override
  String get themeDark => 'Темная';

  @override
  String get themePalette => 'Цветовая палитра';

  @override
  String get themePaletteDescription =>
      'Выберите акцентные цвета для кнопок, карточек и пузырьков чата.';

  @override
  String get themeLight => 'Светлая';

  @override
  String get currentlyUsingDarkTheme => 'Используется темная тема';

  @override
  String get currentlyUsingLightTheme => 'Используется светлая тема';

  @override
  String get aboutConduit => 'О Clinical Guidelines';

  @override
  String versionLabel(String version, String build) {
    return 'Версия: ${version} (${build})';
  }

  @override
  String get githubRepository => 'Репозиторий GitHub';

  @override
  String get unableToLoadAppInfo => 'Не удалось загрузить информацию о приложении';

  @override
  String get thinking => 'Думаю...';

  @override
  String get thoughts => 'Мысли';

  @override
  String thoughtForDuration(String duration) {
    return 'Думал ${duration}';
  }

  @override
  String get appCustomization => 'Настройка приложения';

  @override
  String get appCustomizationSubtitle => 'Персонализируйте отображение имен и интерфейса';

  @override
  String get quickActionsDescription => 'Выберите до двух ярлыков для закрепления рядом с полем ввода';

  @override
  String get chatSettings => 'Чат';

  @override
  String get sendOnEnter => 'Отправка по Enter';

  @override
  String get sendOnEnterDescription =>
      'Enter отправляет (программная клавиатура). Также доступно Cmd/Ctrl+Enter';

  @override
  String get display => 'Отображение';

  @override
  String get realtime => 'Реальное время';

  @override
  String get transportMode => 'Режим транспорта';

  @override
  String get transportModeDescription =>
      'Выберите, как приложение подключается для обновлений в реальном времени.';

  @override
  String get mode => 'Режим';

  @override
  String get transportModeAuto => 'Авто (опрос + WebSocket)';

  @override
  String get transportModeWs => 'Только WebSocket';

  @override
  String get transportModeAutoInfo =>
      'Более надежен в ограничительных сетях. Переходит на WebSocket, когда это возможно.';

  @override
  String get transportModeWsInfo =>
      'Меньше накладных расходов, но может не работать за строгими прокси/брандмауэрами.';

}
