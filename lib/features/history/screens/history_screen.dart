import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/color_extension.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/core/services/interstitial_ad_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/history/models/history_model.dart';
import 'package:tic_tac_toe/commons/models/user_model.dart';
import 'package:tic_tac_toe/features/settings/widgets/profile_card.dart';

/// Day-range options for the "Select days" filter.
enum HistoryDayFilter {
  all('all', null),
  week('last7Days', 7),
  month('last30Days', 30);

  final String labelKey; // i18n key used to resolve the display label
  final int? days; // cutoff window in days; null means no filtering (show all)
  const HistoryDayFilter(this.labelKey, this.days);

  String label(BuildContext context) => context.tr(labelKey);
}

// Shows the signed-in user's coin/purchase history, filterable by day range.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static Route route(RouteSettings settings) => GradientRouter(
        builder: (context) => const HistoryScreen(),
      );

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Currently applied day-range filter.
  HistoryDayFilter _selectedFilter = HistoryDayFilter.all;

  // Live coin/purchase history from Firestore; day filtering is applied client-side in _filter.
  final Stream<List<HistoryModel>> _historyStream =
      DatabaseService.instance.streamHistory();

  @override
  void initState() {
    super.initState();
    InterstitialAdService.loadAd();
  }

  // Applies the selected day-range filter client-side over the live stream.
  List<HistoryModel> _filter(List<HistoryModel> all) {
    final days = _selectedFilter.days;
    if (days == null || all.isEmpty) return all;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => e.dateTime.isAfter(cutoff)).toList();
  }

  //--------------------------------------------------
  // Widget builders
  //--------------------------------------------------
  Widget _buildSummary(BuildContext context, UserModel? user) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ProfileCard.buildInsight(context,
              (title: context.tr('played'), value: user?.matchPlayed ?? 0)),
        ),
        ProfileCard.buildVerticalDivider(context),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6.r(context),
            children: [
              CustomText(context.tr('duration'),
                  fontSize: context.font.small, textAlign: TextAlign.center),
              _buildDayDropdown(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayDropdown(BuildContext context) {
    return PopupMenuButton<HistoryDayFilter>(
      color: context.color.surfaceContainer,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      initialValue: _selectedFilter,
      onSelected: (filter) => setState(() => _selectedFilter = filter),
      itemBuilder: (context) => HistoryDayFilter.values
          .map((filter) => PopupMenuItem(
                value: filter,
                child: CustomText(filter.label(context),
                    fontSize: context.font.medium,
                    color: context.color.onSurface),
              ))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: CustomText(_selectedFilter.label(context),
                fontSize: context.font.large,
                fontWeight: FontWeight.w700,
                color: context.color.onSurface,
                maxLines: 1,
                ellipsis: true),
          ),
          Icon(Icons.keyboard_arrow_down, color: context.color.onSurface),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context, List<HistoryModel> history) {
    return Column(
      spacing: 16.r(context),
      children: [
        // Header sits in its own card, detached from the data — matches the UI.
        InnerShadowContainer(child: _buildHeaderRow(context)),
        // Data card fills the remaining height; the list scrolls within it.
        Expanded(
          child: InnerShadowContainer(
            child: history.isEmpty
                ? Center(
                    child: CustomText(context.tr('noHistoryFound'),
                        fontSize: context.font.normal),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: context.sizes.xs),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => Divider(
                        color: context.color.outline,
                        indent: 16.r(context),
                        endIndent: 16.r(context)),
                    itemBuilder: (context, index) =>
                        _buildHistoryRow(context, history[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    Widget cell(String title) {
      return Expanded(
        child: CustomText(title,
            fontSize: context.font.normal,
            fontWeight: FontWeight.w700,
            color: context.color.onSurface,
            textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.sizes.md, vertical: context.sizes.xs),
      child: Row(
        children: [
          cell(context.tr('transaction')),
          cell(context.tr('status')),
          cell(context.tr('dateTime')),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, HistoryModel item) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.sizes.md, vertical: 6.r(context)),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              '${item.amount}',
              fontSize: context.font.normal,
              fontWeight: FontWeight.w600,
              color: _amountColor(context, item),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: CustomText(item.status.label(context),
                fontSize: context.font.normal, textAlign: TextAlign.center),
          ),
          Expanded(
            child: CustomText(_formatDate(item.dateTime),
                fontSize: context.font.small, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // Negative amounts (spend) are tinted with the error color; positive (earn) use default text color.
  Color _amountColor(BuildContext context, HistoryModel item) {
    return item.amount < 0
        ? context.color.error.brighten(0.1)
        : context.color.onSurface;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)} ${_months[date.month - 1]} ${date.year}\n'
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: CustomText(context.tr('history'),
            fontSize: context.font.xL,
            fontWeight: FontWeight.w700,
            color: AppColors.white),
        backgroundColor: context.color.surfaceContainer,
        surfaceTintColor: context.color.surfaceContainer,
      ),
      body: Padding(
        padding: EdgeInsets.all(context.sizes.md),
        child: Column(
          spacing: 16.r(context),
          children: [
            ProfileCard(bottomBuilder: _buildSummary),
            Expanded(
              child: StreamBuilder<List<HistoryModel>>(
                stream: _historyStream,
                builder: (context, snapshot) {
                  final history =
                      _filter(snapshot.data ?? const <HistoryModel>[]);
                  return _buildHistoryTable(context, history);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
