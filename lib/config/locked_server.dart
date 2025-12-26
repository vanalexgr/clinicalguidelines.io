// lib/config/locked_server.dart

// 1. Define your server URL here
// Change this to your actual OpenWebUI server address
const String kLockedServerUrl = "https://chat.clinicalguidelines.io";

// 2. Helper to check if a URL belongs to your server
bool isServerUrl(String url) {
  return url.startsWith(kLockedServerUrl);
}
