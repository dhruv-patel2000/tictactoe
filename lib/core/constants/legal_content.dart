import 'package:tic_tac_toe/core/constants/settings.dart';

enum LegalContactType { email, phone, responseTime }

// One row (label + value) shown under a legal page's contact section.
class LegalContactItem {
  final LegalContactType type;
  final String label;
  final String value;

  const LegalContactItem({
    required this.type,
    required this.label,
    required this.value,
  });
}

// Content for one LegalInfoScreen instance (title + body + optional contacts).
class LegalInfoPage {
  // localization key resolved via AppLocalization for the screen's app bar title
  final String titleKey;
  final String body;
  // only populated for pages that show contact rows (e.g. contactUs)
  final List<LegalContactItem> contactItems;

  const LegalInfoPage({
    required this.titleKey,
    required this.body,
    this.contactItems = const [],
  });
}

/// Static text shown on LegalInfoScreen. Edit here to update app-side copy
/// for Contact Us, About Us, Terms & Conditions, and Privacy Policy.
class LegalContent {
  LegalContent._();

  // Placeholder body text reused for Terms & Conditions and Privacy Policy
  // until real legal copy is supplied.
  static const String _loremText = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce aliquet vulputate tincidunt. Etiam pharetra auctor massa in aliquet. Curabitur a elit ut mauris ullamcorper pulvinar. Phasellus maximus tellus dui, id iaculis lectus fermentum nec. Aliquam odio erat, porttitor vel luctus id, sollicitudin non tortor. Vestibulum neque est, semper vel dui eu, varius aliquam ante. Donec mollis magna sed metus vestibulum consequat. Ut aliquam vulputate ligula, non cursus nibh gravida vitae. Phasellus tellus tellus, accumsan eget tortor laoreet, molestie mollis nisl.

Donec molestie semper nibh in efficitur. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Suspendisse dignissim, ex ac iaculis pulvinar, sem nisi scelerisque justo, pulvinar pellentesque ex mi bibendum urna. Quisque ac commodo justo. Integer ut dignissim lectus. Donec a elementum dolor. Vivamus eu nunc vitae mi iaculis imperdiet.

Ut ullamcorper risus leo, sit amet dictum magna consequat id. Cras eros leo, ullamcorper a vehicula sed, suscipit nec mi. Donec facilisis, urna eu placerat condimentum, nisi quam tincidunt ex, ac auctor nisi metus vel tellus. Curabitur aliquam felis ut ex facilisis eleifend. Mauris dapibus consectetur eros, id venenatis risus pretium eget. Proin sit amet egestas odio. Vivamus interdum, enim nec egestas vulputate, purus dui convallis velit, eu elementum massa nibh at nulla. Morbi ullamcorper accumsan ipsum, id pulvinar purus ultrices vel. In vehicula ultrices diam sit amet dapibus. Integer arcu diam, luctus nec urna eu, iaculis tempor arcu. Sed sit amet pulvinar arcu, eget consequat ante. Curabitur nunc ante, venenatis at tellus eu, euismod vulputate lectus. Vivamus finibus arcu nulla.

Proin mollis ullamcorper nibh et viverra. Nullam iaculis leo et erat commodo pretium. Phasellus ut sapien vel dui mattis vulputate. Duis non volutpat elit. Nulla vitae mi metus. Donec euismod vulputate risus, ac maximus erat maximus quis. Nullam molestie eget orci ac accumsan. Proin tortor lectus, ultrices id tortor vel, mollis faucibus enim. Proin augue ante, mollis id libero eget, ultrices auctor augue. Nam lacinia dapibus dui, nec bibendum lacus pharetra sit amet.

Maecenas ut diam urna. Sed consectetur ipsum nec tempus facilisis. Proin gravida est lectus, vel sagittis lorem porta non. Maecenas id tempus ex. Integer ullamcorper, lacus sed interdum imperdiet, purus tellus dapibus ipsum, sed auctor dui dolor at lorem.

Sed non placerat erat. Nullam diam purus, cursus vitae sapien et, ultrices molestie eros. Aliquam eleifend sem libero, et facilisis tellus sagittis id. Aliquam faucibus, enim ut fermentum aliquam, arcu nunc mollis justo, in pulvinar ante nisl nec ex. Morbi vel eros non tellus tincidunt sagittis. Sed massa felis, finibus non placerat a, pharetra sit amet massa. Proin ornare magna vitae risus accumsan, vel sagittis nisl finibus. Sed sit amet finibus magna. Proin fringilla risus sit amet velit auctor, sit amet faucibus tellus scelerisque.''';

  static const LegalInfoPage contactUs = LegalInfoPage(
    titleKey: 'contactUs',
    body:
        'For any kind of queries related to products, orders or services feel free to contact us on our official email address or phone number as given below :',
    contactItems: [
      LegalContactItem(
        type: LegalContactType.phone,
        label: 'Call',
        value: AppSettings.supportPhone,
      ),
      LegalContactItem(
        type: LegalContactType.email,
        label: 'Email',
        value: AppSettings.supportEmail,
      ),
    ],
  );

  static const LegalInfoPage aboutUs = LegalInfoPage(
    titleKey: 'aboutUs',
    body: '''
Welcome to Tic Toc Toe

Made by Dhruv Patel
''',
  );

  static const LegalInfoPage termsAndConditions = LegalInfoPage(
    titleKey: 'termsAndConditions',
    body: _loremText,
  );

  static const LegalInfoPage privacyPolicy = LegalInfoPage(
    titleKey: 'privacyPolicy',
    body: _loremText,
  );
}
