# Launch animation source

The animation is based on the supplied 739 × 1600 reference frames.

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

The native transition lasts 800 ms and uses `cubic-bezier(1, 0.01, 0, 0.99)`. The original SVGs remain untouched in `Frame1` and `Frame2`; runtime masks live in the asset catalog.
