#ifndef _PHOSHOR_MASK_CALCULATIONS_H
#define _PHOSHOR_MASK_CALCULATIONS_H

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


/*
SLOT
    p_height:   60 + 6
    p_width:    12 + 6
    p_gap:      2
    horiz_gap:  6
    vert_gap:   6

    pattern: RGB
    top-left: middle of horiz_gap and vert_gap


GRILLE
    p_width:    13 + 4
    p_gap:      3
    horiz_gap:  6

    pattern: RGB
    top-left: middle of horiz_gap


SHADOW
    p_diam:   16 + 6
    p_gap:      0
    vert_gap:   0
    
    pattern: GBR -> RGB
    top-left: middle of green dot


SHADOW EDP = SHADOW w/ 50% vertical stretch
    p_width:    16 + 6
    p_height:   24 + 8
    p_gap:      0
    vert_gap:   0
    
    pattern: GBR -> RGB
    top-left: middle of green dot
*/

/*
 *  Our goal is to use arithmetic to generate the phosphor mask.
 *  Phosphor masks are regular patterns, so we want something periodic.
 *  We want to avoid modular arithmetic because it tends to be inconsistent.
 *  
 *  For all masks, we want to approximate a pulse wave in at least one dimension. This pulse wave
 *  will have narrow peaks, wide troughs, and constant periodicity.
 *    GRILLE will have a pulse wave along the x-axis and will be constant along the y-axis.
 *    SLOT and SHADOW will likely have a superposition of two out-of-phase pulse waves along each axis.
 *      For SHADOW, the width of the peaks will vary such that they generate ellipsoids on the screen.
 *
 *  I've found that `f(t) = 1 - (1 - (0.5 + 0.5 cos(2 pi (t n - o)))^p)^q` can approximate a pulse wave well.
 *    t is the input coordinate in the domain [0, 1].
 *      t = 0 is the left side of the screen, and t = 1 is the right side.
 *    n is the desired number of triads to render along this axis.
 *      Because t is in [0, 1], this is also the periodicity of the pulse wave.
 *    o is the horizontal offset along this axis, normalized to raw_offset / raw_triad_width.
 *      We have `tn - o` instead of `n (t - o)` because t in [0, 1] spans the entire screen, while o in [0, 1] only spans
 *      one triad. Multiplying t by n fixes this mismatch.
 *    p primarily controls the width of troughs, and q primarily the width of peaks.
 *      Large values of p and q produce better approximations of a square wave, but also tend to produce narrower peaks.
 *      In the limit of p and q, f(t) becomes a periodic delta function with frequency 1/s.
 *
 *    This function works by scaling cos(x) to the range [0, 1], so raising it to a large power flattens out the troughs
 *    and sharpens the peaks. Subtracting this result from 1 lets us flip around to flattening the peaks and
 *    sharpening the troughs. We subtract from 1 again to flip back to our original orientation.
 *
 *  It's impractical to describe the effects of p and q analytically, but we can define p in terms of q if we are
 *  willing to choose a pair (t0, y0) that satisfies f(t0) = y0. This equates to us deciding the intensity that denotes the
 *  approximate edge of a phosphor and the width of the phosphor in this axis, which is precisely what we need.
 *    p = log(1 - (1 - y0)^(1/q)) / log(0.5 + 0.5 cos(2 pi t))
 *
 *    For this step, we can use o = 0 to simplify the math and make the function more user-friendly.
 *    Using n = 1 makes this work significantly better. Using n > 1 produces peaks
 *    that are too wide when we plug p back into f(t). I don't know why.
 *
 *  For the GRILLE and SLOT masks, we can compute p once and recycle it.
 *  For the SHADOW mask, we can either compute p on each iteration or find a way to interpolate between min_p and max_p.
 *
 *  Technically you could also use the form g(t) = (1 - (0.5 - 0.5 cos(t))^p)^q. This would save a couple subtraction
 *  operatons, but the resulting square wave approximation isn't quite as good. It ends up having more rounded peaks.
 *  In order to achieve g(t) ~= f(t), you have to choose q_g ~= q_f^2. This is because our "flattening" operations
 *  are not associative.
 *
 *  
 *
 *  One might expect it'd be way better to use a clamped triangle wave rather than an exponentiated cosine wave. 
 *  As far as I can tell, this ends up being incorrect surprisingly enough. Although it's a good bit faster,
 *  it has terrible aliasing artifacts at small scales. The cosine implementation is slower, but it produces
 *  evenly-sized RGB phosphors for a variety of configurations even when the triad width is 3 pixels. At that
 *  scale, the triangle wave approach produces triads where one of the phosphors is thicker than the others.
 *  Taking into account the compute_mask_factor trick, the triangle wave approach would be a negligible
 *  performance improvement at the cost of a large drop in visual quality and user friendliness.
 */


