#ifndef _BIND_SHADER_PARAMS_H
#define _BIND_SHADER_PARAMS_H

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


/////////////////////////////  SETTINGS MANAGEMENT  ////////////////////////////

///////////////////////////////  BEGIN INCLUDES  ///////////////////////////////
#include "helper-functions-and-macros.fxh"
#include "user-settings.fxh"
#include "derived-settings-and-constants.fxh"

////////////////////////////////  END INCLUDES  ////////////////////////////////

//  Override some parameters for gamma-management.h and tex2Dantialias.h:
#ifndef OVERRIDE_DEVICE_GAMMA
    #define OVERRIDE_DEVICE_GAMMA 1
#endif

#ifndef ANTIALIAS_OVERRIDE_BASICS
    #define ANTIALIAS_OVERRIDE_BASICS 1
#endif

#ifndef ANTIALIAS_OVERRIDE_PARAMETERS
    #define ANTIALIAS_OVERRIDE_PARAMETERS 1
#endif

static const float gba_gamma = 3.5; //  Irrelevant but necessary to define.


uniform float crt_gamma <
    ui_label   = "CRT Gamma";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 5.0;
    ui_step    = 0.01;
> = crt_gamma_static;
uniform float lcd_gamma <
    ui_label   = "LCD Gamma";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 5.0;
    ui_step    = 0.01;
> = lcd_gamma_static;
uniform float levels_contrast <
    ui_label   = "Levels Contrast";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = levels_contrast_static;
uniform float halation_weight <
    ui_label   = "Halation";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = halation_weight_static;
uniform float diffusion_weight <
    ui_label   = "Diffusion";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = diffusion_weight_static;
uniform float bloom_underestimate_levels <
    ui_label   = "Bloom Underestimation";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
> = bloom_underestimate_levels_static;
uniform float bloom_excess <
    ui_label   = "Bloom Excess";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = bloom_excess_static;
uniform float beam_min_sigma <
    ui_label   = "Beam Min Sigma";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_min_sigma_static;
uniform float beam_max_sigma <
    ui_label   = "Beam Max Sigma";
    ui_tooltip = "Must be >= Beam Min Sigma";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_max_sigma_static;
uniform float beam_spot_power <
    ui_label   = "Beam Spot Power";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_spot_power_static;
uniform float beam_min_shape <
    ui_label   = "Beam Min Shape";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_min_shape_static;
uniform float beam_max_shape <
    ui_label   = "Beam Max Shape";
    ui_tooltip = "Must be >= Beam Min Shape";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_max_shape_static;
uniform float beam_shape_power <
    ui_label   = "Beam Shape Power";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_shape_power_static;
uniform float beam_horiz_sigma <
    ui_label   = "Beam Horiz Sigma";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
> = beam_horiz_sigma_static;
uniform float beam_horiz_filter <
    ui_label   = "Beam Horiz Filter";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 2.0;
    ui_step    = 1.0;
> = beam_horiz_filter_static;
uniform float beam_horiz_linear_rgb_weight <
    ui_label   = "Beam Horiz Linear RGB Weight";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = beam_horiz_linear_rgb_weight_static;
uniform float convergence_offset_x_r <
    ui_label   = "Convergence Offset X R";
    ui_type    = "slider";
    ui_min     = -4.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = convergence_offsets_r_static.x;
uniform float convergence_offset_x_g <
    ui_label   = "Convergence Offset X G";
    ui_type    = "slider";
    ui_min     = -4.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = convergence_offsets_g_static.x;
uniform float convergence_offset_x_b <
    ui_label   = "Convergence Offset X B";
    ui_type    = "slider";
    ui_min     = -4.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = convergence_offsets_b_static.x;
uniform float convergence_offset_y_r <
    ui_label   = "Convergence Offset Y R";
    ui_type    = "slider";
    ui_min     = -4.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = convergence_offsets_r_static.y;
