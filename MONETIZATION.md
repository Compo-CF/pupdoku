# Pupdoku v3.0 — Monetization (mirrors Critter Conga)

Goal: bring Critter Conga's F2P economy to Pupdoku — a Bones currency, cosmetics,
seasonal Event Passes, a Starter Pack bundle, and the Parade Pass subscription —
alongside the existing Remove Ads + hint packs + tips. Currency is BONES (paw/bone
themed) instead of "gems". Build everything in one v3.0 release.

## Product catalog (App Store Connect)  — all IDs prefixed com.centricfiber.pupdoku
Existing (keep): removeads (NC), hints_small +10 (C), hints_large +50 (C),
tip.small/medium/large (C).

NEW consumables (Bones currency):
- bones.80    $0.99
- bones.500   $4.99
- bones.1200  $9.99
- bones.2800  $19.99

NEW non-consumables:
- starterpack            $1.99  -> grants 600 Bones + Remove Ads + Midnight theme (one time)
- eventpass.spooky2026   $2.99  -> Spooky theme + costume markers + spooky Daily badge
- eventpass.winter2026   $2.99  -> Winter theme + costume markers + winter Daily badge

NEW subscription (auto-renewable) — Group "Pupdoku Passes":
- paradepass.monthly     $2.99/mo -> while active: AD-FREE + UNLIMITED HINTS

## Bones — earn and spend
Earn: small Bones reward on each win (e.g. 10, plus bonus for perfect/size), Daily
completion bonus, rewarded ad ("watch for Bones"). Buy via the 4 tiers.
Spend (sinks):
- Hints: 15 Bones per hint (in addition to the existing hint-count balance from
  packs/free/rewarded).
- Cosmetic board themes (see below).
- Event Passes can also be unlocked with Bones (2000) as an alternative to the IAP.

## Cosmetics — Board Themes (Bones-unlockable; owned forever)
Theme = a region-color palette + background (cheap palette swap over the existing
region system). Set in Settings; applies to every board.
- Classic (free, default)
- Midnight (dark)      500 Bones   (also in Starter Pack)
- Pastel Dream         500 Bones
- Neon Pups            800 Bones
- Autumn Walk          500 Bones
- Spooky   (Event Pass Spooky 2026 only)
- Winter   (Event Pass Winter 2026 only)

## Event Passes — seasonal, non-consumable
Each unlocks: a themed board palette + costume puppy markers (accessory overlay on
the breed art, e.g. witch hats / santa hats) + a themed Daily badge. Owned forever.
Buyable via IAP or 2000 Bones.

## Parade Pass (subscription)
Entitlement subscriptionActive from StoreKit2 Transaction.currentEntitlements for
paradepass.monthly. While active:
- Ads suppressed (treated like removeAdsOwned for banner + interstitial).
- Unlimited hints (useHint bypasses balance/Bones).
Remove Ads (one-time) and hint packs still sold for non-subscribers.

## Code plan
Model:
- Wallet in GameState: bones Int, ownedThemes Set, selectedTheme String,
  ownedEventPasses Set. Earn helpers on recordWin.
- BoardTheme.swift: catalog (id, name, price, region palette, bg, isEventLocked).
- EventPass.swift: catalog (id, name, price, themeId, costumeId).
- Costume overlay: optional accessory layer in BreedTokenView per costume.
IAPManager:
- Add bones/starterpack/eventpass IDs; add subscription product + subscriptionActive
  (Transaction.updates + currentEntitlements). Add bonesGrant(for:), starterpack
  grant, eventpass grant.
GameStore:
- spendBones / addBones; buyTheme; selectTheme; unlockEventPass; useHint honors
  subscription (unlimited) then free balance then Bones.
- adsSuppressed = removeAdsOwned || subscriptionActive.
UI:
- ShopView redesign: Bones balance + 4 tiers, Parade Pass paywall card, Starter Pack,
  Event Passes, hint packs, Remove Ads, tips, restore.
- Themes picker; apply selectedTheme palette in board background + region colors.
Services:
- AdManager suppress when subscriptionActive (in addition to removeAdsOwned).

## ASC setup checklist
1. Create 4 bones consumables, starterpack + 2 event passes (NC), each with review
   screenshot + localization.
2. Create Subscription Group "Pupdoku Passes" -> Parade Pass Monthly (1 month, $2.99),
   localized name/description + review screenshot; first sub group ships with v3.0.
3. Keep existing removeads/hints/tips.

## Build order (v3.0)
1. Economy model + IAPManager + GameStore (spine).
2. Bones earn/spend wired into win + hint flow; ad suppression via subscription.
3. Themes (palettes) + Themes UI + apply to board.
4. Event Passes + seasonal costume art (Spooky/Winter).
5. ShopView redesign incl. subscription paywall (with required disclosure text).
6. Tests; bump 3.0.0; ASC products; TestFlight; submit.

## Subscription paywall disclosure (Apple requires)
Show: title, price + duration ("$2.99 / month"), what it unlocks, auto-renew terms,
and links to Terms (EULA) + Privacy. Restore Purchases present.
