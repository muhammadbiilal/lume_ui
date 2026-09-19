/// Shopping List — `tools/personal/shopping.tool.js` under `crud-engine.js`.
///
/// The reader's items lead — search, To buy and In basket chips, the
/// records ticked from their rows, and the bulk clear of what is in the
/// basket — and the tool's own composition follows: what is still to get
/// with the estimate and a ring of what is ticked, the items by aisle, and
/// Share the list and Clear checked.
///
/// The reference draws that composition from six fixture items that are not
/// the records, ticks that write nowhere the records can see, and two
/// buttons that only say "Sharing your list" and "Checked items cleared".
/// Here the composition reads the records with the reference's formulas;
/// Share makes a card of what is still to get, and Clear checked is the
/// same confirmed bulk clear the list offers (C86).
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_share.dart'
    show LumeShareCard, LumeShareKind;
import '../../../core/widgets/lume/lume_agenda.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/presentation/record_family.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../domain/shopping_family.dart';

abstract final class LumeShoppingTool {
  static const String id = 'shopping';
  static const LumeRecordKeys keys = LumeRecordKeys(id);

  static const Key summaryKey = ValueKey<String>('shopping.summary');
  static const Key actionsKey = ValueKey<String>('shopping.actions');
  static const Key shareKey = ValueKey<String>('shopping.share');
  static const Key clearKey = ValueKey<String>('shopping.clear');

  static Key groupKey(LumeShopAisle? a) =>
      ValueKey<String>('shopping.group.${a?.name ?? 'none'}');
  static Key itemKey(String id) => ValueKey<String>('shopping.item.$id');

  static Widget open(LumeToolRequest request) => LumeRecordTool<LumeShopItem>(
    request: request,
    family: const LumeShoppingFamily(),
    compose: _compose,
    shareCard: shareCard,
  );

  /// What is still to get, as a card — or none when nothing is left, or
  /// when the list is too long for a card to hold honestly.
  static LumeShareCard? shareCard(LumeRecordScope<LumeShopItem> s) {
    final List<String> left = <String>[
      for (final LumeShopItem x in s.items)
        if (!x.done) x.qty.isEmpty ? x.label : '${x.label} (${x.qty})',
    ];
    if (left.isEmpty) return null;
    return LumeShareCard.tryCreate(
      kind: LumeShareKind.reminder,
      text: left.join(' · '),
      source: s.c.l.shoppingShareSource(s.c.f.dateShort(s.c.now)),
    );
  }

  static List<Widget> _compose(
    BuildContext context,
    LumeRecordScope<LumeShopItem> s,
  ) {
    final LumeRecordContext c = s.c;
    final AppLocalizations l = c.l;
    const LumeShoppingFamily family = LumeShoppingFamily();
    final LumeShoppingBoard board = LumeShoppingBoard(s.items);
    final String q = s.query.trim().toLowerCase();
    final List<(LumeShopAisle?, List<LumeShopItem>)> groups = board.groups(
      (LumeShopItem x) => q.isEmpty || x.label.toLowerCase().contains(q),
    );

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: summaryKey,
          kicker: l.shoppingList,
          value: c.f.integer(board.remaining),
          valueSmall: '/ ${c.f.integer(board.items.length)}',
          caption: l.shoppingEstimated(c.f.money(board.estimate)),
          aside: LumeProgressRing(
            value: board.share,
            centreValue:
                '${c.f.integer(board.checked)}/${c.f.integer(board.items.length)}',
            label: l.shoppingProgress,
          ),
        ),
      ),
      for (final (LumeShopAisle? aisle, List<LumeShopItem> items) in groups)
        LumeToolSection(
          title: aisle?.label(l) ?? '—',
          child: LumeRows(
            key: groupKey(aisle),
            children: <Widget>[
              for (final LumeShopItem x in items)
                LumeCheckRow(
                  key: itemKey(x.id),
                  label: x.label,
                  meta: x.qty.isEmpty ? null : x.qty,
                  value: family.price(x, c),
                  done: x.done,
                  onToggle: () => s.toggle(x),
                ),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButtonRow(
          key: actionsKey,
          children: <Widget>[
            LumeButton(
              key: shareKey,
              label: l.shoppingShare,
              icon: LumeIcons.share,
              onPressed: board.remaining == 0 ? null : s.share,
            ),
            LumeButton(
              key: clearKey,
              label: l.shoppingClear,
              icon: LumeIcons.refresh,
              onPressed: board.checked == 0 ? null : s.bulk,
            ),
          ],
        ),
      ),
    ];
  }
}
