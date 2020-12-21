/////////////////////////////////  MIT LICENSE  ////////////////////////////////
//  Copyright (C) 2020 Alex Gunter
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.


#include "shared-objects.fxh"


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

static const float vert_line_thickness = CONTENT_BOX_THICKNESS * orig_pixel_dx;
static const float horiz_line_thickness = CONTENT_BOX_THICKNESS * orig_pixel_dy;

static const float4 box_color = float4(
    CONTENT_BOX_COLOR_R,
    CONTENT_BOX_COLOR_G,
    CONTENT_BOX_COLOR_B,
    1.0
);

#if CONTENT_BOX_INSCRIBED
    // Set the outer borders to the edge of the content
    static const float left_line_1 = content_center_x - content_radius_x;
    static const float left_line_2 = left_line_1 + vert_line_thickness;
    static const float right_line_2 = content_center_x + content_radius_x;
    static const float right_line_1 = right_line_2 - vert_line_thickness;

    static const float upper_line_1 = content_center_y - content_radius_y;
    static const float upper_line_2 = upper_line_1 + horiz_line_thickness;
    static const float lower_line_2 = content_center_y + content_radius_y;
    static const float lower_line_1 = lower_line_2 - horiz_line_thickness;
#else
    // Set the inner borders to the edge of the content
    static const float left_line_2 = content_center_x - content_radius_x;
    static const float left_line_1 = left_line_2 - vert_line_thickness;
    static const float right_line_1 = content_center_x + content_radius_x;
    static const float right_line_2 = right_line_1 + vert_line_thickness;

    static const float upper_line_2 = content_center_y - content_radius_y;
    static const float upper_line_1 = upper_line_2 - horiz_line_thickness;
    static const float lower_line_1 = content_center_y + content_radius_y;
    static const float lower_line_2 = lower_line_1 + horiz_line_thickness;
#endif


void contentBoxPixelShader(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

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
        color = tex2D(samplerColor, texcoord);
    }
}