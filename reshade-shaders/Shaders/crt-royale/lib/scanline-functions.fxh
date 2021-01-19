#ifndef _SCANLINE_FUNCTIONS_H
#define _SCANLINE_FUNCTIONS_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
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


///////////////////////////////  BEGIN INCLUDES  ///////////////////////////////

#include "bind-shader-params.fxh"
#include "gamma-management.fxh"
#include "special-functions.fxh"

////////////////////////////////  END INCLUDES  ////////////////////////////////

/////////////////////////////  SCANLINE FUNCTIONS  /////////////////////////////

float3 get_gaussian_sigma(const float3 color, const float sigma_range)
{
    //  Requires:   Globals:
    //              1.) beam_min_sigma and beam_max_sigma are global floats
    //                  containing the desired minimum and maximum beam standard
    //                  deviations, for dim and bright colors respectively.
    //              2.) beam_max_sigma must be > 0.0
    //              3.) beam_min_sigma must be in (0.0, beam_max_sigma]
    //              4.) beam_spot_power must be defined as a global float.
    //              Parameters:
    //              1.) color is the underlying source color along a scanline
    //              2.) sigma_range = beam_max_sigma - beam_min_sigma; we take
    //                  sigma_range as a parameter to avoid repeated computation
    //                  when beam_{min, max}_sigma are runtime shader parameters
    //  Optional:   Users may set beam_spot_shape_function to 1 to define the
    //              inner f(color) subfunction (see below) as:
    //                  f(color) = sqrt(1.0 - (color - 1.0)*(color - 1.0))
    //              Otherwise (technically, if beam_spot_shape_function < 0.5):
    //                  f(color) = pow(color, beam_spot_power)
    //  Returns:    The standard deviation of the Gaussian beam for "color:"
    //                  sigma = beam_min_sigma + sigma_range * f(color)
    //  Details/Discussion:
    //  The beam's spot shape vaguely resembles an aspect-corrected f() in the
    //  range [0, 1] (not quite, but it's related).  f(color) = color makes
    //  spots look like diamonds, and a spherical function or cube balances
    //  between variable width and a soft/realistic shape.   A beam_spot_power
    //  > 1.0 can produce an ugly spot shape and more initial clipping, but the
    //  final shape also differs based on the horizontal resampling filter and
    //  the phosphor bloom.  For instance, resampling horizontally in nonlinear
    //  light and/or with a sharp (e.g. Lanczos) filter will sharpen the spot
    //  shape, but a sixth root is still quite soft.  A power function (default
    //  1.0/3.0 beam_spot_power) is most flexible, but a fixed spherical curve
    //  has the highest variability without an awful spot shape.
    //
    //  beam_min_sigma affects scanline sharpness/aliasing in dim areas, and its
    //  difference from beam_max_sigma affects beam width variability.  It only
    //  affects clipping [for pure Gaussians] if beam_spot_power > 1.0 (which is
    //  a conservative estimate for a more complex constraint).
    //
    //  beam_max_sigma affects clipping and increasing scanline width/softness
    //  as color increases.  The wider this is, the more scanlines need to be
    //  evaluated to avoid distortion.  For a pure Gaussian, the max_beam_sigma
    //  at which the first unused scanline always has a weight < 1.0/255.0 is:
    //      num scanlines = 2, max_beam_sigma = 0.2089; distortions begin ~0.34
    //      num scanlines = 3, max_beam_sigma = 0.3879; distortions begin ~0.52
    //      num scanlines = 4, max_beam_sigma = 0.5723; distortions begin ~0.70
    //      num scanlines = 5, max_beam_sigma = 0.7591; distortions begin ~0.89
    //      num scanlines = 6, max_beam_sigma = 0.9483; distortions begin ~1.08
    //  Generalized Gaussians permit more leeway here as steepness increases.
    if(beam_spot_shape_function < 0.5)
    {
        //  Use a power function:
        return float3(beam_min_sigma, beam_min_sigma, beam_min_sigma) + sigma_range *
            pow(color, float3(beam_spot_power, beam_spot_power, beam_spot_power));
    }
    else
    {
        //  Use a spherical function:
        const float3 color_minus_1 = color - float3(1.0, 1.0, 1.0);
        return float3(beam_min_sigma, beam_min_sigma, beam_min_sigma) + sigma_range *
            sqrt(float3(1.0, 1.0, 1.0) - color_minus_1*color_minus_1);
    }
}

