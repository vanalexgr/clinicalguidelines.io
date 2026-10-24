/// Clinical Guidelines ships locked to a single Open WebUI server.
///
/// When [kServerLockEnabled] is true the server address cannot be edited,
/// advanced connection options are hidden, sign-in is SSO-only, and the model
/// list is limited to the server's default model.
const String kLockedServerUrl = 'https://chat.clinicalguidelines.io';

const bool kServerLockEnabled = true;
