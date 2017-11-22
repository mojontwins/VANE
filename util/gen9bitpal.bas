' Generates a PNG with a proper 9 bits palette (for swatches)

#include "file.bi"
#include "fbpng.bi"
#include "fbgfx.bi"
#include once "crt.bi"

Dim As Single divider
Dim As Integer r,g,b,c
Dim As Integer r0,g0,b0
Dim img As any Ptr

divider = 255/7
screenres 640, 480, 32, , -1

img = ImageCreate (512, 64, rgb (0, 0, 0))

For b = 0 To 7
	For g = 0 To 7
		For r = 0 To 7
			r0 = r * divider
			g0 = g * divider
			b0 = b * divider
			c = rgb (r0, g0, b0)
			Line img, (b*64+r*8,g*8)-(b*64+r*8+7,g*8+7),c,BF
		Next r
	Next g
Next b

png_save( "9bitpal.png", img )
