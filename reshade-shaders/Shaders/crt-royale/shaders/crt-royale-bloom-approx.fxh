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
#include "../lib/gamma-management.fxh"
#include "../lib/phosphor-mask-resizing.fxh"
#include "../lib/scanline-functions.fxh"
#include "../lib/blur-functions.fxh"
#include "../lib/bloom-functions.fxh"

#include "shared-objects.fxh"



static const int num_sinc_lobes = 3;


void approximateBloomVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,

    out float2 source_size_inv : TEXCOORD1,
    out float2 downsizing_factor : TEXCOORD2
) {
    PostProcessVS(id, position, texcoord);

    source_size_inv = 1.0 / float2(TEX_BEAMCONVERGENCE_SIZE);
    downsizing_factor = float2(TEX_BEAMCONVERGENCE_SIZE) / TEX_BLOOMAPPROXHORIZ_SIZE;
}

void approximateBloomVertPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    in float2 source_size_inv : TEXCOORD1,
    in float2 downsizing_factor : TEXCOORD2,

    out float4 color : SV_Target
) {

    const float2 uv = texcoord / float2(1.0, downsizing_factor.y);

    color = lanczos_downsample_vert(
        samplerBeamConvergence, source_size_inv,
        uv, downsizing_factor.y, num_sinc_lobes,
        1.0
    );
}

void approximateBloomHorizPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    in float2 source_size_inv : TEXCOORD1,
    in float2 downsizing_factor : TEXCOORD2,

    out float4 color : SV_Target
) {
    
    const float2 uv = texcoord / float2(downsizing_factor.x, 1.0);

    color = lanczos_downsample_horiz(
        samplerBloomApproxVert, source_size_inv,
        uv, downsizing_factor.x, num_sinc_lobes,
        1.0
    );
}