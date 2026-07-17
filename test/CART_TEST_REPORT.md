# Test Report — CartNotifier (Shopping Cart State)

**Project:** linh_kien_shop (Flutter e-commerce app)
**Class under test:** `CartNotifier` — `lib/features/cart/providers/cart_provider.dart`
**Framework:** `flutter_test` + `flutter_riverpod` (`ProviderContainer`)
**Date:** 2026-07-03

---

## 1. Why this class

`CartNotifier` holds the shopping-cart state that the badge, the Cart screen
and the Checkout screen all read from. It contains real business logic
(add / merge / remove / change quantity / select / clear) plus two derived
values (`cartSubtotalProvider`, `cartCountProvider`). That makes it a good
target for **both** kinds of test:

- **Unit tests** — each method of `CartNotifier` in isolation.
- **Integration test** — the notifier wired together with its two derived
  providers, exercised through a realistic shopping flow.

---

## 2. Test files

| File | Type | # tests |
|------|------|---------|
| `test/cart_provider_unit_test.dart` | Unit | 8 |
| `test/cart_provider_integration_test.dart` | Integration | 4 |

Every test follows the **Arrange → Act → Assert** pattern from the course
templates. A fresh `ProviderContainer` is created in `setUp()` and disposed in
`tearDown()` so no state leaks between test cases.

---

## 3. Unit tests — `CartNotifier` methods

| # | Test | What it verifies |
|---|------|------------------|
| 1 | add() into empty cart | new line created, quantity stored |
| 2 | add() same product again | quantities **merge** into one line (1 + 3 = 4) |
| 3 | add() different variants | same product, different `variantId` = **separate** lines |
| 4 | remove() | only the matching line is deleted |
| 5 | setQuantity() | quantity is overwritten (→ 9) |
| 6 | setQuantity() invalid | quantity `< 1` is ignored (stays 5) — edge case |
| 7 | toggleSelected() | `selected` flag flips true → false |
| 8 | clear() | cart becomes empty |

## 4. Integration test — cart flow across providers

| # | Test | What it verifies |
|---|------|------------------|
| 1 | full shopping flow | count = 2 lines, subtotal = 14,000,000 after add + merge |
| 2 | deselected line | unticked line still **counted** but excluded from subtotal |
| 3 | live quantity change | subtotal recomputes (5M → 15M) when quantity changes |
| 4 | clear() flow | both `count` and `subtotal` reset to 0 |

---

## 5. How to run

```bash
flutter test test/cart_provider_unit_test.dart test/cart_provider_integration_test.dart
```

## 6. Result

```
00:00 +12: All tests passed!
```

**12 / 12 passed** (8 unit + 4 integration), 0 failed. Run time < 1s.

---

## 7. Conclusion

The unit tests confirm each `CartNotifier` operation behaves correctly on its
own, including the invalid-quantity edge case. The integration test confirms
that the notifier and its derived providers stay consistent through a complete
add → merge → deselect → change-quantity → clear flow — the exact sequence a
real user drives from the cart UI.
