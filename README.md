# CivicMemo

Локальный корпоративный дневник ккал/макросов. Household seats (2–4 стола) + ShareLink дневной служебной записки. Без аккаунта и бэкенда.

- Bundle ID: `com.civicmemo.desk`
- iOS 17+, iPhone portrait, Swift 6.2, Health & Fitness
- Слоты: AM Desk / Midday / PM Desk / Break (Break только в consumed)
- План: 14 дней
- Цели по умолчанию: 2150 kcal / 95 P / 240 C / 70 F
- Каталог: Open Food Facts (`CivicMemo/1.0` User-Agent)
- Единственный SPM: [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) ≥ 1.26.1
- Шрифт: Montserrat OFL — `CivicMemo/Resources/Fonts/Montserrat/LICENSE`

## Уникальные фичи

2–4 локальных household seat, отдельный JSON на место. ShareLink дневной служебной записки. Слоты AM Desk / Midday / PM Desk / Break (Break только в consumed). План 14 дней.

## Чем отличается

Корпоративный TCA-дневник со столами и шарингом. Не стекло, не аркада, не дубовая кладовая, не акварель, не сигнал-сетка.

## Сборка

```bash
xcodegen generate
xcodebuild -project CivicMemo.xcodeproj -scheme CivicMemo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipMacroValidation -IDEPackageEnablePrebuilts=NO \
  SWIFT_ENABLE_EXPLICIT_MODULES=NO \
  CODE_SIGNING_ALLOWED=NO build
```

## Архитектура

TCA: один composition root, NavigationStack push/pop, зависимости (`CatalogGateway`, `SeatFileArchive`). UIKit только через `UIViewRepresentable` (Vision-сканер и UISlider порции). Persistence — JSON-файл на каждое место (`Documents/CivicMemoSeats/`).

## Промпты ассетов (flat vector, corporate)

Общий стиль: clean geometric lines; navy `#1B3A6B`, blue `#2F6FED`, gray `#8A93A0`, white, ice `#E6EBF2`. No photorealism, gradients, 3D, neon, text, or faces.

| Asset | Prompt |
| --- | --- |
| AppIcon | Flat vector iOS app icon, square composition, corporate office style. A white memo folder standing upright with a navy blue header bar, a simple horizontal barcode of thick and thin navy bars, and a small blue circular check mark. Clean geometric lines, limited palette: navy #1B3A6B, bright blue #2F6FED, cool gray #8A93A0, white, light gray #E6EBF2. No text, no letters, no photorealism, no gradients, no 3D, no neon, generous padding from edges, centered, crisp edges, suitable as a 1024px app icon. |
| Splash | Flat vector splash illustration, tall portrait composition. A clean civic office desk from above: white blotter, navy folder, blue pen aligned horizontally, a simple barcode strip, and a gray coffee cup. Corporate office aesthetic, clean geometric lines, limited palette navy #1B3A6B, bright blue #2F6FED, cool gray #8A93A0, white #FFFFFF, light gray #E6EBF2. No text, no faces, no photorealism, no gradients, no 3D, no neon, generous negative space, crisp edges. |
| BriefingWelcome | Flat vector onboarding illustration: welcome to a civic desk. A simple standing desk with a navy nameplate, a white inbox tray, and a blue memo sheet with three gray lines. |
| BriefingScan | Flat vector onboarding illustration: looking up a product. A white handheld scanner gun pointing at a simple barcode on a gray box, plus a magnifying glass over a navy catalog card. |
| BriefingSlots | Flat vector onboarding illustration: four workday meal slots as four equal desk trays in a 2x2 grid. Sun / clock / skyline / cup. |
| BriefingSeats | Flat vector onboarding illustration: four simple desk chairs in a row plus a memo sheet with a share arrow. |
| EmptyDesk | Flat vector empty civic desk: navy inbox tray, gray paperclip, faint blue outline of a missing memo. |
| EmptyEaten | Flat vector empty clipboard with navy clip and a geometric crossed fork-and-knife. |
| EmptyWish | Flat vector navy pin board with four empty white cards and one blue pushpin. |
| SlotAmDesk | Morning AM Desk: navy desk, rising sun in a blue window, white mug, oat bowl. |
| SlotMidday | Midday: white lunch tin, noon clock, geometric sandwich. |
| SlotPmDesk | PM Desk: navy skyline window, white plate with blue fish, gray document stack. |
| SlotBreak | Break: blue espresso cup, gray biscuit, navy pause bars. |
| ShelfOat | Civic oat cup: white cup, navy band, oat circles, blue spoon. |
| ShelfLentil | Desk lentil tin: gray cylinder, navy lid, rust lentil pictogram. |
| ShelfRye | Memo rye slice: two rye rectangles on a navy plate. |
| ShelfYogurt | Council yogurt: white cup, peeled blue foil lid, gray spoon. |
| ShelfApple | Ledger apple: geometric red apple on a gray ledger book. |
| ShelfBroth | Briefing broth: white bowl, amber broth, steam chevrons, navy napkin. |
| ShelfAlmonds | Minute almonds: navy tin, six beige almonds. |
| ShelfTuna | Charter tuna: navy oval tin, blue pull-ring, white fish pictogram. |
| TextureBlotter | Seamless civic blotter: faint navy ruled grid on #E6EBF2. |
| TextureGrid | Seamless civic graph paper on #F4F7FB. |
| ChromeButton | Flat blue #2F6FED button plate, navy outline, white corner ticks. |
| ChromeFrame | White card frame, navy border, short blue header bar, gray corner brackets. |
| ChromeChip | Navy status pill with white inner stroke and a blue status lamp. |

Те же тексты лежат в `Assets.xcassets/*/Contents.json` (`info.comment`).
