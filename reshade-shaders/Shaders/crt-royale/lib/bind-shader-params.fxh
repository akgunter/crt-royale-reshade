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

#if __RENDERER__ != 0x9000
    #define TEXCOORD_OFFSET 0.0
#else
    #define TEXCOORD_OFFSET 0.5
#endif

#ifndef ADVANCED_SETTINGS
    #define ADVANCED_SETTINGS 0
#endif 

// The width of the game's content
#ifndef CONTENT_WIDTH
	#define CONTENT_WIDTH BUFFER_WIDTH
#endif
// The height of the game's content
#ifndef CONTENT_HEIGHT
	#define CONTENT_HEIGHT BUFFER_HEIGHT
#endif

#if ADVANCED_SETTINGS == 1
    #ifndef NUM_BEAMDIST_COLOR_SAMPLES
        #define NUM_BEAMDIST_COLOR_SAMPLES 1024
    #endif

    #ifndef NUM_BEAMDIST_DIST_SAMPLES
        #define NUM_BEAMDIST_DIST_SAMPLES 120
    #endif

    #ifndef BLOOMAPPROX_DOWNSIZING_FACTOR
        #define BLOOMAPPROX_DOWNSIZING_FACTOR 4.0
    #endif

    // Define this internal value, so ADVANCED_SETTINGS == 0 doesn't cause a redefinition error when
    //   NUM_BEAMDIST_COLOR_SAMPLES defined in the preset file. Also makes it easy to avoid bugs
    //   related to parentheses and order-of-operations when the user defines this arithmetically.
    #define NUM_BEAMDIST_COLOR_SAMPLES_INTERNAL int(NUM_BEAMDIST_COLOR_SAMPLES)
    #define NUM_BEAMDIST_DIST_SAMPLES_INTERNAL int(NUM_BEAMDIST_DIST_SAMPLES)
    #define BLOOMAPPROX_DOWNSIZING_FACTOR_INTERNAL float(BLOOMAPPROX_DOWNSIZING_FACTOR)
#else
    #define NUM_BEAMDIST_COLOR_SAMPLES_INTERNAL 1024
    #define NUM_BEAMDIST_DIST_SAMPLES_INTERNAL 120
    #define BLOOMAPPROX_DOWNSIZING_FACTOR_INTERNAL 4.0
#endif

// Wrap the content size in parenthesis for internal use, so the
//   user doesn't have to
#define CONTENT_WIDTH_INTERNAL int(CONTENT_WIDTH)
#define CONTENT_HEIGHT_INTERNAL int(CONTENT_HEIGHT)


// Offset the center of the game's content (horizontal)
#ifndef CONTENT_CENTER_X
	#define CONTENT_CENTER_X 0
#endif
// Offset the center of the game's content (vertical)
#ifndef CONTENT_CENTER_Y
	#define CONTENT_CENTER_Y 0
#endif

static const float2 buffer_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
static const float2 content_size = float2(CONTENT_WIDTH_INTERNAL, CONTENT_HEIGHT_INTERNAL);

uniform uint frame_count < source = "framecount"; >;
uniform int overlay_active < source = "overlay_active"; >;

static const float gba_gamma = 3.5; //  Irrelevant but necessary to define.


// ==== PIXELATION ===
uniform uint pixelation_method < 
    ui_label   = "Pixelation Method";
    ui_tooltip = "Algorithm to create pixelation effect";
    ui_category = "Pixelation";
    ui_type    = "combo";
    ui_items   = "Point Sampling (fast)\0"
                "Averaging (versatile)\0";
    hidden     = !ADVANCED_SETTINGS;
> = 0;
uniform uint pixel_grid_mode <
    ui_label   = "Pixel Grid Param";
    ui_tooltip = "Switch between using Pixel Size or Num Pixels";
    ui_category = "Pixelation";
    ui_type    = "combo";
    ui_items   = "Pixel Size\0"
                "Content Resolution\0";
    hidden     = !ADVANCED_SETTINGS;
> = 0;
uniform float2 pixel_shape <
    ui_label   = "Pixel Size";
    ui_category = "Pixelation";
    ui_category_closed = true;
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 30.0;
    ui_step    = 1.0;
> = float2(1, 1);
uniform float2 pixel_grid_resolution <
    ui_label   = "Num Pixels";
    ui_tooltip = "The number of pixels to downsample to";
    ui_category = "Pixelation";
    ui_type    = "drag";
    ui_min     = 1.0;
    ui_max     = 10000.0;
    ui_step    = 1.0;
    hidden     = !ADVANCED_SETTINGS;
