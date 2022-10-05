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

#include "../lib/user-settings.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management.fxh"
#include "../lib/phosphor-mask-resizing.fxh"
#include "../lib/bloom-functions.fxh"

void bloomVerticalVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 bloom_dxdy : TEXCOORD1,
    out float bloom_sigma_runtime : TEXCOORD2
) {
    PostProcessVS(id, position, texcoord);
   
    float2 input_size = tex2Dsize(samplerBrightpass);
    float2 output_size = TEX_BLOOMVERTICAL_SIZE;

	//  Get the uv sample distance between output pixels.  Calculate dxdy like
    //  blurs/vertex-shader-blur-fast-vertical.h.
    const float2 dxdy = 1 / output_size;
    //  This blur is vertical-only, so zero out the vertical offset:
    bloom_dxdy = float2(0.0, dxdy.y);

    //  Calculate a runtime bloom_sigma in case it's needed:
    const float2 estimated_viewport_size = content_size;
    // const float2 estimated_mask_resize_output_size = tex2Dsize(samplerMaskResizeHorizontal);
    const float2 estimated_mask_resize_output_size = mask_size_xy;
    const float mask_tile_size_x = get_resized_mask_tile_size(estimated_viewport_size, estimated_mask_resize_output_size, true).x;

    bloom_sigma_runtime = get_min_sigma_to_blur_triad(
        mask_tile_size_x / mask_triads_per_tile, bloom_diff_thresh_);
}


void bloomVerticalPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 bloom_dxdy : TEXCOORD1,
    in const float bloom_sigma_runtime : TEXCOORD2,

    out float4 color : SV_Target
) {
    //  Blur the brightpass horizontally with a 9/17/25/43x blur:
    const float bloom_sigma = get_final_bloom_sigma(bloom_sigma_runtime);
    const float3 color3 = tex2DblurNfast(samplerBrightpass, texcoord,
        bloom_dxdy, bloom_sigma, get_intermediate_gamma());

    //  Encode and output the blurred image:
    color = encode_output(float4(color3, 1.0), get_intermediate_gamma());
}