#ifndef _TEXTURE_SETTINGS
#define _TEXTURE_SETTINGS

#define mask_texture_wrap_mode REPEAT
#define mask_texture_magmin_filter_type NONE

// Mask Textures
#ifdef USE_LARGE_TEXTURES
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

texture2D texMaskGrille < source = mask_grille_texture_path; > {
	Width = mask_size_xy;
	Height = mask_size_xy;
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
	Width = mask_size_xy;
	Height = mask_size_xy;
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
	Width = mask_size_xy;
	Height = mask_size_xy;
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