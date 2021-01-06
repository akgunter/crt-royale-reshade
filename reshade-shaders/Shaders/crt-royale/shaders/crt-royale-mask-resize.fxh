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

    out float4 source_mask_size_inv_and_tile_size : TEXCOORD1,
    out float3 downsizing_factor_and_true_tile_size : TEXCOORD2
) {
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    
    source_mask_size_inv_and_tile_size = float4(1.0 / mask_size, TEX_MASKHORIZONTAL_SIZE);
    downsizing_factor_and_true_tile_size = get_downsizing_factor_and_true_tile_size();
}

void maskResizeVertPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    in const float4 source_mask_size_inv_and_tile_size : TEXCOORD1,
    in const float3 downsizing_factor_and_true_tile_size : TEXCOORD2,

    out float4 color : SV_Target
) {
    const float2 source_mask_size_inv = source_mask_size_inv_and_tile_size.xy;
    const float2 tile_size = source_mask_size_inv_and_tile_size.zw;
    const float downsizing_factor = downsizing_factor_and_true_tile_size.x;
    const float2 true_tile_size = downsizing_factor_and_true_tile_size.yz;

    if (mask_sample_mode_desired > 0.5 || texcoord.y * tile_size.y >= true_tile_size.y) {
        color = float4(0, 0, 0, 0);
    }
    else if (mask_type == 0) {
        color = lanczos_downsample_vert(
            samplerMaskGrille, source_mask_size_inv,
            texcoord, downsizing_factor, num_sinc_lobes
        );
    }
    else if (mask_type == 2) {
        color = lanczos_downsample_vert(
            samplerMaskShadow, source_mask_size_inv,
            texcoord, downsizing_factor, num_sinc_lobes
        );
    }
    else {
        color = lanczos_downsample_vert(
            samplerMaskSlot, source_mask_size_inv,
            texcoord, downsizing_factor, num_sinc_lobes
        );
    }
}

void maskResizeHorizVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,

    out float4 source_mask_size_inv_and_tile_size : TEXCOORD1,
    out float3 downsizing_factor_and_true_tile_size : TEXCOORD2
) {
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

    source_mask_size_inv_and_tile_size = float4(1.0 / TEX_MASKVERTICAL_SIZE, TEX_MASKHORIZONTAL_SIZE);
    downsizing_factor_and_true_tile_size = get_downsizing_factor_and_true_tile_size();
}

void maskResizeHorizPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float4 source_mask_size_inv_and_tile_size : TEXCOORD1,
    in const float3 downsizing_factor_and_true_tile_size : TEXCOORD2,

    out float4 color : SV_Target
) {
    const float2 source_mask_size_inv = source_mask_size_inv_and_tile_size.xy;
    const float2 tile_size = source_mask_size_inv_and_tile_size.zw;
    const float downsizing_factor = downsizing_factor_and_true_tile_size.x;
    const float2 true_tile_size = downsizing_factor_and_true_tile_size.yz;

    if (mask_sample_mode_desired > 0.5 || texcoord.x * tile_size.x >= true_tile_size.x) {
        color = float4(0, 0, 0, 0);
    }
    else {
        color = lanczos_downsample_horiz(
            samplerMaskResizeVertical, source_mask_size_inv,
            texcoord, downsizing_factor, num_sinc_lobes
        );
    }
}