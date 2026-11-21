/// THE ENQUIRIES LIST'S OWN RULES
///
/// Five tabs. The first two are why anybody opens the page: what needs ringing
/// back today, and what should have been rung back already.
///
/// **Follow-up soonest first**, because the list is a call list. An enquiry
/// with no follow-up date sorts last — it is not urgent, it is just not
/// scheduled, and `validateEnquiry` warns about it at the time rather than
/// letting the list imply it matters.
library;

import 'enquiry.dart';

enum EnquiryTab { open, dueToday, overdue, won, all }

const Map<EnquiryTab, String> kEnquiryTabLabels = {
  EnquiryTab.open: 'Open',
  EnquiryTab.dueToday: 'Due today',
  EnquiryTab.overdue: 'Overdue',
  EnquiryTab.won: 'Won',
  EnquiryTab.all: 'All',
};

bool inEnquiryTab(Enquiry enquiry, EnquiryTab tab, {required DateTime now}) =>
    switch (tab) {
      EnquiryTab.all => true,
      EnquiryTab.open => !enquiry.closed,
      EnquiryTab.dueToday => enquiry.isDueTodayAt(now),
      EnquiryTab.overdue => enquiry.isOverdueAt(now),
      EnquiryTab.won => enquiry.won,
    };

/// The rows for a tab and a search box.
List<Enquiry> enquiryRows(
  Iterable<Enquiry> all, {
  EnquiryTab tab = EnquiryTab.open,
  String? query,
  required DateTime now,
}) {
  final rows = [
    for (final e in all)
      if (inEnquiryTab(e, tab, now: now) && e.matches(query)) e,
  ];

  final history = tab == EnquiryTab.won;
  rows.sort((a, b) {
    if (history) {
      // Won is a record of what the shop got, so it reads newest first.
      return _compare(
        b.closedAt ?? b.updatedAt ?? b.askedAt,
        a.closedAt ?? a.updatedAt ?? a.askedAt,
        a.headline,
        b.headline,
      );
    }
    return _compare(a.followUpAt, b.followUpAt, a.headline, b.headline);
  });
  return rows;
}

/// Nulls last whichever way round the comparison is, so an unscheduled
/// enquiry never jumps to the top of a call list.
int _compare(DateTime? x, DateTime? y, String xTitle, String yTitle) {
  if (x == null && y == null) return xTitle.compareTo(yTitle);
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

/// How many rows each tab holds for the current search.
Map<EnquiryTab, int> enquiryTabCounts(
  Iterable<Enquiry> all, {
  String? query,
  required DateTime now,
}) {
  final counts = {for (final t in EnquiryTab.values) t: 0};
  for (final e in all) {
    if (!e.matches(query)) continue;
    for (final t in EnquiryTab.values) {
      if (inEnquiryTab(e, t, now: now)) counts[t] = counts[t]! + 1;
    }
  }
  return counts;
}

/// What the dashboard's Open Enquiries tile counts.
int openEnquiryCount(Iterable<Enquiry> all) =>
    all.where((e) => !e.closed).length;

/// What needs ringing today, worst first.
List<Enquiry> enquiryCallList(Iterable<Enquiry> all, {required DateTime now}) =>
    [
      ...enquiryRows(all, tab: EnquiryTab.overdue, now: now),
      ...enquiryRows(all, tab: EnquiryTab.dueToday, now: now),
    ];

/// How many enquiries turned into business.
///
/// Over the CLOSED ones only. Counting won against every enquiry including the
/// ones still open understates it while the shop is still working on them, and
/// a number that moves because somebody wrote a new enquiry down is a number
/// that discourages writing them down.
class EnquiryConversion {
  const EnquiryConversion({
    required this.won,
    required this.lost,
    required this.closed,
    required this.open,
  });

  final int won;
  final int lost;
  final int closed;
  final int open;

  /// Null when nothing has been closed yet — not zero, which would read as
  /// "the shop wins nothing".
  double? get rate => closed == 0 ? null : won / closed;
}

EnquiryConversion enquiryConversion(Iterable<Enquiry> all) {
  var won = 0;
  var lost = 0;
  var closed = 0;
  var open = 0;
  for (final e in all) {
    if (e.closed) {
      closed++;
      if (e.won) won++;
      if (e.status == 'Lost') lost++;
    } else {
      open++;
    }
  }
  return EnquiryConversion(won: won, lost: lost, closed: closed, open: open);
}
