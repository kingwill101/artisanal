The following (incomplete, work in progress) tables track our SIMD value types and my progress on them so far. Many things below are aspirational and will need a separate discussion.

If you have a use case you would like to implement with SIMD, or if you run into problems, please open an issue and mention @modulovalue and I will take a look.

## [`Int32x4`](https://api.dart.dev/dart-typed_data/Int32x4-class.html)

| Operation | API | Codegen optimizations | Benchmark | Issues |
|---|---|---|---|---|
| [`splat`](https://api.dart.dev/dev/latest/dart-typed_data/Int32x4/Int32x4.splat.html) | ✅ [cl/531960](https://dart-review.googlesource.com/c/sdk/+/531960) | [cl/531960](https://dart-review.googlesource.com/c/sdk/+/531960) | ❓ | |
| `zero` (`+` identity) | ✅ [cl/544840](https://dart-review.googlesource.com/c/sdk/+/544840) | 🚧 | ❓ | |
| `one` (`*` identity) | 🚧 | 🚧 | ❓ | |
| `const` constructor | 🚧 | 🚧 | ❓ | [#31487](https://github.com/dart-lang/sdk/issues/31487) |
| [`+` (`add`)](https://api.dart.dev/dart-typed_data/Int32x4/operator_plus.html) | ✅ | ✅ [cl/497000](https://dart-review.googlesource.com/c/sdk/+/497000) | ✅ [`SimdInt32x4`](https://dart-review.googlesource.com/c/sdk/+/497000) | |
| [`-` (`subtract`)](https://api.dart.dev/dart-typed_data/Int32x4/operator_minus.html) | ✅ | ✅ [cl/497000](https://dart-review.googlesource.com/c/sdk/+/497000) | ✅ [`SimdInt32x4`](https://dart-review.googlesource.com/c/sdk/+/497000) | |
| `*` (`multiply`) | 🚧 | 🚧 | ❓ | [#59816](https://github.com/dart-lang/sdk/issues/59816) |
| unary `-` (sign negation) | ✅ [cl/545361](https://dart-review.googlesource.com/c/sdk/+/545361) | 🚧 | ❓ | |
| [`&` (`and`)](https://api.dart.dev/dart-typed_data/Int32x4/operator_bitwise_and.html) | ✅ | ✅ [cl/497000](https://dart-review.googlesource.com/c/sdk/+/497000) | ✅ [`SimdInt32x4`](https://dart-review.googlesource.com/c/sdk/+/497000), [`BitArray32x4`](https://dart-review.googlesource.com/c/sdk/+/521945) | |
| [`\|` (`or`)](https://api.dart.dev/dart-typed_data/Int32x4/operator_bitwise_or.html) | ✅ | ✅ [cl/497000](https://dart-review.googlesource.com/c/sdk/+/497000) | ✅ [`SimdInt32x4`](https://dart-review.googlesource.com/c/sdk/+/497000), [`BitArray32x4`](https://dart-review.googlesource.com/c/sdk/+/521945) | |
| [`^` (`xor`)](https://api.dart.dev/dart-typed_data/Int32x4/operator_bitwise_exclusive_or.html) | ✅ | ✅ [cl/497000](https://dart-review.googlesource.com/c/sdk/+/497000) | ✅ [`SimdInt32x4`](https://dart-review.googlesource.com/c/sdk/+/497000), [`BitArray32x4`](https://dart-review.googlesource.com/c/sdk/+/521945) | |
| [`~` (`not`)](https://api.dart.dev/dev/latest/dart-typed_data/Int32x4/operator_bitwise_negate.html) | ✅ [cl/532480](https://dart-review.googlesource.com/c/sdk/+/532480) | ✅ [cl/532480](https://dart-review.googlesource.com/c/sdk/+/532480) | TODO extend [`BitArray32x4`](https://dart-review.googlesource.com/c/sdk/+/521945) | |
| `andNot` | 🚧 | 🚧 | TODO extend [`BitArray32x4`](https://dart-review.googlesource.com/c/sdk/+/521945) | |
| `<<` (`shiftLeft`) | ✅ [cl/545480](https://dart-review.googlesource.com/c/sdk/+/545480) | 🚧 | ❓ | [#47114](https://github.com/dart-lang/sdk/issues/47114), [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| `>>` (`shiftRight`) | ✅ [cl/545480](https://dart-review.googlesource.com/c/sdk/+/545480) | 🚧 | ❓ | [#47114](https://github.com/dart-lang/sdk/issues/47114), [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| [`equal`](https://api.dart.dev/dev/latest/dart-typed_data/Int32x4/equal.html) | ✅ [cl/528620](https://dart-review.googlesource.com/c/sdk/+/528620) | ✅ [cl/539060](https://dart-review.googlesource.com/c/sdk/+/539060), [cl/539520](https://dart-review.googlesource.com/c/sdk/+/539520) | ✅ [`SimdSearch`](https://dart-review.googlesource.com/c/sdk/+/535540) | |
| `notEqual` | ✅ [cl/541221](https://dart-review.googlesource.com/c/sdk/+/541221) | ✅ [cl/541240](https://dart-review.googlesource.com/c/sdk/+/541240) | TODO extend [`SimdSearch`](https://dart-review.googlesource.com/c/sdk/+/535540) | |
| `<` (`lessThan`) | ✅ [cl/543500](https://dart-review.googlesource.com/c/sdk/+/543500) | 🚧 | ❓ | [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| `<=` (`lessThanOrEqual`) | ✅ [cl/543500](https://dart-review.googlesource.com/c/sdk/+/543500) | 🚧 | ❓ | [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| `>` (`greaterThan`) | ✅ [cl/543500](https://dart-review.googlesource.com/c/sdk/+/543500) | 🚧 | ❓ | [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| `>=` (`greaterThanOrEqual`) | ✅ [cl/543500](https://dart-review.googlesource.com/c/sdk/+/543500) | 🚧 | ❓ | [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| `min` | 🚧 | 🚧 | ❓ | |
| `max` | 🚧 | 🚧 | ❓ | |
| `abs` | ✅ [cl/545361](https://dart-review.googlesource.com/c/sdk/+/545361) | 🚧 | ❓ | |
| [`anyTrue`](https://api.dart.dev/dev/latest/dart-typed_data/Int32x4/anyTrue.html) | ✅ [cl/528620](https://dart-review.googlesource.com/c/sdk/+/528620) | ✅ [cl/539400](https://dart-review.googlesource.com/c/sdk/+/539400) | ✅ [`SimdSearch`](https://dart-review.googlesource.com/c/sdk/+/535540) | [#64129](https://github.com/dart-lang/sdk/issues/64129) |
| `allTrue` | ✅ [cl/543480](https://dart-review.googlesource.com/c/sdk/+/543480) | 🚧 | ❓ | [#64129](https://github.com/dart-lang/sdk/issues/64129) |
| [`signMask`](https://api.dart.dev/dart-typed_data/Int32x4/signMask.html) | ✅ | ✅ [cl/521245](https://dart-review.googlesource.com/c/sdk/+/521245), [cl/542362](https://dart-review.googlesource.com/c/sdk/+/542362), [cl/542363](https://dart-review.googlesource.com/c/sdk/+/542363) | ✅ [`SimdInt32x4`](https://dart-review.googlesource.com/c/sdk/+/542341) | [#41950](https://github.com/dart-lang/sdk/issues/41950), [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| [`x/y/z/w`](https://api.dart.dev/dart-typed_data/Int32x4/x.html) | ✅ | ✅ [cl/507761](https://dart-review.googlesource.com/c/sdk/+/507761) | ✅ [`BitArray32x4`](https://dart-review.googlesource.com/c/sdk/+/521945) | |
| [`flagX/Y/Z/W`](https://api.dart.dev/dart-typed_data/Int32x4/flagX.html) | ✅ | ✅ | ❓ | [#64129](https://github.com/dart-lang/sdk/issues/64129) |
| [`withX/Y/Z/W`](https://api.dart.dev/dart-typed_data/Int32x4/withX.html) | ✅ |  | ❓ | [#40240](https://github.com/dart-lang/sdk/issues/40240) |
| [`withFlagX/Y/Z/W`](https://api.dart.dev/dart-typed_data/Int32x4/withFlagX.html) | ✅ | ✅ | ❓ | [#64129](https://github.com/dart-lang/sdk/issues/64129) |
| [`shuffle`](https://api.dart.dev/dart-typed_data/Int32x4/shuffle.html) | ✅ | ✅ | ❓ | [#63680](https://github.com/dart-lang/sdk/issues/63680) |
| [`shuffleMix`](https://api.dart.dev/dart-typed_data/Int32x4/shuffleMix.html) | ✅ | ✅ | ❓ | |
| `swizzle` | 🚧 | 🚧 | ❓ | |
| [`select`](https://api.dart.dev/dart-typed_data/Int32x4/select.html) | ✅ | ✅ | ❓ | |
| `==` / `hashCode` | 🚧 | 🚧 | ❓ | [#43255](https://github.com/dart-lang/sdk/issues/43255) |
| `toString` | 🚧 | ❓ | ❓ | [#63847](https://github.com/dart-lang/sdk/issues/63847) |
| conversions ([`fromFloat32x4Bits`](https://api.dart.dev/dart-typed_data/Int32x4/Int32x4.fromFloat32x4Bits.html)) | 🚧 | ❓ | ❓ | [#46182](https://github.com/dart-lang/sdk/issues/46182) |

## [`Float32x4`](https://api.dart.dev/dart-typed_data/Float32x4-class.html)

| Operation | API | Codegen optimizations | Benchmark | Issues |
|---|---|---|---|---|
| [`splat`](https://api.dart.dev/dart-typed_data/Float32x4/Float32x4.splat.html) | ✅ | ✅ | ❓ | |
| [`zero`](https://api.dart.dev/dart-typed_data/Float32x4/Float32x4.zero.html) (`+` identity) | ✅ | ✅ | ❓ | |
| `one` (`*` identity) | 🚧 | 🚧 | ❓ | |
| `const` constructor | 🚧 | 🚧 | ❓ | [#31487](https://github.com/dart-lang/sdk/issues/31487), [#56363](https://github.com/dart-lang/sdk/issues/56363) |
| [`+` (`add`)](https://api.dart.dev/dart-typed_data/Float32x4/operator_plus.html) | ✅ | ✅ | ❓ | |
| [`-` (`subtract`)](https://api.dart.dev/dart-typed_data/Float32x4/operator_minus.html) | ✅ | ✅ | ❓ | |
| [`*` (`multiply`)](https://api.dart.dev/dart-typed_data/Float32x4/operator_multiply.html) | ✅ | ✅ | ❓ | |
| [`/` (`divide`)](https://api.dart.dev/dart-typed_data/Float32x4/operator_divide.html) | ✅ | ✅ | ❓ | |
| [unary `-` (sign negation)](https://api.dart.dev/dart-typed_data/Float32x4/operator_unary_minus.html) | ✅ | ✅ | ❓ | |
| [`abs`](https://api.dart.dev/dart-typed_data/Float32x4/abs.html) | ✅ | ✅ | ❓ | |
| [`min`](https://api.dart.dev/dart-typed_data/Float32x4/min.html) | ✅ | 🚧 [cl/543520](https://dart-review.googlesource.com/c/sdk/+/543520) | ❓ | [#63962](https://github.com/dart-lang/sdk/issues/63962) |
| [`max`](https://api.dart.dev/dart-typed_data/Float32x4/max.html) | ✅ | 🚧 [cl/543520](https://dart-review.googlesource.com/c/sdk/+/543520) | ❓ | [#63962](https://github.com/dart-lang/sdk/issues/63962) |
| [`sqrt`](https://api.dart.dev/dart-typed_data/Float32x4/sqrt.html) | ✅ | ✅ | ❓ | |
| [`reciprocal`](https://api.dart.dev/dart-typed_data/Float32x4/reciprocal.html) | ✅ | ✅ | ❓ | [#39551](https://github.com/dart-lang/sdk/issues/39551) |
| [`reciprocalSqrt`](https://api.dart.dev/dart-typed_data/Float32x4/reciprocalSqrt.html) | ✅ | ✅ | ❓ | [#39551](https://github.com/dart-lang/sdk/issues/39551) |
| [`scale`](https://api.dart.dev/dart-typed_data/Float32x4/scale.html) | ✅ | ✅ | ❓ | |
| [`clamp`](https://api.dart.dev/dart-typed_data/Float32x4/clamp.html) | ✅ | ✅ | ❓ | [#40426](https://github.com/dart-lang/sdk/issues/40426) |
| `ceil` | 🚧 | 🚧 | ❓ | |
| `floor` | 🚧 | 🚧 | ❓ | |
| `trunc` | 🚧 | 🚧 | ❓ | |
| `nearest` | 🚧 | 🚧 | ❓ | [#61240](https://github.com/dart-lang/sdk/issues/61240) |
| `pmin` | 🚧 | 🚧 | ❓ | |
| `pmax` | 🚧 | 🚧 | ❓ | |
| [`equal`](https://api.dart.dev/dart-typed_data/Float32x4/equal.html) | ✅ | ✅ | ❓ | |
| [`notEqual`](https://api.dart.dev/dart-typed_data/Float32x4/notEqual.html) | ✅ | ✅ | ❓ | |
| [`<` (`lessThan`)](https://api.dart.dev/dart-typed_data/Float32x4/lessThan.html) | ✅ | ✅ | ❓ | |
| [`<=` (`lessThanOrEqual`)](https://api.dart.dev/dart-typed_data/Float32x4/lessThanOrEqual.html) | ✅ | ✅ | ❓ | |
| [`>` (`greaterThan`)](https://api.dart.dev/dart-typed_data/Float32x4/greaterThan.html) | ✅ | ✅ | ❓ | |
| [`>=` (`greaterThanOrEqual`)](https://api.dart.dev/dart-typed_data/Float32x4/greaterThanOrEqual.html) | ✅ | ✅ | ❓ | |
| [`signMask`](https://api.dart.dev/dart-typed_data/Float32x4/signMask.html) | ✅ | ✅ [cl/542362](https://dart-review.googlesource.com/c/sdk/+/542362), [cl/542363](https://dart-review.googlesource.com/c/sdk/+/542363) | ❓ | |
| [`x/y/z/w`](https://api.dart.dev/dart-typed_data/Float32x4/x.html) | ✅ | ✅ | ❓ | |
| [`withX/Y/Z/W`](https://api.dart.dev/dart-typed_data/Float32x4/withX.html) | ✅ | ✅ | ❓ | [#40240](https://github.com/dart-lang/sdk/issues/40240) |
| [`shuffle`](https://api.dart.dev/dart-typed_data/Float32x4/shuffle.html) | ✅ | ✅ | ❓ | |
| [`shuffleMix`](https://api.dart.dev/dart-typed_data/Float32x4/shuffleMix.html) | ✅ | ✅ | ❓ | |
| `==` / `hashCode` | 🚧 | 🚧 | ❓ | [#43255](https://github.com/dart-lang/sdk/issues/43255) |
| `toString` | 🚧 | ❓ | ❓ | [#63847](https://github.com/dart-lang/sdk/issues/63847) |
| conversions ([`fromInt32x4Bits`](https://api.dart.dev/dart-typed_data/Float32x4/Float32x4.fromInt32x4Bits.html), [`fromFloat64x2`](https://api.dart.dev/dart-typed_data/Float32x4/Float32x4.fromFloat64x2.html)) | 🚧 | ❓ | ❓ | [#46182](https://github.com/dart-lang/sdk/issues/46182) |

## [`Float64x2`](https://api.dart.dev/dart-typed_data/Float64x2-class.html)

| Operation | API | Codegen optimizations | Benchmark | Issues |
|---|---|---|---|---|
| [`splat`](https://api.dart.dev/dart-typed_data/Float64x2/Float64x2.splat.html) | ✅ | ✅ | ❓ | |
| [`zero`](https://api.dart.dev/dart-typed_data/Float64x2/Float64x2.zero.html) (`+` identity) | ✅ | ✅ | ❓ | |
| `one` (`*` identity) | 🚧 | 🚧 | ❓ | |
| `const` constructor | 🚧 | 🚧 | ❓ | [#31487](https://github.com/dart-lang/sdk/issues/31487) |
| [`+` (`add`)](https://api.dart.dev/dart-typed_data/Float64x2/operator_plus.html) | ✅ | ✅ | ❓ | |
| [`-` (`subtract`)](https://api.dart.dev/dart-typed_data/Float64x2/operator_minus.html) | ✅ | ✅ | ❓ | |
| [`*` (`multiply`)](https://api.dart.dev/dart-typed_data/Float64x2/operator_multiply.html) | ✅ | ✅ | ❓ | |
| [`/` (`divide`)](https://api.dart.dev/dart-typed_data/Float64x2/operator_divide.html) | ✅ | ✅ | ❓ | |
| [unary `-` (sign negation)](https://api.dart.dev/dart-typed_data/Float64x2/operator_unary_minus.html) | ✅ | ✅ | ❓ | |
| [`abs`](https://api.dart.dev/dart-typed_data/Float64x2/abs.html) | ✅ | ✅ | ❓ | |
| [`min`](https://api.dart.dev/dart-typed_data/Float64x2/min.html) | ✅ | 🚧 [cl/543520](https://dart-review.googlesource.com/c/sdk/+/543520) | ❓ | [#63962](https://github.com/dart-lang/sdk/issues/63962), [#31048](https://github.com/dart-lang/sdk/issues/31048) |
| [`max`](https://api.dart.dev/dart-typed_data/Float64x2/max.html) | ✅ | 🚧 [cl/543520](https://dart-review.googlesource.com/c/sdk/+/543520) | ❓ | [#63962](https://github.com/dart-lang/sdk/issues/63962), [#31048](https://github.com/dart-lang/sdk/issues/31048) |
| [`sqrt`](https://api.dart.dev/dart-typed_data/Float64x2/sqrt.html) | ✅ | ✅ | ❓ | |
| [`scale`](https://api.dart.dev/dart-typed_data/Float64x2/scale.html) | ✅ | ✅ | ❓ | |
| [`clamp`](https://api.dart.dev/dart-typed_data/Float64x2/clamp.html) | ✅ | ✅ | ❓ | [#40426](https://github.com/dart-lang/sdk/issues/40426) |
| `ceil` | 🚧 | 🚧 | ❓ | |
| `floor` | 🚧 | 🚧 | ❓ | |
| `trunc` | 🚧 | 🚧 | ❓ | |
| `nearest` | 🚧 | 🚧 | ❓ | [#61240](https://github.com/dart-lang/sdk/issues/61240) |
| `pmin` | 🚧 | 🚧 | ❓ | |
| `pmax` | 🚧 | 🚧 | ❓ | |
| `equal` | 🚧 | 🚧 | ❓ | |
| `notEqual` | 🚧 | 🚧 | ❓ | |
| `<` (`lessThan`) | 🚧 | 🚧 | ❓ | |
| `<=` (`lessThanOrEqual`) | 🚧 | 🚧 | ❓ | |
| `>` (`greaterThan`) | 🚧 | 🚧 | ❓ | |
| `>=` (`greaterThanOrEqual`) | 🚧 | 🚧 | ❓ | |
| [`signMask`](https://api.dart.dev/dart-typed_data/Float64x2/signMask.html) | ✅ | ✅ [cl/542363](https://dart-review.googlesource.com/c/sdk/+/542363) | ❓ | |
| [`x/y`](https://api.dart.dev/dart-typed_data/Float64x2/x.html) | ✅ | ✅ | ❓ | |
| [`withX/Y`](https://api.dart.dev/dart-typed_data/Float64x2/withX.html) | ✅ | ✅ | ❓ | |
| `==` / `hashCode` | 🚧 | 🚧 | ❓ | [#43255](https://github.com/dart-lang/sdk/issues/43255) |
| `toString` | 🚧 | ❓ | ❓ | [#63847](https://github.com/dart-lang/sdk/issues/63847) |
| conversions ([`fromFloat32x4`](https://api.dart.dev/dart-typed_data/Float64x2/Float64x2.fromFloat32x4.html)) | 🚧 | ❓ | ❓ | [#46182](https://github.com/dart-lang/sdk/issues/46182) |

## `Int8x16` / `Uint8x16`, `Int16x8` / `Uint16x8`, `Uint32x4`, `Int64x2`

They are on my todo list. We don't have types for those yet.

<!--
<details>
<summary><b>Supporting CLs</b></summary>

- finish unboxing `Int32x4` in instance fields [cl/543040](https://dart-review.googlesource.com/c/sdk/+/543040/1): benchmarked by `SimdFields` [cl/543020](https://dart-review.googlesource.com/c/sdk/+/543020)
- `int.trailingZeroBitCount` needed for efficient search: added [cl/498041](https://dart-review.googlesource.com/c/sdk/+/498041), graph-inlinable [cl/507560](https://dart-review.googlesource.com/c/sdk/+/507560), JIT speedup [cl/523380](https://dart-review.googlesource.com/c/sdk/+/523380)
- intrinsics: [cl/532581](https://dart-review.googlesource.com/c/sdk/+/532581), [cl/532600](https://dart-review.googlesource.com/c/sdk/+/532600), [cl/539262](https://dart-review.googlesource.com/c/sdk/+/539262), [cl/539320](https://dart-review.googlesource.com/c/sdk/+/539320), [cl/539380](https://dart-review.googlesource.com/c/sdk/+/539380), [cl/541200](https://dart-review.googlesource.com/c/sdk/+/541200), [cl/542342](https://dart-review.googlesource.com/c/sdk/+/542342), [cl/542362](https://dart-review.googlesource.com/c/sdk/+/542362), [cl/542363](https://dart-review.googlesource.com/c/sdk/+/542363)
- cleanup: [cl/523280](https://dart-review.googlesource.com/c/sdk/+/523280), [cl/523360](https://dart-review.googlesource.com/c/sdk/+/523360)
- dart2wasm: `Int32x4` value `v128` backing [cl/507760](https://dart-review.googlesource.com/c/sdk/+/507760)
- dart2wasm: `Int32x4List` `WasmArray<WasmV128>` backing [cl/522700](https://dart-review.googlesource.com/c/sdk/+/522700)
- dart2wasm: `Float32x4` value `v128` backing [cl/530820](https://dart-review.googlesource.com/c/sdk/+/530820)
- dart2wasm: `Float32x4List` backing [cl/531140](https://dart-review.googlesource.com/c/sdk/+/531140)
- dart2wasm: `Float64x2` value `v128` backing [cl/531120](https://dart-review.googlesource.com/c/sdk/+/531120)
- dart2wasm: `Float64x2List` backing [cl/531640](https://dart-review.googlesource.com/c/sdk/+/531640)

</details>
-->









## Third-party blockers

- Efficient `WasmArray` reinterpretation: #64256

## Use cases

- Optimal 4x4 matrix multiplication: #64238
- Vectorized search over bytes: #63821


