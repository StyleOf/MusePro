# MusePro

**Realtime AI guided by your hand.**

<p align="center">
  <a href="https://apps.apple.com/us/app/muse-pro/id6475118587"><img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="50"/></a>
  &nbsp;&nbsp;
  <a href="https://www.producthunt.com/posts/muse-pro"><img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-badge.svg?post_id=442693&theme=dark&period=daily" alt="Product Hunt" height="50"/></a>
</p>

Own the composition and elevate your creativity. MusePro is the next generation of drawing tools - a professional-grade app for iOS and visionOS where your Apple Pencil strokes guide real-time AI image generation.

<p align="center" width="100%">
  <video src="https://github.com/user-attachments/assets/496e5681-70d2-4411-a394-3c1ff0eee2a1" width="80%" controls></video>
</p>

## See It In Action

<table>
<tr>
<td align="center"><b>App Overview</b></td>
<td align="center"><b>Realtime Generation</b></td>
</tr>
<tr>
<td><video src="https://github.com/user-attachments/assets/87f4926c-22c4-4b52-95cc-42f633ede3ac" width="400" controls></video></td>
<td><video src="https://github.com/user-attachments/assets/c466a3dd-e2b8-40db-b860-6d81e64880b6" width="400" controls></video></td>
</tr>
<tr>
<td align="center"><b>Prompting & Vision</b></td>
<td align="center"><b>AI Control</b></td>
</tr>
<tr>
<td><video src="https://github.com/user-attachments/assets/c76b0ef8-905f-407f-b60c-3c975e30b1de" width="400" controls></video></td>
<td><video src="https://github.com/user-attachments/assets/2926d590-7524-44ac-861b-37c0b3e66109" width="400" controls></video></td>
</tr>
<tr>
<td align="center"><b>Enhance & Upscale</b></td>
<td align="center"><b>Assets & Shapes</b></td>
</tr>
<tr>
<td><video src="https://github.com/user-attachments/assets/b03e2818-85a1-4daf-a69c-9d7e086f41e6" width="400" controls></video></td>
<td><video src="https://github.com/user-attachments/assets/e3e3d54b-0ea7-4c01-951f-60c3b517a3ac" width="400" controls></video></td>
</tr>
</table>

---

## A Magical Toolset

Unleash your creativity with familiar tools and groundbreaking AI.

### Realtime AI Generation

**Watch your vision unfold as your strokes guide the AI.**

Your drawings transform as you create them - not after. The AI follows your composition, respecting your artistic intent while adding stunning detail in real-time.

- Full Apple Pencil support with pressure sensitivity
- Sub-second inference via WebSocket streaming
- Powered by Latent Consistency Models for instant results
- SDXL-quality outputs with minimal latency

### Intelligent Prompting

**Guide the AI with prompts to bring your ideas to life.**

- **Text-to-Image** - Quickly change directions with words
- **Randomize** - Never face a blank canvas again
- **Enhance** - Beautiful detail with a tap
- **Vision** - Your drawing described by GPT-4 Vision

### AI Control

**Fine-tune the AI with intuitive sliders. You're always in control.**

- Shuffle the seed to explore endless possibilities
- Pause to put AI collaboration on hold
- Adjust influence strength to balance your drawing vs AI interpretation

### One-Tap Enhancement

**Enhance details and polish your masterpiece.**

- **2x Upscaling** - Print-ready outputs from your sketches
- **Creative Enhancement** - Sliders help bring rough concepts to life
- **Background Removal** - Clean cutouts instantly

### Professional Layer System

**Experiment and refine effortlessly with layers.**

