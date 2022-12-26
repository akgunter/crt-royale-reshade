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
#include "../lib/gamma-management.fxh"
#include "../lib/phosphor-mask-resizing.fxh"

#include "shared-objects.fxh"

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
 *    n is desired number of triads to render along this axis.
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
 *    Using n = 1 makes this work significantly better. Multiplying by n produces peaks
 *    that are too wide when we plug p back into f(t). I don't know why.
 *
 *  For the GRILLE and SLOT masks, we can compute p once and recycle it.
 *  For the SHADOW mask, we can either compute p on each iteration or find a way to interpolate between min_p and max_p.
 *
 *  Technically you could also use the form g(t) = (1 - (0.5 - 0.5 cos(t))^p)^q. This would save a couple subtraction
 *  operatons, but the resulting square wave approximation isn't quite as good. It ends up having more rounded peaks.
 *  In order to achieve g(t) ~= f(t), you have to choose q_g ~= q_f^2. This is because our "stretching" operations
 *  are not associative.
 */

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
static const float slot_edge_norm_tx = slot_edge_tx / slot_raw_triad_width;
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
static const float shadow_edge_norm_ty = shadow_edge_ty / shadow_raw_triad_height;
static const float shadow_norm_phosphor_rad = (shadow_raw_phosphor_diam/2) / shadow_raw_triad_width;


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
    const float3 theta = 2 * pi * (texcoord.x * viewport_frequency_factor.x - grille_norm_center_offsets);
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
    const float3 theta_x = pi * (texcoord.x * viewport_frequency_factor.x - slot_norm_center_offsets_x);
    const float3 alpha_x1 = cos(theta_x) * 0.5 + 0.5;
    const float3 alpha_x2 = cos(theta_x + pi) * 0.5 + 0.5;
    
    const float3 theta_y = 2 * pi * (texcoord.y * viewport_frequency_factor.y - slot_norm_center_offsets_y);
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
    const float2 shadow_q = phosphor_sharpness;

    const float3 x_adj = texcoord.x * viewport_frequency_factor.x - shadow_norm_center_offsets_x;
	const float3 theta_x = 2 * pi * x_adj;

    const float3 texcoord_x_periodic1 = shadow_norm_phosphor_rad * abs(-abs(1 - fmod(3*x_adj, 1.0) * 2) + 1);
    const float3 texcoord_x_periodic2 = shadow_norm_phosphor_rad * abs(-abs(1 - fmod(3*x_adj, 1.0) * 2));
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
        texcoord.y * viewport_frequency_factor.y - shadow_norm_center_offsets_y
    );
    const float3 alpha_y1 = cos(theta_y) * 0.5 + 0.5;
    const float3 alpha_y2 = cos(theta_y + pi) * 0.5 + 0.5;

    const float3 f_y1 = 1 - pow(1 - pow(alpha_y1, shadow_py1), shadow_q.y);
    const float3 f_y2 = 1 - pow(1 - pow(alpha_y2, shadow_py2), shadow_q.y);
    return saturate(f_x1 * f_y1) + saturate(f_x2 * f_y2);
}

void generatePhosphorMaskVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 viewport_frequency_factor: TEXCOORD1,
    out float2 mask_pq_x : TEXCOORD2,
    out float2 mask_pq_y : TEXCOORD3
) {

    const float compute_mask_factor = frame_count % 60 == 0 || overlay_active > 0;
    
    texcoord.x = (id == 2) ? compute_mask_factor*2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

    const float2 viewport_size = tex2Dsize(samplerDeinterlace);
    const float aspect_ratio = aspect_ratio_adjustment * ((mask_type == 1) ? slot_aspect_ratio : shadow_aspect_ratio);
    const float2 triad_size_factor = viewport_size * rcp(mask_triad_size_desired * float2(1, aspect_ratio));
    const float2 num_triads_factor = mask_num_triads_desired * float2(1, viewport_size.y * rcp(viewport_size.x) * rcp(aspect_ratio));

    viewport_frequency_factor = ((mask_specify_num_triads == 0) ? triad_size_factor : num_triads_factor);

    const float edge_norm_tx = (mask_type == 0) ? grille_edge_norm_t : ((mask_type == 1) ? slot_edge_norm_tx*0.5 : shadow_edge_norm_tx);
    const float edge_norm_ty = (mask_type == 1) ? slot_edge_norm_ty : shadow_edge_norm_ty*0.5;

    const float mask_p_x = calculate_phosphor_p_value(edge_norm_tx, phosphor_thickness.x, phosphor_sharpness.x);
    const float mask_p_y = calculate_phosphor_p_value(edge_norm_ty, phosphor_thickness.y, phosphor_sharpness.y);
    mask_pq_x = float2(mask_p_x, phosphor_sharpness.x);
    mask_pq_y = float2(mask_p_y, phosphor_sharpness.y);
}

void generatePhosphorMaskPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 viewport_frequency_factor: TEXCOORD1,
    in float2 mask_pq_x : TEXCOORD2,
    in float2 mask_pq_y : TEXCOORD3,
    
    out float4 color : SV_Target
) {
    float3 phosphor_color;
    if (mask_type == 0) {
        phosphor_color = get_phosphor_intensity_grille(
            texcoord,
            viewport_frequency_factor,
            mask_pq_x
        );
    }
    else if (mask_type == 1) {
        phosphor_color = get_phosphor_intensity_slot(
            texcoord,
            viewport_frequency_factor,
            mask_pq_x,
            mask_pq_y
        );
    }
    else {
        phosphor_color = get_phosphor_intensity_shadow(
            texcoord,
            viewport_frequency_factor
        );
    }

    color = float4(phosphor_color, 1.0);
}


void applyComputedPhosphorMaskPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    
    out float4 color : SV_Target
) {
    const float3 scanline_color_dim = tex2D(samplerDeinterlace, texcoord).rgb;
    const float3 phosphor_color = tex2D(samplerPhosphorMask, texcoord).rgb;

    //  Sample the halation texture (auto-dim to match the scanlines), and
    //  account for both horizontal and vertical convergence offsets, given
    //  in units of texels horizontally and same-field scanlines vertically:
    const float3 halation_color = tex2D_linearize(samplerBlurHorizontal, texcoord, get_intermediate_gamma()).rgb;

    //  Apply halation: Halation models electrons flying around under the glass
    //  and hitting the wrong phosphors (of any color).  It desaturates, so
    //  average the halation electrons to a scalar.  Reduce the local scanline
    //  intensity accordingly to conserve energy.
    const float halation_intensity_dim_scalar = dot(halation_color, 1.0 / float3(1, 1, 1));
    const float3 halation_intensity_dim = halation_intensity_dim_scalar * float3(1, 1, 1);
    const float3 electron_intensity_dim = lerp(scanline_color_dim, halation_intensity_dim, halation_weight);

    //  Apply the phosphor mask:
    const float3 phosphor_emission_dim = electron_intensity_dim * phosphor_color;
    
    color = float4(phosphor_emission_dim, 1.0);
}