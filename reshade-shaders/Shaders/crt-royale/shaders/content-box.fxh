#ifndef _CONTENT_BOXING
#define _CONTENT_BOXING

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


#include "content-crop.fxh"


#if CONTENT_BOX_VISIBLE
#ifndef CONTENT_BOX_INSCRIBED
    #define CONTENT_BOX_INSCRIBED 1
#endif

#ifndef CONTENT_BOX_THICKNESS
    #define CONTENT_BOX_THICKNESS 5
#endif

#ifndef CONTENT_BOX_COLOR_R
    #define CONTENT_BOX_COLOR_R 1.0
#endif

#ifndef CONTENT_BOX_COLOR_G
    #define CONTENT_BOX_COLOR_G 0.0
#endif

#ifndef CONTENT_BOX_COLOR_B
    #define CONTENT_BOX_COLOR_B 0.0
#endif

static const float vert_line_thickness = float(CONTENT_BOX_THICKNESS) / BUFFER_WIDTH;
static const float horiz_line_thickness = float(CONTENT_BOX_THICKNESS) / BUFFER_HEIGHT;

#if CONTENT_BOX_INSCRIBED
    // Set the outer borders to the edge of the content
    static const float left_line_1 = content_left;
    static const float left_line_2 = left_line_1 + vert_line_thickness;
    static const float right_line_2 = content_right;
    static const float right_line_1 = right_line_2 - vert_line_thickness;

    static const float upper_line_1 = content_upper;
    static const float upper_line_2 = upper_line_1 + horiz_line_thickness;
    static const float lower_line_2 = content_lower;
    static const float lower_line_1 = lower_line_2 - horiz_line_thickness;
#else
    // Set the inner borders to the edge of the content
    static const float left_line_2 = content_left;
    static const float left_line_1 = left_line_2 - vert_line_thickness;
    static const float right_line_1 = content_right;
    static const float right_line_2 = right_line_1 + vert_line_thickness;

    static const float upper_line_2 = content_upper;
    static const float upper_line_1 = upper_line_2 - horiz_line_thickness;
    static const float lower_line_1 = content_lower;
    static const float lower_line_2 = lower_line_1 + horiz_line_thickness;
#endif


static const float4 box_color = float4(
    CONTENT_BOX_COLOR_R,
    CONTENT_BOX_COLOR_G,
    CONTENT_BOX_COLOR_B,
    1.0
);

void contentBoxPixelShader(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {

    const bool is_inside_outerbound = (
        texcoord.x >= left_line_1 && texcoord.x <= right_line_2 &&
        texcoord.y >= upper_line_1 && texcoord.y <= lower_line_2
    );
    const bool is_outside_innerbound = (
        texcoord.x <= left_line_2 || texcoord.x >= right_line_1 ||
        texcoord.y <= upper_line_2 || texcoord.y >= lower_line_1
    );

    if (is_inside_outerbound && is_outside_innerbound) {
        color = box_color;
    }
    else {
        color = tex2D(ReShade::BackBuffer, texcoord);
    }
}


#endif  // CONTENT_BOX_VISIBLE
#endif  //  _CONTENT_BOXING