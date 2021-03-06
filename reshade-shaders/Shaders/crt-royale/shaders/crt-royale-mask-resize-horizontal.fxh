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
#include "shared-objects.fxh"

void pixelShader6(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    float2 tex_uv = texcoord;
    //  First estimate the viewport size (the user will get the wrong number of
    //  triads if it's wrong and mask_specify_num_triads is 1.0/true).
    const float2 input_size = tex2Dsize(samplerMaskResizeVertical);
    // const float2 output_size = tex2Dsize(samplerMaskResizeHorizontal);
    const float2 output_size = TEX_MASKHORIZONTAL_SIZE;
    // const float2 estimated_viewport_size = output_size / mask_resize_viewport_scale;
    const float2 estimated_viewport_size = content_size;
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
    #if _PHOSPHOR_MASK_MANUALLY_RESIZE
        //  Discard unneeded fragments in case our profile allows real branches.
        //const float2 tile_uv_wrap = tile_uv_wrap;
        if(get_mask_sample_mode() < 0.5 &&
            max(tile_uv_wrap.x, tile_uv_wrap.y) <= mask_resize_num_tiles)
        {
            const float2 src_tex_uv = frac(src_tex_uv_wrap);
            const float3 pixel_color = downsample_horizontal_sinc_tiled(samplerMaskResizeVertical,
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
        // color = float4(1.0,1.0,1.0,1.0);
    #endif
}