[README.md](https://github.com/user-attachments/files/33116000/README.md)
# AppVersal — Gallery Cleaner (iOS)

A modern, high-performance iOS Gallery Cleaner built with **SwiftUI**, **PhotoKit**, and **Swift Concurrency**. Engineered for maximum speed, 100% on-device privacy, and seamless photo library management.

---

## 🌟 Key Highlights

- **⚡ Blazing Fast On-Device Analysis:** Instant scanning using metadata clustering and streamed hash fingerprinting. No UI freezing, zero background memory leaks.
- **🔒 100% Private & Offline:** Zero external network calls or cloud uploads. All photo library analysis runs locally on the device.
- **🛡️ Two-Stage Safe Deletion:** Items are moved to an in-app **Trash** bin first, allowing instant restoration before permanent deletion.
- **🎨 Native Apple Human Interface Guidelines (HIG):** Adaptive grid, interactive swipe cards, dynamic system blur, native haptic feedback, and fluid spring animations.

---

## 📱 Features & Modules

| Category | Description | Performance & Logic |
| :--- | :--- | :--- |
| 📸 **Similar Photos** | Groups burst shots, continuous exposures, and duplicate poses taken within close time windows. | **Chronological & Aspect-Ratio Clustering:** Clusters shots taken within 90s with matching aspect ratios. Identifies **Best Shot** (highest resolution/size) and enables **1-Tap Auto-Select** for inferior photos. |
| 📑 **Duplicate Photos** | Detects exact photo duplicates across the gallery. | Tiered deterministic hashing (resolution matching + SHA-256 fingerprinting) avoiding unnecessary image decodes. |
| 🎬 **Duplicate Videos** | Finds identical video recordings and saved duplicates. | Duration bucketing + bounded chunk stream hashing (64KB header + trailer). |
| 🎥 **Similar Videos** | Identifies repetitive or continuous video takes. | Evaluates timestamp proximity, dimensions, and duration delta. |
| 🐘 **Large Videos** | Highlights videos consuming the most storage space. | Sorted strictly descending by byte size with human-readable formatting. |
| 📱 **Screenshots** | Isolates screen captures and device snips. | Uses `PHAssetMediaSubtype.photoScreenshot` and dimensional pattern heuristics. |
| 🗑️ **Trash Bin** | In-app recovery station for deleted media. | Safe-stage quarantine with Restore and Permanent Deletion capabilities. |
| 🗓️ **Date Filtering** | Filter any view by time period. | Instant multi-option filtering: All Time, Past Week, Past Month, Past Year. |

---

## 🚀 Similar Photos Engine (Gallery Cleaner Architecture)

The similarity detection engine in **AppVersal** employs a battle-tested chronological clustering pipeline:

1. **Chronological Sorting:** Photos are sorted chronologically ($O(N \log N)$).
2. **Temporal Proximity Window:** Adjacent items within a $\le 90\text{s}$ time window (or burst takes within $\le 10\text{s}$) are evaluated.
3. **Aspect-Ratio & Orientation Invariance:** Computes relative aspect ratios ($W/H$ and $H/W$) with a tight tolerance ($\Delta < 0.15$).
4. **Best Shot Keeper Selection:** Evaluates pixel resolution ($W \times H$) and file size to crown the highest-quality photo as **`BEST`**.
5. **Smart Auto-Select:** Automatically pre-selects all inferior/redundant shots so the user can reclaim space in a single tap while preserving the best memory.
6. **Reclaimable Space Calculation:** Dynamically calculates potential storage savings in real-time.

---

## 🏗️ Architecture & Project Structure

The project follows the clean **MVVM + Actor-isolated Services** pattern:

```text
AppVersal/
├── AppVersalApp.swift                 # App entry point & lifecycle
├── ContentView.swift                  # Navigation shell & root router
├── Core/
│   ├── Analysis/
│   │   ├── SimilarPhotoAnalyzer.swift   # High-speed chronological clustering engine
│   │   ├── SimilarVideoAnalyzer.swift   # Video similarity analyzer
│   │   ├── DuplicatePhotoAnalyzer.swift # Tiered image SHA-256 duplicate detector
│   │   ├── DuplicateVideoAnalyzer.swift # Video chunk hashing engine
│   │   └── GalleryAnalysisActor.swift   # Isolated background global actor
│   ├── Photos/
│   │   ├── PhotoLibraryService.swift    # PhotoKit fetchers & change observer
│   │   └── PhotoAuthorizationService.swift # Granular permission flow handler
│   ├── Media/
│   │   ├── TrashManager.swift           # In-app trash persistence & restore engine
│   │   ├── MediaThumbnailService.swift  # Cached PHImageManager thumbnail pipeline
│   │   └── HeroThumbnailCache.swift     # High-priority preview cache
│   └── Utilities/
│       ├── ByteFormatter.swift          # Human-readable size converter (MB/GB)
│       └── Logger.swift                 # Unified Apple OSLog logging
├── Models/
│   ├── MediaItem.swift                # Core domain model for photos & videos
│   ├── SimilarGroup.swift             # Grouping model with bestItem & reclaimable space
│   ├── DuplicateGroup.swift           # Exact duplicate cluster model
│   ├── MediaCategory.swift            # 7 cleaner categories & metadata
│   ├── AnalysisState.swift            # State enum (idle, loading, loaded, empty, error)
│   └── DateFilterOption.swift         # Date filtering options
├── Features/
│   ├── Home/                          # Storage breakdown dashboard & category cards
│   ├── SimilarPhotos/                 # Similar photos view with auto-select & Best badge
│   ├── SimilarVideos/                 # Similar videos review interface
│   ├── DuplicatePhotos/               # Exact duplicate photos cleaner
│   ├── DuplicateVideos/               # Exact duplicate videos cleaner
│   ├── LargeVideos/                   # Storage-sorted large video manager
│   ├── Screenshots/                   # Dedicated screenshots clean-up view
│   ├── Trash/                         # Restore or permanent purge bin
│   └── Explore/                       # Interactive swipe-deck timeline review
└── DesignSystem/
    ├── AppTheme.swift                 # Color tokens, typography, spacing, corner radii
    └── Components/
        ├── ThumbnailCell.swift        # Async thumbnail cell with BEST badge & selection
        ├── NativeDeleteBottomBar.swift # Liquid floating delete bar
        ├── DateFilterBar.swift        # Capsule filter selector
        ├── ProgressHeader.swift       # Linear progress header during analysis
        └── EmptyStateView.swift       # Delightful vector empty states
```

---

## ⚙️ Technical Requirements

- **iOS Deployment Target:** iOS 17.0+
- **Xcode Version:** Xcode 15.0 or later
- **Language:** Swift 5.9 / Swift 6 compatible
- **Frameworks:** SwiftUI, PhotoKit, PhotosUI, CryptoKit, OSLog

---



## 🔒 Permissions & Privacy

In your `Info.plist`, ensure the following keys are set:
- `NSPhotoLibraryUsageDescription`: *"AppVersal requires access to your photos to identify duplicate and similar media."*
- `NSPhotoLibraryAddUsageDescription`: *"AppVersal requires photo library write permissions to clean and organize media."*

---

## 📄 License

Developed for personal and commercial gallery optimization. All rights reserved.
