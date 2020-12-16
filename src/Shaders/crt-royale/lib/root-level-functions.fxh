// ReShade 4 does not permit the use of functions or the ternary operator
// outside of a function definition. This is a problem for this port
// because the GLSL crt-royale shader makes heavy use of such root level
// language constructs.

// These preprocessor definitions are a workaround for this limitation.
// Note that they are strictly intended for defining complex global
// constants. Whenever possible, use the analagous intrinsic functions
// instead.

#ifndef _ROOT_LEVEL_FUNCTIONS_H
    #define _ROOT_LEVEL_FUNCTIONS_H

    #define root_sign(c) -((int) (c != 0)) * -((int) (c > 0))
    #define root_abs(c) c * root_sign(c)

    #define root_min(c, d) c * ((int) (c <= d)) + d * ((int) (c > d))
    #define root_max(c, d) c * ((int) (c >= d)) + d * ((int) (c < d))
    #define root_clamp(c, l, u) root_min(root_max(c, l), u)

    #define root_ceil(c) (float) ((int) c + (int) (((int) c) < c))

    #define root_cond(c, a, b) float(c) * a + float(!c) * b
#endif  //  _ROOT_LEVEL_FUNCTIONS_H