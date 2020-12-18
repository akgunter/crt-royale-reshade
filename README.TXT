This is a port of the crt-royale shader by TroggleMonkey from libretro to
ReShade 4.8.3+.

The vast majority of the code here is copy/pasted from the current libretro
shader repositories, so the vast majority of the credit goes to those authors.

libretro/glsl-shaders:      https://github.com/libretro/glsl-shaders
libretro/slang-shaders:     https://github.com/libretro/slang-shaders

Special thanks goes to crosire and co. for their work on ReShade, particularly
for adding support for rectangular matrices and for ReShade's built-in
debugging tools. Those features made this project orders of magnitude easier.



For the most part, configuring this port should be the same as configuring the
libretro versions, so refer to any past experience or to the existing
documentation for help with that. I've left almost all of the code's comments
intact, so you can also scroll through that for descriptions of the various
preprocessor definitions. You should be able to find all of them in
user-settings.fxh, derived-settings-and-constants.fxh, and
bind-shader-params.fxh. The main difference is that you configure many
preprocessor definitions by setting them to integer values rather than
just defining them. This is to let users set them from ReShade's UI
instead of editing the source code.



Bear in mind that not everything ported identically.

The biggest change for me was that setting Mask Sample Mode to 0 is too green,
while 1 looks a ton better. Meanwhile setting it to 1 in the libretro version
was too purple. It seems to be caused by a difference in how ReShade and
RetroArch are tiling the phosphor mask in
crt-royale-scanlines-horizontal-apply-mask.fxh.

I've also noticed that the bloom is more pronounced in this version. It might
be because of a tweak I made to the write-operation at the end of
crt-royale-bloom-approx.fxh, but that's just a guess.

For now I've forced RUNTIME_GEOMETRY_TILT to be active, hidden it from the
ReShade UI, and commented out the logic for it being disabled. This is because
that logic uses sin() and cos() to define global static constants, which
ReShade doesn't like; and I don't know a good way to port that math without
making them hard-coded runtime values (which would defeat the point).

PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS and its siblings are still there,
but instead of defining one of them, you set PHOSPHOR_BLOOM_TRIAD_SIZE_MODE
to a value in range [0 - 4]. See user-settings.fxh for details.

The same is true for SIMULATE_CRT_ON_LCD and its siblings. Set
GAMMA_SIMULATION_MODE to [0 - 4] to control which of those is active. See
derived-settings-and-constants.fxh for details.

And finally, for now the library always behaves as if
RUNTIME_SHADER_PARAMS_ENABLE is defined/true. That was mainly for my sanity
while porting the code, although I don't have a clue how it'll interact
with ReShade's UI.



If you try to port your RetroArch crt-royale config to this version, let me
know if you find any significant differences. I especially want to know about
any cases that work in RetroArch but crash in ReShade, or are performant in
RetroArch but unplayable in ReShade.