// Central registry of asset paths (svg/png) used throughout the app's UI.
abstract class AppIcons {
  static final String mazeIcon = _getPng('maze_icon');
  static final String appLogo = _getPng('app_logo');
  static final String doraIcon = _getSvg('dora');
  static final String google = _getSvg('google');
  static final String apple = _getSvg('apple');
  static final String emailLogin = _getSvg('email_login');
  static final String guestLogin = _getSvg('guest_login');
  static final String coin = _getPng('coin');
  static final String dora1 = _getSvg('dora_1');
  static final String dora2 = _getSvg('dora_2');
  static final String dora3 = _getSvg('dora_3');
  static final String dora4 = _getSvg('dora_4');
  static final String versus = _getSvg('versus');
  static final String clock = _getSvg('clock');
  static final String incrementCoin = _getSvg('increment_coin');
  static final String leaderBoardIcon = _getSvg('leaderboard_icon');
  static final String speaker = _getSvg('volume_up');
  static final String guest = _getPng('guest');
  static final String next = _getSvg('next');
  static final String contactUs = _getSvg('contact_us');
  static final String deleteAccount = _getSvg('delete_account');
  static final String deleteAccountIllustration = _getSvg('deleteAccount');
  static final String logoutAccountIllustration = _getSvg('logoutAccount');
  static final String aboutUs = _getSvg('about_us');
  static final String privacyPolicy = _getSvg('privacy_policy');
  static final String termsAndConditions = _getSvg('terms_and_conditions');
  static final String rateUs = _getSvg('rate_us');
  static final String skin = _getSvg('skin');
  static final String history = _getSvg('history');
  static final String shop = _getSvg('shop');
  static final String shareApp = _getSvg('share_app');
  static final String language = _getSvg('language');
  static final String moreGame = _getSvg('more_game');
  static final String howToPlay = _getSvg('how_to_play');
  static final String starGroup = _getPng('star_group');
  static final String coinStackSmall = _getPng('coin_stack_small');
  static final String coinStackMedium = _getPng('coin_stack_medium');
  static final String coinStackLarge = _getPng('coin_stack_large');
  static final String coinBagSmall = _getPng('coin_bag_small');
  static final String coinBagLarge = _getPng('coin_bag_large');
  static final String ads = _getPng('ads');
  static final String rank1 = _getSvg('rank1');
  static final String rank2 = _getSvg('rank2');
  static final String rank3 = _getSvg('rank3');

  static String _getSvg(String name) {
    return 'assets/svg/$name.svg';
  }

  static String _getPng(String name) {
    return 'assets/png/$name.png';
  }
}
