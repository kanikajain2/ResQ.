import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkService {
  Future<String> createResponderLink(String incidentId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://resq.page.link',
      link: Uri.parse('https://resq.emergency.com/responder/$incidentId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.resq.emergency',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.resq.emergency',
        minimumVersion: '1',
      ),
    );

    final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  Future<void> handleDynamicLinks(Function(String) onLinkReceived) async {
    // Check if the app was opened from a link
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      onLinkReceived(initialLink.link.path);
    }

    // Listen for links while the app is in the background or foreground
    FirebaseDynamicLinks.instance.onLink.listen(
      (pendingDynamicLinkData) {
        onLinkReceived(pendingDynamicLinkData.link.path);
      },
    ).onError((error) {
      print('Dynamic Link Failed: ${error.message}');
    });
  }
}
