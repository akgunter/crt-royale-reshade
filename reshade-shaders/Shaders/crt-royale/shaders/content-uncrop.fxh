#ifndef _CONTENT_CROPPING
#define _CONTENT_CROPPING

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


#include "shared-objects.fxh"


void uncropContentPixelShader(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const bool is_in_boundary = float(
        texcoord.x >= content_left && texcoord.x <= content_right &&
        texcoord.y >= content_upper && texcoord.y <= content_lower
    );
    const float2 texcoord_uncropped = ((texcoord - content_offset) * buffer_size + 0) / content_size;

    const float4 raw_color = tex2D(samplerGeometry, texcoord_uncropped);
    color = float4(is_in_boundary * raw_color.rgb, raw_color.a);
}

#endif  //  _CONTENT_CROPPING