#include "bind-shader-params.fxh"
#include "scanline-functions.fxh"

/*
 *  The GRILLE mask consists of an array of vertical stripes, so each channel will vary along the x-axis and will be constant
 *  along the y-axis.
 *
 *  It has the following dimensions:
 *    Phosphors are 18 units wide with unbounded height.
 *    Phosphors in a triad are 2 units apart.
 *    Triads are 6 units apart.
 *    Triad centers are 64 units apart.
 *    The phosphors follow an RGB pattern.
 *    The left-most phosphor is red and offset by 3 units to the right.
 */
static const float grille_raw_phosphor_width = 18;
static const float grille_raw_phosphor_gap = 2;
static const float grille_raw_triad_horiz_gap = 6;
static const float grille_raw_triad_width = 3*grille_raw_phosphor_width + 2*grille_raw_phosphor_gap + grille_raw_triad_horiz_gap;

static const float grille_raw_r_offset = (grille_raw_triad_horiz_gap + grille_raw_phosphor_width) / 2;
static const float grille_raw_g_offset = grille_raw_r_offset + grille_raw_phosphor_width + grille_raw_phosphor_gap;
static const float grille_raw_b_offset = grille_raw_g_offset + grille_raw_phosphor_width + grille_raw_phosphor_gap;
static const float3 grille_norm_center_offsets = float3(
    grille_raw_r_offset,
    grille_raw_g_offset,
    grille_raw_b_offset
) / grille_raw_triad_width;

static const float grille_edge_t = grille_raw_phosphor_width / 2;
static const float grille_edge_norm_t = grille_edge_t / grille_raw_triad_width;


/*
 *  The SLOT mask consists of an array of rectangles, so each channel will vary along both the x- and y-axes.
 *
 *  It has the following dimensions:
 *    Phosphors are 18 units wide and 66 units tall.
 *    Phosphors in a triad are 2 units apart.
 *    Triads are 6 units apart horizontally and 6 units apart vertically.
 *    Triad centers are 64 units apart horizontally and 73 units apart vertically.
 *    The phosphors follow an RGB pattern.
 *    The upper-left-most phosphor is red and offset by 3 units to the right and 3 units down.
 */
static const float slot_raw_phosphor_width = 18;
static const float slot_raw_phosphor_gap = 2;
static const float slot_raw_triad_horiz_gap = 6;
static const float slot_raw_triad_width = 3*slot_raw_phosphor_width + 2*slot_raw_phosphor_gap + slot_raw_triad_horiz_gap;

static const float slot_raw_phosphor_height = 66;
static const float slot_raw_triad_vert_gap = 6;
static const float slot_raw_triad_height = slot_raw_phosphor_height + slot_raw_triad_vert_gap;

static const float slot_aspect_ratio = slot_raw_triad_height / slot_raw_triad_width;

