/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

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
#include "../lib/new-phosphor-mask-resizing.fxh"
#include "shared-objects.fxh"

static const int num_sinc_lobes = 3;

void maskResizeVertVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 source_mask_size_inv : TEXCOORD1,
    out float2 output_size: TEXCOORD2,
    out float downsizing_factor : TEXCOORD3,
    out float2 true_tile_size : TEXCOORD4
) {
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    
    source_mask_size_inv = 1.0 / mask_size;
    output_size = TEX_MASKHORIZONTAL_SIZE;
    
    const float tile_aspect_inv = mask_resize_src_lut_size.x/mask_resize_src_lut_size.y;

    if (mask_specify_num_triads == 0) {
        downsizing_factor = mask_size.x / (mask_triad_size_desired * mask_triads_per_tile);
        true_tile_size = mask_triad_size_desired * mask_triads_per_tile * float2(1, tile_aspect_inv);
    }
    else {
        const float calculated_triad_size = float(CONTENT_WIDTH) / mask_num_triads_desired;
        downsizing_factor = mask_size.x / (calculated_triad_size * mask_triads_per_tile);
        true_tile_size = calculated_triad_size * mask_triads_per_tile * float2(1, tile_aspect_inv);
    }
}

void maskResizeVertPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 source_mask_size_inv : TEXCOORD1,
    in const float2 output_size : TEXCOORD2,
    in const float downsizing_factor : TEXCOORD3,
    in const float2 true_tile_size : TEXCOORD4,

    out float4 color : SV_Target
) {
    if (mask_sample_mode_desired > 0.5 || texcoord.y * output_size.y >= true_tile_size.y) {
        color = float4(0, 0, 0, 0);
    }
    else {
        color = lanczos_downsample_vert(
            samplerPhosphorMask, source_mask_size_inv,
            texcoord, downsizing_factor, num_sinc_lobes
        );
    }
}

void maskResizeHorizVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 source_mask_size_inv : TEXCOORD1,
    out float2 output_size: TEXCOORD2,
    out float downsizing_factor : TEXCOORD3,
    out float2 true_tile_size : TEXCOORD4
) {
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    
    source_mask_size_inv = 1.0 / TEX_MASKVERTICAL_SIZE;
    output_size = TEX_MASKHORIZONTAL_SIZE;

    if (mask_specify_num_triads == 0) {
        downsizing_factor = mask_size.x / (mask_triad_size_desired * mask_triads_per_tile);
        true_tile_size = mask_triad_size_desired * mask_triads_per_tile * float2(1, 1);
    }
    else {
        const float calculated_triad_size = float(CONTENT_WIDTH) / mask_num_triads_desired;
        downsizing_factor = mask_size.x / (calculated_triad_size * mask_triads_per_tile);
        true_tile_size = calculated_triad_size * mask_triads_per_tile * float2(1, 1);
    }
}

void maskResizeHorizPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 source_mask_size_inv : TEXCOORD1,
    in const float2 output_size : TEXCOORD2,
    in const float downsizing_factor : TEXCOORD3,
    in const float2 true_tile_size : TEXCOORD4,

    out float4 color : SV_Target
) {
    if (mask_sample_mode_desired > 0.5 || texcoord.x * output_size.x >= true_tile_size.x) {
        color = float4(0, 0, 0, 0);
    }
    else {
        color = lanczos_downsample_horiz(
            samplerMaskResizeVertical, source_mask_size_inv,
            texcoord, downsizing_factor, num_sinc_lobes
        );
    }
}