uniform float convergence_offset_y_g <
    ui_label   = "Convergence Offset Y G";
    ui_type    = "slider";
    ui_min     = -4.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = convergence_offsets_g_static.y;
uniform float convergence_offset_y_b <
    ui_label   = "Convergence Offset Y B";
    ui_type    = "slider";
    ui_min     = -4.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = convergence_offsets_b_static.y;

#ifndef phosphor_mask_type
    #define phosphor_mask_type 1
#endif

#define mask_type phosphor_mask_type

uniform float mask_sample_mode_desired <
    ui_label   = "Mask Sample Mode";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 2.0;
    ui_step    = 1.0;
> = mask_sample_mode_static;
uniform float lanczos_weight_at_center <
    ui_label   = "Lanczos Weight at Center";
    ui_tooltip = "Tunes the sharpness of Mask Sample Mode 0";
    ui_type    = "slider";
    ui_min     = 0.1;
    ui_max     = 20.0;
    ui_step    = 0.1;
> = 1.0;
uniform float mask_specify_num_triads <
    ui_label   = "Mask Specify Num Triads";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 1.0;
> = mask_specify_num_triads_static;
uniform float mask_triad_size_desired <
    ui_label   = "Mask Triad Size";
    ui_type    = "slider";
    ui_min     = 3.0;
    ui_max     = 18.0;
    ui_step    = 0.1;
> = mask_triad_size_desired_static;
uniform float mask_num_triads_desired <
    ui_label   = "Mask Num Triads";
    ui_type    = "input";
    ui_min     = 1.0;
    ui_max     = 1280.0;
    ui_step    = 1.0;
> = mask_num_triads_desired_static;
uniform float aa_subpixel_r_offset_x_runtime <
    ui_label   = "AA Subpixel R Offet X";
    ui_type    = "slider";
    ui_min     = -0.5;
    ui_max     = 0.5;
    ui_step    = 0.01;
> = aa_subpixel_r_offset_static.x;
uniform float aa_subpixel_r_offset_y_runtime <
    ui_label   = "AA Subpixel R Offet Y";
    ui_type    = "slider";
    ui_min     = -0.5;
    ui_max     = 0.5;
    ui_step    = 0.01;
> = aa_subpixel_r_offset_static.y;

static const float aa_cubic_c = aa_cubic_c_static;
static const float aa_gauss_sigma = aa_gauss_sigma_static;

uniform float geom_mode_runtime <
    ui_label   = "Geom Mode";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 3.0;
    ui_step    = 1.0;
> = geom_mode_static;
uniform float geom_radius <
    ui_label   = "Geom Radius";
    ui_type    = "slider";
    ui_min     = 1.0 / (2.0 * pi);
    ui_max     = 1024;
    ui_step    = 0.01;
> = geom_radius_static;
uniform float geom_view_dist <
    ui_label   = "Geom View Distance";
    ui_type    = "slider";
    ui_min     = 0.5;
    ui_max     = 1024;
    ui_step    = 0.01;
> = geom_view_dist_static;
uniform float geom_tilt_angle_x <
    ui_label   = "Geom Tilt Angle X";
    ui_type    = "slider";
    ui_min     = -pi;
    ui_max     = pi;
    ui_step    = 0.01;
> = geom_tilt_angle_static.x;
uniform float geom_tilt_angle_y <
    ui_label   = "Geom Tilt Angle Y";
    ui_type    = "slider";
    ui_min     = -pi;
    ui_max     = pi;
    ui_step    = 0.01;
> = geom_tilt_angle_static.y;
uniform float geom_aspect_ratio_x <
    ui_label   = "Geom Aspect Ratio X";
    ui_type    = "drag";
    ui_min     = 1.0;
    ui_step    = 0.01;
> = geom_aspect_ratio_static;
uniform float geom_aspect_ratio_y <
    ui_label   = "Geom Aspect Ratio Y";
    ui_type    = "drag";
    ui_min     = 1.0;
    ui_step    = 0.01;