> = content_size;
uniform float2 pixel_grid_offset <
    ui_label   = "Pixel Grid Offset";
    ui_category = "Pixelation";
    ui_type    = "slider";
    ui_min     = -15.0;
    ui_max     = 15.0;
    ui_step    = 1.0;
> = float2(0, 0);

// ==== PHOSPHOR MASK ====
uniform int mask_type <
    ui_label   = "Mask Type";
    ui_tooltip = "Selects the phosphor shape";
    ui_category = "Phosphor Mask";
    ui_category_closed = true;
    ui_type    = "combo";
    ui_items   = "Grille\0"
                 "Slot\0"
                 "Shadow\0";
> = mask_type_static;
uniform uint mask_specify_num_triads <
    ui_label   = "Mask Size Param";
    ui_tooltip = "Switch between using Mask Triad Size or Mask Num Triads";
    ui_category = "Phosphor Mask";
    ui_type    = "combo";
    ui_items   = "Triad Width\0"
                "Num Triads Across\0";
    hidden     = !ADVANCED_SETTINGS;
> = mask_specify_num_triads_static;
uniform float mask_triad_size_desired <
    ui_label   = "Mask Triad Width";
    ui_tooltip = "The width of a triad";
    ui_category = "Phosphor Mask";
    ui_type    = "slider";
    ui_min     = 1.0;
    ui_max     = 60.0;
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
    hidden     = !ADVANCED_SETTINGS;
> = mask_num_triads_desired_static;
uniform float aspect_ratio_adjustment<
    ui_label   = "Triad Aspect Ratio";
    ui_category = "Phosphor Mask";
    ui_type    = "drag";
    ui_min     = 0.01;
    ui_max     = 10.0;
    ui_step    = 0.01;
> = 1.0;
uniform float2 phosphor_thickness <
    ui_label   = "Phosphor Thickness";
    ui_tooltip = "Sets the brightness of the phosphor's edges, which appears to widen the phosphor.";
    ui_category = "Phosphor Mask";
    ui_type    = "drag";
    ui_min     = 0.01;
    ui_max     = 0.99;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = 0.2;
uniform float2 phosphor_sharpness <
    ui_label   = "Phosphor Sharpness";
    ui_tooltip = "Controls the steepness of the phosphor's edges, which appears to sharpen the phosphor.";
    ui_category = "Phosphor Mask";
    ui_type    = "drag";
    ui_min     = 0.01;
    ui_max     = 1000.0;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = 50;


// ==== ELECTRON BEAM ====
uniform bool enable_interlacing <
    ui_label   = "Enable Interlacing";
    ui_category = "Electron Beam";
    ui_category_closed = true;
> = false;
uniform bool interlace_bff <
    ui_label   = "Draw Back-Field First";
    ui_tooltip = "Draw odd-numbered scanlines first (often has no effect)";
    ui_category = "Electron Beam";
> = interlace_bff_static;
uniform uint scanline_deinterlacing_mode <
    ui_label   = "Deinterlacing Mode";
    ui_tooltip = "Selects the deinterlacing algorithm. For crt-royale's original appearance, choose None.";
    ui_category = "Electron Beam";
    ui_type    = "combo";
    ui_items   = "None\0"
                 "Weaving\0"
                 "Blended Weaving\0"
                 "Static\0";
> = 1;
uniform uint beam_shape_mode <
    ui_label   = "Beam Shape Mode";
    ui_category = "Electron Beam";
    ui_type    = "combo";
    ui_items   = "Digital\0"
                 "Linear\0"
                 "Gaussian\0"
                 "Multi-Source Gaussian\0";
> = 1;
uniform uint scanline_num_pixels <
    ui_label   = "Scanline Thickness";
    ui_category = "Electron Beam";
    ui_type    = "slider";
    ui_min     = 1;
    ui_max     = 30;
    ui_step    = 1;
> = 2;
uniform float scanline_offset <
    ui_label   = "Scanline Offset";
    ui_category = "Electron Beam";
    ui_type    = "slider";
    ui_min     = -30;
    ui_max     = 30;
    ui_step    = 1;
> = 0;
uniform float scanline_blend_gamma <
    ui_label   = "Deinterlacing Blend Gamma";
    ui_tooltip = "Nudge this if deinterlacing changes your colors too much";
    ui_category = "Electron Beam";
    ui_type    = "slider";
    ui_min     = 0.01;
    ui_max     = 5.0;
    ui_step    = 0.01;
