# Launch animation source

The approved animation uses the supplied 739 × 1600 reference frames and the exact timing defined by the user reference.

## Frame 1

- `glasslogo.svg`: 442 × 298, centered.
- `textlogo.svg`: 131 × 88, `#F1F1F1`, centered.
- `iconlogo.svg`: 66 × 53, black, centered.
- `lightsbackground.svg`: two `#313131` rectangles blurred with σ 23.4, positioned on the left.

## Frame 2

- `glasslogo.svg`: unchanged.
- `textlogo.svg`: 29 × 19, black, centered.
- `iconlogo.svg`: 164 × 131, `#F1F1F1`, centered.
- `lightsbackground.svg`: wider light rectangles positioned on the right.

## Runtime implementation

The exact visual result is rendered offline at 60 fps into `CortexSplashIntro.mp4`. The app plays this silent H.264 resource with `AVPlayerLayer`; no HTML, JavaScript, network request, or `WKWebView` is involved in the startup animation.

The timeline contains a 900 ms initial hold, an 800 ms transition using `cubic-bezier(1, 0.01, 0, 0.99)`, and two final display frames. `native-render-manifest.json` records the source and runtime hashes, dimensions, frame count, and duration. The original SVGs remain untouched in `Frame1` and `Frame2`.
