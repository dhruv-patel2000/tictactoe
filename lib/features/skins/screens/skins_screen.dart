import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/core/services/interstitial_ad_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/skins/models/skin_model.dart';
import 'package:tic_tac_toe/features/skins/widgets/skin_tile.dart';

// Lists purchasable/equippable X-O skins, combining the catalog stream with
// the user's owned-skins stream to mark each skin purchased/active.
class SkinsScreen extends StatefulWidget {
  const SkinsScreen({super.key});
  static Route route(RouteSettings settings) {
    return GradientRouter(builder: (context) => const SkinsScreen());
  }

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialAdService.loadAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title:
            Text(context.tr('skins'), style: TextStyle(color: AppColors.white)),
        backgroundColor: context.color.surface,
      ),
      body: StreamBuilder<List<Skin>>(
        stream: DatabaseService.instance.streamAvailableSkins(),
        builder: (context, availableSnapshot) {
          if (availableSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator(color: context.color.secondary));
          }
          // Catalog list, falls back to bundled defaults if Firebase hasn't loaded yet.
          final availableSkins = availableSnapshot.data ?? AppSettings.skins;

          return StreamBuilder(
            stream: DatabaseService.instance.userSkins.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                  color: context.color.secondary,
                ));
              }
              // `onValue` is a persistent listener that only ever moves
              // waiting -> active (it never completes/errors in normal use),
              // so the `Container()` fallback below is effectively dead code
              // rather than a real error/done state to handle.
              if (snapshot.connectionState == ConnectionState.active) {
                // Build the skin-id -> owned-skin-snapshots lookup once per
                // stream update instead of rescanning the full snapshot for
                // every row inside itemBuilder.
                final Map<String, List<DataSnapshot>> userSkinsById = {};
                for (final element in snapshot.data?.snapshot.children ??
                    const <DataSnapshot>[]) {
                  final id = (element.value as dynamic)['id'];
                  // Legacy pre-redesign entries have no 'id' key; skip them
                  // like the old lookup implicitly did.
                  if (id is! String) continue;
                  userSkinsById.putIfAbsent(id, () => []).add(element);
                }

                return ListView.separated(
                  itemCount: availableSkins.length,
                  padding: EdgeInsets.all(context.sizes.md),
                  separatorBuilder: (context, index) => SizedBox(
                    height: context.sizes.md,
                  ),
                  itemBuilder: (context, index) {
                    final currentSkin = availableSkins[index];
                    final userSkins =
                        userSkinsById[currentSkin.id] ?? const <DataSnapshot>[];
                    bool isPurchased = userSkins.isNotEmpty;
                    bool isActive = userSkins.any(
                      (element) =>
                          (element.value as dynamic)['selectedStatus'] ==
                          'active',
                    );

                    return SkinTile(
                      skin: currentSkin,
                      isPurchased: isPurchased,
                      isActive: isActive,
                    );
                  },
                );
              }
              return Container();
            },
          );
        },
      ),
    );
  }
}
