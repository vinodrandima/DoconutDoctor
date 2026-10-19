# CoconutDoctor (DoconutDoctor)

An on-device iOS & iPadOS application built with SwiftUI, Core ML, and Vision to detect coconut leaf diseases offline for Sri Lankan coconut farmers.

## Features
- **On-Device Disease Classification**: Real-time diagnosis using `CoconutDoctor.mlpackage` (INT8 quantized Core ML model).
- **Target Disease Classes**:
  1. Bud Rot (`BudRot`)
  2. Grey Leaf Spot (`GreyLeafSpot`)
  3. Leaf Rot (`LeafRot`)
  4. Stem Bleeding (`StemBleeding`)
  5. Healthy Palm (`Healthy`)
- **Zero-Internet Architecture**: Inference runs completely offline on-device with pre-baked model normalization.
- **Modern Architecture**: SwiftUI + MVVM + Repository Pattern + Dependency Injection.
- **Hardware Integration**: In-app camera capture and photo gallery picker with permission handling.
- **Adaptive UI**: Optimized for iPhone and iPad with dark mode support.

## Tech Stack
- iOS 17.0+ / iPadOS 17.0+
- Swift 5.9+ / Swift 6 Concurrency
- Core ML & Vision Framework
- SwiftUI
