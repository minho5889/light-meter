# Sunny Light Meter — Product Specification (Translated from Korean)

## Page 1: Title

Sunny Light Meter

## Page 2: Target Resolutions

Our baseline resolution: 1,179 x 2,556 pixels

Supported devices at this resolution:
- iPhone 14 Pro
- iPhone 15
- iPhone 15 Pro

The design must be responsive. The following resolution must also be supported:

1,170 x 2,532:
- iPhone 13
- iPhone 14

## Page 3: Font Scaling Rules

All text on the main screen must disable system font scaling so the smartphone's font size settings do not affect the app layout.

For React Native (reference from original doc):
```jsx
<Text {...props} allowFontScaling={false} />
```

Alternative approach — allow limited scaling with a cap:
```jsx
maxFontSizeMultiplier={1.2}
```

This lets the text grow slightly with system settings but caps the maximum size. Best of both worlds for accessibility and layout stability.

> Note: The original doc references React Native props. For our SwiftUI implementation, the equivalent approach is using fixed font sizes (`.font(.system(size: N))`) or capping Dynamic Type with `.dynamicTypeSize(...:.large)`.

## Page 4: (Blank page — likely a visual mockup placeholder)

## Page 5: Main Screen Behavior

When the app launches:
- The camera turns on and the live camera feed becomes the app's real-time background
- The lux value updates in real time on screen

Capture button (round button at the bottom):
- Tapping it captures the current moment
- Shows the captured lux value and an interpretation/description of that lux level

Camera toggle button (next to capture button):
- Switches between front and rear camera

After capture:
- The background freezes (like taking a photo — the background image stops moving)
- Displays lux reading + contextual interpretation (e.g., "Brighter than a movie theater but darker than a living room")

Reference: A similar app's demo video was linked in the original doc.

## Page 6: Lux Range Reference Table

| Lux Range | Environment / Use Case | User Guide Tip |
|-----------|----------------------|----------------|
| 0–10 | Very dark outdoors, full moon night | "Pre-sleep conditions. Be careful when moving around." |
| 20–100 | Hallways, bathrooms, storage rooms, movie theaters | "Suitable for passing through. Not appropriate for extended work." |
| 100–200 | Living room relaxation, dining, hotel rooms | "Optimal for comfortable rest. Good for watching TV." |
| 200–500 | General office work, kitchen cooking, light reading | "The most standard brightness for daily activities and office work." |
| 500–1,000 | Focused studying, precision handwork, store displays | "Recommended for study rooms or detailed tasks like sewing." |
| 1,000–2,000 | Bright window (indoors), broadcast studios, operating rooms | "Very bright. Suitable for video production or professional work." |
| 2,000–10,000 | Cloudy day outdoors, sunset outdoors | "Good for outdoor activities. Partial shade level for plants." |
| 10,000–100,000+ | Direct sunlight on a clear day, noon outdoors | "Strong sunlight. Protect your eyes and watch for plant burns." |

## Page 7: Color Temperature Reference Table

| Kelvin | Color Tone | Recommended Environment |
|--------|-----------|------------------------|
| Below 2,000K | Candlelight / Sunset 🔥 | Psychological calm, pre-sleep, atmospheric cafes |
| 2,700K–3,000K | Warm White 💡 | Bedrooms, living rooms, relaxation spaces |
| 3,500K–4,500K | Natural White 🌤 | Kitchens, dressing rooms, bathrooms |
| 5,000K–6,000K | Daylight 📖 | Study rooms, offices, precision work (improves focus) |
| 6,500K+ | Cool White ❄ | Hospitals, factories, warehouses |
| 10,000K+ | Blue Sky 🧊 | Clear day shade, specialized lab environments |

Contextual example: "The color temperature is higher than a bedroom but lower than a study room."

## Page 8: Flicker Percentage & Eye Health

| Flicker % | Safety Level | Description |
|-----------|-------------|-------------|
| 0%–3% | Very Safe | Minimal eye fatigue even with prolonged use |
| 3%–10% | Safe | Sensitive individuals may feel mild dryness or fatigue with long exposure |
| 10%–30% | Caution | Noticeable eye pain, blurred focus, and discomfort may occur |
| 30%–60% | Dangerous | Severe eye fatigue, migraines, dizziness. Focus drops sharply |
| 60%+ | Very Dangerous | Visible flickering. Risk of nausea, photosensitive seizures for sensitive individuals |

The page also shows a captured reading example:
- 120 LUX / 3,500 Kelvin / 5% Flicker
- With contextual tags: Reading & Study, Office & Focus, TV & Movies, Dining & Conversation, Sleep & Rest, Baby & Childcare, Kitchen/Dressing Room suitable, Date & Romantic, Coffee & Tea time

## Page 9: Records Screen

