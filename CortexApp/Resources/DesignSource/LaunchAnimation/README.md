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

`SplashAnimationView.swift` rebuilds the composition directly in SwiftUI. The runtime contains no movie, HTML, JavaScript, `WKWebView`, `AVPlayer`, or network access.

The supplied SVGs remain the design source. Runtime copies are rasterized as transparent Retina assets at 1x, 2x and 3x so the iOS compositor cannot rebase vector layers during the first SwiftUI frame. The scene itself is never flattened or scaled as one group: every design rectangle is converted directly into screen coordinates and placed using top-left `frame + offset`. SwiftUI animates the two scene lights, the two refracted lights, both caustics, logo frames, and crossfades. `CortexSplashShaders.metal` receives the current X/Y scale and applies the native 0.008 × 0.024 noise warp with seed 17 and displacement scale 17 in the original 739 × 1600 coordinate system.

The timeline is fixed to a 900 ms initial hold, an 800 ms transition using `cubic-bezier(1, 0.01, 0, 0.99)`, and a 50 ms final hold before the Home screen is released. The original SVGs remain untouched in `Frame1` and `Frame2`.