static const float slot_raw_r_offset_x = (slot_raw_triad_horiz_gap + slot_raw_phosphor_width) / 2;
static const float slot_raw_g_offset_x = slot_raw_r_offset_x + slot_raw_phosphor_width + slot_raw_phosphor_gap;
static const float slot_raw_b_offset_x = slot_raw_g_offset_x + slot_raw_phosphor_width + slot_raw_phosphor_gap;
static const float3 slot_norm_center_offsets_x = float3(
    slot_raw_r_offset_x,
    slot_raw_g_offset_x,
    slot_raw_b_offset_x
) / slot_raw_triad_width;
static const float3 slot_norm_center_offsets_y = float3(0.5, 0.5, 0.5);

static const float slot_edge_tx = slot_raw_phosphor_width / 2;
// We draw the slot mask as two sets of columns. To do that, we have to pretend the horizontal gap is the size of a whole triad.
//   Then we need to halve the position of the phosphor edge.
static const float slot_edge_norm_tx = 0.5 * slot_edge_tx / slot_raw_triad_width;
static const float slot_edge_ty = slot_raw_phosphor_height / 2;
static const float slot_edge_norm_ty = slot_edge_ty / slot_raw_triad_height;

/*
 *  The SHADOW mask consists of an array of circles, so each channel will vary along both the x- and y-axes.
 *
 *  It has the following dimensions:
 *    Phosphors are 21 units in diameter.
 *    All phosphors are 0 units apart.
 *    Triad centers are 63 units apart horizontally and 21 units apart vertically.
 *    The phosphors follow a GBR pattern on odd rows and RBG on even rows.
 *    The upper-left-most phosphor is green and centered on the corner of the screen.
 */
static const float shadow_raw_phosphor_diam = 21;
static const float shadow_raw_phosphor_gap = 0;
static const float shadow_raw_triad_horiz_gap = 0;
static const float shadow_raw_triad_vert_gap = 0;

static const float shadow_raw_triad_width = 3*shadow_raw_phosphor_diam + 2*shadow_raw_phosphor_gap + shadow_raw_triad_horiz_gap;
static const float shadow_raw_triad_height = shadow_raw_phosphor_diam + shadow_raw_triad_vert_gap;

static const float shadow_aspect_ratio = shadow_raw_triad_height / shadow_raw_triad_width;

static const float shadow_raw_g_offset_x = 0;
static const float shadow_raw_b_offset_x = shadow_raw_g_offset_x + shadow_raw_phosphor_diam + shadow_raw_phosphor_gap;
static const float shadow_raw_r_offset_x = shadow_raw_b_offset_x + shadow_raw_phosphor_diam + shadow_raw_phosphor_gap;
static const float3 shadow_norm_center_offsets_x = float3(
    shadow_raw_r_offset_x,
    shadow_raw_g_offset_x,
    shadow_raw_b_offset_x
) / shadow_raw_triad_width;

static const float3 shadow_norm_center_offsets_y = float3(0.0, 0.0, 0.0);

static const float shadow_edge_tx = shadow_raw_phosphor_diam / 2;
static const float shadow_edge_norm_tx = shadow_edge_tx / shadow_raw_triad_width;
static const float shadow_edge_ty = shadow_raw_phosphor_diam / 2;
// We draw the shadow mask as two sets of rows. To do that, we have to pretend the vertical gap is the size of a whole triad.
//   Then we need to halve the position of the phosphor edge.
static const float shadow_edge_norm_ty = 0.5 * shadow_edge_ty / shadow_raw_triad_height;
static const float shadow_norm_phosphor_rad = (shadow_raw_phosphor_diam/2) / shadow_raw_triad_width;


/*
 *  The SMALL GRILLE mask is composed of magenta and green stripes.
 *  Sourced from http://filthypants.blogspot.com/2020/02/crt-shader-masks.html
 *  
 *  It has the following dimensions:
 *    Stripes are 32 units wide.
 *    Stripes in a triad are 0 units apart.
 *    Triads are 0 units apart horizontally.
 *    
 *  Each triad has two quads, side-by-side and aligned.
 *    Neighboring triads are offset vertically.
 *    Below is an array of 2 triads.
 *    x's denote magenta stripes, and o's denote green ones.
 *
 *      xxooxxoo
 *      xxooxxoo
 *      xxooxxoo
 *      xxooxxoo
 *      xxooxxoo
 *      xxooxxoo
 *
 *    The phosphors follow a MG pattern.
 *    The left-most phosphor is magenta and offset by 16 units to the right.
 */