float3 get_generalized_gaussian_beta(const float3 color,
    const float shape_range)
{
    //  Requires:   Globals:
    //              1.) beam_min_shape and beam_max_shape are global floats
    //                  containing the desired min/max generalized Gaussian
    //                  beta parameters, for dim and bright colors respectively.
    //              2.) beam_max_shape must be >= 2.0
    //              3.) beam_min_shape must be in [2.0, beam_max_shape]
    //              4.) beam_shape_power must be defined as a global float.
    //              Parameters:
    //              1.) color is the underlying source color along a scanline
    //              2.) shape_range = beam_max_shape - beam_min_shape; we take
    //                  shape_range as a parameter to avoid repeated computation
    //                  when beam_{min, max}_shape are runtime shader parameters
    //  Returns:    The type-I generalized Gaussian "shape" parameter beta for
    //              the given color.
    //  Details/Discussion:
    //  Beta affects the scanline distribution as follows:
    //  a.) beta < 2.0 narrows the peak to a spike with a discontinuous slope
    //  b.) beta == 2.0 just degenerates to a Gaussian
    //  c.) beta > 2.0 flattens and widens the peak, then drops off more steeply
    //      than a Gaussian.  Whereas high sigmas widen and soften peaks, high
    //      beta widen and sharpen peaks at the risk of aliasing.
    //  Unlike high beam_spot_powers, high beam_shape_powers actually soften shape
    //  transitions, whereas lower ones sharpen them (at the risk of aliasing).
    return beam_min_shape + shape_range * pow(color, float3(beam_shape_power, beam_shape_power, beam_shape_power));
}

float3 get_raw_interpolated_color(const float3 color0,
    const float3 color1, const float3 color2, const float3 color3,
    const float4 weights)
{
    //  Use max to avoid bizarre artifacts from negative colors:
    const float4x3 mtrx = float4x3(color0, color1, color2, color3);
    const float3 m = mul(weights, mtrx);
    return max(m, 0.0);
}

