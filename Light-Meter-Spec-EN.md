# Sunny Light Meter — Product Specification

## What Is It?

Sunny Light Meter is an iOS app that turns your iPhone camera into a real-time light measurement tool. Point your phone at any environment and instantly see the brightness (lux) and color temperature (Kelvin) of the light around you — along with plain-language interpretations of what those numbers mean.

The app is designed for anyone curious about their lighting environment: photographers checking exposure, parents evaluating nursery lighting, office workers wondering if their desk lamp is bright enough, or plant owners checking if their succulents are getting enough sun.

## How It Works

When you open the app, the camera activates and the live feed becomes the full-screen background. Overlaid on top is a frosted-glass card showing real-time readings:

- The current brightness in lux
- The current color temperature in Kelvin
- Both values update continuously as you move the phone

Tap the capture button to freeze the moment. The background stops moving (like taking a photo), and the card expands to show an interpretation: what kind of environment matches that brightness level, a practical tip, and a contextual comparison (e.g., "Brighter than a movie theater but darker than a living room").

## Target Devices

Baseline resolution: 1,179 × 2,556 pixels (iPhone 14 Pro, iPhone 15, iPhone 15 Pro)

Also supported at 1,170 × 2,532: iPhone 13, iPhone 14

The layout must be responsive across these resolutions. All text on the main screen uses fixed font sizes — system Dynamic Type settings must not affect the app layout. For accessibility balance, a capped scaling approach (max 1.2×) is acceptable.

## Core Features

### 1. Live Light Measurement

The primary experience. The camera feed fills the screen, and a translucent measurement card floats near the top showing:

- Color temperature (e.g., `3,800K`)
- Brightness (e.g., `120 LUX`) in large, prominent text

Both values stream in real time from the back camera's exposure metadata.

### 2. Capture & Interpret

A round capture button sits at the bottom of the screen. Tapping it:

1. Freezes the camera background (the image stops moving)
2. Expands the measurement card to show:
   - The lux range interpretation (environment description + user guide tip)
   - A contextual comparison sentence
3. A back arrow appears to return to live mode

### 3. Camera Toggle

A toggle button next to the capture button switches between front and rear cameras.

### 4. Lux Interpretation

Raw lux numbers are mapped to human-readable descriptions:

| Lux Range | Environment | User Guide Tip |
|-----------|------------|----------------|
| 0–10 | Very dark outdoors, full moon night | Pre-sleep conditions. Be careful when moving around. |
| 11–100 | Hallways, bathrooms, storage rooms, movie theaters | Suitable for passing through. Not appropriate for extended work. |
| 101–200 | Living room relaxation, dining, hotel rooms | Optimal for comfortable rest. Good for watching TV. |
| 201–500 | General office work, kitchen cooking, light reading | The most standard brightness for daily activities and office work. |
| 501–1,000 | Focused studying, precision handwork, store displays | Recommended for study rooms or detailed tasks like sewing. |
| 1,001–2,000 | Bright window (indoors), broadcast studios, operating rooms | Very bright. Suitable for video production or professional work. |
| 2,001–10,000 | Cloudy day outdoors, sunset outdoors | Good for outdoor activities. Partial shade level for plants. |
| 10,001+ | Direct sunlight on a clear day, noon outdoors | Strong sunlight. Protect your eyes and watch for plant burns. |

### 5. Color Temperature Interpretation

Raw Kelvin values are mapped to color tone labels and recommended environments:

| Kelvin | Color Tone | Recommended Environment |
|--------|-----------|------------------------|
| Below 2,000K | Candlelight / Sunset 🔥 | Psychological calm, pre-sleep, atmospheric cafes |
| 2,000K–3,499K | Warm White 💡 | Bedrooms, living rooms, relaxation spaces |
| 3,500K–4,999K | Natural White 🌤 | Kitchens, dressing rooms, bathrooms |
| 5,000K–6,499K | Daylight 📖 | Study rooms, offices, precision work (improves focus) |
| 6,500K–9,999K | Cool White ❄ | Hospitals, factories, warehouses |
| 10,000K+ | Blue Sky 🧊 | Clear day shade, specialized lab environments |