static const float smallgrille_raw_stripe_width = 32;
static const float smallgrille_raw_triad_width = 2*smallgrille_raw_stripe_width;

static const float smallgrille_raw_r_offset_x = 0.5 * smallgrille_raw_stripe_width;
static const float smallgrille_raw_g_offset_x = smallgrille_raw_r_offset_x + smallgrille_raw_stripe_width;
static const float smallgrille_raw_b_offset_x = smallgrille_raw_r_offset_x;
static const float3 smallgrille_norm_center_offsets_x = float3(
    smallgrille_raw_r_offset_x,
    smallgrille_raw_g_offset_x,
    smallgrille_raw_b_offset_x
) / smallgrille_raw_triad_width;

static const float smallgrille_edge_t = 0.5 * smallgrille_raw_stripe_width;
static const float smallgrille_edge_norm_t = smallgrille_edge_t / smallgrille_raw_triad_width;


/*
 *  The SMALL SLOT mask is composed of magenta and green quads.
 *  Sourced from http://filthypants.blogspot.com/2020/02/crt-shader-masks.html
 *  
 *  It has the following dimensions:
 *    Quads are 32 units wide and 48 units tall.
 *    Quads in a triad are 0 units apart.
 *    Triads are 0 units apart horizontally and 16 units apart vertically.
 *    
 *  Each triad has two quads, side-by-side and aligned.
 *    Neighboring triads are offset vertically.
 *    Below is a 2x2 matrix of 4 triads.
 *    x's denote magenta quads, and o's denote green ones.
 *
 *      xxoo    
 *      xxooxxoo
 *      xxooxxoo
 *          xxoo
 *      xxoo    
 *      xxooxxoo
 *      xxooxxoo
 *          xxoo
 *
 *    The phosphors follow a MG pattern.
 *    The upper-left-most phosphor is magenta and offset by 16 units to the right and 16 units down.
 */

static const float smallslot_raw_quad_width = 32;
static const float smallslot_raw_triad_width = 2*smallslot_raw_quad_width;

static const float smallslot_raw_quad_height = 1.5 * smallslot_raw_quad_width;
static const float smallslot_raw_triad_vert_gap = 0.5 * smallslot_raw_quad_width;
static const float smallslot_raw_triad_height = smallslot_raw_quad_height + smallslot_raw_triad_vert_gap;

static const float smallslot_aspect_ratio = smallslot_raw_triad_height / smallslot_raw_triad_width;

static const float smallslot_raw_r_offset_x = 0.5 * smallslot_raw_quad_width;
static const float smallslot_raw_g_offset_x = smallslot_raw_r_offset_x + smallslot_raw_quad_width;
static const float smallslot_raw_b_offset_x = smallslot_raw_r_offset_x;
static const float3 smallslot_norm_center_offsets_x = float3(
    smallslot_raw_r_offset_x,
    smallslot_raw_g_offset_x,
    smallslot_raw_b_offset_x
) / smallslot_raw_triad_width;

static const float3 smallslot_norm_center_offsets_y1 = 0.5 * smallslot_raw_quad_height / smallslot_raw_triad_height;
static const float3 smallslot_norm_center_offsets_y2 = smallslot_norm_center_offsets_y1 + smallslot_raw_triad_vert_gap / smallslot_raw_triad_height;