Each time the capture button is pressed, a record card is automatically saved with:
- Date
- Time
- Brightness (lux)
- Color Temperature (Kelvin)

Records screen behavior:
- Tapping "Record" shows cards in newest-first order (top to bottom)
- Swipe left on a card to reveal a Delete icon — tap to delete
- Tapping a card shows the captured photo with lux and color temperature info overlaid

Time format localization:
- English/French/Spanish: time suffix (e.g., 09:45 AM, 11:10 PM)
- Korean/Japanese/Chinese (Simplified & Traditional): time prefix (e.g., 오전 09:45, 午後 11:10)

## Page 10: Settings

References an external Google Slides document for the settings screen design.

---

## Analysis & Understanding

This PDF describes a full-featured light meter app called "Sunny Light Meter" that goes well beyond our current spec 01 skeleton. Here's what the full product vision includes:

1. Live camera background — the camera feed is the app background, not just metadata extraction
2. Capture functionality — a shutter button that freezes the frame and records the reading
3. Lux interpretation — contextual descriptions based on lux ranges (not just raw numbers)
4. Color temperature interpretation — contextual descriptions based on Kelvin ranges
5. Flicker detection — measuring light flicker percentage for eye health assessment
6. Front/rear camera toggle — switching between cameras
7. Records system — persistent storage of captured readings as cards with date/time
8. Record management — swipe-to-delete, tap-to-review with photo overlay
9. Localized time formatting — different time display formats per language
10. Responsive design — supporting multiple iPhone resolutions
11. Font scaling control — preventing system font size from breaking the layout
12. Settings screen — referenced externally, details not in this PDF

Our current spec 01 covers items 1 (partially — metadata only, no live preview), the raw lux calculation, and the raw color temperature calculation. The full product is significantly larger.

```mermaid
graph TD
    subgraph "Spec 01 — Current (Skeleton)"
        A[Camera Session<br/>Back camera metadata only] --> B[Lux Calculator<br/>Raw number]
        A --> C[Color Temp Calculator<br/>Raw Kelvin]
        B --> D[Measurement View<br/>Numbers only]
        C --> D
    end

    subgraph "Full Product — Sunny Light Meter"
        E[Live Camera Preview<br/>Real-time background] --> F[Lux Calculator<br/>+ Range Interpretation]
        E --> G[Color Temp Calculator<br/>+ Kelvin Interpretation]
        E --> H[Flicker Detector<br/>Eye health %]
        I[Capture Button] --> J[Freeze Frame<br/>+ Save Reading]
        K[Camera Toggle<br/>Front / Rear]
        J --> L[Records System<br/>Cards with date/time]
        L --> M[Record Management<br/>Swipe delete, tap review]
        F --> N[Main Display<br/>Lux + Context + Tips]
        G --> N
        H --> N
        N --> I
        N --> K
        O[Settings Screen] --> P[Font Scaling<br/>Responsive Design<br/>Localization]
    end

    D -.->|"evolves into"| N
```

The gap between spec 01 and the full product includes: live camera preview rendering, capture/freeze functionality, lux/kelvin interpretation tables, flicker detection, records persistence, camera switching, localization, and settings. These would each be their own spec.

## UI Screen Reference (from product mockups)

The following diagrams represent the key screens and flows observed in the product design mockups.

### Main Screen — Live Measurement (LUX Tab)

The primary screen shows the live camera feed as a full-screen background with a frosted-glass measurement card overlaid near the top. A bottom tab bar provides navigation.

```mermaid
graph TD
    subgraph "Main Screen — Live Mode"
        direction TB
        SB["─── Status Bar (9:41, signal, battery) ───"]
        GEAR["⚙ Settings icon (top-right)"]
        SB --- CARD
        subgraph CARD["Frosted Glass Card"]
            K["3,800K"]
            LUX["120 LUX (large text)"]
            K --- LUX
        end
        CARD --- CAMERA_BG["Live Camera Feed (full-screen background)<br/>e.g. indoor room with sofa, window light"]
        CAMERA_BG --- BUTTONS
        subgraph BUTTONS["Bottom Controls"]
            CAPTURE["◯ Capture Button (white circle)"]
            TOGGLE["🔄 Camera Toggle (front/rear)"]
        end
        BUTTONS --- TAB
        subgraph TAB["Bottom Tab Bar"]
            T1["LUX (selected)"]
            T2["Temperature"]
            T3["Find"]
            T4["Record"]
        end
    end
```

### Main Screen — After Capture (Frozen + Interpretation)

Tapping the capture button freezes the camera background and expands the card to show the user guide interpretation text.

