This is a port of the crt-royale shader by TroggleMonkey from libretro to ReShade 4.8.3+.


#### CREDIT

The vast majority of the code here is taken from the current libretro shader repositories, so the most of the credit goes to those authors.

[libretro/glsl-shaders](https://github.com/libretro/glsl-shaders)<br>
[libretro/slang-shaders](https://github.com/libretro/slang-shaders)

Special thanks goes to crosire and co. for their work on ReShade, particularly for adding support for rectangular matrices and for ReShade's built-in debugging tools. Those features made this project orders of magnitude easier.


#### API SUPPORT
This shader works with D3D10, D3D11, D3D12, and OpenGL. Please report any issues with those APIs because they shouldn't be there.

This shader currently does not support D3D9 or Vulkan. D3D9 doesn't permit enough registers or something, while Vulkan crashes and does some of the math incorrectly. I'm still debugging these issues and can't promise anything with them.


#### SETUP

1)  As of this writing, ReShade 4.8.3 isn't actually released yet. So you'll have to build it, install it, and install the base shader repository. Remember to clone ReShade's repository with `--recurse-submodules`. Also remember to edit `version.h` in the ReShade source, so your executable thinks it's at least version 4. Otherwise ReShade.fxh will blow up and fuss at you. [ReShade's git repository](https://github.com/crosire/reshade) has instructions for building an installer from source.

	Once you have that working, paste the contents of my `reshade-shaders/` directory into your installation's `reshade-shaders/` directory.

2)  The libretro implementation of crt-royale has the luxury of having the game's true viewport passed directly to it. The ReShade implementation by nature does not. This means the ReShade version by default grabs any letter-boxing as part of its input, and that throws off its geometry and phosphor calculations.

    To help with this, I've added a "debug mode" of sorts. You can enable it by setting `CONTENT_BOX_VISIBLE` to `1` in the global preprocessor definitions section of the ReShade UI. This will disable the main pipeline and swap to one that draws a box around the screen. Use `CONTENT_HEIGHT` and `CONTENT_WIDTH` to change the box's dimensions in pixels. Use `CONTENT_CENTER_X` and `CONTENT_CENTER_Y` to move the box left, right, up, or down as needed. Toggle `CONTENT_BOX_INSCRIBED` to switch between drawing the box inside the viewport or drawing outside the viewport. And use `CONTENT_BOX_THICKNESS` and the `CONTENT_BOX_COLOR` settings to change the thickness and color of the box's lines, just in case the defaults aren't visible enough.

    Once you've got the box aligned, you can switch off `CONTENT_BOX_VISIBLE`; and the main pipeline will use your settings to draw everything correctly.

    Be aware that, if you resize the game's viewport, you'll probably have to readjust these settings. You can mitigate this by defining `CONTENT_WIDTH` and `CONTENT_HEIGHT` algebraically in terms of `BUFFER_WIDTH` and `BUFFER_HEIGHT`, but you'll have to figure out the expressions for that on a case by case basis. As an example, if you know the content has a 4:3 aspect ratio and fills the screen vertically, you can define `CONTENT_HEIGHT` as `BUFFER_HEIGHT` and `CONTENT_WIDTH` as `CONTENT_HEIGHT * 4.0 / 3.0`.


#### CONFIGURATION

For the most part, configuring this implementation of crt-royale should be the same as configuring the libretro versions, so refer to any past experience or to the existing documentation for help with that. I've left almost all of the code's comments
intact, so you can also scroll through that for descriptions of the various preprocessor definitions. You should be able to find all of them in `user-settings.fxh`, `derived-settings-and-constants.fxh`, `bind-shader-params.fxh`, and `shared-objects.fxh`. The main difference is that you configure many preprocessor definitions by setting them to integer values rather than just defining them. This is to let users set them from ReShade's UI instead of editing the source code.

There are a handful of notable differences:
1)  `PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS` and its siblings are still present, but instead of defining one of them at a time, you set `PHOSPHOR_BLOOM_TRIAD_SIZE_MODE` to a value in range `[0 - 4]`. This is defined in `user-settings.fxh`.

2)  The same is true for `SIMULATE_CRT_ON_LCD` and its siblings. Set `GAMMA_SIMULATION_MODE` to `[0 - 4]` to control which of those is active. This is defined in `derived-settings-and-constants.fxh`.

3)  `RUNTIME_GEOMETRY_TILT`, `GAMMA_ENCODE_EVERY_FBO`, and `RUNTIME_SHADER_PARAMS_ENABLE` are currently not configurable. Disabling runtime geometry-tilt requires defining global constants with sin() and cos(), which is not possible in ReShade. Enabling `GAMMA_ENCODE_EVERY_FBO` introduces some control-flow wonkiness that I haven't gotten around to dealing with yet, so for now all intermediate buffers use gamma 1.0 and never ntsc_gamma. `RUNTIME_SHADER_PARAMS_ENABLE` required a ton more copy/pasting that I haven't felt like doing yet.

4)  I figured out that the default anti-aliasing setting was way too strong, so I turned it into a preprocessor definition antialias_level and defaulted it to 0. This is defined in `user-settings.fxh`.


#### QUALITATIVE DIFFERENCES

The biggest change for me is the phosphor mask - it tiles differently in ReShade for some odd reason, although I think it looks better now. The side effect is that setting Mask Sample Mode to 1 was too purple in the libretro implementation while it's arguably too bright now.

I've also noticed that the bloom is more pronounced in this implementation. It might be because of a tweak I made to the write-operation at the end of `crt-royale-bloom-approx.fxh`, but that's just a guess.


#### REPORTING DISCREPANCIES

My goal was to replicate crt-royale with the only discrepancies being improvements, but I only use a narrow range of configurations; and crt-royale has a stupendous number of settings that can all break in weird ways. It's pretty much guaranteed some configurations don't work correctly. If you try to port your RetroArch crt-royale config to this implementation, let me know if you find any significant differences. I especially want to know about any configs that work correctly in RetroArch but crash in ReShade, or are performant in RetroArch but unplayable in ReShade.

Please bear in mind that, if the discrepancy involves dark colors getting crushed, I can't promise anything. The libretro implementation uses an 8-bit SRGB encoding that, as far as I can tell, isn't currently available in ReShade. I've tried to compensate with a 16-bit UNORM encoding, but that isn't perfect.