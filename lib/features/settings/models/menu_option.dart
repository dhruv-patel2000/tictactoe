// Model: a single tappable card entry shown in a menu/grid (title, icon,
// tap handler).
class MenuCardModel {
  final String title;
  final String icon;
  final Function() onTap;

  const MenuCardModel({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