float3 get_interpolated_linear_color(const float3 color0, const float3 color1,
    const float3 color2, const float3 color3, const float4 weights)
{
    //  Requires:   1.) Requirements of include/gamma-management.h must be met:
    //                  intermediate_gamma must be globally defined, and input
    //                  colors are interpreted as linear RGB unless you #define
    //                  GAMMA_ENCODE_EVERY_FBO (in which case they are
    //                  interpreted as gamma-encoded with intermediate_gamma).
    //              2.) color0-3 are colors sampled from a texture with tex2D().
    //                  They are interpreted as defined in requirement 1.
    //              3.) weights contains weights for each color, summing to 1.0.
    //              4.) beam_horiz_linear_rgb_weight must be defined as a global
    //                  float in [0.0, 1.0] describing how much blending should
    //                  be done in linear RGB (rest is gamma-corrected RGB).
    //              5.) _RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE must be #defined
    //                  if beam_horiz_linear_rgb_weight is anything other than a
    //                  static constant, or we may try branching at runtime
    //                  without dynamic branches allowed (slow).
    //  Returns:    Return an interpolated color lookup between the four input
    //              colors based on the weights in weights.  The final color will
    //              be a linear RGB value, but the blending will be done as
    //              indicated above.
    const float intermediate_gamma = get_intermediate_gamma();
    const float inv_intermediate_gamma = 1.0 / intermediate_gamma;
    //  Branch if beam_horiz_linear_rgb_weight is static (for free) or if the
    //  profile allows dynamic branches (faster than computing extra pows):
    #if !_RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE
        #define SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
    #else
        #if _DRIVERS_ALLOW_DYNAMIC_BRANCHES
            #define SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
        #endif
    #endif
    #ifdef SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
        //  beam_horiz_linear_rgb_weight is static, so we can branch:
        #ifdef GAMMA_ENCODE_EVERY_FBO
            const float3 gamma_mixed_color = pow(get_raw_interpolated_color(
                color0, color1, color2, color3, weights), float3(intermediate_gamma, intermediate_gamma, intermediate_gamma));
            if(beam_horiz_linear_rgb_weight > 0.0)
            {
                const float3 linear_mixed_color = get_raw_interpolated_color(
                    pow(color0, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                    pow(color1, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                    pow(color2, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                    pow(color3, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                    weights);
                return lerp(gamma_mixed_color, linear_mixed_color,
                    beam_horiz_linear_rgb_weight);
            }
            else
            {
                return gamma_mixed_color;
            }
        #else
            const float3 linear_mixed_color = get_raw_interpolated_color(
                color0, color1, color2, color3, weights);
            if(beam_horiz_linear_rgb_weight < 1.0)
            {
                const float3 gamma_mixed_color = get_raw_interpolated_color(
                    pow(color0, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    pow(color1, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    pow(color2, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    pow(color3, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    weights);
                return lerp(gamma_mixed_color, linear_mixed_color,
                    beam_horiz_linear_rgb_weight);
            }
            else
            {
                return linear_mixed_color;
            }
        #endif  //  GAMMA_ENCODE_EVERY_FBO
    #else
        #ifdef GAMMA_ENCODE_EVERY_FBO
            //  Inputs: color0-3 are colors in gamma-encoded RGB.
            const float3 gamma_mixed_color = pow(get_raw_interpolated_color(
                color0, color1, color2, color3, weights), intermediate_gamma);
            const float3 linear_mixed_color = get_raw_interpolated_color(
                pow(color0, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                pow(color1, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                pow(color2, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                pow(color3, float3(intermediate_gamma, intermediate_gamma, intermediate_gamma)),
                weights);
            return lerp(gamma_mixed_color, linear_mixed_color,
                beam_horiz_linear_rgb_weight);
        #else
            //  Inputs: color0-3 are colors in linear RGB.
            const float3 linear_mixed_color = get_raw_interpolated_color(
                color0, color1, color2, color3, weights);
            const float3 gamma_mixed_color = get_raw_interpolated_color(
                    pow(color0, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    pow(color1, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    pow(color2, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    pow(color3, float3(inv_intermediate_gamma, inv_intermediate_gamma, inv_intermediate_gamma)),
                    weights);
            // wtf fixme
//			const float beam_horiz_linear_rgb_weight1 = 1.0;
            return lerp(gamma_mixed_color, linear_mixed_color,
                beam_horiz_linear_rgb_weight);
        #endif  //  GAMMA_ENCODE_EVERY_FBO
    #endif  //  SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
}

float3 get_scanline_color(const sampler2D tex, const float2 scanline_uv,
    const float2 uv_step_x, const float4 weights)
{
    //  Requires:   1.) scanline_uv must be vertically snapped to the caller's
    //                  desired line or scanline and horizontally snapped to the
    //                  texel just left of the output pixel (color1)
    //              2.) uv_step_x must contain the horizontal uv distance
    //                  between texels.
    //              3.) weights must contain interpolation filter weights for
    //                  color0, color1, color2, and color3, where color1 is just
    //                  left of the output pixel.
    //  Returns:    Return a horizontally interpolated texture lookup using 2-4
    //              nearby texels, according to weights and the conventions of
    //              get_interpolated_linear_color().
    //  We can ignore the outside texture lookups for Quilez resampling.
    const float3 color1 = tex2D(tex, scanline_uv).rgb;
    const float3 color2 = tex2D(tex, scanline_uv + uv_step_x).rgb;
    float3 color0 = float3(0.0, 0.0, 0.0);
    float3 color3 = float3(0.0, 0.0, 0.0);
    if(beam_horiz_filter > 0.5)
    {
        color0 = tex2D(tex, scanline_uv - uv_step_x).rgb;
        color3 = tex2D(tex, scanline_uv + 2.0 * uv_step_x).rgb;
    }
    //  Sample the texture as-is, whether it's linear or gamma-encoded:
    //  get_interpolated_linear_color() will handle the difference.
    return get_interpolated_linear_color(color0, color1, color2, color3, weights);
}

float3 sample_single_scanline_horizontal(const sampler2D tex,
    const float2 tex_uv, const float2 tex_size,
    const float2 texture_size_inv)
{
    //  TODO: Add function requirements.
    //  Snap to the previous texel and get sample dists from 2/4 nearby texels:
    const float2 curr_texel = tex_uv * tex_size;
    //  Use under_half to fix a rounding bug right around exact texel locations.
    const float2 prev_texel =
        floor(curr_texel - float2(under_half, under_half)) + float2(0.5, 0.5);
    const float2 prev_texel_hor = float2(prev_texel.x, curr_texel.y);
    const float2 prev_texel_hor_uv = prev_texel_hor * texture_size_inv;
    const float prev_dist = curr_texel.x - prev_texel_hor.x;
    const float4 sample_dists = float4(1.0 + prev_dist, prev_dist,
        1.0 - prev_dist, 2.0 - prev_dist);
    //  Get Quilez, Lanczos2, or Gaussian resize weights for 2/4 nearby texels:
    float4 weights;
    if(beam_horiz_filter < 0.5)
    {
        //  Quilez:
        const float x = sample_dists.y;
        const float w2 = x*x*x*(x*(x*6.0 - 15.0) + 10.0);
        weights = float4(0.0, 1.0 - w2, w2, 0.0);
    }
    else if(beam_horiz_filter < 1.5)
    {
        //  Gaussian:
        float inner_denom_inv = 1.0/(2.0*beam_horiz_sigma*beam_horiz_sigma);
        weights = exp(-(sample_dists*sample_dists)*inner_denom_inv);
    }
    else
    {
        //  Lanczos2:
        const float4 pi_dists = FIX_ZERO(sample_dists * pi);
        weights = 2.0 * sin(pi_dists) * sin(pi_dists * 0.5) /
            (pi_dists * pi_dists);
    }
    //  Ensure the weight sum == 1.0:
    const float4 final_weights = weights/dot(weights, float4(1.0, 1.0, 1.0, 1.0));
    //  Get the interpolated horizontal scanline color:
    const float2 uv_step_x = float2(texture_size_inv.x, 0.0);
    return get_scanline_color(
        tex, prev_texel_hor_uv, uv_step_x, final_weights);
}

float3 sample_rgb_scanline_horizontal(const sampler2D tex,
    const float2 tex_uv, const float2 tex_size,
    const float2 texture_size_inv)
{
    //  TODO: Add function requirements.
    //  Rely on a helper to make convergence easier.
    if(beam_misconvergence)
    {
        const float3 convergence_offsets_rgb =
            get_convergence_offsets_x_vector();
        const float3 offset_u_rgb =
            convergence_offsets_rgb * texture_size_inv.xxx;
        const float2 scanline_uv_r = tex_uv - float2(offset_u_rgb.r, 0.0);
        const float2 scanline_uv_g = tex_uv - float2(offset_u_rgb.g, 0.0);
        const float2 scanline_uv_b = tex_uv - float2(offset_u_rgb.b, 0.0);
        const float3 sample_r = sample_single_scanline_horizontal(
            tex, scanline_uv_r, tex_size, texture_size_inv);
        const float3 sample_g = sample_single_scanline_horizontal(
            tex, scanline_uv_g, tex_size, texture_size_inv);
        const float3 sample_b = sample_single_scanline_horizontal(
            tex, scanline_uv_b, tex_size, texture_size_inv);
        return float3(sample_r.r, sample_g.g, sample_b.b);
    }
    else
    {
        return sample_single_scanline_horizontal(tex, tex_uv, tex_size,
            texture_size_inv);
    }
}

float3 get_bobbed_scanline_sample(
    sampler2D tex, const float2 texcoord,
    const float scanline_start_y, const float v_step_y,
    const float input_gamma
) {
    // Sample `scanline_num_pixels` vertically-contiguous pixels and average them.

    float3 interpolated_line;
    for (int i = 0; i < scanline_num_pixels; i++) {
        float4 coord = float4(texcoord.x, scanline_start_y + i * v_step_y, 0, 0);
        interpolated_line += tex2Dlod_linearize(tex, coord, input_gamma).rgb;
    }
    interpolated_line /= float(scanline_num_pixels);

    return interpolated_line;
}


float2 get_curr_texel(const float2 tex_uv, const float2 tex_size)
{
    // Rescale tex_uv to match the texture's dimensions
    return floor(tex_uv * tex_size + under_half);
}

float get_curr_scanline_idx(
    const float texcoord_y,
    const float tex_size_y
) {
    // Given a y-coordinate in [0, 1] and a texture size,
    // return the scanline index. Note that a scanline is a single band of
    // thickness `scanline_num_pixels` belonging to a single field.

    const float curr_line_texel_y = floor(texcoord_y * tex_size_y + under_half);
    return floor(curr_line_texel_y / scanline_num_pixels);
}

float2 get_frame_and_line_field_idx(const float cur_scanline_idx)
{
    // Given a scanline index, determine which field it belongs to.
    // Also determine which field is being drawn this frame.

    const float modulus = enable_interlacing + 1.0;
    const float frame_field_idx = fmod(frame_count + interlace_bff, modulus);
    const float line_field_idx = fmod(cur_scanline_idx, modulus);

    return float2(frame_field_idx, line_field_idx);
}

float curr_line_is_wrong_field(float cur_scanline_idx)
{
    // Return 1.0 if the current scanline is in the current field.
    // 0.0 otherwise

    const float2 frame_and_line_field_idx = get_frame_and_line_field_idx(cur_scanline_idx);
    return float(frame_and_line_field_idx.x != frame_and_line_field_idx.y);
}

float curr_line_is_wrong_field(float2 frame_and_line_field_idx)
{
    // Return 1.0 if the current scanline is in the current field.
    // 0.0 otherwise

    return float(frame_and_line_field_idx.x != frame_and_line_field_idx.y);
}

float get_scanline_pair_start(const float curr_scanline_idx, const float frame_field_idx)
{
    const float modulus = enable_interlacing + 1.0;
    const float scanline_pair_start = curr_scanline_idx - fmod(curr_scanline_idx, modulus) + frame_field_idx;
    const float upper_line_start = scanline_pair_start * scanline_num_pixels;
    return upper_line_start;
}

float get_beam_center(const float texel_y, const float scanline_idx, const float wrong_field)
{
    const float true_center = scanline_idx * scanline_num_pixels + scanline_num_pixels / 2.0;
    const float direction = texel_y <= true_center ? -1 : 1;

    const float parity_correction = direction * (1 - fmod(scanline_num_pixels, 2.0)) * 0.5;
    const float corrected_center = true_center + parity_correction;

    return corrected_center + wrong_field * direction * scanline_num_pixels;
}

float3 get_dist_from_beam(const float texel_y, const float3 beam_center, const float wrong_field)
{
    return abs(texel_y - beam_center) / scanline_num_pixels;
}


float3 get_beam_strength(float3 dist, float3 color,
    const float sigma_range, const float shape_range)
{
    //  See scanline_gaussian integral_contrib() for detailed comments!
    //  gaussian sample = 1/(sigma*sqrt(2*pi)) * e**(-(x**2)/(2*sigma**2))
    const float3 sigma = get_gaussian_sigma(color, sigma_range);
    //  Avoid repeated divides:
    const float3 sigma_inv = 1.0 / sigma;
    const float3 inner_denom_inv = 0.5 * sigma_inv * sigma_inv;
    const float3 outer_denom_inv = sigma_inv/sqrt(2.0*pi);

    return color*exp(-(dist*dist)*inner_denom_inv)*outer_denom_inv;
}

void get_scanline_base_params(
    const float2 texcoord,
    const float2 tex_size,

    out float2 curr_texel,
    out float curr_scanline_idx,
    out float2 frame_and_line_field_idx,
    out float wrong_field
) {

    curr_texel = get_curr_texel(texcoord, tex_size);
    curr_scanline_idx = get_curr_scanline_idx(texcoord.y, tex_size.y);
    frame_and_line_field_idx = get_frame_and_line_field_idx(curr_scanline_idx);
    wrong_field = curr_line_is_wrong_field(frame_and_line_field_idx);
}


#endif  //  _SCANLINE_FUNCTIONS_H