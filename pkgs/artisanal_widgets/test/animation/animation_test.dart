import 'package:artisanal_widgets/artisanal_widgets.dart';import 'package:test/test.dart';

void main() {
  group('AnimationStatus', () {
    test('all four statuses exist', () {
      expect(AnimationStatus.values, hasLength(4));
      expect(AnimationStatus.values, contains(AnimationStatus.dismissed));
      expect(AnimationStatus.values, contains(AnimationStatus.forward));
      expect(AnimationStatus.values, contains(AnimationStatus.reverse));
      expect(AnimationStatus.values, contains(AnimationStatus.completed));
    });
  });

  group('AlwaysStoppedAnimation', () {
    test('has the value it was constructed with', () {
      const anim = AlwaysStoppedAnimation<double>(0.5);
      expect(anim.value, 0.5);
    });

    test('status is always dismissed', () {
      const anim = AlwaysStoppedAnimation<double>(1.0);
      expect(anim.status, AnimationStatus.dismissed);
      expect(anim.isDismissed, isTrue);
      expect(anim.isCompleted, isFalse);
      expect(anim.isAnimating, isFalse);
    });

    test('value is immutable regardless of type', () {
      const intAnim = AlwaysStoppedAnimation<int>(42);
      expect(intAnim.value, 42);

      const stringAnim = AlwaysStoppedAnimation<String>('hello');
      expect(stringAnim.value, 'hello');
    });

    test('addListener and removeListener are no-ops', () {
      const anim = AlwaysStoppedAnimation<double>(0.0);
      // These should not throw.
      void listener() {}
      anim.addListener(listener);
      anim.removeListener(listener);
    });

    test('addStatusListener and removeStatusListener are no-ops', () {
      const anim = AlwaysStoppedAnimation<double>(0.0);
      void statusListener(AnimationStatus status) {}
      anim.addStatusListener(statusListener);
      anim.removeStatusListener(statusListener);
    });

    test('toString includes the value', () {
      const anim = AlwaysStoppedAnimation<double>(0.75);
      expect(anim.toString(), contains('0.75'));
      expect(anim.toString(), contains('AlwaysStoppedAnimation'));
    });

    test('isDismissed isCompleted isAnimating helpers', () {
      const anim = AlwaysStoppedAnimation<double>(0.0);
      expect(anim.isDismissed, isTrue);
      expect(anim.isCompleted, isFalse);
      expect(anim.isAnimating, isFalse);
    });

    test('const constructor allows compile-time constants', () {
      // Verify that const construction works.
      const a = AlwaysStoppedAnimation<double>(1.0);
      const b = AlwaysStoppedAnimation<double>(1.0);
      expect(identical(a, b), isTrue);
    });

    test('with zero value', () {
      const anim = AlwaysStoppedAnimation<double>(0.0);
      expect(anim.value, 0.0);
    });

    test('with negative value', () {
      const anim = AlwaysStoppedAnimation<double>(-5.0);
      expect(anim.value, -5.0);
    });
  });

  group('ProxyAnimation', () {
    test('defaults to AlwaysStoppedAnimation(0.0) when no parent', () {
      final proxy = ProxyAnimation();
      expect(proxy.value, 0.0);
      expect(proxy.status, AnimationStatus.dismissed);
    });

    test('delegates value to parent', () {
      const parent = AlwaysStoppedAnimation<double>(0.75);
      final proxy = ProxyAnimation(parent);
      expect(proxy.value, 0.75);
    });

    test('delegates status to parent', () {
      const parent = AlwaysStoppedAnimation<double>(0.5);
      final proxy = ProxyAnimation(parent);
      expect(proxy.status, AnimationStatus.dismissed);
    });

    test('swapping parent updates value', () {
      const parentA = AlwaysStoppedAnimation<double>(0.25);
      const parentB = AlwaysStoppedAnimation<double>(0.75);

      final proxy = ProxyAnimation(parentA);
      expect(proxy.value, 0.25);

      proxy.parent = parentB;
      expect(proxy.value, 0.75);
    });

    test('setting same parent is a no-op', () {
      const parent = AlwaysStoppedAnimation<double>(0.5);
      final proxy = ProxyAnimation(parent);

      // Should not throw or do anything.
      proxy.parent = parent;
      expect(proxy.value, 0.5);
    });

    test('listeners are transferred when parent changes', () {
      final controllerA = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final controllerB = AnimationController(
        duration: const Duration(milliseconds: 300),
      );

      final proxy = ProxyAnimation(controllerA);
      var notifyCount = 0;
      proxy.addListener(() => notifyCount++);

      // Notify through A
      controllerA.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controllerA.processTick(start);
      controllerA.processTick(start.add(const Duration(milliseconds: 150)));
      final countFromA = notifyCount;
      expect(countFromA, greaterThan(0));

      // Swap to B
      proxy.parent = controllerB;

      // Notifications from A should no longer reach proxy
      final countBeforeANotify = notifyCount;
      controllerA.processTick(start.add(const Duration(milliseconds: 200)));
      expect(notifyCount, countBeforeANotify);

      // Notifications from B should reach proxy
      controllerB.forward();
      final startB = DateTime(2024, 1, 1, 0, 0, 1, 0);
      controllerB.processTick(startB);
      controllerB.processTick(startB.add(const Duration(milliseconds: 150)));
      expect(notifyCount, greaterThan(countBeforeANotify));

      controllerA.dispose();
      controllerB.dispose();
    });

    test('status listeners are transferred when parent changes', () {
      final controllerA = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final controllerB = AnimationController(
        duration: const Duration(milliseconds: 300),
      );

      final proxy = ProxyAnimation(controllerA);
      final statuses = <AnimationStatus>[];
      proxy.addStatusListener(statuses.add);

      // Status change through A
      controllerA.forward();
      expect(statuses, contains(AnimationStatus.forward));

      // Swap to B
      statuses.clear();
      proxy.parent = controllerB;

      // Status changes on A should not reach proxy anymore
      controllerA.stop();
      expect(statuses, isEmpty);

      // Status changes on B should reach proxy
      controllerB.forward();
      expect(statuses, contains(AnimationStatus.forward));

      controllerA.dispose();
      controllerB.dispose();
    });

    test('addListener registers on current parent', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final proxy = ProxyAnimation(controller);

      var notified = false;
      proxy.addListener(() => notified = true);

      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 500)));

      expect(notified, isTrue);
      controller.dispose();
    });

    test('removeListener unregisters from current parent', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final proxy = ProxyAnimation(controller);

      var callCount = 0;
      void listener() => callCount++;

      proxy.addListener(listener);
      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 200)));
      final countBefore = callCount;
      expect(countBefore, greaterThan(0));

      proxy.removeListener(listener);
      controller.processTick(start.add(const Duration(milliseconds: 400)));
      expect(callCount, countBefore);

      controller.dispose();
    });

    test('addStatusListener registers on current parent', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final proxy = ProxyAnimation(controller);

      AnimationStatus? reported;
      proxy.addStatusListener((s) => reported = s);

      controller.forward();
      expect(reported, AnimationStatus.forward);
      controller.dispose();
    });

    test('removeStatusListener unregisters from current parent', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final proxy = ProxyAnimation(controller);

      var callCount = 0;
      void listener(AnimationStatus s) => callCount++;

      proxy.addStatusListener(listener);
      controller.forward();
      expect(callCount, 1);

      proxy.removeStatusListener(listener);
      controller.stop();
      // Should not have been called again.
      expect(callCount, 1);
      controller.dispose();
    });

    test('toString includes parent info', () {
      const parent = AlwaysStoppedAnimation<double>(0.5);
      final proxy = ProxyAnimation(parent);
      expect(proxy.toString(), contains('ProxyAnimation'));
    });

    test('parent getter returns the current parent', () {
      const parentA = AlwaysStoppedAnimation<double>(0.1);
      const parentB = AlwaysStoppedAnimation<double>(0.9);

      final proxy = ProxyAnimation(parentA);
      expect(proxy.parent, same(parentA));

      proxy.parent = parentB;
      expect(proxy.parent, same(parentB));
    });

    test('isDismissed reflects parent status', () {
      const parent = AlwaysStoppedAnimation<double>(0.0);
      final proxy = ProxyAnimation(parent);
      expect(proxy.isDismissed, isTrue);
    });

    test('isAnimating reflects parent status', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final proxy = ProxyAnimation(controller);

      expect(proxy.isAnimating, isFalse);
      controller.forward();
      expect(proxy.isAnimating, isTrue);

      controller.dispose();
    });
  });

  group('Animation.drive', () {
    test('chains with a Tween to create derived animation', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );

      final derived = controller.drive(Tween<double>(begin: 0.0, end: 200.0));

      expect(derived.value, 100.0);
      controller.dispose();
    });

    test('chains with CurveTween', () {
      final controller = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 300),
      );

      final curved = controller.drive(CurveTween(curve: Curves.linear));
      expect(curved.value, 0.0);

      controller.dispose();
    });

    test('chains with CurveTween then Tween', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );

      // First apply curve, then scale
      final curved = controller.drive(CurveTween(curve: Curves.linear));
      final scaled = curved.drive(Tween<double>(begin: 0.0, end: 100.0));

      expect(scaled.value, closeTo(50.0, 1e-6));
      controller.dispose();
    });

    test('derived animation status reflects parent', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final derived = controller.drive(Tween<double>(begin: 10.0, end: 20.0));

      expect(derived.status, AnimationStatus.dismissed);

      controller.forward();
      expect(derived.status, AnimationStatus.forward);

      controller.dispose();
    });

    test('derived animation listeners receive updates from parent', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 100.0));

      var notified = false;
      derived.addListener(() => notified = true);

      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 500)));

      expect(notified, isTrue);
      controller.dispose();
    });

    test('removeListener on derived stops notifications', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 100.0));

      var callCount = 0;
      void listener() => callCount++;

      derived.addListener(listener);
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 200)));
      final countBefore = callCount;
      expect(countBefore, greaterThan(0));

      derived.removeListener(listener);
      controller.processTick(start.add(const Duration(milliseconds: 400)));
      expect(callCount, countBefore);

      controller.dispose();
    });

    test('derived status listeners receive updates', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 100.0));

      final statuses = <AnimationStatus>[];
      derived.addStatusListener(statuses.add);

      controller.forward();
      expect(statuses, contains(AnimationStatus.forward));

      controller.dispose();
    });

    test('removeStatusListener on derived stops notifications', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 100.0));

      var callCount = 0;
      void listener(AnimationStatus s) => callCount++;

      derived.addStatusListener(listener);
      controller.forward();
      expect(callCount, 1);

      derived.removeStatusListener(listener);
      controller.stop();
      expect(callCount, 1);

      controller.dispose();
    });
  });

  group('Animatable.animate', () {
    test('creates a derived animation that evaluates the animatable', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      const parent = AlwaysStoppedAnimation<double>(0.5);
      final derived = tween.animate(parent);

      expect(derived.value, 50.0);
    });

    test('derived animation reflects parent status', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      const parent = AlwaysStoppedAnimation<double>(0.0);
      final derived = tween.animate(parent);

      expect(derived.status, AnimationStatus.dismissed);
    });

    test('derived animation value updates with parent', () {
      final tween = Tween<double>(begin: 0.0, end: 200.0);
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final derived = tween.animate(controller);

      expect(derived.value, 0.0);

      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);

      expect(derived.value, closeTo(100.0, 10.0));

      controller.dispose();
    });

    test('toString includes parent and evaluatable info', () {
      final tween = Tween<double>(begin: 0.0, end: 1.0);
      const parent = AlwaysStoppedAnimation<double>(0.5);
      final derived = tween.animate(parent);

      final str = derived.toString();
      expect(str, contains('parent'));
      expect(str, contains('evaluatable'));
    });
  });

  group('Animatable.chain', () {
    test('chains two animatables', () {
      final curveTween = CurveTween(curve: Curves.linear);
      final valueTween = Tween<double>(begin: 0.0, end: 100.0);
      final chained = valueTween.chain(curveTween);

      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(0.5), closeTo(50.0, 1e-6));
      expect(chained.transform(1.0), 100.0);
    });

    test('chain applies parent first then child', () {
      // CurveTween maps 0.5 to some value via easeIn (less than 0.5)
      final curveTween = CurveTween(curve: Curves.easeIn);
      final valueTween = Tween<double>(begin: 0.0, end: 100.0);
      final chained = valueTween.chain(curveTween);

      // easeIn(0.5) < 0.5, so valueTween of that should be < 50
      final result = chained.transform(0.5);
      expect(result, lessThan(50.0));
    });

    test('double chain', () {
      final curve1 = CurveTween(curve: Curves.linear);
      final curve2 = CurveTween(curve: Curves.linear);
      final valueTween = Tween<double>(begin: 10.0, end: 20.0);

      final chained = valueTween.chain(curve1).chain(curve2);

      expect(chained.transform(0.0), 10.0);
      expect(chained.transform(0.5), closeTo(15.0, 1e-6));
      expect(chained.transform(1.0), 20.0);
    });

    test('chain toString includes parent and child info', () {
      final curveTween = CurveTween(curve: Curves.linear);
      final valueTween = Tween<double>(begin: 0.0, end: 1.0);
      final chained = valueTween.chain(curveTween);

      final str = chained.toString();
      expect(str, contains('parent'));
      expect(str, contains('child'));
    });
  });

  group('Animatable.evaluate', () {
    test('evaluates at the animation current value', () {
      final tween = Tween<double>(begin: 0.0, end: 200.0);
      const anim = AlwaysStoppedAnimation<double>(0.25);
      expect(tween.evaluate(anim), 50.0);
    });

    test('evaluate at 0.0 returns begin', () {
      final tween = Tween<double>(begin: 5.0, end: 15.0);
      const anim = AlwaysStoppedAnimation<double>(0.0);
      expect(tween.evaluate(anim), 5.0);
    });

    test('evaluate at 1.0 returns end', () {
      final tween = Tween<double>(begin: 5.0, end: 15.0);
      const anim = AlwaysStoppedAnimation<double>(1.0);
      expect(tween.evaluate(anim), 15.0);
    });
  });

  group('Animation helper properties', () {
    test('isDismissed is true only for dismissed status', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.isDismissed, isTrue);

      controller.forward();
      expect(controller.isDismissed, isFalse);

      controller.dispose();
    });

    test('isCompleted is true only for completed status', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.isCompleted, isFalse);

      controller.forward();
      expect(controller.isCompleted, isFalse);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 300)));
      expect(controller.isCompleted, isTrue);

      controller.dispose();
    });

    test('isAnimating is true for forward and reverse', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.isAnimating, isFalse);

      controller.forward();
      expect(controller.isAnimating, isTrue);

      controller.stop();
      expect(controller.isAnimating, isFalse);

      controller.reverse(from: 1.0);
      expect(controller.isAnimating, isTrue);

      controller.dispose();
    });
  });

  group('Integration: drive chain with controller', () {
    test('CurveTween + Tween through drive produces curved scaled values', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );

      // drive CurveTween first, then Tween
      final curved = controller.drive(CurveTween(curve: Curves.linear));
      final scaled = curved.drive(Tween<double>(begin: 0.0, end: 300.0));

      // linear(0.5) = 0.5, Tween(0.5) = 150.0
      expect(scaled.value, closeTo(150.0, 1e-6));

      controller.dispose();
    });

    test('IntTween through animate produces integer values', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );

      final intAnim = IntTween(begin: 0, end: 10).animate(controller);
      expect(intAnim.value, 5);

      controller.dispose();
    });

    test('complete animation lifecycle through drive', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );

      final percentage = controller.drive(
        Tween<double>(begin: 0.0, end: 100.0),
      );

      expect(percentage.value, 0.0);

      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // 25%
      controller.processTick(start.add(const Duration(milliseconds: 250)));
      expect(percentage.value, closeTo(25.0, 2.5));

      // 50%
      controller.processTick(start.add(const Duration(milliseconds: 500)));
      expect(percentage.value, closeTo(50.0, 2.5));

      // 100%
      controller.processTick(start.add(const Duration(milliseconds: 1000)));
      expect(percentage.value, 100.0);

      controller.dispose();
    });
  });
}
