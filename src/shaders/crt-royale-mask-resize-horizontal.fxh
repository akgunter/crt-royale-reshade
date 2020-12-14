#include "../lib/bind-shader-params.fxh"
#include "../lib/phosphor-mask-resizing.fxh"

#include "shared-objects.fxh"

void pixelShader6(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    float2 tex_uv = texcoord;
    //  First estimate the viewport size (the user will get the wrong number of
    //  triads if it's wrong and mask_specify_num_triads is 1.0/true).
    const float2 input_size = tex2Dsize(samplerOutput5);
    const float2 output_size = tex2Dsize(samplerOutput6);
    // const float2 estimated_viewport_size = output_size / mask_resize_viewport_scale;
    const float2 estimated_viewport_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    //  Find the final size of our resized phosphor mask tiles.  We probably
    //  estimated the viewport size and MASK_RESIZE output size differently last
    //  pass, so do not swear they were the same. ;)
    const float2 mask_resize_tile_size = get_resized_mask_tile_size(
        estimated_viewport_size, output_size, true);

    //  We'll render resized tiles until filling the output FBO or meeting a
    //  limit, so compute [wrapped] tile uv coords based on the output uv coords
    //  and the number of tiles that will fit in the FBO.
    const float2 output_tiles_this_pass = output_size / mask_resize_tile_size;
    const float2 output_video_uv = tex_uv;
    const float2 tile_uv_wrap = output_video_uv * output_tiles_this_pass;

    //  Get the texel size of an input tile and related values:
    const float2 input_tile_size = float2(min(
        mask_resize_src_lut_size.x, input_size.x), mask_resize_tile_size.y);
    const float2 tile_size_uv = input_tile_size / input_size;
    const float2 input_tiles_per_texture = input_size / input_tile_size;

    //  Derive [wrapped] texture uv coords from [wrapped] tile uv coords and
    //  the tile size in uv coords, and save frac() for the fragment shader.
    const float2 src_tex_uv_wrap = tile_uv_wrap * tile_size_uv;

    //  Output the values we need, including the magnification scale and step:
    //tile_uv_wrap = tile_uv_wrap;
    //src_tex_uv_wrap = src_tex_uv_wrap;
    const float2 resize_magnification_scale = mask_resize_tile_size / input_tile_size;
    const float2 src_dxdy = float2(1.0/input_size.x, 0.0);
    //tile_size_uv = tile_size_uv;
    //input_tiles_per_texture = input_tiles_per_texture;

    //  The input contains one mask tile horizontally and a number vertically.
    //  Resize the tile horizontally to its final screen size and repeat it
    //  until drawing at least mask_resize_num_tiles, leaving it unchanged
    //  vertically.  Lanczos-resizing the phosphor mask achieves much sharper
    //  results than mipmapping, outputting >= mask_resize_num_tiles makes for
    //  easier tiled sampling later.
    #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
        //  Discard unneeded fragments in case our profile allows real branches.
        //const float2 tile_uv_wrap = tile_uv_wrap;
        if(get_mask_sample_mode() < 0.5 &&
            max(tile_uv_wrap.x, tile_uv_wrap.y) <= mask_resize_num_tiles)
        {
            const float2 src_tex_uv = frac(src_tex_uv_wrap);
            const float3 pixel_color = downsample_horizontal_sinc_tiled(samplerOutput5,
                src_tex_uv, input_size, src_dxdy.x,
                resize_magnification_scale.x, tile_size_uv.x);
            //  The input LUT was linear RGB, and so is our output:
            color = float4(pixel_color, 1.0);
        }
        else
        {
            discard;
        }
    #else
        discard;
        color = float4(1.0,1.0,1.0,1.0);
    #endif
}

// #if defined(VERTEX)

//     #if __VERSION__ >= 130
//     #define COMPAT_VARYING out
//     #define COMPAT_ATTRIBUTE in
//     #define COMPAT_TEXTURE texture
//     #else
//     #define COMPAT_VARYING varying 
//     #define COMPAT_ATTRIBUTE attribute 
//     #define COMPAT_TEXTURE texture2D
//     #endif

//     #ifdef GL_ES
//     #define COMPAT_PRECISION mediump
//     #else
//     #define COMPAT_PRECISION
//     #endif

//     COMPAT_ATTRIBUTE vec4 VertexCoord;
//     COMPAT_ATTRIBUTE vec4 COLOR;
//     COMPAT_ATTRIBUTE vec4 TexCoord;
//     COMPAT_VARYING vec4 COL0;
//     COMPAT_VARYING vec4 TEX0;
//     COMPAT_VARYING vec2 src_tex_uv_wrap;
//     COMPAT_VARYING vec2 tile_uv_wrap;
//     COMPAT_VARYING vec2 resize_magnification_scale;
//     COMPAT_VARYING vec2 src_dxdy;
//     COMPAT_VARYING vec2 tile_size_uv;
//     COMPAT_VARYING vec2 input_tiles_per_texture;

//     vec4 _oPosition1; 
//     uniform mat4 MVPMatrix;
//     uniform COMPAT_PRECISION int FrameDirection;
//     uniform COMPAT_PRECISION int FrameCount;
//     uniform COMPAT_PRECISION vec2 OutputSize;
//     uniform COMPAT_PRECISION vec2 TextureSize;
//     uniform COMPAT_PRECISION vec2 InputSize;