static const float smallslot_edge_tx = 0.5 * smallslot_raw_quad_width;
// We draw the slot mask as two sets of columns. To do that, we have to pretend the horizontal gap is the size of a whole triad.
//   Then we need to halve the position of the phosphor edge.
static const float smallslot_edge_norm_tx = 0.5 * smallslot_edge_tx / smallslot_raw_triad_width;
static const float smallslot_edge_ty = smallslot_raw_quad_height / 2;
static const float smallslot_edge_norm_ty = smallslot_edge_ty / smallslot_raw_triad_height;

/*
 *  The SMALL SHADOW mask is composed of magenta and green quads.
 *  Sourced from http://filthypants.blogspot.com/2020/02/crt-shader-masks.html
 *  
 *  It has the following dimensions:
 *    Quads are 17 units wide and 17 units tall.
 *    Quads in a triad are 0 units apart.
 *    Triads are 0 units apart horizontally and 0 units apart vertically.
 *    
 *  Each triad has two quads, side-by-side and aligned.
 *    Neighboring triads are offset vertically.
 *    Below is a 2x2 matrix of 4 triads.
 *    x's denote magenta quads, and o's denote green ones.
 *
 *      xxooxxoo
 *      xxooxxoo
 *      ooxxooxx
 *      ooxxooxx
 *
 *    The phosphors follow a MG pattern.
 *    The upper-left-most phosphor is magenta and offset by 16 units to the right and 16 units down.
 */

static const float smallshadow_raw_quad_width = 17;
static const float smallshadow_raw_triad_width = 2 * smallshadow_raw_quad_width;

static const float smallshadow_raw_quad_height = 17;
static const float smallshadow_raw_triad_height = smallshadow_raw_quad_height;

static const float smallshadow_aspect_ratio = smallshadow_raw_triad_height / smallshadow_raw_triad_width;

static const float smallshadow_raw_r_offset_x = 0.5 * smallshadow_raw_quad_width;
static const float smallshadow_raw_g_offset_x = smallshadow_raw_r_offset_x + smallshadow_raw_quad_width;
static const float smallshadow_raw_b_offset_x = smallshadow_raw_r_offset_x;
static const float3 smallshadow_norm_center_offsets_x = float3(
    smallshadow_raw_r_offset_x,
    smallshadow_raw_g_offset_x,
    smallshadow_raw_b_offset_x
) / smallshadow_raw_triad_width;

static const float3 smallshadow_norm_center_offsets_y = 0.5 * smallshadow_raw_triad_height;

static const float smallshadow_edge_tx = 0.5 * smallshadow_raw_quad_width;
static const float smallshadow_edge_norm_tx = smallshadow_edge_tx / smallshadow_raw_triad_width;
static const float smallshadow_edge_ty = 0.5 * smallshadow_raw_quad_height;
// We draw the shadow mask as two sets of rows. To do that, we have to pretend the vertical gap is the size of a whole triad.
//   Then we need to halve the position of the phosphor edge.
static const float smallshadow_edge_norm_ty = 0.5 * smallshadow_edge_ty / smallshadow_raw_triad_height;




float get_selected_aspect_ratio() {
    float aspect_ratio;
    [flatten]
    if (mask_type == 0 || mask_type == 3) {
            aspect_ratio = scale_triad_height;
    }
    else if (mask_type == 1 || mask_type == 4) {
            aspect_ratio = scale_triad_height * slot_aspect_ratio;
    }
    else {
            aspect_ratio = scale_triad_height * shadow_aspect_ratio;
    }
    [flatten]
    switch (mask_type) {
        case 0:
            aspect_ratio = scale_triad_height;
            break;
        case 1:
            aspect_ratio = scale_triad_height * slot_aspect_ratio;
            break;
        case 2:
            aspect_ratio = scale_triad_height * shadow_aspect_ratio;
            break;
        case 3:
            aspect_ratio = scale_triad_height;
            break;
        case 4:
            aspect_ratio = scale_triad_height * smallslot_aspect_ratio;
            break;
        default:
            aspect_ratio = scale_triad_height * smallshadow_aspect_ratio;
            break;
    }

    return aspect_ratio;
}

