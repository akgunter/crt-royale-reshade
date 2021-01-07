/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  crt-royale-reshade: A port of TroggleMonkey's crt-royale from libretro to ReShade.
//  Copyright (C) 2020 Alex Gunter <akg7634@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA

#include "../lib/bind-shader-params.fxh"
#include "../lib/phosphor-mask-resizing.fxh"
#include "../lib/texture-settings.fxh"
#include "shared-objects.fxh"

void pixelShader5(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    float2 tex_uv = texcoord.xy;
    //  First estimate the viewport size (the user will get the wrong number of
    //  triads if it's wrong and mask_specify_num_triads is 1.0/true).
    // const float2 output_size = tex2Dsize(samplerMaskResizeVertical);
    const float2 output_size = TEX_MASKVERTICAL_SIZE;
    const float viewport_y = CONTENT_HEIGHT;
    const float aspect_ratio = geom_aspect_ratio_x / geom_aspect_ratio_y;
    // const float2 estimated_viewport_size = float2(viewport_y * aspect_ratio, viewport_y);
    const float2 estimated_viewport_size = content_size;
    //  Estimate the output size of MASK_RESIZE (the next pass).  The estimated
    //  x component shouldn't matter, because we're not using the x result, and
    //  we're not swearing it's correct (if we did, the x result would influence
    //  the y result to maintain the tile aspect ratio).
    // const float2 estimated_mask_resize_output_size = float2(output_size.y * aspect_ratio, output_size.y);
    const float2 estimated_mask_resize_output_size = tex2Dsize(samplerMaskResizeHorizontal);
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
    #if _PHOSPHOR_MASK_MANUALLY_RESIZE
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
                    samplerMaskGrille, src_tex_uv, mask_size,
                    src_dy, resize_magnification_scale.y, 1.0);
            }
            else if(mask_type < 1.5)
            {
                pixel_color = downsample_vertical_sinc_tiled(
                    samplerMaskSlot, src_tex_uv, mask_size,
                    src_dy, resize_magnification_scale.y, 1.0);
            }
            else
            {
                pixel_color = downsample_vertical_sinc_tiled(
                    samplerMaskShadow, src_tex_uv, mask_size,
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
        // color = float4(1.0, 1.0, 1.0, 1.0);
    #endif
}
