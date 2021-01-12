This is a port of the crt-royale shader by TroggleMonkey from libretro to ReShade 4.8.3+.


#### CREDIT

The vast majority of the code here is taken from the current libretro shader repositories, so the most of the credit goes to those authors.

[libretro/glsl-shaders](https://github.com/libretro/glsl-shaders)<br>
[libretro/slang-shaders](https://github.com/libretro/slang-shaders)

Special thanks goes to crosire and co. for their work on ReShade, particularly for adding support for rectangular matrices and for ReShade's built-in debugging tools. Those features made this project orders of magnitude easier. And also thank you, Matsilagi, for your time, suggestions, testing, and debugging.


#### API SUPPORT
This shader should work with DX9, DX10/11/12, OpenGL, and Vulkan. It'll probably spit out a bunch of yellow error messages in DX9, but that's okay.


#### SETUP

1)  This shader requires ReShade 4.9+. It requires rectangular matrix multiplication that Crosire added in 4.9.

2)  The libretro implementation of crt-royale has the luxury of having the game's true viewport passed directly to it. The ReShade implementation by nature does not. This means the ReShade version by default grabs any letter-boxing as part of its input, and that throws off its geometry and phosphor calculations.

    To help with this, I've added a "debug mode" of sorts. You can enable it by setting `CONTENT_BOX_VISIBLE` to `1` in the global preprocessor definitions section of the ReShade UI. This will disable the main pipeline and swap to one that draws a box around the screen. Use `CONTENT_HEIGHT` and `CONTENT_WIDTH` to change the box's dimensions in pixels. Use `CONTENT_CENTER_X` and `CONTENT_CENTER_Y` to move the box left, right, up, or down as needed. Toggle `CONTENT_BOX_INSCRIBED` to switch between drawing the box inside the viewport or drawing outside the viewport. And use `CONTENT_BOX_THICKNESS` and the `CONTENT_BOX_COLOR` settings to change the thickness and color of the box's lines, just in case the defaults aren't visible enough.

    Once you've got the box aligned, you can switch off `CONTENT_BOX_VISIBLE`; and the main pipeline will use your settings to draw everything correctly.

    Be aware that, if you resize the game's viewport, you'll probably have to readjust these settings. You can mitigate this by defining `CONTENT_WIDTH` and `CONTENT_HEIGHT` algebraically in terms of `BUFFER_WIDTH` and `BUFFER_HEIGHT`, but you'll have to figure out the expressions for that on a case by case basis. As an example, if you know the content has a 4:3 aspect ratio and fills the screen vertically, you can define `CONTENT_HEIGHT` as `BUFFER_HEIGHT` and `CONTENT_WIDTH` as `CONTENT_HEIGHT * 4.0 / 3.0`.

3)  Focus primarily on setting the Mask Type, Mask Sample Mode, and Mask Triad Size. Sample Mode 0 tends to be smoother but dimmer, while Mode 1 tends to be sharper and brighter but more prone to artifacts. You'll usually get the best results with triad sizes 3, 6, 9, etc. Multiples of 0.5 also seem to work fairly well, but they might cause color issues. If you're using DX9, the Mask Type is set by a preprocessor definition `phosphor_mask_type` instead of a slider.

4)  Use the `USE_LARGE_PHOSPHOR_MASK` preprocessor definition to fix some artifacting with the phosphor mask. If you want a triad size larger than 8, you must set `USE_LARGE_PHOSPHOR_MASK` to 1, or you will get artifacts. If you have artifacting or color issues with a triad size of 3-8, try setting `USE_LARGE_PHOSPHOR_MASK` to 0.

5)  Use `Enable Interlacing` to toggle all things interlacing. This replaces all of the autodetection logic, so you have complete control over it now. Use `Scanline Thickness` to control the thickness of the scanlines in pixels. You might need to adjust your vsync settings to make these look good. They can be prone to jittering.

6)  Geom Mode, Geom Radius, and the `antialias_level` preprocessor definition are worth playing with; but I strongly recommend setting `CONTENT_HEIGHT` and `CONTENT_WIDTH` first. Meaningful values for `antialias_level` are 0, 1, 5, 6, 7, 8, 12, 16, 20, and 24. Values in between these will basically be rounded down to one of these.


#### NOTABLE CHANGES

For the most part, configuring this implementation of crt-royale should be the same as configuring the libretro versions, so refer to any past experience or to the existing documentation for help with that. I've left almost all of the code's comments intact, so you can also scroll through that for descriptions of the various preprocessor definitions. You should be able to find all of them in `user-settings.fxh`, `derived-settings-and-constants.fxh`, `bind-shader-params.fxh`, and `shared-objects.fxh`. The main difference is that you configure many preprocessor definitions by setting them to integer values rather than just defining them. This is to let users set them from ReShade's UI instead of editing the source code.

There are a handful of notable differences:
1)  Mask Sample Mode 0 has a new setting `Downsampling Sharpness`. You can use it to make Mode 0 look more similar to Mode 1 if you prefer something in between. I find this particularly useful for the Shadow mask.

2)  The scanline logic is now user-toggleable instead of autodetected, and you can change the thickness of the scanlines if you want.

3)  `PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS` and its siblings are still present. You can choose one or none of them by setting `PHOSPHOR_BLOOM_TRIAD_SIZE_MODE` to a value in range `[0 - 4]`. This is defined in `user-settings.fxh`.

4)  The same is true for `SIMULATE_CRT_ON_LCD` and its siblings. Set `GAMMA_SIMULATION_MODE` to `[0 - 4]` to control which of those is active. This is defined in `derived-settings-and-constants.fxh`.

5)  Most of the "RUNTIME_...", "ANISOTROPIC_...", "DRIVERS_ALLOW_...", and other performance-related preprocessor definitions are either hidden from the UI or gone. Some of them are extremely difficult to port correctly. Some of them either don't do anything anymore or never did anything to begin with. And some of them I'll be adding back later, but I'll have to refactor them and the affected code to make them more user-friendly.

6)  I've exposed `antialias_filter`, `antialias_level`, and `antialias_temporal` as preprocessor definitions. Note that the code dedicated to having `antialias_level` set to `4` is disabled for now because it's currently broken.

7)  In DX9, the Mask Type is set by a preprocessor definition `phosphor_mask_type`. It can be either 0 for the Grille mask, 1 for the Slot mask, or 2 for the Shadow mask.


#### QUALITATIVE DIFFERENCES

The biggest change for me is the phosphor mask - it tiles differently in ReShade for some odd reason, although I think it looks better now. The side effect is that setting Mask Sample Mode to 1 was too purple in the libretro implementation while it's arguably too bright now.

I've also noticed that the bloom is more pronounced in this implementation. It might be because of a tweak I made to the write-operation at the end of `crt-royale-bloom-approx.fxh`, but that's just a guess.


#### REPORTING DISCREPANCIES

My goal was to replicate crt-royale with the only discrepancies being improvements, but I only use a narrow range of configurations; and crt-royale has a stupendous number of settings that can all break in weird ways. It's pretty much guaranteed some configurations don't work correctly. If you try to port your RetroArch crt-royale config to this implementation, let me know if you find any significant differences. I especially want to know about any configs that work correctly in RetroArch but crash in ReShade, or are performant in RetroArch but unplayable in ReShade.

Please bear in mind that, if the discrepancy involves dark colors getting crushed, I can't promise anything. The libretro implementation uses an 8-bit SRGB encoding that, as far as I can tell, isn't currently available in ReShade. I've tried to compensate with a 16-bit UNORM encoding, but that isn't perfect.