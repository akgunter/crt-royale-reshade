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
#ifndef _OVERRIDE_DEVICE_GAMMA
    #define _OVERRIDE_DEVICE_GAMMA 1
#endif

// #ifndef ANTIALIAS_OVERRIDE_BASICS
//     #define ANTIALIAS_OVERRIDE_BASICS 1
// #endif

// #ifndef ANTIALIAS_OVERRIDE_PARAMETERS
//     #define ANTIALIAS_OVERRIDE_PARAMETERS 1
// #endif

static const float gba_gamma = 3.5; //  Irrelevant but necessary to define.

// ==== PHOSPHOR MASK ====
#if __RENDERER__ != 0x9000
    uniform int mask_type <
        ui_label   = "Mask Type";
        ui_tooltip = "Selects the phosphor shape";
        ui_category = "Phosphor Mask";
        ui_type    = "combo";
        ui_items   = "Grille\0"
                     "Slot\0"
                     "Shadow\0";
    > = mask_type_static;
#else
    #define GRILLE 0
    #define SLOT 1
    #define SHADOW 2

    #ifndef phosphor_mask_type
        #define phosphor_mask_type SLOT
    #endif

    #define mask_type phosphor_mask_type
#endif

uniform int mask_sample_mode_desired <
    ui_label   = "Mask Sample Mode";
    ui_tooltip = "Selects the phosphor downsampling method";
    ui_category = "Phosphor Mask";
    ui_type    = "combo";
    ui_items   = "Smooth (Lanczos)\0"
                 "Sharp (Point)\0"
                 "Debug\0";
> = mask_sample_mode_static;
uniform float lanczos_weight_at_center <
    ui_label   = "Downsampling Sharpness";
    ui_tooltip = "Tunes the sharpness of the Smooth Mask Sample Mode";
    ui_category = "Phosphor Mask";
    ui_type    = "slider";
    ui_min     = 0.1;
    ui_max     = 50.0;
    ui_step    = 0.1;
> = 1.0;
uniform int mask_specify_num_triads <
    ui_label   = "Mask Size Param";
    ui_tooltip = "Switch between using Mask Triad Size or Mask Num Triads";
    ui_category = "Phosphor Mask";
    ui_type    = "combo";
    ui_items   = "Triad Width\0"
                 "Num Triads Across\0";
> = mask_specify_num_triads_static;
uniform float mask_triad_size_desired <
    ui_label   = "Mask Triad Width";
    ui_tooltip = "The width of a triad";
    ui_category = "Phosphor Mask";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 18.0;
    ui_step    = 0.1;
> = mask_triad_size_desired_static;
uniform float mask_num_triads_desired <
    ui_label   = "Mask Num Triads Across";
    ui_tooltip = "The number of triads in the viewport (horizontally)";
    ui_category = "Phosphor Mask";
    ui_type    = "drag";
    ui_min     = 1.0;
    ui_max     = 1280.0;
    ui_step    = 1.0;
> = mask_num_triads_desired_static;


// ==== INTERLACING ====
uniform bool enable_interlacing <
    ui_label   = "Enable Interlacing";
    ui_category = "Interlacing and Scanlines";
    // ui_type    = "combo";
    // ui_items   = "No\0Yes\0";
> = true;
uniform int scanline_deinterlacing_mode <
    ui_label   = "Deinterlacing Mode";
    ui_tooltip = "Selects the deinterlacing algorithm. For crt-royale's original appearance, choose None.";
    ui_category = "Interlacing and Scanlines";
    ui_type    = "combo";
    ui_items   = "None\0"
                 "Weaving\0"
                 "Blended Weaving\0"
                 "Static\0";
> = 1;
uniform float scanline_num_pixels <
    ui_label   = "Scanline Thickness";
    ui_category = "Interlacing and Scanlines";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 30.0;
    ui_step    = 1.0;
> = 2.0;
/*
uniform float blur_dim_x <
    ui_label   = "Blur Dim X";
    ui_category = "Interlacing and Scanlines";
    ui_type    = "slider";
    ui_min     = 320;
    ui_max     = 2560;
    ui_step    = 10.0;
> = 2560;
uniform float blur_dim_y <
    ui_label   = "Blur Dim Y";
    ui_category = "Interlacing and Scanlines";
    ui_type    = "slider";
    ui_min     = 240;
    ui_max     = 1440;
    ui_step    = 10.0;
> = 1440;
*/
uniform float scanline_blend_gamma <
    ui_label   = "Scanline Blend Gamma";
    ui_tooltip = "Nudge this if Scanline Blend Strength changes your colors too much";
    ui_category = "Interlacing and Scanlines";
    ui_type    = "slider";
    ui_min     = 0.01;
    ui_max     = 5.0;
    ui_step    = 0.01;
