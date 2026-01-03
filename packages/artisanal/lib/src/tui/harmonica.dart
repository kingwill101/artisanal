/// Minimal port of Charmbracelet's harmonica helpers (spring + projectile).
///
/// The goal is feature parity for Bubble Tea examples and components.
library;

import 'dart:math' as math;

/// Returns the time delta for a given frames-per-second value.
double fpsDelta(int n) => (1 / n);

/// A stable damped spring integrator (Ryan Juckett formulation) matching
/// charmbracelet/harmonica.
class Spring {
  Spring(this.deltaTime, this.frequency, this.damping) {
    _recompute();
  }

  final double deltaTime;
  final double
  frequency; // angular frequency (radians/sec divided by 2π in Go impl)
  final double damping; // damping ratio

  // Precomputed coefficients
  late final double _posPosCoef;
  late final double _posVelCoef;
  late final double _velPosCoef;
  late final double _velVelCoef;

  static const double _epsilon = 1e-10;

  void _recompute() {
    // In Go harmonica, frequency is angular frequency. We mirror that: expect
    // callers to pass angular frequency (same as harmonica.NewSpring).
    final w = math.max(0.0, frequency);
    final zeta = math.max(0.0, damping);

    if (w < _epsilon) {
      _posPosCoef = 1.0;
      _posVelCoef = 0.0;
      _velPosCoef = 0.0;
      _velVelCoef = 1.0;
      return;
    }

    if (zeta > 1.0 + _epsilon) {
      // Over-damped
      final za = -w * zeta;
      final zb = w * math.sqrt(zeta * zeta - 1.0);
      final z1 = za - zb;
      final z2 = za + zb;

      final e1 = math.exp(z1 * deltaTime);
      final e2 = math.exp(z2 * deltaTime);

      final invTwoZb = 1.0 / (2.0 * zb);
      final e1OverTwoZb = e1 * invTwoZb;
      final e2OverTwoZb = e2 * invTwoZb;
      final z1e1OverTwoZb = z1 * e1OverTwoZb;
      final z2e2OverTwoZb = z2 * e2OverTwoZb;

      _posPosCoef = e1OverTwoZb * z2 - z2e2OverTwoZb + e2;
      _posVelCoef = -e1OverTwoZb + e2OverTwoZb;
      _velPosCoef = (z1e1OverTwoZb - z2e2OverTwoZb + e2) * z2;
      _velVelCoef = -z1e1OverTwoZb + z2e2OverTwoZb;
    } else if (zeta < 1.0 - _epsilon) {
      // Under-damped
      final omegaZeta = w * zeta;
      final alpha = w * math.sqrt(1.0 - zeta * zeta);

      final expTerm = math.exp(-omegaZeta * deltaTime);
      final cosTerm = math.cos(alpha * deltaTime);
      final sinTerm = math.sin(alpha * deltaTime);
      final invAlpha = 1.0 / alpha;

      final expSin = expTerm * sinTerm;
      final expCos = expTerm * cosTerm;
      final expOmegaZetaSinOverAlpha = expTerm * omegaZeta * sinTerm * invAlpha;

      _posPosCoef = expCos + expOmegaZetaSinOverAlpha;
      _posVelCoef = expSin * invAlpha;
      _velPosCoef = -expSin * alpha - omegaZeta * expOmegaZetaSinOverAlpha;
      _velVelCoef = expCos - expOmegaZetaSinOverAlpha;
    } else {
      // Critically damped
      final expTerm = math.exp(-w * deltaTime);
      final timeExp = deltaTime * expTerm;
      final timeExpFreq = timeExp * w;

      _posPosCoef = timeExpFreq + expTerm;
      _posVelCoef = timeExp;
      _velPosCoef = -w * timeExpFreq;
      _velVelCoef = -timeExpFreq + expTerm;
    }
  }

  /// Update position/velocity toward [equilibriumPos].
  (double, double) update(double pos, double vel, double equilibriumPos) {
    final oldPos = pos - equilibriumPos;
    final oldVel = vel;

    final newPos = oldPos * _posPosCoef + oldVel * _posVelCoef + equilibriumPos;
    final newVel = oldPos * _velPosCoef + oldVel * _velVelCoef;
    return (newPos, newVel);
  }
}

/// A simple friction integrator mirroring harmonica/friction.go.
class Friction {
  Friction(this.deltaTime, this.friction) {
    _coef = math.exp(-friction * deltaTime);
  }

  final double deltaTime;
  final double friction;
  late final double _coef;

  /// Update position/velocity.
  (double, double) update(double pos, double vel) {
    final newVel = vel * _coef;
    // If friction is very small, use linear approximation to avoid division by zero
    if (friction.abs() < 1e-6) {
      return (pos + vel * deltaTime, newVel);
    }
    final newPos = pos + (vel * (1 - _coef) / friction);
    return (newPos, newVel);
  }
}

/// A simple projectile integrator mirroring harmonica/projectile.go.
class Projectile {
  Projectile(
    this.deltaTime,
    Point initialPosition,
    Vector initialVelocity,
    Vector initialAcceleration,
  ) : _pos = initialPosition,
      _vel = initialVelocity,
      _acc = initialAcceleration;

  final double deltaTime;
  Point _pos;
  Vector _vel;
  final Vector _acc;

  /// Advance one frame and return the new position.
  Point update() {
    _pos = Point(
      _pos.x + _vel.x * deltaTime,
      _pos.y + _vel.y * deltaTime,
      _pos.z + _vel.z * deltaTime,
    );
    _vel = Vector(
      _vel.x + _acc.x * deltaTime,
      _vel.y + _acc.y * deltaTime,
      _vel.z + _acc.z * deltaTime,
    );
    return _pos;
  }

  Point get position => _pos;
  Vector get velocity => _vel;
  Vector get acceleration => _acc;
}

/// 3D point helper.
class Point {
  const Point(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

/// 3D vector helper.
class Vector {
  const Vector(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

/// Gravity helpers (match harmonica names).
const gravity = Vector(0, -9.81, 0);
const terminalGravity = Vector(0, 9.81, 0);

/// Convenience to create a spring using FPS like the Go API.
Spring newSpringFromFps(int fps, double frequency, double damping) {
  return Spring(fpsDelta(fps), frequency, damping);
}
