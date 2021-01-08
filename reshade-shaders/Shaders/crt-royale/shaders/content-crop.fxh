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


// The normalized center is 0.5 plus the normalized offset
static const float2 content_center = float2(CONTENT_CENTER_X, CONTENT_CENTER_Y) / buffer_size + 0.5;
// The content's normalized diameter d is its size divided by the buffer's size. The radius is d/2.
static const float2 content_radius = content_size / (2.0 * buffer_size);

static const float content_left = content_center.x - content_radius.x;
static const float content_right = content_center.x + content_radius.x;
static const float content_upper = content_center.y - content_radius.y;
static const float content_lower = content_center.y + content_radius.y;

// The xy-offset of the top-left pixel in the content box
static const float2 content_offset = float2(content_left, content_upper);



void cropContentPixelShader(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 texcoord_cropped = texcoord * content_size / buffer_size + content_offset;
    color = tex2D(samplerColor, texcoord_cropped);
}

void uncropContentPixelShader(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const bool is_in_boundary = (
        texcoord.x >= content_left && texcoord.x <= content_right &&
        texcoord.y >= content_upper && texcoord.y <= content_lower
    );
    const float2 texcoord_uncropped = (texcoord - content_offset) * buffer_size / content_size;

    if (is_in_boundary) color = tex2D(samplerGeometry, texcoord_uncropped);
    else color = float4(0, 0, 0, 1);
}

#endif  //  _CONTENT_CROPPING