### 6. Flicker Detection & Eye Health

The app measures light flicker percentage to assess eye safety:

| Flicker % | Safety Level | Description |
|-----------|-------------|-------------|
| 0%–3% | Very Safe | Minimal eye fatigue even with prolonged use |
| 3%–10% | Safe | Sensitive individuals may feel mild dryness or fatigue with long exposure |
| 10%–30% | Caution | Noticeable eye pain, blurred focus, and discomfort may occur |
| 30%–60% | Dangerous | Severe eye fatigue, migraines, dizziness. Focus drops sharply |
| 60%+ | Very Dangerous | Visible flickering. Risk of nausea, photosensitive seizures for sensitive individuals |

A captured reading might show: `120 LUX / 3,500K / 5% Flicker` with contextual activity tags like "Reading & Study", "Office & Focus", "TV & Movies", "Sleep & Rest", "Baby & Childcare", etc.

### 7. Records

Every capture is automatically saved as a record card containing:

- Date and time
- Brightness (lux)
- Color temperature (Kelvin)

The Records tab displays cards in newest-first order. Swipe left on a card to reveal a delete button. Tapping a card opens a full-screen detail view showing the captured photo with lux and Kelvin interpretations overlaid.

Time format is localized:
- English/French/Spanish: suffix format (e.g., `09:45 AM`)
- Korean/Japanese/Chinese: prefix format (e.g., `오전 09:45`, `午後 11:10`)

### 8. Settings

A settings screen is accessible via the gear icon in the top-right corner. (Design details are maintained in a separate document.)

## App Navigation

The app uses a bottom tab bar with four tabs:

| Tab | Purpose |
|-----|---------|
| LUX | Main measurement screen with live camera background |
| Temperature | Color temperature focused view |
| Check | Light quality check (flicker analysis) |
| Records | Saved measurement history |

## UI Screen Reference

The following diagrams represent the key screens and user flows.

### Main Screen — Live Measurement (LUX Tab)

The live camera feed fills the screen. A frosted-glass card shows real-time lux and Kelvin. Capture and camera toggle buttons sit near the bottom.

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

Tapping capture freezes the background and expands the card with interpretation text.

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
            GUIDE["User Guide"]
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

Bright outdoor scenes produce high lux readings with corresponding interpretation.

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

Tapping a record opens a full-screen view with the captured photo and lux + Kelvin interpretations.

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

Saved measurements displayed as cards. Swipe left to delete.

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
    B -->|"Tab: Check"| E["Flicker Check Tab"]
    B -->|"Tab: Records"| F["Records List"]
    F -->|"Tap Card"| G["Record Detail<br/>(Photo + LUX + Kelvin)"]
    G -->|"✕ Close"| F
    F -->|"Swipe Left"| H["Delete Record"]
    B -->|"⚙ Settings"| I["Settings Screen"]
    B -->|"🔄 Toggle"| J["Switch Front/Rear Camera"]
```

## Implementation Progress

The app is being built incrementally through a series of specs:

```mermaid
graph TD
    subgraph "Spec 01 — Skeleton (Complete ✅)"
        A[Camera Session<br/>Back camera metadata] --> B[Lux Calculator<br/>Raw number]
        A --> C[Color Temp Calculator<br/>Raw Kelvin]
        B --> D[Measurement View<br/>Numbers only, black background]
        C --> D
    end

    subgraph "Spec 02 — Interpretation + Preview (In Progress 🔧)"
        E[Lux Interpreter<br/>8-range mapping] --> F[Updated Measurement View<br/>Numbers + descriptions + tips]
        G[Kelvin Interpreter<br/>6-range mapping] --> F
        H[Camera Preview<br/>Live feed background] --> F
    end

    subgraph "Future Specs"
        I[Capture & Freeze]
        J[Flicker Detection]
        K[Records System]
        L[Camera Toggle]
        M[Settings & Localization]
    end

    D -.->|"evolves into"| F
    F -.->|"next"| I
    I -.-> J -.-> K -.-> L -.-> M
```
