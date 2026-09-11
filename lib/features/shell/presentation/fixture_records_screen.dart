/// A record collection, drawn in the real master-detail shell.
///
/// Twenty records is enough to scroll a compact list past a screen, which is
/// what makes "the list kept its position" a claim a test can fail.
library;

import 'package:flutter/material.dart';

import '../../../core/layout/lume_measure.dart';
import '../../../core/navigation/lume_master_detail.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';

/// One fixture record.
@immutable
class FixtureRecord {
  const FixtureRecord(this.id, this.title, this.value);

  final String id;
  final String title;
  final String value;
}

/// The collection every fixture tool shares.
List<FixtureRecord> fixtureRecords(String label) => <FixtureRecord>[
  for (int i = 1; i <= 20; i++) FixtureRecord('$i', '$label $i', '$i'),
];

/// A collection screen, and the detail for whichever record is selected.
class FixtureRecordsScreen extends StatelessWidget {
  const FixtureRecordsScreen({
    super.key,
    required this.toolId,
    this.initialRecordId,
    this.onBack,
  });

  final String toolId;

  /// A record named by the route. Carried into the shell as its opening
  /// selection, and not touched again — after that the selection is state.
  final String? initialRecordId;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<FixtureRecord> records = fixtureRecords(l.commonHistory);

    return LumeMasterDetailShell(
      initialSelectedId: initialRecordId,
      emptyDetail: LumeCollectionState(
        kind: LumeCollectionStateKind.pane,
        title: l.recordsNoSelectionTitle,
        text: l.recordsNoSelectionText,
      ),
      listBuilder:
          (
            BuildContext context,
            String? selectedId,
            ValueChanged<String?> select,
          ) {
            return CustomScrollView(
              key: const PageStorageKey<String>('fixture-records'),
              primary: false,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: LumeMeasure(
                    gutters: false,
                    child: LumeToolbar(
                      title: l.commonHistory,
                      subtitle: toolId,
                      onBack: onBack,
                      backLabel: l.actionBack,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LumeMeasure(
                    child: Column(
                      children: <Widget>[
                        for (final FixtureRecord r in records)
                          LumeRecordRow(
                            title: r.title,
                            value: r.value,
                            selected: r.id == selectedId,
                            onTap: () => select(r.id),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ),
              ],
            );
          },
      detailBuilder: (BuildContext context, String id) {
        final FixtureRecord record = records.firstWhere(
          (FixtureRecord r) => r.id == id,
          orElse: () => FixtureRecord(id, l.commonHistory, id),
        );
        return _RecordDetail(record: record);
      },
    );
  }
}

class _RecordDetail extends StatelessWidget {
  const _RecordDetail({required this.record});

  final FixtureRecord record;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: LumeMeasure(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: LumeSpace.gapCard),
                LumeRecordHero(title: record.title, value: record.value),
                const SizedBox(height: LumeSpace.gapCard),
                LumeCard(
                  child: Column(
                    children: <Widget>[
                      LumeCompactRow(
                        label: l.commonStatus,
                        value: record.value,
                        chevron: false,
                      ),
                      LumeCompactRow(
                        label: l.commonToday,
                        value: record.id,
                        chevron: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }
}