float2 calc_triad_size() {
    const float aspect_ratio = get_selected_aspect_ratio();

    [branch]
    if (mask_size_param == 0) {
        return float2(1, aspect_ratio) * mask_triad_width;
    }
    else {
        float triad_width = content_size.x * rcp(mask_num_triads_across);
        return float2(1, aspect_ratio) * triad_width;
    }

}

float2 calc_phosphor_viewport_frequency_factor() {
    const float aspect_ratio = get_selected_aspect_ratio();

    float2 triad_size_factor;
    float2 num_triads_factor;
    [branch]
    if (geom_rotation_mode == 0 || geom_rotation_mode == 2) {
        triad_size_factor = content_size * rcp(mask_triad_width * float2(1, aspect_ratio));
        num_triads_factor = mask_num_triads_across * float2(1, content_size.y * rcp(content_size.x) * rcp(aspect_ratio));
    }
    else {
        triad_size_factor = content_size * rcp(mask_triad_width * float2(1, aspect_ratio)).yx;
        num_triads_factor = mask_num_triads_across * float2(1, content_size.y * rcp(content_size.x) * rcp(aspect_ratio)).yx;
    }

    return ((mask_size_param == 0) ? triad_size_factor : num_triads_factor);
}


/*
 *  We have a pulse wave f(t0_norm, p, q) = y0 with unknown p.
 *  This function solves for p.
 */
float calculate_phosphor_p_value(
    const float t0_norm,
    const float y0,
    const float q
) {
    static const float n = log(1 - pow(1 - y0, 1/q));
    static const float d = log(0.5 + 0.5 * cos(t0_norm * 2 * pi));

    return n / d;
}

/*
 *  Generates a grille mask with the desired resolution and sharpness.
 */
float3 get_phosphor_intensity_grille(
    const float2 texcoord,
    const float2 viewport_frequency_factor,
    const float2 grille_pq
) {
    float3 center_offsets = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        grille_norm_center_offsets.bgr : grille_norm_center_offsets;

    const float3 theta = 2 * pi * (texcoord.x * viewport_frequency_factor.x - center_offsets);
    const float3 alpha = cos(theta) * 0.5 + 0.5;

    return 1 - pow(1 - pow(alpha, grille_pq.x), grille_pq.y);
}


/*
 *  Generates a slot mask with the desired resolution and sharpness.
 */
float3 get_phosphor_intensity_slot(
    const float2 texcoord,
    const float2 viewport_frequency_factor,
    const float2 slot_pq_x,
    const float2 slot_pq_y
) {
    float3 center_offsets_x = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        slot_norm_center_offsets_x.bgr : slot_norm_center_offsets_x;
    float3 center_offsets_y = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        slot_norm_center_offsets_y.bgr : slot_norm_center_offsets_y;
    
    const float3 theta_x = pi * (texcoord.x * viewport_frequency_factor.x - center_offsets_x);
    const float3 alpha_x1 = cos(theta_x) * 0.5 + 0.5;
    const float3 alpha_x2 = cos(theta_x + pi) * 0.5 + 0.5;
    
    const float3 theta_y = 2 * pi * (texcoord.y * viewport_frequency_factor.y - center_offsets_y);
    const float3 alpha_y1 = cos(theta_y) * 0.5 + 0.5;
    const float3 alpha_y2 = cos(theta_y + pi) * 0.5 + 0.5;

    const float3 f_x1 = 1 - pow(1 - pow(alpha_x1, slot_pq_x.x), slot_pq_x.y);
    const float3 f_x2 = 1 - pow(1 - pow(alpha_x2, slot_pq_x.x), slot_pq_x.y);
    const float3 f_y1 = 1 - pow(1 - pow(alpha_y1, slot_pq_y.x), slot_pq_y.y);
    const float3 f_y2 = 1 - pow(1 - pow(alpha_y2, slot_pq_y.x), slot_pq_y.y);

    return f_x1 * f_y1 + f_x2 * f_y2;
}