> = 1.0;
uniform bool interlace_bff <
    // ui_type    = "combo";
    ui_label   = "Draw Back-Field First";
    ui_tooltip = "Draw odd-numbered scanlines first (often has no effect)";
    ui_category = "Interlacing and Scanlines";
    // ui_items   = "No\0Yes\0";
> = interlace_bff_static;

// ==== ELECTRON BEAM ====
// static const float beam_min_sigma = beam_min_sigma_static;
// static const float beam_max_sigma = beam_max_sigma_static;
// static const float beam_spot_power = beam_spot_power_static;
// static const float beam_min_shape = beam_min_shape_static;
// static const float beam_max_shape = beam_max_shape_static;
static const float beam_shape_power = beam_shape_power_static;

uniform float3 convergence_offset_x <
    ui_label   = "Convergence Offset X RGB";
    ui_tooltip = "Shift the color channels horizontally";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = -10;
    ui_max     = 10;
    ui_step    = 0.05;
> = 0;
uniform float3 convergence_offset_y <
    ui_label   = "Convergence Offset Y RGB";
    ui_tooltip = "Shift the color channels vertically";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = -10;
    ui_max     = 10;
    ui_step    = 0.05;
> = 0;
uniform int beam_shape_mode <
    ui_label   = "Beam Shape Mode";
    ui_category = "Electron Beam";
    ui_type    = "combo";
    ui_items   = "Digital\0"
                 "Gaussian\0"
                 "Multi-Source Gaussian\0";
> = 1;
/*
uniform float beam_intensity <
    ui_label = "Beam Intensity";
    ui_tooltip = "0.5 recommended for Digital Beam Shape and 0.7 for Gaussian. Adjust from there.";
    ui_category = "Electron Beam";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 2.0;
    ui_step = 0.01;
> = 0.7;
*/
uniform float beam_min_sigma <
    ui_label   = "Beam Min Sigma";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_min_sigma_static;
uniform float beam_max_sigma <
    ui_label   = "Beam Max Sigma";
    ui_tooltip = "Should be >= Beam Min Sigma";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_max_sigma_static;
uniform float beam_spot_power <
    ui_label   = "Beam Spot Power";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_spot_power_static;
uniform float beam_min_shape <
    ui_label   = "Beam Min Shape";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_min_shape_static;
uniform float beam_max_shape <
    ui_label   = "Beam Max Shape";
    ui_tooltip = "Should be >= Beam Min Shape";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_max_shape_static;
/*
uniform float beam_shape_power <
    ui_label   = "Beam Shape Power";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_shape_power_static;
*/
uniform int beam_horiz_filter <
    ui_label   = "Beam Horiz Filter";
    ui_tooltip = "Default is Quilez";
    ui_category = "Electron Beam";
    ui_type    = "combo";
    ui_items   = "None\0"
                 "Quilez (Fast)\0"
                 "Gaussian (Tunable)\0"
                 "Lanczos (Sharp)\0";
> = beam_horiz_filter_static;
uniform float beam_horiz_sigma <
    ui_label   = "Beam Horiz Sigma";
    ui_tooltip = "Requires Gaussian Horiz Filter";
    ui_category = "Electron Beam";
    ui_type    = "slider";
    ui_min     = 0.01;
    ui_max     = 0.67;
    ui_step    = 0.01;
> = beam_horiz_sigma_static;
uniform float beam_horiz_linear_rgb_weight <
    ui_label   = "Beam Horiz Linear RGB Weight";
    ui_category = "Electron Beam";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = beam_horiz_linear_rgb_weight_static;


// ==== IMAGE COLORIZATION ====
uniform float crt_gamma <
    ui_label   = "CRT Gamma";
    ui_tooltip = "The gamma-level of the original content";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 5.0;
    ui_step    = 0.01;
> = crt_gamma_static;
uniform float lcd_gamma <
    ui_label   = "LCD Gamma";
    ui_tooltip = "The gamma-level of your display";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 5.0;
    ui_step    = 0.01;
> = lcd_gamma_static;
uniform float levels_contrast <
    ui_label   = "Levels Contrast";
    ui_tooltip = "2.0 recommended for Gaussian Beam Shapes. 1.0 for Digital.";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = levels_contrast_static;
uniform float halation_weight <
    ui_label   = "Halation";
    ui_tooltip = "Desaturation due to eletrons exciting the wrong phosphors";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = halation_weight_static;
uniform float diffusion_weight <
    ui_label   = "Diffusion";
    ui_tooltip = "Blurring due to refraction from the screen's glass";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = diffusion_weight_static;
