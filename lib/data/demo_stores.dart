import 'package:flutter/widgets.dart';

import '../domain/common/form_draft.dart';
import '../domain/labels/label_target.dart';
import '../domain/sales/sale.dart';
import '../domain/sales/sale_item.dart';
import 'customer_repository.dart';
import 'enquiry_repository.dart';
import 'label_repository.dart';
import 'photo_uploader.dart';
import 'print_server.dart';
import 'product_repository.dart';
import 'rating_repository.dart';
import 'sales_repository.dart';
import 'second_hand_repository.dart';
import 'service_repository.dart';
import 'settings_repository.dart';
import 'task_repository.dart';

/// PRACTICE DATA FOR THE TOUR
///
/// While the app tour runs, every screen reads and writes these instead of
/// the shop's own records: a few made-up customers, repairs, phones, bills
/// and products, all held in the phone's memory. The tour types into the
/// forms and may press their buttons; whatever it does lands here and is
/// thrown away when the tour ends. Nothing reaches the shop's database, the
/// printer, the photo store or the saved drafts.
class DemoStores {
  DemoStores._({
    required this.settings,
    required this.secondHand,
    required this.customers,
    required this.service,
    required this.products,
    required this.enquiries,
    required this.tasks,
    required this.sales,
    required this.labels,
    required this.ratings,
  });

  factory DemoStores.create() {
    final settings = InMemorySettingsStore();
    final secondHand = InMemorySecondHandStore();
    final customers = InMemoryCustomerStore();
    final service = InMemoryServiceStore(settings: settings);
    final products = InMemoryProductStore();
    final now = DateTime.now();
    DateTime at(int h) => DateTime(now.year, now.month, now.day, h);
    Sale bill(
      String id,
      String no,
      String what,
      num price,
      String method, {
      num? paid,
      String name = '',
      String phone = '',
      int h = 11,
    }) => Sale(
      id: id,
      invoiceNumber: no,
      customerName: name,
      customerPhone: phone,
      items: [SaleItem(description: what, unitPrice: price)],
      paymentMethod: method,
      amountPaid: paid ?? price,
      status: SaleStatus.completed,
      completedAt: at(h),
    );
    final sales = InMemorySalesStore(
      stock: secondHand,
      products: products,
      customers: customers,
      seed: [
        bill(
          'demo-s1',
          'INV-001',
          'Samsung Galaxy A54 8/128',
          18500,
          'UPI',
          name: 'Ramesh K',
          phone: '9876543210',
          h: 11,
        ),
        bill('demo-s2', 'INV-002', 'Tempered glass', 250, 'Cash', h: 13),
        bill(
          'demo-s3',
          'INV-003',
          'Vivo Y21 4/64',
          9500,
          'Cash',
          paid: 6000,
          name: 'Anand M',
          phone: '9988776655',
          h: 15,
        ),
        Sale(
          id: 'demo-s4',
          customerName: 'Priya S',
          customerPhone: '9123456780',
          items: const [SaleItem(description: 'Back cover', unitPrice: 300)],
        ),
      ],
    );
    final labels = InMemoryLabelStore(
      targets: {
        LabelTargetKind.secondHand: LabelTargetBinding(
          snapshot: secondHand.labelSnapshot,
          attach: (id, number) => secondHand.attachLabel(id, number),
        ),
        LabelTargetKind.service: LabelTargetBinding(
          snapshot: service.labelSnapshot,
          attach: (_, _) async {},
        ),
        LabelTargetKind.sale: LabelTargetBinding(
          snapshot: sales.labelSnapshot,
          attach: (_, _) async {},
        ),
        LabelTargetKind.product: LabelTargetBinding(
          snapshot: products.labelSnapshot,
          attach: (id, number) => products.attachLabel(id, number),
        ),
      },
    );
    return DemoStores._(
      settings: settings,
      secondHand: secondHand,
      customers: customers,
      service: service,
      products: products,
      enquiries: InMemoryEnquiryStore(),
      tasks: InMemoryTaskStore(),
      sales: sales,
      labels: labels,
      ratings: InMemoryRatingStore(),
    );
  }

  final InMemorySettingsStore settings;
  final InMemorySecondHandStore secondHand;
  final InMemoryCustomerStore customers;
  final InMemoryServiceStore service;
  final InMemoryProductStore products;
  final InMemoryEnquiryStore enquiries;
  final InMemoryTaskStore tasks;
  final InMemorySalesStore sales;
  final InMemoryLabelStore labels;
  final InMemoryRatingStore ratings;

  /// Drafts stay in memory: a half-typed tour form must not come back in
  /// the real form tomorrow.
  final DraftStore drafts = InMemoryDraftStore();

  /// Labels "print" nowhere.
  final PrintServer printer = RecordingPrintServer();

  /// No photos are taken or uploaded in a tour.
  final PhotoUploader photos = const _NoPhotos();

  void dispose() {
    for (final store in <ChangeNotifier>[
      settings,
      secondHand,
      customers,
      service,
      products,
      enquiries,
      tasks,
      sales,
      labels,
      ratings,
    ]) {
      store.dispose();
    }
  }
}

class _NoPhotos implements PhotoUploader {
  const _NoPhotos();

  @override
  bool get isConfigured => false;

  @override
  Future<String?> pickAndUpload({required bool camera}) async => null;
}

/// Whether the app is showing practice data for a tour. main.dart gives the
/// screens [demo]'s stores while it is on, the shop's own when it is off.
class TourSandbox extends ChangeNotifier {
  DemoStores? _demo;

  DemoStores? get demo => _demo;
  bool get active => _demo != null;

  /// Fresh practice data, so every tour starts from the same records.
  void enter() {
    if (_demo != null) return;
    _demo = DemoStores.create();
    notifyListeners();
  }

  /// Back to the shop's own records. The practice data is thrown away once
  /// no screen is using it any more.
  void exit() {
    final old = _demo;
    if (old == null) return;
    _demo = null;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }
}