/*
 *  Generates a shadow mask with the desired resolution and sharpness.
 */
float3 get_phosphor_intensity_shadow(
    const float2 texcoord,
    const float2 viewport_frequency_factor
) {
    float3 center_offsets_x = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        shadow_norm_center_offsets_x.bgr : shadow_norm_center_offsets_x;
    float3 center_offsets_y = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        shadow_norm_center_offsets_y.bgr : shadow_norm_center_offsets_y;

    const float2 shadow_q = phosphor_sharpness;

    const float3 x_adj = texcoord.x * viewport_frequency_factor.x - center_offsets_x;
    const float3 theta_x = 2 * pi * x_adj;

    const float3 texcoord_x_periodic1 = shadow_norm_phosphor_rad * triangle_wave(x_adj * 3 - 0.5, 1.0);
    const float3 texcoord_x_periodic2 = shadow_norm_phosphor_rad * triangle_wave(x_adj * 3, 1.0);
    const float3 ty1 = sqrt(
        shadow_norm_phosphor_rad*shadow_norm_phosphor_rad - texcoord_x_periodic1*texcoord_x_periodic1
    );
    const float3 ty2 = sqrt(
        shadow_norm_phosphor_rad*shadow_norm_phosphor_rad - texcoord_x_periodic2*texcoord_x_periodic2
    );

    const float shadow_px = (
        log(1 - pow(1 - phosphor_thickness.x, 1/shadow_q.x)) /
        log(0.5 + 0.5 * cos(shadow_edge_norm_tx * 2 * pi))
    );
    const float3 alpha_x1 = cos(theta_x) * 0.5 + 0.5;
    const float3 alpha_x2 = cos(theta_x + pi) * 0.5 + 0.5;
    const float3 f_x1 = 1 - pow(1 - pow(alpha_x1, shadow_px), shadow_q.x);
    const float3 f_x2 = 1 - pow(1 - pow(alpha_x2, shadow_px), shadow_q.x);

    const float3 shadow_py_gamma1 = 0.5 + 0.5 * cos(ty1 * pi / shadow_aspect_ratio);
    const float3 shadow_py_gamma2 = 0.5 + 0.5 * cos(ty2 * pi / shadow_aspect_ratio);
    const float3 shadow_py1 = (
        log(1 - pow(1 - phosphor_thickness.y, 1/shadow_q.y)) /
        log(shadow_py_gamma1)
    );
    const float3 shadow_py2 = (
        log(1 - pow(1 - phosphor_thickness.y, 1/shadow_q.y)) /
        log(shadow_py_gamma2)
    );

    const float3 theta_y = pi * (
        texcoord.y * viewport_frequency_factor.y - center_offsets_y
    );
    const float3 alpha_y1 = cos(theta_y) * 0.5 + 0.5;
    const float3 alpha_y2 = cos(theta_y + pi) * 0.5 + 0.5;

    const float3 f_y1 = 1 - pow(1 - pow(alpha_y1, shadow_py1), shadow_q.y);
    const float3 f_y2 = 1 - pow(1 - pow(alpha_y2, shadow_py2), shadow_q.y);
    return f_x1 * f_y1 + f_x2 * f_y2;
}

float3 get_phosphor_intensity_grille_small(
    const float2 texcoord,
    const float2 viewport_frequency_factor,
    const float2 slot_pq_x
) {
    float3 center_offsets_x = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        smallgrille_norm_center_offsets_x.grg : smallgrille_norm_center_offsets_x;
    
    const float3 theta_x = 2 * pi * (texcoord.x * viewport_frequency_factor.x - center_offsets_x);
    const float3 alpha_x = cos(theta_x) * 0.5 + 0.5;

    const float3 f_x = 1 - pow(1 - pow(alpha_x, slot_pq_x.x), slot_pq_x.y);

    // Taking a sqrt here helps hide the gaps between the pixels when the triad size is small
    return sqrt(f_x);
}

