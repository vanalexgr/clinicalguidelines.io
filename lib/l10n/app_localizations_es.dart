// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for es (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Clinical Guidelines';

  @override
  String get initializationFailed => 'Error de inicialización';

  @override
  String get retry => 'Reintentar';

  @override
  String get back => 'Atrás';

  @override
  String get you => 'Tú';

  @override
  String get loadingProfile => 'Cargando perfil...';

  @override
  String get unableToLoadProfile => 'No se puede cargar el perfil';

  @override
  String get pleaseCheckConnection => 'Por favor, verifica tu conexión e inténtalo de nuevo';

  @override
  String get connectionIssueTitle => 'No se puede conectar al servidor';

  @override
  String get connectionIssueSubtitle =>
      'Reconecta para continuar o cierra sesión para elegir otro servidor.';

  @override
  String get stillOfflineMessage =>
      'Todavía no podemos conectarnos al servidor. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get account => 'Cuenta';

  @override
  String get supportConduit => 'Apoyar Clinical Guidelines';

  @override
  String get supportConduitSubtitle =>
      'Mantén Clinical Guidelines independiente financiando el desarrollo continuo.';

  @override
  String get githubSponsorsTitle => 'GitHub Sponsors';

  @override
  String get githubSponsorsSubtitle =>
      'Conviértete en un patrocinador recurrente para financiar elementos del roadmap.';

  @override
  String get buyMeACoffeeTitle => 'Buy Me a Coffee';

  @override
  String get buyMeACoffeeSubtitle => 'Haz una donación única para agradecer.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get endYourSession => 'Finalizar tu sesión';

  @override
  String get defaultModel => 'Modelo predeterminado';

  @override
  String get autoSelect => 'Selección automática';

  @override
  String get loadingModels => 'Cargando modelos...';

  @override
  String get failedToLoadModels => 'No se pudieron cargar los modelos';

  @override
  String get availableModels => 'Modelos disponibles';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get searchModels => 'Buscar modelos...';

  @override
  String get errorMessage => 'Algo salió mal. Por favor, inténtalo de nuevo.';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get menuItem => 'Configuración';

  @override
  String dynamicContentWithPlaceholder(String name) {
    return '¡Bienvenido, ${name}!';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 elemento',
      other: '${count} elementos',
      zero: 'Sin elementos',
    );
    return '$_temp0';
  }

  @override
  String get closeButtonSemantic => 'Cerrar';

  @override
  String get loadingContent => 'Cargando contenido';

  @override
  String get noItems => 'Sin elementos';

  @override
  String get noItemsToDisplay => 'No hay elementos para mostrar';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get workspace => 'Espacio de trabajo';

  @override
  String get recentFiles => 'Archivos recientes';

  @override
  String get knowledgeBase => 'Base de conocimientos';

  @override
  String get noFilesYet => 'Aún no hay archivos';

  @override
  String get uploadDocsPrompt =>
      'Sube documentos para referenciarlos en tus conversaciones con Clinical Guidelines';

  @override
  String get uploadFirstFile => 'Sube tu primer archivo';

  @override
  String get attachments => 'Adjuntos';

  @override
  String get knowledgeBaseEmpty => 'La base de conocimientos está vacía';

  @override
  String get createCollectionsPrompt =>
      'Crea colecciones de documentos relacionados para referencia fácil';

  @override
  String get chooseSourcePhoto => 'Elige tu fuente';

  @override
  String get takePhoto => 'Tomar una foto';

  @override
  String get chooseFromGallery => 'Elegir de tus fotos';

  @override
  String get document => 'Documento';

  @override
  String get documentHint => 'Archivo PDF, Word o de texto';

  @override
  String get uploadFileTitle => 'Subir archivo';

  @override
  String fileUploadComingSoon(String type) {
    return '¡La carga de archivos para ${type} estará disponible pronto!';
  }

  @override
  String get kbCreationComingSoon =>
      '¡La creación de base de conocimientos estará disponible pronto!';

  @override
  String get backToServerSetup => 'Volver a configuración del servidor';

  @override
  String get connectedToServer => 'Conectado al servidor';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get enterCredentials =>
      'Ingresa tus credenciales para acceder a tus conversaciones de IA';

  @override
  String get credentials => 'Credenciales';

  @override
  String get apiKey => 'Clave API';

  @override
  String get usernameOrEmail => 'Usuario o correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get signInWithApiKey => 'Iniciar sesión con clave API';

  @override
  String get connectToServer => 'Conectar al servidor';

  @override
  String get enterServerAddress => 'Ingresa la dirección de tu servidor Open-WebUI para comenzar';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get serverUrlHint => 'https://tu-servidor.com';

  @override
  String get enterServerUrlSemantic => 'Ingresa la URL o dirección IP de tu servidor';

  @override
  String get headerName => 'Nombre de encabezado';

  @override
  String get headerValue => 'Valor de encabezado';

  @override
  String get headerValueHint => 'api-key-123 o Bearer token';

  @override
  String get addHeader => 'Añadir encabezado';

  @override
  String get maximumHeadersReached => 'Número máximo de encabezados alcanzado';

  @override
  String get removeHeader => 'Eliminar encabezado';

  @override
  String get connecting => 'Conectando...';

  @override
  String get connectToServerButton => 'Conectar al servidor';

  @override
  String get demoModeActive => 'Modo demo activo';

  @override
  String get skipServerSetupTryDemo => 'Omitir configuración del servidor y probar la demo';

  @override
  String get enterDemo => 'Entrar a demo';

  @override
  String get demoBadge => 'Demo';

  @override
  String get serverNotOpenWebUI => 'Esto no parece ser un servidor Open-WebUI.';

  @override
  String get serverUrlEmpty => 'La URL del servidor no puede estar vacía';

  @override
  String get invalidUrlFormat => 'Formato de URL inválido. Por favor, verifica tu entrada.';

  @override
  String get onlyHttpHttps => 'Solo se admiten los protocolos HTTP y HTTPS.';

  @override
  String get serverAddressRequired =>
      'Se requiere dirección del servidor (ej. 192.168.1.10 o example.com).';

  @override
  String get portRange => 'El puerto debe estar entre 1 y 65535.';

  @override
  String get invalidIpFormat =>
      'Formato de dirección IP inválido. Usa un formato como 192.168.1.10.';

  @override
  String get couldNotConnectGeneric =>
      'No se pudo conectar. Verifica la dirección e inténtalo de nuevo.';

  @override
  String get weCouldntReachServer =>
      'No pudimos conectarnos al servidor. Verifica tu conexión y que el servidor esté funcionando.';

  @override
  String get connectionTimedOut =>
      'Se agotó el tiempo de conexión. El servidor puede estar ocupado o bloqueado por un firewall.';

  @override
  String get useHttpOrHttpsOnly => 'Usa solo http:// o https://.';

  @override
  String get loginFailed => 'Error al iniciar sesión';

  @override
  String get invalidCredentials =>
      'Usuario o contraseña inválidos. Por favor, inténtalo de nuevo.';

  @override
  String get serverRedirectingHttps =>
      'El servidor está redirigiendo solicitudes. Verifica la configuración HTTPS de tu servidor.';

  @override
  String get unableToConnectServer =>
      'No se puede conectar al servidor. Por favor, verifica tu conexión.';

  @override
  String get requestTimedOut =>
      'Se agotó el tiempo de espera de la solicitud. Por favor, inténtalo de nuevo.';

  @override
  String get genericSignInFailed =>
      'No pudimos iniciar tu sesión. Verifica tus credenciales y configuración del servidor.';

  @override
  String get skip => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get done => 'Listo';

  @override
  String onboardStartTitle(String username) {
    return 'Hola, ${username}';
  }

  @override
  String get onboardStartSubtitle =>
      'Elige un modelo para comenzar. Toca Nueva conversación cuando quieras.';

  @override
  String get onboardStartBullet1 =>
      'Toca el nombre del modelo en la barra superior para cambiar modelos';

  @override
  String get onboardStartBullet2 => 'Usa Nueva conversación para restablecer el contexto';

  @override
  String get onboardAttachTitle => 'Añadir contexto';

  @override
  String get onboardAttachSubtitle =>
      'Fundamenta las respuestas con contenido del espacio de trabajo o fotos.';

  @override
  String get onboardAttachBullet1 => 'Espacio de trabajo: PDFs, documentos, conjuntos de datos';

  @override
  String get onboardAttachBullet2 => 'Fotos: cámara o galería';

  @override
  String get onboardSpeakTitle => 'Habla naturalmente';

  @override
  String get onboardSpeakSubtitle =>
      'Toca el micrófono para dictar con retroalimentación de forma de onda en vivo.';

  @override
  String get onboardSpeakBullet1 => 'Detente en cualquier momento; el texto parcial se conserva';

  @override
  String get onboardSpeakBullet2 => 'Genial para notas rápidas o prompts largos';

  @override
  String get onboardQuickTitle => 'Acciones rápidas';

  @override
  String get onboardQuickSubtitle =>
      'Abre el menú para cambiar entre Conversaciones, Espacio de trabajo y Perfil.';

  @override
  String get onboardQuickBullet1 =>
      'Toca el menú para acceder a Conversaciones, Espacio de trabajo, Perfil';

  @override
  String get onboardQuickBullet2 =>
      'Inicia Nueva conversación o gestiona modelos desde la barra superior';

  @override
  String get addAttachment => 'Añadir adjunto';

  @override
  String get attachmentLabel => 'Adjunto';

  @override
  String get tools => 'Herramientas';

  @override
  String get voiceInput => 'Entrada de voz';

  @override
  String get voice => 'Voz';

  @override
  String get voiceStatusListening => 'Escuchando...';

  @override
  String get voiceStatusRecording => 'Grabando...';

  @override
  String get voiceHoldToTalk => 'Mantén presionado para hablar';

  @override
  String get voiceAutoSend => 'Envío automático';

  @override
  String get voiceTranscript => 'Transcripción';

  @override
  String get voicePromptSpeakNow => 'Habla ahora...';

  @override
  String get voicePromptTapStart => 'Toca Iniciar para comenzar';

  @override
  String get voiceActionStop => 'Detener';

  @override
  String get voiceActionStart => 'Iniciar';

  @override
  String get messageInputLabel => 'Entrada de mensaje';

  @override
  String get messageInputHint => 'Escribe tu mensaje';

  @override
  String get messageHintText => 'Mensaje...';

  @override
  String get stopGenerating => 'Detener generación';

  @override
  String get codeCopiedToClipboard => 'Código copiado al portapapeles.';

  @override
  String get send => 'Enviar';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get file => 'Archivo';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Cámara';

  @override
  String get apiUnavailable => 'Servicio de API no disponible';

  @override
  String get unableToLoadImage => 'No se puede cargar la imagen';

  @override
  String notAnImageFile(String fileName) {
    return 'No es un archivo de imagen: ${fileName}';
  }

  @override
  String failedToLoadImage(String error) {
    return 'No se pudo cargar la imagen: ${error}';
  }

  @override
  String get invalidDataUrl => 'Formato de URL de datos inválido';

  @override
  String get failedToDecodeImage => 'No se pudo decodificar la imagen';

  @override
  String get invalidImageFormat => 'Formato de imagen inválido';

  @override
  String get emptyImageData => 'Datos de imagen vacíos';

  @override
  String get featureRequiresInternet => 'Esta función requiere conexión a Internet';

  @override
  String get messagesWillSendWhenOnline => 'Los mensajes se enviarán cuando vuelvas a estar en línea';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get inputField => 'Campo de entrada';

  @override
  String get captureDocumentOrImage => 'Capturar un documento o imagen';

  @override
  String get checkConnection => 'Verificar conexión';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get chooseDifferentFile => 'Elegir otro archivo';

  @override
  String get goBack => 'Volver';

  @override
  String get technicalDetails => 'Detalles técnicos';

  @override
  String get save => 'Guardar';

  @override
  String get chooseModel => 'Elegir modelo';

  @override
  String get reviewerMode => 'MODO REVISOR';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get newFolder => 'Nueva carpeta';

  @override
  String get folderName => 'Nombre de carpeta';

  @override
  String get newChat => 'Nueva conversación';

  @override
  String get more => 'Más';

  @override
  String get clear => 'Limpiar';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get searchConversations => 'Buscar conversaciones...';

  @override
  String get create => 'Crear';

  @override
  String get folderCreated => 'Carpeta creada';

  @override
  String get failedToCreateFolder => 'No se pudo crear la carpeta';

  @override
  String movedChatToFolder(String title, String folder) {
    return 'Se movió "${title}" a "${folder}"';
  }

  @override
  String get failedToMoveChat => 'No se pudo mover la conversación';

  @override
  String get failedToLoadChats => 'No se pudieron cargar las conversaciones';

  @override
  String get failedToUpdatePin => 'No se pudo actualizar el anclaje';

  @override
  String get failedToDeleteChat => 'No se pudo eliminar la conversación';

  @override
  String get manage => 'Gestionar';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get renameChat => 'Renombrar conversación';

  @override
  String get enterChatName => 'Ingresa nombre de conversación';

  @override
  String get failedToRenameChat => 'No se pudo renombrar la conversación';

  @override
  String get failedToUpdateArchive => 'No se pudo actualizar el archivo';

  @override
  String get unarchive => 'Desarchivar';

  @override
  String get archive => 'Archivar';

  @override
  String get pin => 'Anclar';

  @override
  String get unpin => 'Desanclar';

  @override
  String get recent => 'Reciente';

  @override
  String get system => 'Sistema';

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
  String get deleteMessagesTitle => 'Eliminar mensajes';

  @override
  String deleteMessagesMessage(int count) {
    return '¿Eliminar ${count} mensajes?';
  }

  @override
  String routeNotFound(String routeName) {
    return 'Ruta no encontrada: ${routeName}';
  }

  @override
  String get deleteChatTitle => 'Eliminar conversación';

  @override
  String get deleteChatMessage => 'Esta conversación se eliminará permanentemente.';

  @override
  String get deleteFolderTitle => 'Eliminar carpeta';

  @override
  String get deleteFolderMessage => 'Esta carpeta y sus referencias de asignación se eliminarán.';

  @override
  String get failedToDeleteFolder => 'No se pudo eliminar la carpeta';

  @override
  String get aboutApp => 'Acerca de la aplicación';

  @override
  String get aboutAppSubtitle => 'Información y enlaces de Clinical Guidelines';

  @override
  String get web => 'Web';

  @override
  String get imageGen => 'Generación de imágenes';

  @override
  String get pinned => 'Anclado';

  @override
  String get folders => 'Carpetas';

  @override
  String get archived => 'Archivado';

  @override
  String get appLanguage => 'Idioma de la aplicación';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get webSearch => 'Búsqueda web';

  @override
  String get webSearchDescription => 'Busca en la web y cita fuentes en las respuestas.';

  @override
  String get imageGeneration => 'Generación de imágenes';

  @override
  String get imageGenerationDescription => 'Crea imágenes a partir de tus prompts.';

  @override
  String get copy => 'Copiar';

  @override
  String get ttsListen => 'Escuchar';

  @override
  String get ttsStop => 'Detener';

  @override
  String get edit => 'Editar';

  @override
  String get regenerate => 'Regenerar';

  @override
  String get noConversationsYet => 'Aún no hay conversaciones';

  @override
  String get usernameOrEmailHint => 'Ingresa tu usuario o correo electrónico';

  @override
  String get passwordHint => 'Ingresa tu contraseña';

  @override
  String get enterApiKey => 'Ingresa tu clave API';

  @override
  String get signingIn => 'Iniciando sesión...';

  @override
  String get advancedSettings => 'Configuración avanzada';

  @override
  String get customHeaders => 'Encabezados personalizados';

  @override
  String get customHeadersDescription =>
      'Añade encabezados HTTP personalizados para autenticación, claves API o requisitos especiales del servidor.';

  @override
  String get allowSelfSignedCertificates => 'Confiar en certificados autofirmados';

  @override
  String get allowSelfSignedCertificatesDescription =>
      'Acepta el certificado TLS de este servidor incluso si es autofirmado. Actívalo solo para servidores en los que confíes.';

  @override
  String get headerNameEmpty => 'El nombre del encabezado no puede estar vacío';

  @override
  String get headerNameTooLong => 'Nombre de encabezado demasiado largo (máx. 64 caracteres)';

  @override
  String get headerNameInvalidChars =>
      'Nombre de encabezado inválido. Usa solo letras, números y estos símbolos: !#\$&-^_`|~';

  @override
  String headerNameReserved(String key) {
    return 'No se puede sobrescribir el encabezado reservado "${key}"';
  }

  @override
  String get headerValueEmpty => 'El valor del encabezado no puede estar vacío';

  @override
  String get headerValueTooLong => 'Valor de encabezado demasiado largo (máx. 1024 caracteres)';

  @override
  String get headerValueInvalidChars =>
      'El valor del encabezado contiene caracteres inválidos. Usa solo ASCII imprimible.';

  @override
  String get headerValueUnsafe =>
      'El valor del encabezado parece contener contenido potencialmente inseguro';

  @override
  String headerAlreadyExists(String key) {
    return
        'El encabezado "${key}" ya existe. Elimínalo primero para actualizarlo.';
  }

  @override
  String get maxHeadersReachedDetail =>
      'Máximo de 10 encabezados personalizados permitidos. Elimina algunos para añadir más.';

  @override
  String get editMessage => 'Editar mensaje';

  @override
  String get noModelsAvailable => 'No hay modelos disponibles';

  @override
  String followingSystem(String theme) {
    return 'Siguiendo el sistema: ${theme}';
  }

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themePalette => 'Paleta de acentos';

  @override
  String get themePaletteDescription =>
      'Elige los colores de acento usados para botones, tarjetas y burbujas de chat.';

  @override
  String get themeLight => 'Claro';

  @override
  String get currentlyUsingDarkTheme => 'Usando actualmente el tema oscuro';

  @override
  String get currentlyUsingLightTheme => 'Usando actualmente el tema claro';

  @override
  String get aboutConduit => 'Acerca de Clinical Guidelines';

  @override
  String versionLabel(String version, String build) {
    return 'Versión: ${version} (${build})';
  }

  @override
  String get githubRepository => 'Repositorio GitHub';

  @override
  String get unableToLoadAppInfo => 'No se puede cargar información de la aplicación';

  @override
  String get thinking => 'Pensando...';

  @override
  String get thoughts => 'Pensamientos';

  @override
  String thoughtForDuration(String duration) {
    return 'Pensó durante ${duration}';
  }

  @override
  String get appCustomization => 'Personalización de la aplicación';

  @override
  String get appCustomizationSubtitle => 'Personaliza cómo se muestran los nombres y la interfaz';

  @override
  String get quickActionsDescription =>
      'Elige hasta dos accesos directos para anclar cerca del compositor';

  @override
  String get chatSettings => 'Conversación';

  @override
  String get sendOnEnter => 'Enviar con Enter';

  @override
  String get sendOnEnterDescription =>
      'Enter envía (teclado virtual). Cmd/Ctrl+Enter también disponible';

  @override
  String get display => 'Visualización';

  @override
  String get realtime => 'Tiempo real';

  @override
  String get transportMode => 'Modo de transporte';

  @override
  String get transportModeDescription =>
      'Elige cómo se conecta la aplicación para actualizaciones en tiempo real.';

  @override
  String get mode => 'Modo';

  @override
  String get transportModeAuto => 'Automático (Polling + WebSocket)';

  @override
  String get transportModeWs => 'Solo WebSocket';

  @override
  String get transportModeAutoInfo =>
      'Más robusto en redes restrictivas. Se actualiza a WebSocket cuando es posible.';

  @override
  String get transportModeWsInfo =>
      'Menor sobrecarga, pero puede fallar detrás de proxies/firewalls estrictos.';

}