//     // compatibility #defines
//     #define vTexCoord TEX0.xy
//     #define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
//     #define OutSize vec4(OutputSize, 1.0 / OutputSize)

//     void main()
//     {
//         gl_Position = MVPMatrix * VertexCoord;
//         TEX0.xy = TexCoord.xy;
//         float2 tex_uv = TEX0.xy;
//         //  First estimate the viewport size (the user will get the wrong number of
//         //  triads if it's wrong and mask_specify_num_triads is 1.0/true).
//         const float2 estimated_viewport_size =
//             output_size / mask_resize_viewport_scale;
//         //  Find the final size of our resized phosphor mask tiles.  We probably
//         //  estimated the viewport size and MASK_RESIZE output size differently last
//         //  pass, so do not swear they were the same. ;)
//         const float2 mask_resize_tile_size = get_resized_mask_tile_size(
//             estimated_viewport_size, output_size, false);

//         //  We'll render resized tiles until filling the output FBO or meeting a
//         //  limit, so compute [wrapped] tile uv coords based on the output uv coords
//         //  and the number of tiles that will fit in the FBO.
//         const float2 output_tiles_this_pass = output_size / mask_resize_tile_size;
//         const float2 output_video_uv = tex_uv * texture_size / video_size;
//         const float2 tile_uv_wrap = output_video_uv * output_tiles_this_pass;

//         //  Get the texel size of an input tile and related values:
//         const float2 input_tile_size = float2(min(
//             mask_resize_src_lut_size.x, video_size.x), mask_resize_tile_size.y);
//         tile_size_uv = input_tile_size / texture_size;
//         input_tiles_per_texture = texture_size / input_tile_size;

//         //  Derive [wrapped] texture uv coords from [wrapped] tile uv coords and
//         //  the tile size in uv coords, and save frac() for the fragment shader.
//         src_tex_uv_wrap = tile_uv_wrap * tile_size_uv;

//         //  Output the values we need, including the magnification scale and step:
//         //tile_uv_wrap = tile_uv_wrap;
//         //src_tex_uv_wrap = src_tex_uv_wrap;
//         resize_magnification_scale = mask_resize_tile_size / input_tile_size;
//         src_dxdy = float2(1.0/texture_size.x, 0.0);
//         //tile_size_uv = tile_size_uv;
//         //input_tiles_per_texture = input_tiles_per_texture;
//     }

// #elif defined(FRAGMENT)

//     #ifdef GL_ES
//     #ifdef GL_FRAGMENT_PRECISION_HIGH
//     precision highp float;
//     #else
//     precision mediump float;
//     #endif
//     #define COMPAT_PRECISION mediump
//     #else
//     #define COMPAT_PRECISION
//     #endif

//     #if __VERSION__ >= 130
//     #define COMPAT_VARYING in
//     #define COMPAT_TEXTURE texture
//     out COMPAT_PRECISION vec4 FragColor;
//     #else
//     #define COMPAT_VARYING varying
//     #define FragColor gl_FragColor
//     #define COMPAT_TEXTURE texture2D
//     #endif

//     uniform COMPAT_PRECISION int FrameDirection;
//     uniform COMPAT_PRECISION int FrameCount;
//     uniform COMPAT_PRECISION vec2 OutputSize;
//     uniform COMPAT_PRECISION vec2 TextureSize;
//     uniform COMPAT_PRECISION vec2 InputSize;
//     uniform sampler2D Texture;
//     #define input_texture Texture
//     COMPAT_VARYING vec4 TEX0;
//     COMPAT_VARYING vec2 src_tex_uv_wrap;
//     COMPAT_VARYING vec2 tile_uv_wrap;
//     COMPAT_VARYING vec2 resize_magnification_scale;
//     COMPAT_VARYING vec2 src_dxdy;
//     COMPAT_VARYING vec2 tile_size_uv;
//     COMPAT_VARYING vec2 input_tiles_per_texture;

//     // compatibility #defines
//     #define Source Texture
//     #define vTexCoord TEX0.xy

//     #define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
//     #define OutSize vec4(OutputSize, 1.0 / OutputSize)

//     void main()
//     {
//         //  The input contains one mask tile horizontally and a number vertically.
//         //  Resize the tile horizontally to its final screen size and repeat it
//         //  until drawing at least mask_resize_num_tiles, leaving it unchanged
//         //  vertically.  Lanczos-resizing the phosphor mask achieves much sharper
//         //  results than mipmapping, outputting >= mask_resize_num_tiles makes for
//         //  easier tiled sampling later.
//         #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
//             //  Discard unneeded fragments in case our profile allows real branches.
//             //const float2 tile_uv_wrap = tile_uv_wrap;
//             if(get_mask_sample_mode() < 0.5 &&
//                 max(tile_uv_wrap.x, tile_uv_wrap.y) <= mask_resize_num_tiles)
//             {
//                 const float src_dx = src_dxdy.x;
//                 const float2 src_tex_uv = frac(src_tex_uv_wrap);
//                 const float3 pixel_color = downsample_horizontal_sinc_tiled(input_texture,
//                     src_tex_uv, texture_size, src_dxdy.x,
//                     resize_magnification_scale.x, tile_size_uv.x);
//                 //  The input LUT was linear RGB, and so is our output:
//                 FragColor = float4(pixel_color, 1.0);
//             }
//             else
//             {
//                 discard;
//             }
//         #else
//             discard;
//             FragColor = float4(1.0,1.0,1.0,1.0);
//         #endif
//     } 
// #endif