> = 1.0;
uniform float geom_overscan_x <
    ui_label   = "Geom Overscan X";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
> = geom_overscan_static.x;
uniform float geom_overscan_y <
    ui_label   = "Geom Overscan Y";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
> = geom_overscan_static.y;
uniform float border_size <
    ui_label   = "Border Size";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 0.5;
    ui_step    = 0.01;
> = border_size_static;
uniform float border_darkness <
    ui_label   = "Border Darkness";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = border_darkness_static;
uniform float border_compress <
    ui_label   = "Border Compress";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = border_compress_static;
uniform float interlace_bff <
    ui_label   = "Use Interlace BFF";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 1.0;
> = interlace_bff_static;
uniform float interlace_1080i <
    ui_label   = "Assume 1080 signal is 1080i";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 1.0;
> = interlace_1080i_static;

//  Provide accessors for vector constants that pack scalar uniforms:
float2 get_aspect_vector(const float geom_aspect_ratio)
{
    //  Get an aspect ratio vector.  Enforce geom_max_aspect_ratio, and prevent
    //  the absolute scale from affecting the uv-mapping for curvature:
    const float geom_clamped_aspect_ratio =
        min(geom_aspect_ratio, geom_max_aspect_ratio);
    const float2 geom_aspect =
        normalize(float2(geom_clamped_aspect_ratio, 1.0));
    return geom_aspect;
}

float2 get_geom_overscan_vector()
{
    return float2(geom_overscan_x, geom_overscan_y);
}

float2 get_geom_tilt_angle_vector()
{
    return float2(geom_tilt_angle_x, geom_tilt_angle_y);
}

float3 get_convergence_offsets_x_vector()
{
    return float3(convergence_offset_x_r, convergence_offset_x_g,
        convergence_offset_x_b);
}

float3 get_convergence_offsets_y_vector()
{
    return float3(convergence_offset_y_r, convergence_offset_y_g,
        convergence_offset_y_b);
}

float2 get_convergence_offsets_r_vector()
{
    return float2(convergence_offset_x_r, convergence_offset_y_r);
}

float2 get_convergence_offsets_g_vector()
{
    return float2(convergence_offset_x_g, convergence_offset_y_g);
}

float2 get_convergence_offsets_b_vector()
{
    return float2(convergence_offset_x_b, convergence_offset_y_b);
}

float2 get_aa_subpixel_r_offset()
{
    #if RUNTIME_ANTIALIAS_WEIGHTS
        #if _RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
            //  WARNING: THIS IS EXTREMELY EXPENSIVE.
            return float2(aa_subpixel_r_offset_x_runtime,
                aa_subpixel_r_offset_y_runtime);
        #else
            return aa_subpixel_r_offset_static;
        #endif
    #else
        return aa_subpixel_r_offset_static;
    #endif
}

//  Provide accessors settings which still need "cooking:"
float get_mask_amplify()
{
    static const float mask_grille_amplify = 1.0/mask_grille_avg_color;
    static const float mask_slot_amplify = 1.0/mask_slot_avg_color;
    static const float mask_shadow_amplify = 1.0/mask_shadow_avg_color;
    return mask_type < 0.5 ? mask_grille_amplify :
        mask_type < 1.5 ? mask_slot_amplify :
        mask_shadow_amplify;
}

float get_mask_sample_mode()
{
    #ifdef _RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
        #if PHOSPHOR_MASK_MANUALLY_RESIZE
            return mask_sample_mode_desired;
        #else
            return clamp(mask_sample_mode_desired, 1.0, 2.0);
        #endif
    #else
        #if PHOSPHOR_MASK_MANUALLY_RESIZE
            return mask_sample_mode_static;
        #else
            return clamp(mask_sample_mode_static, 1.0, 2.0);
        #endif
    #endif
}

#endif  //  _BIND_SHADER_PARAMS_H