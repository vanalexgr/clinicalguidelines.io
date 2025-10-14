// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for zh (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Clinical Guidelines';

  @override
  String get initializationFailed => '初始化失败';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get you => '你';

  @override
  String get loadingProfile => '加载个人资料中...';

  @override
  String get unableToLoadProfile => '无法加载个人资料';

  @override
  String get pleaseCheckConnection => '请检查您的连接并重试';

  @override
  String get connectionIssueTitle => '无法连接到您的服务器';

  @override
  String get connectionIssueSubtitle => '重新连接以继续或退出登录以选择其他服务器。';

  @override
  String get stillOfflineMessage => '我们仍然无法访问服务器。请仔细检查您的连接并重试。';

  @override
  String get account => '账户';

  @override
  String get supportConduit => '支持 Clinical Guidelines';

  @override
  String get supportConduitSubtitle => '通过资助持续开发来保持 Clinical Guidelines 的独立性。';

  @override
  String get githubSponsorsTitle => 'GitHub 赞助';

  @override
  String get githubSponsorsSubtitle => '成为定期赞助者以资助路线图项目。';

  @override
  String get buyMeACoffeeTitle => 'Buy Me a Coffee';

  @override
  String get buyMeACoffeeSubtitle => '一次性捐赠以表达感谢。';

  @override
  String get signOut => '退出登录';

  @override
  String get endYourSession => '结束您的会话';

  @override
  String get defaultModel => '默认模型';

  @override
  String get autoSelect => '自动选择';

  @override
  String get loadingModels => '加载模型中...';

  @override
  String get failedToLoadModels => '无法加载模型';

  @override
  String get availableModels => '可用模型';

  @override
  String get noResults => '无结果';

  @override
  String get searchModels => '搜索模型...';

  @override
  String get errorMessage => '出了点问题。请重试。';

  @override
  String get loginButton => '登录';

  @override
  String get menuItem => '设置';

  @override
  String dynamicContentWithPlaceholder(String name) {
    return '欢迎，${name}！';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count} 个项目',
      zero: '无项目',
    );
    return '$_temp0';
  }

  @override
  String get closeButtonSemantic => '关闭';

  @override
  String get loadingContent => '加载内容中';

  @override
  String get noItems => '无项目';

  @override
  String get noItemsToDisplay => '无可显示的项目';

  @override
  String get loadMore => '加载更多';

  @override
  String get workspace => '工作区';

  @override
  String get recentFiles => '最近文件';

  @override
  String get knowledgeBase => '知识库';

  @override
  String get noFilesYet => '尚无文件';

  @override
  String get uploadDocsPrompt => '上传文档以在您与 Clinical Guidelines 的对话中引用';

  @override
  String get uploadFirstFile => '上传您的第一个文件';

  @override
  String get attachments => '附件';

  @override
  String get knowledgeBaseEmpty => '知识库为空';

  @override
  String get createCollectionsPrompt => '创建相关文档集合以便于引用';

  @override
  String get chooseSourcePhoto => '选择来源';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseFromGallery => '从相册中选择';

  @override
  String get document => '文档';

  @override
  String get documentHint => 'PDF、Word 或文本文件';

  @override
  String get uploadFileTitle => '上传文件';

  @override
  String fileUploadComingSoon(String type) {
    return '${type} 的文件上传即将推出！';
  }

  @override
  String get kbCreationComingSoon => '知识库创建即将推出！';

  @override
  String get backToServerSetup => '返回服务器设置';

  @override
  String get connectedToServer => '已连接到服务器';

  @override
  String get signIn => '登录';

  @override
  String get enterCredentials => '输入您的凭据以访问您的 AI 对话';

  @override
  String get credentials => '凭据';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get usernameOrEmail => '用户名或电子邮件';

  @override
  String get password => '密码';

  @override
  String get signInWithApiKey => '使用 API 密钥登录';

  @override
  String get connectToServer => '连接到服务器';

  @override
  String get enterServerAddress => '输入您的 Open-WebUI 服务器地址以开始';

  @override
  String get serverUrl => '服务器 URL';

  @override
  String get serverUrlHint => 'https://your-server.com';

  @override
  String get enterServerUrlSemantic => '输入您的服务器 URL 或 IP 地址';

  @override
  String get headerName => '标头名称';

  @override
  String get headerValue => '标头值';

  @override
  String get headerValueHint => 'api-key-123 或 Bearer token';

  @override
  String get addHeader => '添加标头';

  @override
  String get maximumHeadersReached => '已达到最大标头数';

  @override
  String get removeHeader => '删除标头';

  @override
  String get connecting => '连接中...';

  @override
  String get connectToServerButton => '连接到服务器';

  @override
  String get demoModeActive => '演示模式已激活';

  @override
  String get skipServerSetupTryDemo => '跳过服务器设置并尝试演示';

  @override
  String get enterDemo => '进入演示';

  @override
  String get demoBadge => '演示';

  @override
  String get serverNotOpenWebUI => '这似乎不是 Open-WebUI 服务器。';

  @override
  String get serverUrlEmpty => '服务器 URL 不能为空';

  @override
  String get invalidUrlFormat => '无效的 URL 格式。请检查您的输入。';

  @override
  String get onlyHttpHttps => '仅支持 HTTP 和 HTTPS 协议。';

  @override
  String get serverAddressRequired => '需要服务器地址（例如 192.168.1.10 或 example.com）。';

  @override
  String get portRange => '端口必须在 1 到 65535 之间。';

  @override
  String get invalidIpFormat => '无效的 IP 地址格式。使用如 192.168.1.10 的格式。';

  @override
  String get couldNotConnectGeneric => '无法连接。请仔细检查地址并重试。';

  @override
  String get weCouldntReachServer => '我们无法访问服务器。请检查您的连接和服务器是否正在运行。';

  @override
  String get connectionTimedOut => '连接超时。服务器可能很忙或被防火墙阻止。';

  @override
  String get useHttpOrHttpsOnly => '仅使用 http:// 或 https://。';

  @override
  String get loginFailed => '登录失败';

  @override
  String get invalidCredentials => '无效的用户名或密码。请重试。';

  @override
  String get serverRedirectingHttps => '服务器正在重定向请求。请检查您的服务器的 HTTPS 配置。';

  @override
  String get unableToConnectServer => '无法连接到服务器。请检查您的连接。';

  @override
  String get requestTimedOut => '请求超时。请重试。';

  @override
  String get genericSignInFailed => '我们无法让您登录。请检查您的凭据和服务器设置。';

  @override
  String get skip => '跳过';

  @override
  String get next => '下一步';

  @override
  String get done => '完成';

  @override
  String onboardStartTitle(String username) {
    return '你好，${username}';
  }

  @override
  String get onboardStartSubtitle => '选择一个模型以开始。随时点击新对话。';

  @override
  String get onboardStartBullet1 => '点击顶部栏中的模型名称以切换模型';

  @override
  String get onboardStartBullet2 => '使用新对话重置上下文';

  @override
  String get onboardAttachTitle => '添加上下文';

  @override
  String get onboardAttachSubtitle => '使用工作区或照片中的内容来支持回复。';

  @override
  String get onboardAttachBullet1 => '工作区：PDF、文档、数据集';

  @override
  String get onboardAttachBullet2 => '照片：相机或相册';

  @override
  String get onboardSpeakTitle => '自然说话';

  @override
  String get onboardSpeakSubtitle => '点击麦克风以实时波形反馈听写。';

  @override
  String get onboardSpeakBullet1 => '随时停止；部分文本会保留';

  @override
  String get onboardSpeakBullet2 => '非常适合快速笔记或长提示';

  @override
  String get onboardQuickTitle => '快速操作';

  @override
  String get onboardQuickSubtitle => '打开菜单在对话、工作区和个人资料之间切换。';

  @override
  String get onboardQuickBullet1 => '点击菜单访问对话、工作区、个人资料';

  @override
  String get onboardQuickBullet2 => '从顶部栏开始新对话或管理模型';

  @override
  String get addAttachment => '添加附件';

  @override
  String get attachmentLabel => '附件';

  @override
  String get tools => '工具';

  @override
  String get voiceInput => '语音输入';

  @override
  String get voice => '语音';

  @override
  String get voiceStatusListening => '正在听...';

  @override
  String get voiceStatusRecording => '正在录制...';

  @override
  String get voiceHoldToTalk => '按住说话';

  @override
  String get voiceAutoSend => '自动发送';

  @override
  String get voiceTranscript => '转录';

  @override
  String get voicePromptSpeakNow => '现在说话...';

  @override
  String get voicePromptTapStart => '点击开始以开始';

  @override
  String get voiceActionStop => '停止';

  @override
  String get voiceActionStart => '开始';

  @override
  String get messageInputLabel => '消息输入';

  @override
  String get messageInputHint => '输入您的消息';

  @override
  String get messageHintText => '消息...';

  @override
  String get stopGenerating => '停止生成';

  @override
  String get codeCopiedToClipboard => '代码已复制到剪贴板。';

  @override
  String get send => '发送';

  @override
  String get sendMessage => '发送消息';

  @override
  String get file => '文件';

  @override
  String get photo => '照片';

  @override
  String get camera => '相机';

  @override
  String get apiUnavailable => 'API 服务不可用';

  @override
  String get unableToLoadImage => '无法加载图像';

  @override
  String notAnImageFile(String fileName) {
    return '不是图像文件：${fileName}';
  }

  @override
  String failedToLoadImage(String error) {
    return '无法加载图像：${error}';
  }

  @override
  String get invalidDataUrl => '无效的数据 URL 格式';

  @override
  String get failedToDecodeImage => '无法解码图像';

  @override
  String get invalidImageFormat => '无效的图像格式';

  @override
  String get emptyImageData => '空图像数据';

  @override
  String get featureRequiresInternet => '此功能需要互联网连接';

  @override
  String get messagesWillSendWhenOnline => '当您重新上线时将发送消息';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get inputField => '输入字段';

  @override
  String get captureDocumentOrImage => '捕获文档或图像';

  @override
  String get checkConnection => '检查连接';

  @override
  String get openSettings => '打开设置';

  @override
  String get chooseDifferentFile => '选择其他文件';

  @override
  String get goBack => '返回';

  @override
  String get technicalDetails => '技术详情';

  @override
  String get save => '保存';

  @override
  String get chooseModel => '选择模型';

  @override
  String get reviewerMode => '审核者模式';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get newFolder => '新文件夹';

  @override
  String get folderName => '文件夹名称';

  @override
  String get newChat => '新对话';

  @override
  String get more => '更多';

  @override
  String get clear => '清除';

  @override
  String get searchHint => '搜索...';

  @override
  String get searchConversations => '搜索对话...';

  @override
  String get create => '创建';

  @override
  String get folderCreated => '文件夹已创建';

  @override
  String get failedToCreateFolder => '无法创建文件夹';

  @override
  String movedChatToFolder(String title, String folder) {
    return '已将「${title}」移至「${folder}」';
  }

  @override
  String get failedToMoveChat => '无法移动对话';

  @override
  String get failedToLoadChats => '无法加载对话';

  @override
  String get failedToUpdatePin => '无法更新置顶';

  @override
  String get failedToDeleteChat => '无法删除对话';

  @override
  String get manage => '管理';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get renameChat => '重命名对话';

  @override
  String get enterChatName => '输入对话名称';

  @override
  String get failedToRenameChat => '无法重命名对话';

  @override
  String get failedToUpdateArchive => '无法更新存档';

  @override
  String get unarchive => '取消存档';

  @override
  String get archive => '存档';

  @override
  String get pin => '置顶';

  @override
  String get unpin => '取消置顶';

  @override
  String get recent => '最近';

  @override
  String get system => '系统';

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
  String get deleteMessagesTitle => '删除消息';

  @override
  String deleteMessagesMessage(int count) {
    return '删除 ${count} 条消息？';
  }

  @override
  String routeNotFound(String routeName) {
    return '未找到路由：${routeName}';
  }

  @override
  String get deleteChatTitle => '删除对话';

  @override
  String get deleteChatMessage => '此对话将被永久删除。';

  @override
  String get deleteFolderTitle => '删除文件夹';

  @override
  String get deleteFolderMessage => '此文件夹及其分配引用将被删除。';

  @override
  String get failedToDeleteFolder => '无法删除文件夹';

  @override
  String get aboutApp => '关于应用';

  @override
  String get aboutAppSubtitle => 'Clinical Guidelines 信息和链接';

  @override
  String get web => '网页';

  @override
  String get imageGen => '图像生成';

  @override
  String get pinned => '已置顶';

  @override
  String get folders => '文件夹';

  @override
  String get archived => '已存档';

  @override
  String get appLanguage => '应用语言';

  @override
  String get darkMode => '深色模式';

  @override
  String get webSearch => '网页搜索';

  @override
  String get webSearchDescription => '搜索网页并在回复中引用来源。';

  @override
  String get imageGeneration => '图像生成';

  @override
  String get imageGenerationDescription => '从您的提示创建图像。';

  @override
  String get copy => '复制';

  @override
  String get ttsListen => '收听';

  @override
  String get ttsStop => '停止';

  @override
  String get edit => '编辑';

  @override
  String get regenerate => '重新生成';

  @override
  String get noConversationsYet => '尚无对话';

  @override
  String get usernameOrEmailHint => '输入您的用户名或电子邮件';

  @override
  String get passwordHint => '输入您的密码';

  @override
  String get enterApiKey => '输入您的 API 密钥';

  @override
  String get signingIn => '正在登录...';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get customHeaders => '自定义标头';

  @override
  String get customHeadersDescription => '为身份验证、API 密钥或特殊服务器要求添加自定义 HTTP 标头。';

  @override
  String get allowSelfSignedCertificates => '信任自签名证书';

  @override
  String get allowSelfSignedCertificatesDescription => '接受此服务器的 TLS 证书，即使它是自签名的。仅对您信任的服务器启用。';

  @override
  String get headerNameEmpty => '标头名称不能为空';

  @override
  String get headerNameTooLong => '标头名称太长（最多 64 个字符）';

  @override
  String get headerNameInvalidChars => '无效的标头名称。仅使用字母、数字和这些符号：!#\$&-^_`|~';

  @override
  String headerNameReserved(String key) {
    return '无法覆盖保留的标头「${key}」';
  }

  @override
  String get headerValueEmpty => '标头值不能为空';

  @override
  String get headerValueTooLong => '标头值太长（最多 1024 个字符）';

  @override
  String get headerValueInvalidChars => '标头值包含无效字符。仅使用可打印的 ASCII。';

  @override
  String get headerValueUnsafe => '标头值似乎包含潜在的不安全内容';

  @override
  String headerAlreadyExists(String key) {
    return '标头「${key}」已存在。首先删除它以更新。';
  }

  @override
  String get maxHeadersReachedDetail => '最多允许 10 个自定义标头。删除一些以添加更多。';

  @override
  String get editMessage => '编辑消息';

  @override
  String get noModelsAvailable => '无可用模型';

  @override
  String followingSystem(String theme) {
    return '跟随系统：${theme}';
  }

  @override
  String get themeDark => '深色';

  @override
  String get themePalette => '强调色调色板';

  @override
  String get themePaletteDescription => '选择用于按钮、卡片和对话气泡的强调色。';

  @override
  String get themeLight => '浅色';

  @override
  String get currentlyUsingDarkTheme => '当前使用深色主题';

  @override
  String get currentlyUsingLightTheme => '当前使用浅色主题';

  @override
  String get aboutConduit => '关于 Clinical Guidelines';

  @override
  String versionLabel(String version, String build) {
    return '版本：${version}（${build}）';
  }

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get unableToLoadAppInfo => '无法加载应用信息';

  @override
  String get thinking => '思考中...';

  @override
  String get thoughts => '思路';

  @override
  String thoughtForDuration(String duration) {
    return '思考了 ${duration}';
  }

  @override
  String get appCustomization => '应用自定义';

  @override
  String get appCustomizationSubtitle => '个性化名称和 UI 显示';

  @override
  String get quickActionsDescription => '选择最多两个快捷方式以固定在撰写器附近';

  @override
  String get chatSettings => '对话';

  @override
  String get sendOnEnter => '回车发送';

  @override
  String get sendOnEnterDescription => '回车发送（软键盘）。Cmd/Ctrl+Enter 也可用';

  @override
  String get display => '显示';

  @override
  String get realtime => '实时';

  @override
  String get transportMode => '传输模式';

  @override
  String get transportModeDescription => '选择应用如何连接以进行实时更新。';

  @override
  String get mode => '模式';

  @override
  String get transportModeAuto => '自动（轮询 + WebSocket）';

  @override
  String get transportModeWs => '仅 WebSocket';

  @override
  String get transportModeAutoInfo => '在限制性网络上更稳健。在可能的情况下升级到 WebSocket。';

  @override
  String get transportModeWsInfo => '开销较低，但可能在严格的代理/防火墙后失败。';

}
