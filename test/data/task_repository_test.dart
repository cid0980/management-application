import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/task_repository.dart';
import 'package:fm_shop/domain/tasks/task.dart';

const _admin = TaskActor(uid: 'owner', isAdmin: true);
const _mani = TaskActor(uid: 'mani', isAdmin: false);
final _today = DateTime(2026, 11, 11, 10);

ShopTask _t(String id, {String assignedTo = 'mani'}) =>
    ShopTask(id: id, title: 'Wipe the cabinet', assignedTo: assignedTo);

void main() {
  group('the repository applies the rule to the write, not just the screen',
      () {
    test('staff cannot tick somebody else\'s task', () async {
      final store = InMemoryTaskStore(seed: [_t('a', assignedTo: 'suresh')]);
      addTearDown(store.dispose);
      final result = await store.tick('a', _mani, day: _today);
      expect(result.block, TaskBlock.notYours);
      expect(store.byId('a')!.completedDays, isEmpty);
    });

    test('staff cannot add, edit or delete a task', () async {
      final store = InMemoryTaskStore(seed: [_t('a')]);
      addTearDown(store.dispose);
      expect((await store.save(_t('b'), _mani)).block, TaskBlock.adminOnly);
      expect((await store.delete('a', _mani)).block, TaskBlock.adminOnly);
      expect(store.tasks.map((t) => t.id), ['a']);
    });

    test('a task with no title is refused and nothing is stored', () async {
      final store = InMemoryTaskStore(seed: const []);
      addTearDown(store.dispose);
      final result =
          await store.save(const ShopTask(id: 'a', title: ' '), _admin);
      expect(result.block, TaskBlock.noTitle);
      expect(store.tasks, isEmpty);
    });
  });

  group('ticking', () {
    test('marks today done, and ticking twice is one tick', () async {
      final store = InMemoryTaskStore(seed: [_t('a')]);
      addTearDown(store.dispose);
      await store.tick('a', _mani, day: _today);
      await store.tick('a', _mani, day: _today);
      expect(store.byId('a')!.completedDays, ['2026-11-11']);
      expect(store.byId('a')!.lastCompletedBy, 'mani');
    });

    test('undo takes today back off and leaves yesterday alone', () async {
      final store = InMemoryTaskStore(seed: [
        _t('a').copyWith(completedDays: ['2026-11-10', '2026-11-11']),
      ]);
      addTearDown(store.dispose);
      await store.untick('a', _mani, day: _today);
      expect(store.byId('a')!.completedDays, ['2026-11-10']);
    });

    test('tomorrow a daily task is to do again, with nothing run overnight',
        () async {
      final store = InMemoryTaskStore(seed: [_t('a')]);
      addTearDown(store.dispose);
      await store.tick('a', _mani, day: _today);
      final tomorrow = _today.add(const Duration(days: 1));
      expect(store.byId('a')!.isDoneOn(tomorrow), isFalse);
    });
  });

  group('editing', () {
    test('changing the wording keeps the ticks already made', () async {
      final store = InMemoryTaskStore(seed: [_t('a')]);
      addTearDown(store.dispose);
      await store.tick('a', _mani, day: _today);
      await store.save(_t('a').copyWith(title: 'Wipe both cabinets'), _admin);
      final task = store.byId('a')!;
      expect(task.title, 'Wipe both cabinets');
      expect(task.isDoneOn(_today), isTrue);
    });

    test('the owner deletes a task', () async {
      final store = InMemoryTaskStore(seed: [_t('a')]);
      addTearDown(store.dispose);
      expect((await store.delete('a', _admin)).ok, isTrue);
      expect(store.tasks, isEmpty);
    });
  });
}