> = 1.0;
uniform float beam_linear_thickness <
    ui_label   = "Linear Beam Thickness";
    ui_category = "Electron Beam";
    ui_type    = "slider";
    ui_min     = 0.01;
    ui_max     = 3.0;
    ui_step    = 0.01;
> = 1.0;
uniform float beam_min_sigma <
    ui_label   = "Gaussian Beam Min Sigma";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_min_sigma_static;
uniform float beam_max_sigma <
    ui_label   = "Gaussian Beam Max Sigma";
    ui_tooltip = "Should be >= Beam Min Sigma";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_max_sigma_static;
uniform float beam_spot_power <
    ui_label   = "Gaussian Beam Spot Power";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
> = beam_spot_power_static;
uniform float beam_min_shape <
    ui_label   = "Gaussian Beam Min Shape";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = beam_min_shape_static;
uniform float beam_max_shape <
    ui_label   = "Gaussian Beam Max Shape";
    ui_tooltip = "Should be >= Beam Min Shape";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = beam_max_shape_static;
uniform float beam_shape_power <
    ui_label   = "Gaussian Beam Shape Power";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = 0.0;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = beam_shape_power_static;
uniform float3 convergence_offset_x <
    ui_label   = "Convergence Offset X RGB";
    ui_tooltip = "Shift the color channels horizontally";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = -10;
    ui_max     = 10;
    ui_step    = 0.05;
    hidden     = !ADVANCED_SETTINGS;
> = 0;
uniform float3 convergence_offset_y <
    ui_label   = "Convergence Offset Y RGB";
    ui_tooltip = "Shift the color channels vertically";
    ui_category = "Electron Beam";
    ui_type    = "drag";
    ui_min     = -10;
    ui_max     = 10;
    ui_step    = 0.05;
    hidden     = !ADVANCED_SETTINGS;
> = 0;

static uint beam_horiz_filter = beam_horiz_filter_static;
static float beam_horiz_sigma = beam_horiz_sigma_static;
static float beam_horiz_linear_rgb_weight = beam_horiz_linear_rgb_weight_static;

// ==== IMAGE COLORIZATION ====
uniform float crt_gamma <
    ui_label   = "CRT Gamma";
    ui_tooltip = "The gamma-level of the original content";
    ui_category = "Colors and Effects";
    ui_category_closed = true;
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
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 4.0;
    ui_step    = 0.01;
> = levels_contrast_static;
uniform float blur_radius <
    ui_label   = "Blur Radius";
    ui_tooltip = "Scales the radius of the halation and diffusion effects";
    ui_category = "Colors and Effects";
    ui_type    = "slider";
    ui_min     = 0.01;
    ui_max     = 5.0;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = 1.0;
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
uniform float2 aa_subpixel_r_offset_runtime <
    ui_label   = "AA Subpixel R Offet XY";
    ui_category = "Colors and Effects";
    ui_type    = "drag";
    ui_min     = -0.5;
    ui_max     = 0.5;
    ui_step    = 0.01;
    hidden     = _RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS;
> = aa_subpixel_r_offset_static;

static const float aa_cubic_c = aa_cubic_c_static;
static const float aa_gauss_sigma = aa_gauss_sigma_static;


// ==== GEOMETRY ====
uniform uint geom_mode_runtime <
    ui_label   = "Geom Mode";
    ui_tooltip = "Select screen curvature";
    ui_category = "Screen Geometry";
    ui_category_closed = true;
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
    hidden     = !ADVANCED_SETTINGS;
> = geom_view_dist_static;
uniform float2 geom_tilt_angle <
    ui_label   = "Geom Tilt Angle XY";
    ui_category = "Screen Geometry";
    ui_type    = "drag";
    ui_min     = -pi;
    ui_max     = pi;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = geom_tilt_angle_static;
uniform float2 geom_aspect_ratio <
    ui_label   = "Geom Aspect Ratio XY";
    ui_category = "Screen Geometry";
    ui_type    = "drag";
    ui_min     = 1.0;
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = float2(geom_aspect_ratio_static, 1);
uniform float2 geom_overscan <
    ui_label   = "Geom Overscan XY";
    ui_category = "Screen Geometry";
    ui_type    = "drag";
    ui_min     = FIX_ZERO(0.0);
    ui_step    = 0.01;
    hidden     = !ADVANCED_SETTINGS;
> = geom_overscan_static;

// ==== BORDER ====
uniform float border_size <
    ui_label   = "Border Size";
    ui_category = "Screen Border";
    ui_category_closed = true;
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

#endif  //  _BIND_SHADER_PARAMS_H