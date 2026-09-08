# Screen text-rendering recommendations

These recommendations are for the current KDE Plasma Wayland system on `fn`, using native resolution and 100% display scaling unless stated otherwise.

## Screen summary

| Screen | Current identification | Native/current mode | Approx. pixel density | Current scale |
| --- | --- | --- | ---: | ---: |
| Framework 16 builtin (`eDP-1`) | BOE `NE160QDM-NZ6` | 2560×1600 @ 165 Hz | ~189 PPI | 125% |
| ASUS external (`DP-3`) | ASUS VG34V-class display | 3440×1440 @ 144 Hz | ~109–110 PPI | 100% |

The Framework panel is identified locally from its EDID as `NE160QDM-NZ6`. Framework specifies the Laptop 16 display as a 16-inch, 2560×1600, 165 Hz panel. The ASUS profile is identified locally as `AUS 13365 113755`; its stored ICC profile is for the VG34V family. See the [Framework specifications](https://frame.work/laptop16?tab=specs) and [ASUS VG34VQL1B specifications](https://www.asus.com/uk/displays-desktops/monitors/tuf-gaming/tuf-gaming-vg34vql1b/techspec/).

## Common rendering settings

- **Anti-aliasing:** enabled.
- **Anti-aliasing range exclusion:** disabled; do not exclude any font-size range.
- **Hinting:** `slight` / `hintslight`.
- **Force font DPI:** disabled or automatic.
- **Subpixel rendering:** use `RGB` for a normal landscape RGB-stripe panel. Use `None` if colored fringes are visible or if a Wayland application renders more cleanly without subpixel filtering.
- **Do not use `VBGR`** for these normally oriented displays unless direct visual testing proves that it is correct for the individual panel.

Slight hinting provides useful vertical alignment at small sizes while retaining the font's intended widths, curves, and spacing. Full hinting applies more aggressive pixel-grid fitting and can make modern fonts look heavy or distorted. At the Framework's higher density, hinting has a smaller effect, but `slight` remains the safest consistent setting. See [FreeType's text-rendering guidance](https://freetype.org/freetype2/docs/hinting/text-rendering-general.html) and [KDE's font settings documentation](https://docs.kde.org/stable_kf6/en/plasma-workspace/kcontrol/fonts/index.html).

## ASUS at 100% scaling

Recommended sizes:

- **Fira Sans/UI:** 10 pt default; 9 pt minimum for regular text.
- **Fira Code/terminals:** 10 pt is a good baseline; 11–12 pt is more comfortable for sustained use.
- **Smallest readable font:** 8 pt, limited to compact labels and secondary UI.

For the ASUS's lower pixel density, `RGB` subpixel rendering is more likely to provide a visible sharpness benefit. If colored edges appear around text, switch to `None`.

## Framework 16 at 100% scaling

Recommended sizes:

- **Fira Sans/UI:** 11–12 pt; 10 pt is the practical minimum.
- **Fira Code/terminals:** 12 pt baseline; 13 pt is more comfortable for sustained use.
- **Smallest readable font:** 9–10 pt; use 10 pt if this is meant to be a genuine system-wide minimum.

The Framework panel is about 1.7 times as dense as the ASUS. At 100% scaling, 10 pt text is therefore much smaller physically even though it is rendered smoothly. The current 125% Framework profile makes 10 pt appear approximately like 12.5 pt at 100%, which explains why 12–13 pt is the better 100% terminal size.

At this density, `RGB` is acceptable when it looks clean, but the benefit over grayscale (`None`) is smaller. For Wayland applications, choose whichever looks cleaner on the panel; do not force subpixel rendering merely to maximize theoretical horizontal resolution.

## Current configuration note

The current KDE font settings are already `antialiasing=true`, `hintslight`, and `XftSubPixel=rgb`. The generated Fontconfig policy still forces `rgba=vbgr`, so it should be changed to `rgb` or `none` if these recommendations are applied consistently. The declarative WezTerm and Kitty settings are now 10 pt; at 100% scaling on the Framework, 12–13 pt is the more comfortable choice.