float3 get_phosphor_intensity_slot_small(
    const float2 texcoord,
    const float2 viewport_frequency_factor,
    const float2 slot_pq_x,
    const float2 slot_pq_y
) {
    float3 center_offsets_x = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        smallslot_norm_center_offsets_x.grg : smallslot_norm_center_offsets_x;
    float3 center_offsets_y1 = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        smallslot_norm_center_offsets_y1.grg : smallslot_norm_center_offsets_y1;
    float3 center_offsets_y2 = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        smallslot_norm_center_offsets_y2.grg : smallslot_norm_center_offsets_y2;
    
    const float3 theta_x = pi * (texcoord.x * viewport_frequency_factor.x - center_offsets_x);
    const float3 alpha_x1 = cos(theta_x) * 0.5 + 0.5;
    const float3 alpha_x2 = cos(theta_x + pi) * 0.5 + 0.5;
    
    const float3 theta_y1 = 2 * pi * (texcoord.y * viewport_frequency_factor.y - center_offsets_y1);
    const float3 alpha_y1 = cos(theta_y1) * 0.5 + 0.5;
    const float3 theta_y2 = 2 * pi * (texcoord.y * viewport_frequency_factor.y - center_offsets_y2);
    const float3 alpha_y2 = cos(theta_y2) * 0.5 + 0.5;

    const float3 f_x1 = 1 - pow(1 - pow(alpha_x1, slot_pq_x.x), slot_pq_x.y);
    const float3 f_x2 = 1 - pow(1 - pow(alpha_x2, slot_pq_x.x), slot_pq_x.y);
    const float3 f_y1 = 1 - pow(1 - pow(alpha_y1, slot_pq_y.x), slot_pq_y.y);
    const float3 f_y2 = 1 - pow(1 - pow(alpha_y2, slot_pq_y.x), slot_pq_y.y);

    // Taking a sqrt here helps hide the gaps between the pixels when the triad size is small
    return sqrt(f_x1 * f_y1 + f_x2 * f_y2);
}

float3 get_phosphor_intensity_shadow_small(
    const float2 texcoord,
    const float2 viewport_frequency_factor,
    const float2 shadow_pq_x,
    const float2 shadow_pq_y
) {
    float3 center_offsets_x = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        smallshadow_norm_center_offsets_x.grg : smallshadow_norm_center_offsets_x;
    float3 center_offsets_y = (geom_rotation_mode == 2 || geom_rotation_mode == 3) ?
        smallshadow_norm_center_offsets_y.grg : smallshadow_norm_center_offsets_y;
    
    const float3 alpha_x1 = triangle_wave(texcoord.x * viewport_frequency_factor.x - center_offsets_x, 1.0);
    const float3 alpha_x2 = triangle_wave(texcoord.x * viewport_frequency_factor.x - center_offsets_x + 0.5, 1.0);
    const float3 alpha_y1 = triangle_wave(texcoord.y * viewport_frequency_factor.y - center_offsets_y, 0.5);
    const float3 alpha_y2 = triangle_wave(texcoord.y * viewport_frequency_factor.y - center_offsets_y + 1, 0.5);

    const float3 f_x1 = 1 - pow(1 - pow(alpha_x1, shadow_pq_x.x), shadow_pq_x.y);
    const float3 f_x2 = 1 - pow(1 - pow(alpha_x2, shadow_pq_x.x), shadow_pq_x.y);
    const float3 f_y1 = 1 - pow(1 - pow(alpha_y1, shadow_pq_y.x), shadow_pq_y.y);
    const float3 f_y2 = 1 - pow(1 - pow(alpha_y2, shadow_pq_y.x), shadow_pq_y.y);

    // Taking a sqrt here helps hide the gaps between the pixels when the triad size is small
    return sqrt(f_x1 * f_y1 + f_x2 * f_y2);
}

#endif  //  _PHOSHOR_MASK_CALCULATIONS_H