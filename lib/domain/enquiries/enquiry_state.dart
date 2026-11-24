/// WHAT STATE AN ENQUIRY IS IN
///
/// A walk-in asks whether the shop has an A54 in second hand, or what a
/// display costs. Worth writing down, because the shop can ring them when one
/// comes in — and worth closing, because an enquiry list nobody closes is a
/// list nobody reads.
///
/// The statuses are the shop's answer to "what came of it":
///
///   Open                 asked, nothing done yet
///   Waiting For Stock    the answer is "when one comes in"
///   Quoted               a price was given
///   Won                  it turned into a sale or a repair
///   Lost                 they went elsewhere, or changed their mind
///   Closed               dealt with, and none of the above
///
/// **Won needs something to point at.** An enquiry marked won with nothing to
/// point at is how a conversion rate gets inflated — so closing one as Won
/// asks which sale or service order it became, and says so if it cannot.
///
/// The derived state is the same three answers as a service order, for the
/// same reason: the list has to say at a glance what needs doing. And **closed
/// beats overdue** here too — an enquiry dealt with last month is not an alarm
/// because its follow-up date has passed.
library;

import '../common/dates.dart';

const List<String> kEnquiryStatuses = [
  'Open',
  'Waiting For Stock',
  'Quoted',
  'Won',
  'Lost',
  'Closed',
];

/// Dealt with, one way or another. Nothing more is owed on it.
bool isEnquiryClosed(String? status) =>
    status == 'Won' || status == 'Lost' || status == 'Closed';

/// The statuses that mean the shop got the business, for counting.
bool isEnquiryWon(String? status) => status == 'Won';

/// The slice of an enquiry the state rules need.
class EnquiryStateView {
  const EnquiryStateView({this.status, this.followUpAt});

  final String? status;
  final Object? followUpAt;

  DateTime? get followUp => normalizeDate(followUpAt);
}

bool isEnquiryOverdue(EnquiryStateView enquiry, {DateTime? now}) {
  if (isEnquiryClosed(enquiry.status)) return false;
  final due = enquiry.followUp;
  return due != null && due.isBefore(now ?? DateTime.now());
}

bool isEnquiryDueToday(EnquiryStateView enquiry, {DateTime? now}) {
  if (isEnquiryClosed(enquiry.status)) return false;
  final due = enquiry.followUp;
  if (due == null) return false;
  final n = now ?? DateTime.now();
  final start = DateTime(n.year, n.month, n.day);
  final end = DateTime(n.year, n.month, n.day + 1);
  return !due.isBefore(start) && due.isBefore(end);
}

enum EnquiryLifecycle { overdue, open, closed }

EnquiryLifecycle enquiryStateOf(EnquiryStateView enquiry, {DateTime? now}) {
  if (isEnquiryClosed(enquiry.status)) return EnquiryLifecycle.closed;
  return isEnquiryOverdue(enquiry, now: now)
      ? EnquiryLifecycle.overdue
      : EnquiryLifecycle.open;
}

const Map<EnquiryLifecycle, String> kEnquiryStateLabels = {
  EnquiryLifecycle.overdue: 'Follow-up overdue',
  EnquiryLifecycle.open: 'Open',
  EnquiryLifecycle.closed: 'Dealt with',
};

/// What somebody may move an enquiry to.
///
/// Everything, from anywhere — unlike a service order, an enquiry has no
/// workflow to protect. Somebody who quoted a price and then heard the
/// customer went elsewhere moves it straight from Open to Lost, and reopening
/// a Lost enquiry because they came back is an ordinary Tuesday.
///
/// An enquiry carrying a status this build has never seen still shows it.
List<String> enquiryStatusOptions(String? current) {
  if (current == null ||
      current.isEmpty ||
      kEnquiryStatuses.contains(current)) {
    return kEnquiryStatuses;
  }
  return [current, ...kEnquiryStatuses];
}

/// Why an enquiry cannot be closed as Won.
enum WonBlock {
  /// Nothing to point at. A conversion with no sale or repair behind it is a
  /// number that flatters the shop and means nothing.
  noOutcome,
}

const Map<WonBlock, String> kWonBlockMessages = {
  WonBlock.noOutcome:
      'Say which sale or repair this became — a won enquiry with nothing to '
      'point at cannot be counted',
};

/// Whether this enquiry may be marked Won.
///
/// [outcomeRef] is the sale or service order it became. Anything non-empty
/// counts: the reference is for a human to follow, and refusing a note that
/// says "sold over the counter, no bill" would just stop the enquiry being
/// closed at all.
///
/// At least three characters: "x" points at nothing anyone can follow
/// (FM #45), while a job or bill number, or "sold, no bill", does.
WonBlock? wonBlockFor(String? outcomeRef) =>
    (outcomeRef ?? '').trim().length < 3 ? WonBlock.noOutcome : null;