| Layers | Brushes |
|:---:|:---:|
| ![Layers](https://cdn.prod.website-files.com/65dcad0fb21096e8c41cfd96/65e7e3255598890c627fbefd_feature-layers.png) | ![Brushes](https://cdn.prod.website-files.com/65dcad0fb21096e8c41cfd96/65e8922d0fdf7cb0b55f7336_feature-brushes.png) |

- Unlimited layers with 16 blend modes
- Per-layer opacity and locking
- Drag & drop reordering

### Assets & Tools

**Infuse your art with shapes, images, and text.**

Import photos, add geometric shapes, and incorporate typography directly into your canvas as composition guides.

### Diverse Brush Library

**A brush library for every artistic dream.**

17+ brush categories from dry media to vintage effects, all with full pressure and tilt sensitivity. Compatible with Procreate brushes.

---

## Technical Excellence

This isn't a wrapper around an API. MusePro is built from the ground up with custom technology.

### Custom Metal Rendering Engine

- **120 FPS rendering** - Buttery smooth on ProMotion displays
- **GPU-accelerated compositing** - Zero lag layer blending
- **Hand-written Metal shaders** - Custom brush rendering and blend modes
- **Texture-based brush system** - Grain textures, shape dynamics, pressure curves
- **Smart memory management** - Efficient texture caching and buffer handling

### The Rendering Pipeline

1. **Stroke Capture** - Apple Pencil events at 240Hz with position, pressure, tilt, azimuth
2. **Bezier Generation** - Raw input to smooth curves preserving natural dynamics
3. **Brush Stamping** - Textured quads along curves with configurable blending
4. **Layer Compositing** - Per-layer textures with GPU blend modes
5. **Display** - Final composite at up to 120fps

### Real-Time AI Integration

1. **Canvas Snapshot** - Current state captured and compressed
2. **WebSocket Stream** - Persistent connection to Fal.ai inference
3. **Incremental Updates** - Results stream without blocking UI
4. **Graceful Handling** - Connection drops, retries, rate limiting

---

## Architecture

```
MusePro/
├── Canvas/           # Metal rendering engine & canvas management
├── Brush/            # Brush system with texture support
├── BrushSets/        # Pre-built brush libraries
├── MetalBase/        # Core Metal infrastructure & shaders
├── Elements/         # Drawing primitives (lines, shapes, chartlets)
├── Enhancer/         # AI upscaling & enhancement views
├── Tools/            # UI components (color picker, layers, controls)
├── Data & Documents/ # Document system, storage, undo/redo
├── Math & Utils/     # Bezier curves, gesture recognition, utilities
└── Colors.xcassets/  # Color palette definitions
```

---

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 16.4+ / visionOS 1.0+
- Apple Developer account (for device deployment)

### Configuration

1. Clone the repository:
   ```bash
   git clone https://github.com/StyleOf/MusePro.git
   cd MusePro
   ```

2. Set up your API keys:

   **`GoogleService-Info.plist`** - Firebase configuration
   ```xml
   <key>API_KEY</key>
   <string>YOUR_FIREBASE_API_KEY</string>
   ```

   **`RemoteConfigDefaults.plist`** - Fal.ai API key
   ```xml
   <key>falKey</key>
   <string>YOUR_FAL_AI_API_KEY</string>
   ```

   **`UserManager.swift`** - RevenueCat (for subscriptions, optional)
   ```swift
   Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")
   ```

   **`App.swift`** - Intercom (for support, optional)
   ```swift
   Intercom.setApiKey("YOUR_INTERCOM_API_KEY", forAppId: "YOUR_APP_ID")
   ```

   **`LiveImageModel.swift`** - OpenAI (for prompt enhancement)
   ```swift
   let openAI = OpenAI(apiToken: "YOUR_OPENAI_API_KEY")
   ```

3. Update the bundle identifier to your own

4. Build and run!

### Dependencies

Managed via Swift Package Manager:

| Dependency | Purpose |
|------------|---------|
| Firebase | Analytics, Remote Config |
| RevenueCat | Subscription management |
| FalClient | Real-time AI inference |
| OpenAI | GPT-4 prompt enhancement |
| Intercom | Customer support |
| Kingfisher | Image caching |
| ZIPFoundation | Document compression |

---

## Platform Support

| Platform | Version | Status |
|----------|---------|--------|
| iPhone | iOS 16.4+ | Full Support |
| iPad | iPadOS 16.4+ | Full Support (Optimized) |
| Vision Pro | visionOS 1.0+ | Full Support |

---

## Using MusePro?

We'd love to hear about it! While not required, please consider:
- Starring this repo
- Sharing your project with us on [Twitter/X](https://x.com/styleofapp)
- Crediting MusePro in your app's about section

## Contributing

Contributions are welcome! Feel free to:

- Report bugs and request features via Issues
- Submit Pull Requests for improvements
- Share your creations made with MusePro

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Custom Metal rendering engine built with love
- AI powered by [Fal.ai](https://fal.ai)
- Originally developed by [Omer Karisman](https://github.com/okaris)

---

<p align="center">
  <i>Made for artists and creators who want to own their composition while embracing AI collaboration.</i>
</p>
