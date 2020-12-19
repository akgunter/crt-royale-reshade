This is a port of the crt-royale shader by TroggleMonkey from libretro to
ReShade 4.8.3+.


################# CREDIT #################

The vast majority of the code here is copy/pasted from the current libretro
shader repositories, so the vast majority of the credit goes to those authors.

libretro/glsl-shaders:      https://github.com/libretro/glsl-shaders
libretro/slang-shaders:     https://github.com/libretro/slang-shaders

Special thanks goes to crosire and co. for their work on ReShade, particularly
for adding support for rectangular matrices and for ReShade's built-in
debugging tools. Those features made this project orders of magnitude easier.



################# SETUP #################

0)  For now, this shader only works for OpenGL and D3D12 applications. D3D9
    doesn't permit enough registers, and D3D11 just shows a black screen for
    some reason. I haven't tested a D3D10 application yet, but it probably
    doesn't work either.

1)  As of this writing, ReShade 4.8.3 isn't actually released yet. So you'll
    have to build it, install it, and install the base shader repo.
    Remember to edit/replace version.h in the ReShade source, so your
    executable thinks it's at least version 4. Otherwise ReShade.fxh will
    blow up and fuss at you. ReShade's git repository has instructions for
    building an installer from source: https://github.com/crosire/reshade

    Once you have that working, paste the contents of my src/ directory into
    your reshade-shaders/ directory.

2)  The libretro verson of crt-royale has the luxury of having the game's true
    viewport passed directly to it. The ReShade version by nature does not.
    This means the ReShade version by default grabs any letterboxing as part
    of its input, and that throws off its geometry and phosphor calculations.

    To help with this, I've added a "debug mode" of sorts. You can enable it
    by setting CONTENT_BOX_VISIBLE to 1 in the global preprocessor definitions
    section of the ReShade UI. This will disable the main pipeline and swap
    to one that draws a box around the screen. Use CONTENT_HEIGHT and
    CONTENT_WIDTH to change the box's dimensions in pixels. Use
    CONTENT_CENTER_X and CONTENT_CENTER_Y to move the box left, right, up, or
    down as needed. Toggle CONTENT_BOX_INSCRIBED to switch between drawing the
    box inside the viewport or drawing outside the viewport. And use
    CONTENT_BOX_THICKNESS and the CONTENT_BOX_COLOR settings to change the
    thickness and color of the box's lines, just in case the defaults aren't
    visible enough.

    Once you've got the box aligned, you can switch off CONTENT_BOX_VISIBLE;
    and the main pipeline will use your settings to draw everything correctly.

    Be aware that, if you resize the game's viewport, you'll have to readjust
    these settings.


################# CONFIGURATION #################

For the most part, configuring this version should be the same as configuring
the libretro versions, so refer to any past experience or to the existing
documentation for help with that. I've left almost all of the code's comments
intact, so you can also scroll through that for descriptions of the various
preprocessor definitions. You should be able to find all of them in
user-settings.fxh, derived-settings-and-constants.fxh, and
bind-shader-params.fxh. The main difference is that you configure many
preprocessor definitions by setting them to integer values rather than
just defining them. This is to let users set them from ReShade's UI
instead of editing the source code.

There are a handful of notable differences:
1)  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS and its siblings are still
    present, but instead of defining one of them at a time, you set
    PHOSPHOR_BLOOM_TRIAD_SIZE_MODE to a value in range [0 - 4].
    See user-settings.fxh for details.

2)  The same is true for SIMULATE_CRT_ON_LCD and its siblings. Set
    GAMMA_SIMULATION_MODE to [0 - 4] to control which of those is active.
    See derived-settings-and-constants.fxh for details.

3)  RUNTIME_GEOMETRY_TILT, GAMMA_ENCODE_EVERY_FBO, and
    RUNTIME_SHADER_PARAMS_ENABLE are currently not configurable. Disabling
    runtime geometry-tilt requires defining global constants with sin()
    and cos(), which is not possible in ReShade. Enabling
    GAMMA_ENCODE_EVERY_FBO introduces some control-flow wonkiness that
    I haven't gotten around to dealing with yet, so for now all intermediate
    buffers use gamma 1.0 and never ntsc_gamma. RUNTIME_SHADER_PARAMS_ENABLE
    required a ton more copy/pasting that I haven't felt like doing yet.

4)  For now I've changed the default Mask Sample Mode from 0 to 1 because
    it makes images too green, at least for me.

5)  I figured out that the default anti-aliasing setting was way too strong,
    so I turned it into a preprocessor definition aa_level and defaulted it
    to 0. See user-settings.fxh for details.


################# QUALITATIVE DIFFERENCES #################

The biggest change for me was that setting Mask Sample Mode to 0 is too green,
while 1 looks a ton better. Meanwhile setting it to 1 in the libretro version
was too purple. It seems to be caused by a difference in how ReShade and
RetroArch are tiling the phosphor mask in
crt-royale-scanlines-horizontal-apply-mask.fxh.

I've also noticed that the bloom is more pronounced in this version. It might
be because of a tweak I made to the write-operation at the end of
crt-royale-bloom-approx.fxh, but that's just a guess.


###############################################################################

If you try to port your RetroArch crt-royale config to this version, let me
know if you find any significant differences. I especially want to know about
any configs that work correctly in RetroArch but crash in ReShade, or are
performant in RetroArch but unplayable in ReShade.