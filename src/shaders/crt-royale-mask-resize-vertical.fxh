#include "../lib/bind-shader-params.fxh"
#include "../lib/phosphor-mask-resizing.fxh"

#include "../lib/texture-settings.fxh"
#include "shared-objects.fxh"


void pixelShader5b(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 viewport_size = tex2Dsize(samplerOutput5);
    const float tile_size_px = mask_triads_per_tile * mask_triad_size_desired_static;
    const float2 maskcoord = texcoord * viewport_size / tile_size_px;

    if (mask_type < 0.5)
    {
        color = tex2D(samplerMaskGrille, maskcoord);
    }
    else if (mask_type < 1.5)
    {
        color = tex2D(samplerMaskSlot, maskcoord);
    }
    else
    {
        color = tex2D(samplerMaskShadow, maskcoord);
    }
}

void pixelShader5(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    float2 tex_uv = texcoord.xy;
    //  First estimate the viewport size (the user will get the wrong number of
    //  triads if it's wrong and mask_specify_num_triads is 1.0/true).
    const float2 output_size = tex2Dsize(samplerOutput5);
    const float viewport_y = BUFFER_HEIGHT;
    const float aspect_ratio = geom_aspect_ratio_x / geom_aspect_ratio_y;
    // const float2 estimated_viewport_size = float2(viewport_y * aspect_ratio, viewport_y);
    const float2 estimated_viewport_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    //  Estimate the output size of MASK_RESIZE (the next pass).  The estimated
    //  x component shouldn't matter, because we're not using the x result, and
    //  we're not swearing it's correct (if we did, the x result would influence
    //  the y result to maintain the tile aspect ratio).
    // const float2 estimated_mask_resize_output_size = float2(output_size.y * aspect_ratio, output_size.y);
    const float2 estimated_mask_resize_output_size = tex2Dsize(samplerOutput6);
    //  Find the final intended [y] size of our resized phosphor mask tiles,
    //  then the tile size for the current pass (resize y only):
    const float2 mask_resize_tile_size = get_resized_mask_tile_size(estimated_viewport_size, estimated_mask_resize_output_size, true);
    const float2 pass_output_tile_size = float2(min(mask_size_xy, output_size.x), mask_resize_tile_size.y);

    //  We'll render resized tiles until filling the output FBO or meeting a
    //  limit, so compute [wrapped] tile uv coords based on the output uv coords
    //  and the number of tiles that will fit in the FBO.
    const float2 output_tiles_this_pass = output_size / pass_output_tile_size;
    const float2 output_video_uv = tex_uv; // * texture_size / video_size;
    const float2 tile_uv_wrap = output_video_uv * output_tiles_this_pass;

    //  The input LUT is just a single mask tile, so texture uv coords are the
    //  same as tile uv coords (save frac() for the fragment shader).  The
    //  magnification scale is also straightforward:
    const float2 src_tex_uv_wrap = tile_uv_wrap;
    const float2 resize_magnification_scale = pass_output_tile_size / mask_size_xy;


    //  Resize the input phosphor mask tile to the final vertical size it will
    //  appear on screen.  Keep 1x horizontal size if possible (IN.output_size
    //  >= mask_size_xy), and otherwise linearly sample horizontally
    //  to fit exactly one tile.  Lanczos-resizing the phosphor mask achieves
    //  much sharper results than mipmapping, and vertically resizing first
    //  minimizes the total number of taps required.  We output a number of
    //  resized tiles >= mask_resize_num_tiles for easier tiled sampling later.
    //const float2 src_tex_uv_wrap = src_tex_uv_wrap;
    #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
        //  Discard unneeded fragments in case our profile allows real branches.
        // const float2 tile_uv_wrap = src_tex_uv_wrap;
        if(get_mask_sample_mode() < 0.5 &&
            tile_uv_wrap.y <= mask_resize_num_tiles)
        {
            static const float src_dy = 1.0/mask_size_xy;
            const float2 src_tex_uv = frac(src_tex_uv_wrap);
            float3 pixel_color;
            if(mask_type < 0.5)
            {
                pixel_color = downsample_vertical_sinc_tiled(
                    samplerMaskGrille, src_tex_uv, mask_size_xy,
                    src_dy, resize_magnification_scale.y, 1.0);
            }
            else if(mask_type < 1.5)
            {
                pixel_color = downsample_vertical_sinc_tiled(
                    samplerMaskSlot, src_tex_uv, mask_size_xy,
                    src_dy, resize_magnification_scale.y, 1.0);
            }
            else
            {
                pixel_color = downsample_vertical_sinc_tiled(
                    samplerMaskShadow, src_tex_uv, mask_size_xy,
                    src_dy, resize_magnification_scale.y, 1.0);
            }
            //  The input LUT was linear RGB, and so is our output:
            color = float4(pixel_color, 1.0);
        }
        else
        {
            discard;
        }
    #else
        discard;
        color = float4(1.0, 1.0, 1.0, 1.0);
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
//     COMPAT_VARYING vec2 resize_magnification_scale;

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

    // void main()
    // {
    //     gl_Position = MVPMatrix * VertexCoord;
    //     TEX0.xy = TexCoord.xy;
    //     float2 tex_uv = TEX0.xy;
    //     //  First estimate the viewport size (the user will get the wrong number of
    //     //  triads if it's wrong and mask_specify_num_triads is 1.0/true).

    //     const float viewport_y = output_size.y / mask_resize_viewport_scale.y;
    //     const float aspect_ratio = geom_aspect_ratio_x / geom_aspect_ratio_y;
    //     const float2 estimated_viewport_size =
    //         float2(viewport_y * aspect_ratio, viewport_y);
    //     //  Estimate the output size of MASK_RESIZE (the next pass).  The estimated
    //     //  x component shouldn't matter, because we're not using the x result, and
    //     //  we're not swearing it's correct (if we did, the x result would influence
    //     //  the y result to maintain the tile aspect ratio).
    //     const float2 estimated_mask_resize_output_size =
    //         float2(output_size.y * aspect_ratio, output_size.y);
    //     //  Find the final intended [y] size of our resized phosphor mask tiles,
    //     //  then the tile size for the current pass (resize y only):
    //     float2 mask_resize_tile_size = get_resized_mask_tile_size(
    //         estimated_viewport_size, estimated_mask_resize_output_size, false);
    //     float2 pass_output_tile_size = float2(min(
    //         mask_size_xy.x, output_size.x), mask_resize_tile_size.y);

    //     //  We'll render resized tiles until filling the output FBO or meeting a
    //     //  limit, so compute [wrapped] tile uv coords based on the output uv coords
    //     //  and the number of tiles that will fit in the FBO.
    //     const float2 output_tiles_this_pass = output_size / pass_output_tile_size;
    //     const float2 output_video_uv = tex_uv * texture_size / video_size;
    //     const float2 tile_uv_wrap = output_video_uv * output_tiles_this_pass;

    //     //  The input LUT is just a single mask tile, so texture uv coords are the
    //     //  same as tile uv coords (save frac() for the fragment shader).  The
    //     //  magnification scale is also straightforward:
    //     src_tex_uv_wrap = tile_uv_wrap;
    //     resize_magnification_scale =
    //         pass_output_tile_size / mask_size_xy;
    // }

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
//     #ifdef PHOSPHOR_MASK_RESIZE_MIPMAPPED_LUT
//         uniform sampler2D mask_grille_texture_large;
//         uniform sampler2D mask_slot_texture_large;
//         uniform sampler2D mask_shadow_texture_large;
//     #else
//         uniform sampler2D mask_grille_texture_small;
//         uniform sampler2D mask_slot_texture_small;
//         uniform sampler2D mask_shadow_texture_small;
//     #endif
//     COMPAT_VARYING vec4 TEX0;
//     COMPAT_VARYING vec2 src_tex_uv_wrap;
//     COMPAT_VARYING vec2 resize_magnification_scale;

//     // compatibility #defines
//     #define Source Texture
//     #define vTexCoord TEX0.xy

//     #define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
//     #define OutSize vec4(OutputSize, 1.0 / OutputSize)

//     void main()
//     {
//         //  Resize the input phosphor mask tile to the final vertical size it will
//         //  appear on screen.  Keep 1x horizontal size if possible (IN.output_size
//         //  >= mask_size_xy), and otherwise linearly sample horizontally
//         //  to fit exactly one tile.  Lanczos-resizing the phosphor mask achieves
//         //  much sharper results than mipmapping, and vertically resizing first
//         //  minimizes the total number of taps required.  We output a number of
//         //  resized tiles >= mask_resize_num_tiles for easier tiled sampling later.
//         //const float2 src_tex_uv_wrap = src_tex_uv_wrap;
//         #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
//             //  Discard unneeded fragments in case our profile allows real branches.
//             const float2 tile_uv_wrap = src_tex_uv_wrap;
//             if(get_mask_sample_mode() < 0.5 &&
//                 tile_uv_wrap.y <= mask_resize_num_tiles)
//             {
//                 static const float src_dy = 1.0/mask_size_xy.y;
//                 const float2 src_tex_uv = frac(src_tex_uv_wrap);
//                 float3 pixel_color;
//                 //  If mask_type is static, this branch will be resolved statically.
//                 #ifdef PHOSPHOR_MASK_RESIZE_MIPMAPPED_LUT
//                     if(mask_type < 0.5)
//                     {
//                         pixel_color = downsample_vertical_sinc_tiled(
//                             mask_grille_texture_large, src_tex_uv, mask_size_xy,
//                             src_dy, resize_magnification_scale.y, 1.0);
//                     }
//                     else if(mask_type < 1.5)
//                     {
//                         pixel_color = downsample_vertical_sinc_tiled(
//                             mask_slot_texture_large, src_tex_uv, mask_size_xy,
//                             src_dy, resize_magnification_scale.y, 1.0);
//                     }
//                     else
//                     {
//                         pixel_color = downsample_vertical_sinc_tiled(
//                             mask_shadow_texture_large, src_tex_uv, mask_size_xy,
//                             src_dy, resize_magnification_scale.y, 1.0);
//                     }
//                 #else
//                     if(mask_type < 0.5)
//                     {
//                         pixel_color = downsample_vertical_sinc_tiled(
//                             mask_grille_texture_small, src_tex_uv, mask_size_xy,
//                             src_dy, resize_magnification_scale.y, 1.0);
//                     }
//                     else if(mask_type < 1.5)
//                     {
//                         pixel_color = downsample_vertical_sinc_tiled(
//                             mask_slot_texture_small, src_tex_uv, mask_size_xy,
//                             src_dy, resize_magnification_scale.y, 1.0);
//                     }
//                     else
//                     {
//                         pixel_color = downsample_vertical_sinc_tiled(
//                             mask_shadow_texture_small, src_tex_uv, mask_size_xy,
//                             src_dy, resize_magnification_scale.y, 1.0);
//                     }
//                 #endif
//                 //  The input LUT was linear RGB, and so is our output:
//                 FragColor = float4(pixel_color, 1.0);
//             }
//             else
//             {
//                 discard;
//             }
//         #else
//             discard;
//             FragColor = float4(1.0, 1.0, 1.0, 1.0);
//         #endif
//     } 
// #endif
