# <img src="animate_symbol_2d.png" alt="AnimateSymbol2D Node Icon" title="AnimateSymbol2D Node Icon" height=32> GDAnimate

A Godot plugin that adds the `AnimateSymbol2D` node, which lets you play back
Flash / Adobe Animate symbols like an `AnimatedSprite2D`.

## Features

### Format Support
* Sparrow Atlas
    - Overriding texture
    - Exporting to `SpriteFrames` to use outside of the plugin

* Texture Atlas
    - Animate **2020**+ Atlases (the older 2018 format has not been tested much, but if there is demand support may be added in the future)
    - [BetterTextureAtlas](https://github.com/Dot-Stuff/BetterTextureAtlas) Atlases
    - Easy individual symbol playback as well as stage playback
    - Color effects
    - Masking (only one layer deep)
    - Custom material support per blend mode
    - Baked filters (via [BTA](https://github.com/Dot-Stuff/BetterTextureAtlas))
    - Blend modes (via [BTA](https://github.com/Dot-Stuff/BetterTextureAtlas))
    - `Performance` rendering mode for simpler atlases to playback as efficiently as possible (`Full` has been optimized as much as I reasonably can and want to, but sometimes you just don't need any of the extra overhead)

### AnimateSymbol2D features

`AnimateSymbol2D` has plenty of features that previous iterations of GDAnimate were missing including:

* `centered`, `flip_h`, `flip_v` support (not 100% perfect on Texture Atlases)
* Symbol picker dropdown
* Playing in reverse
* Autoplaying animation on scene load
* `frame_progress` and signals for animation playback
* Multiple symbol libraries at once in a node (easily switch between with `symbol_library_index`)

## Compatibilty Notes

This plugin was created and designed primarily for use in Godot 4.7 at the time of its creation,
using versions of Godot before is unsupported and as newer Godot versions become stable the previous
stable versions generally become unsupported as well.

### For GDAnimate users before version 1.0

If you were using a previous version (especially one before any of the rewrites) you will have to
replace any old `AnimateSymbol` nodes with the new `AnimateSymbol2D`, ***and if you are confused as to
why your sprite is in the wrong place*** then make sure the symbol you currently have selected is
the **main one of the atlas**, not blank. The blank symbol refers to the stage and accounts automatically
for any stage transform that may have been applied. Previous versions of GDAnimate did not do this
and used the symbol without that transform, so switching to the symbol directly should solve the issue.