uniform float bloom_underestimate_levels <
    ui_label   = "Bloom Underestimation";
    ui_tooltip = "Scale the bloom effect's intensity";
    ui_category = "Colors and Effects";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
> = bloom_underestimate_levels_static;
uniform float bloom_excess <
    ui_label   = "Bloom Excess";
    ui_tooltip = "Extra bloom applied to all colors";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
> = bloom_excess_static;
#if _RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
    uniform float2 aa_subpixel_r_offset_runtime <
        ui_label   = "AA Subpixel R Offet XY";
        ui_category = "Colors and Effects";
        ui_type    = "drag";
        ui_min     = -0.5;
        ui_max     = 0.5;
        ui_step    = 0.01;
    > = aa_subpixel_r_offset_static;
#endif

static const float aa_cubic_c = aa_cubic_c_static;
static const float aa_gauss_sigma = aa_gauss_sigma_static;


// ==== GEOMETRY ====
uniform int geom_mode_runtime <
    ui_label   = "Geom Mode";
    ui_tooltip = "Select screen curvature";
    ui_category = "Screen Geometry";
    ui_type    = "combo";
    ui_items   = "Flat\0"
                 "Spherical\0"
                 "Spherical (Alt)\0"
                 "Cylindrical (Trinitron)\0";
> = geom_mode_static;
uniform float geom_radius <
    ui_label   = "Geom Radius";
    ui_tooltip = "Select screen curvature radius";
    ui_category = "Screen Geometry";
    ui_type    = "slider";
    ui_min     = 1.0 / (2.0 * pi);
    ui_max     = 1024;
    ui_step    = 0.01;
> = geom_radius_static;
uniform float geom_view_dist <
    ui_label   = "Geom View Distance";
    ui_category = "Screen Geometry";
    ui_type    = "slider";
    ui_min     = 0.5;
    ui_max     = 1024;
    ui_step    = 0.01;
> = geom_view_dist_static;
uniform float2 geom_tilt_angle <
    ui_label   = "Geom Tilt Angle XY";
    ui_category = "Screen Geometry";
    ui_type    = "drag";
    ui_min     = -pi;
    ui_max     = pi;
    ui_step    = 0.01;
> = geom_tilt_angle_static;
uniform float2 geom_aspect_ratio <
    ui_label   = "Geom Aspect Ratio XY";
    ui_category = "Screen Geometry";
    ui_type    = "drag";
    ui_min     = 1.0;
    ui_step    = 0.01;
> = float2(geom_aspect_ratio_static, 1);
uniform float2 geom_overscan <
    ui_label   = "Geom Overscan XY";
    ui_category = "Screen Geometry";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
> = geom_overscan_static;

// ==== BORDER ====
uniform float border_size <
    ui_label   = "Border Size";
    ui_category = "Screen Border";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 0.5;
    ui_step    = 0.01;
> = border_size_static;
uniform float border_darkness <
    ui_label   = "Border Darkness";
    ui_category = "Screen Border";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = border_darkness_static;
uniform float border_compress <
    ui_label   = "Border Compress";
    ui_category = "Screen Border";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = border_compress_static;



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
    return geom_overscan;
}

float2 get_geom_tilt_angle_vector()
{
    return geom_tilt_angle;
}

float3 get_convergence_offsets_x_vector()
{
    return convergence_offset_x;
}

float3 get_convergence_offsets_y_vector()
{
    return convergence_offset_y;
}

float2 get_convergence_offsets_r_vector()
{
    return float2(convergence_offset_x.r, convergence_offset_y.r);
}

float2 get_convergence_offsets_g_vector()
{
    return float2(convergence_offset_x.g, convergence_offset_y.g);
}

float2 get_convergence_offsets_b_vector()
{
    return float2(convergence_offset_x.b, convergence_offset_y.b);
}

float2 get_aa_subpixel_r_offset()
{
    #if _RUNTIME_ANTIALIAS_WEIGHTS
        #if _RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
            //  WARNING: THIS IS EXTREMELY EXPENSIVE.
            return aa_subpixel_r_offset_runtime;
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
        #if _PHOSPHOR_MASK_MANUALLY_RESIZE
            return mask_sample_mode_desired;
        #else
            return clamp(mask_sample_mode_desired, 1.0, 2.0);
        #endif
    #else
        #if _PHOSPHOR_MASK_MANUALLY_RESIZE
            return mask_sample_mode_static;
        #else
            return clamp(mask_sample_mode_static, 1.0, 2.0);
        #endif
    #endif
}

#endif  //  _BIND_SHADER_PARAMS_H