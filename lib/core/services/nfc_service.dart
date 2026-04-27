import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  Future<bool> isAvailable() async {
    // Note: isAvailable() is still valid but sometimes marked as deprecated depending on version.
    // We'll keep it as it's the standard way to check.
    return await NfcManager.instance.isAvailable();
  }

  Future<String?> scanNfcTag() async {
    String? result;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          final data = tag.data as Map<String, dynamic>;
          final ndefData = data['ndef'];
          if (ndefData != null) {
            result = "Room 304"; // Mock detected room
            await NfcManager.instance.stopSession();
          }
        },
      );
      // Wait a bit for the async callback
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Use logging instead of print in production
    }
    return result;
  }

  void startSession({required Function(String) onTagRead}) {
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        onTagRead("ResQ_SOS_Tag_Room_304");
        await NfcManager.instance.stopSession();
      }
    );
  }

  void stopSession() {
    NfcManager.instance.stopSession();
  }
}
