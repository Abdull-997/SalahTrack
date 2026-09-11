# Mosque launcher icon

Artwork: `mosque-icon.png`, created with the built-in image generation tool.
An ivory mosque and gold crescent on deep emerald, matching the app palette.

Run `powershell -ExecutionPolicy Bypass -File tool/export_app_icons.ps1` from
the repository root to export Android density variants and every iOS icon size.
The exports are stored under `native/` and copied into the platform projects.
Platform bootstrap also restores these exports.

## Generation prompt

Use case: logo-brand. Asset type: production mobile app launcher icon, one square 1024x1024 artwork, no mockup. Create a distinctive and beautifully crafted mosque icon for a calm prayer app. A sculptural warm ivory mosque with a broad elegant dome, two slender but clearly readable minarets, one deep emerald arched doorway, and a small warm brushed-gold crescent above the dome. Frontal, symmetrically balanced geometry, graceful Islamic architectural proportions, contemporary premium icon design, subtle shallow bas-relief depth and soft ambient shading, clean broad surfaces. Background: opaque deep emerald green (#123E32) filling the entire square edge to edge with extremely subtle tonal depth. Palette inspired by the app's forest green #276749 and warm ivory #F5F0E7, restrained gold accent. Mosque plus crescent must be wholly contained within the central 60% of canvas width and central 60% of canvas height, with ample uninterrupted emerald margin on ALL four sides so Android circular adaptive masks never clip the landmark. Large simple iconic shapes, legible at 48px, no tiny windows or ornament. Full square artwork with straight square corners; no rounded icon tile, no outer frame, no phone, no text, no lettering, no watermark, no stars, no photographic landscape. Make it feel quietly luminous, welcoming, memorable, and refined.
