#ifndef _ROOT_LEVEL_FUNCTIONS_H
#define _ROOT_LEVEL_FUNCTIONS_H

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


// ReShade 4 does not permit the use of functions or the ternary operator
// outside of a function definition. This is a problem for this port
// because the original crt-royale shader makes heavy use of these
// constructs at the root level.

// These preprocessor definitions are a workaround for this limitation.
// Note that they are strictly intended for defining complex global
// constants. I doubt they're more performant than the built-in
// equivalents, so I recommend using the built-ins whenever you can.


#define root_sign(c) -((int) (c != 0)) * -((int) (c > 0))
#define root_abs(c) c * root_sign(c)

#define root_min(c, d) c * ((int) (c <= d)) + d * ((int) (c > d))
#define root_max(c, d) c * ((int) (c >= d)) + d * ((int) (c < d))
#define root_clamp(c, l, u) root_min(root_max(c, l), u)

#define root_ceil(c) (float) ((int) c + (int) (((int) c) < c))

#define root_cond(c, a, b) float(c) * a + float(!c) * b

float fmod(float x, float y)
{
    return x - y * floor(x/y);
}


#endif  //  _ROOT_LEVEL_FUNCTIONS_H