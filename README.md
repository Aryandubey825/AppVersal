[Uploading README.md…]()
# Gallery Cleaner — Production iOS Application

An iOS Gallery Cleaner built with Swift, SwiftUI, PhotoKit, and Apple's Vision framework.

## 📱 Features

- **Screenshots:** Instantly enumerates screen captures using `PHAssetMediaSubtype.photoScreenshot`.
- **Videos:** Displays all recorded video assets lazily with duration and storage metrics.
- **Duplicate Photos:** Identifies exact photo duplicates using tiered deterministic fingerprinting (size, pixel dimensions, and CryptoKit SHA-256).
- **Similar Photos:** Detects visually similar shots using candidate temporal bucketing and Apple's Vision framework (`VNGenerateImageFeaturePrintRequest`).
- **Duplicate Videos:** Finds exact video duplicates via duration pre-filtering and 64KB chunk stream hashing without memory pressure.
- **Large Videos:** Ranks video files strictly largest-first with human-readable size formatting (`ByteCountFormatter`).

---

## 🏗️ Architecture

The app adopts a clean MVVM + Actor-isolated Service architecture:

```text
AppVersal/
├── App/                # App entry point & environment configuration
├── Core/
│   ├── Photos/         # PhotoKit authorization, change observers, and fetchers
│   ├── Media/          # Image caching service wrapping PHCachingImageManager
│   ├── Analysis/       # Actor-isolated background engines for duplicate/similarity analysis
│   └── Utilities/      # Byte formatters and structured OSLog logger
├── Models/             # Domain models (MediaItem, DuplicateGroup, SimilarGroup, AnalysisState)
├── Features/           # View & ViewModel pairs for Home and all 6 categories
└── DesignSystem/       # AppTheme tokens, cards, thumbnail cells, progress headers, empty states
```

---

## 🔬 Algorithmic & Performance Strategy

1. **Exact Duplicate Photo Hashing:** Avoids heavy decoding by pre-filtering assets by file size and pixel resolution before executing SHA-256 data hashing on candidates.
2. **Visual Similarity Candidate Bucketing:** Avoids $O(N^2)$ visual comparison explosions by clustering photos shot within 10-minute time windows before generating Vision feature vectors.
3. **Duplicate Video Chunk Hashing:** Computes fingerprints via bounded byte streams (64KB head + 64KB tail), keeping RAM consumption under 10MB during video analysis.
4. **Main-Thread Safety:** All heavy analysis is offloaded to a dedicated `@GalleryAnalysisActor`. Progress updates stream continuously via `AsyncStream<AnalysisProgress>`.

---

## 🔐 Privacy & Permission Strategy

- **100% On-Device Processing:** Zero cloud uploads or external AI dependencies. All analysis is local using native Apple frameworks (`PhotoKit` & `Vision`).
- **Permission States:** Gracefully manages `authorized`, `limited`, `denied`, and `notDetermined` PhotoKit permission states.
- **Zero Sensitive Data Logging:** `OSLog` telemetry excludes media contents and PII.

---

## 🚀 How to Run

1. Open `AppVersal/AppVersal.xcodeproj` in **Xcode 15.0+**.
2. Select an iOS 17.0+ Simulator or attached physical iOS device.
3. Press **⌘R** to build and launch the application.

---

## 🧪 Testing

Unit tests covering formatters, domain models, and analyzer logic are located in `AppVersal/AppVersalTests/`. Run using **⌘U** in Xcode.