```mermaid
graph TD
    subgraph "Main Screen — Captured Mode"
        direction TB
        SB2["─── Status Bar ───"]
        BACK["‹ Back arrow (top-left)"]
        GEAR2["⚙ Settings (top-right)"]
        SB2 --- CARD2
        subgraph CARD2["Expanded Frosted Glass Card"]
            K2["3,800K"]
            LUX2["120 LUX (large text)"]
            DIV["──── divider ────"]
            GUIDE["User Guide (사용자 가이드)"]
            DESC["Living room relaxation, dining, hotel rooms<br/>Optimal for comfortable rest.<br/>Good for watching TV."]
            CONTEXT["Brighter than a movie theater<br/>but darker than a living room"]
            K2 --- LUX2 --- DIV --- GUIDE --- DESC --- CONTEXT
        end
        CARD2 --- FROZEN_BG["Frozen Camera Image<br/>(background stops moving, like a photo)"]
        FROZEN_BG --- TAB2
        subgraph TAB2["Bottom Tab Bar"]
            T2_1["LUX (selected)"]
            T2_2["Temperature"]
            T2_3["Find"]
            T2_4["Record"]
        end
    end
```

### Outdoor High-Lux Example

When pointing at bright outdoor scenes, the readings and interpretation update accordingly.

```mermaid
graph TD
    subgraph "Outdoor — Direct Sunlight"
        direction TB
        SB3["─── Status Bar ───"]
        SB3 --- CARD3
        subgraph CARD3["Frosted Glass Card (expanded)"]
            K3["5,000K"]
            LUX3["100,000 LUX (large text)"]
            DIV3["──── divider ────"]
            GUIDE3["User Guide"]
            DESC3["Strong sunlight.<br/>Protect your eyes and<br/>watch for plant burns."]
            K3 --- LUX3 --- DIV3 --- GUIDE3 --- DESC3
        end
        CARD3 --- OUTDOOR_BG["Outdoor Camera Feed<br/>(lake, sky, bright daylight)"]
        OUTDOOR_BG --- TAB3
        subgraph TAB3["Bottom Tab Bar"]
            T3_1["LUX (selected)"]
            T3_2["Temperature"]
            T3_3["Find"]
            T3_4["Record"]
        end
    end
```

### Record Detail — Tapped Card

Tapping a record card opens a full-screen view with the captured photo as background and lux + Kelvin interpretation overlaid.

```mermaid
graph TD
    subgraph "Record Detail View"
        direction TB
        CLOSE["✕ Close button (top-right)"]
        CLOSE --- PHOTO["Captured Photo<br/>(e.g. lamp in a room)"]
        PHOTO --- RLUX["120 LUX (large blue text)"]
        RLUX --- RLUX_DESC["Living room relaxation, dining, hotel rooms<br/>Optimal for comfortable rest.<br/>Good for watching TV."]
        RLUX_DESC --- RKELVIN["3,500K (large blue text)"]
        RKELVIN --- RKELVIN_DESC["Natural White 🌤<br/>Kitchens, dressing rooms, bathrooms"]
    end
```

### Records Screen — Card List

The Records tab shows saved measurement cards in reverse chronological order. Swipe left reveals a delete button.

```mermaid
graph TD
    subgraph "Records Screen"
        direction TB
        subgraph CARD_1["Record Card 1"]
            D1["10/12/2026  10:45 AM"]
            B1["Brightness: 120"]
            CT1["Color Temp: 3,500K"]
        end
        subgraph CARD_2["Record Card 2"]
            D2["10/09/2026  08:22 PM"]
            B2["Brightness: 150"]
            CT2["Color Temp: 3,650K"]
        end
        subgraph CARD_3["Record Card 3 (swiped left → 🗑 delete)"]
            D3["09/27/2026  06:32 AM"]
            B3["Brightness: 80"]
            CT3["Color Temp: 2,750K"]
        end
        CARD_1 --- CARD_2 --- CARD_3
        CARD_3 --- TAB_R
        subgraph TAB_R["Bottom Tab Bar"]
            TR1["LUX"]
            TR2["Color Temperature"]
            TR3["Check"]
            TR4["Records (selected)"]
        end
    end
```

### Screen Flow Overview

```mermaid
graph LR
    A["App Launch"] --> B["Main Screen<br/>(Live Camera + LUX)"]
    B -->|"Tap Capture ◯"| C["Captured Mode<br/>(Frozen BG + Interpretation)"]
    C -->|"‹ Back"| B
    B -->|"Tab: Temperature"| D["Color Temperature Tab"]
    B -->|"Tab: Find"| E["Find Tab"]
    B -->|"Tab: Record"| F["Records List"]
    F -->|"Tap Card"| G["Record Detail<br/>(Photo + LUX + Kelvin)"]
    G -->|"✕ Close"| F
    F -->|"Swipe Left"| H["Delete Record"]
    B -->|"⚙ Settings"| I["Settings Screen"]
    B -->|"🔄 Toggle"| J["Switch Front/Rear Camera"]
```
