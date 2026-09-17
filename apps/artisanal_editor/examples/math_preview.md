# Math preview

Open this file in the Artisanal editor to check terminal math in the
markdown preview. The preview uses the shared markdown renderer; there is no
extra `renderMath` call.

```sh
dart run artisanal_editor edit apps/artisanal_editor/examples/math_preview.md
```

## Inline

Einstein: \(E = mc^2\). Pythagoras: $a^2 + b^2 = c^2$. TeX grouping:
\(x^22\) is \(x^2\) then 2; write \(x^{22}\) for twenty-two. Currency stays
literal: $5 and $10.

## Display

Quadratic formula:

$$
\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$

A fraction and a root:

\[
\sqrt{\frac{a}{b}} = \left(\frac{a}{b}\right)^{1/2}
\]

## Operators

Sum with limits:

$$
\sum_{i=0}^{n} i = \frac{n(n+1)}{2}
$$

Integral:

$$
\int_0^1 x\,dx = \frac{1}{2}
$$

## Linear algebra

$$
\begin{pmatrix}
a & b \\
c & d
\end{pmatrix}
\begin{pmatrix}
x \\
y
\end{pmatrix}
=
\begin{pmatrix}
ax + by \\
cx + dy
\end{pmatrix}
$$

## Accents

Unit vector: \(\hat{x}\), force: \(\vec{F}\), boxed: \(\boxed{x}\).
