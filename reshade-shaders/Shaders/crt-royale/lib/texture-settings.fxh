#ifndef _TEXTURE_SETTINGS
#define _TEXTURE_SETTINGS

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


#define mask_texture_wrap_mode REPEAT
#define mask_texture_magmin_filter_type LINEAR

// Mask Textures
// #define USE_LARGE_TEXTURES

#ifdef PHOSPHOR_MASK_RESIZE_MIPMAPPED_LUT
    #define mask_grille_texture_path "crt-royale/TileableLinearApertureGrille15Wide8And5d5Spacing.png"
    #define mask_slot_texture_path "crt-royale/TileableLinearSlotMaskTall15Wide9And4d5Horizontal9d14VerticalSpacing.png"
    #define mask_shadow_texture_path "crt-royale/TileableLinearShadowMaskEDP.png"
	#define mask_size_xy 512
    #define mask_texture_mip_filter_type LINEAR
#else
    #define mask_grille_texture_path "crt-royale/TileableLinearApertureGrille15Wide8And5d5SpacingResizeTo64.png"
    #define mask_slot_texture_path "crt-royale/TileableLinearSlotMaskTall15Wide9And4d5Horizontal9d14VerticalSpacingResizeTo64.png"
    #define mask_shadow_texture_path "crt-royale/TileableLinearShadowMaskEDPResizeTo64.png"
	#define mask_size_xy 64
    #define mask_texture_mip_filter_type NONE
#endif

static const float2 mask_size = float2(mask_size_xy, mask_size_xy);

texture2D texMaskGrille < source = mask_grille_texture_path; > {
	Width = mask_size.x;
	Height = mask_size.y;
};
sampler2D samplerMaskGrille {
    Texture = texMaskGrille;

    AddressU = mask_texture_wrap_mode;
	AddressV = mask_texture_wrap_mode;
	AddressW = mask_texture_wrap_mode;
    
	MagFilter = mask_texture_magmin_filter_type;
	MinFilter = mask_texture_magmin_filter_type;
	MipFilter = mask_texture_mip_filter_type;
};

texture2D texMaskSlot < source = mask_slot_texture_path; > {
	Width = mask_size.x;
	Height = mask_size.y;
};
sampler2D samplerMaskSlot {
    Texture = texMaskSlot;

    AddressU = mask_texture_wrap_mode;
	AddressV = mask_texture_wrap_mode;
	AddressW = mask_texture_wrap_mode;
    
	MagFilter = mask_texture_magmin_filter_type;
	MinFilter = mask_texture_magmin_filter_type;
	MipFilter = mask_texture_mip_filter_type;
};

texture2D texMaskShadow < source = mask_shadow_texture_path; > {
	Width = mask_size.x;
	Height = mask_size.y;
};
sampler2D samplerMaskShadow {
    Texture = texMaskShadow;

    AddressU = mask_texture_wrap_mode;
	AddressV = mask_texture_wrap_mode;
	AddressW = mask_texture_wrap_mode;
    
	MagFilter = mask_texture_magmin_filter_type;
	MinFilter = mask_texture_magmin_filter_type;
	MipFilter = mask_texture_mip_filter_type;
};

#endif  // _TEXTURE_SETTINGS