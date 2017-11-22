' Make cluster
' Version 0.2 - detects w & h to make "cuts".
' If w & h <> 320x192 (40x24), it's a cut.
' "flags" will be W (MSB) and H (LSB).

' Palettes are SORTED so pallette fiddling is unnecessary (hopefully)

#include "file.bi"
#include "fbpng.bi"
#include "fbgfx.bi"
#include once "crt.bi"

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

#define MSB( x ) ( x Shr 8 )
#define LSB( x ) ( x And 255 )

Dim As Integer curCmdP, i, j, x, y, xx, yy, c, t, pixel, curPalIndx, found, w, h, isCut, swapped, ww, hh, palisfixed
Dim As Integer tsPtr, tmPtr, tstPtr
Dim As String tilesStore (2000), tempT
Dim As uByte tileset (65535)
Dim As uShort tilemap (9999)
Dim Shared As Integer pal (16)
Dim As Any Ptr img
Dim As uByte d, r, g, b
Dim Shared As Single divider
Dim As String image, palImage

Dim Shared As uByte fullBinary (1024*256-1)	' 2Mbit max
Dim Shared as uInteger fbi 
Dim As Long tempIndex (127), indexval
Dim As Integer idx

Sub add2bin (c as uByte)
	fullBinary (fbi) = c
	fbi = fbi + 1
End Sub

Sub usage 
	Puts "makecluster out.bin [pal:pal.png] in1.png[#pal.png] in2.png[#pal.png] in3.png[#pal.png]..."
	Puts "pal is calculated & stored for each image unless you specify a pal image"
	Puts "(Which should be a 16x1 pixels image with the 16 palette entries!)"
	Puts "you can use a different image (using <pal.png) othar than the original to auto-calc pal"
	Puts "confusing uh?"
	System
End Sub

Function findInPal (pixel As Integer) as Integer
	Dim As Integer i, c
	Dim As uByte r, g, b
	Dim As Integer res
	
	res = 0
	
	r = RGBA_R (pixel)
	g = RGBA_G (pixel)
	b = RGBA_B (pixel)
	
	' 0000BBB0GGG0RRR0
	' 255->7; divide 
	r = r / divider
	g = g / divider
	b = b / divider
	
	c = (r shl 1) or (g shl 5) or (b shl 9)
	
	For i = 0 To 15
		If pal (i) = c Then res = i: Exit For
	Next i
	
	Return res
End Function

Function luma (genPalEntry as Integer) As Integer
	Dim As Integer i, c
	Dim As uByte r, g, b
	Dim As Integer res
	
	res = 0
	
	r = (genPalEntry And &H0F) Shr 1
	g = (genPalEntry And &HF0) Shr 5
	b = (genPalEntry And &HF00) Shr 9
	
	c = (r + g + b) / 3
	
	res = (c Shl 1) or (c Shl 5) or (c Shl 9)
	
	return res
End Function

If Len (Command (2)) = 0 Then usage: System

screenres 640, 480, 32, , -1
divider = 255/7

If len (Command (2)) > 5 And Left (Command (2), 4) = "pal:" Then
	' Fixed pal from pal
	palIsFixed = -1
	Puts "Reading palette from " & Right (Command (2), Len (Command (2)) - 4)
	img = png_load (Right (Command (2), Len (Command (2)) - 4))
	If ImageInfo (img, w, h, , , , ) Then
		' Error!
	End If
	If w <> 16 Or h <> 1 Then 
		Puts "Pal file MUST be 16x1 png, supplied being " & w & "x" & h
		System
	End If
	For i = 0 To 15
		pixel = point (i, 0, img)
		r = RGBA_R (pixel)
		g = RGBA_G (pixel)
		b = RGBA_B (pixel)
		
		' 0000BBB0GGG0RRR0
		' 255->7; divide 
		r = r / divider
		g = g / divider
		b = b / divider
		
		pal (i) = (r shl 1) or (g shl 5) or (b shl 9)
		' puts "" & pixel & " " & pal(i)
	Next i
	' Sort palette.
	Do
		swapped = 0
		For j = 0 to 14
			if pal (j) > pal (j + 1) then
				c = pal (j)
				pal (j) = pal (j + 1)
				pal (j + 1) = c
				swapped = not 0
			End If
		Next j
	Loop Until not swapped
	
	curCmdP = 3
Else 
	curCmdP = 2
	palIsFixed = 0
End If

idx = 0: fbi = 0

While Len (Command (curCmdP))
	
	i = Instr (Command (curCmdP), "#") 
	
	If i > 0 Then
		image = Left (Command (curCmdP), i - 1)
		palImage = Right (Command (CurCmdP), Len (Command (CurCmdP)) - i)
		Puts ("Image: " & image & ", extract palette from " & palImage)
	Else
		image = Command (curCmdP)
		palImage = Command (curCmdP)
		Puts ("Image: " & image)
	End If
	
	' Calculate palette
	If Not palIsFixed Then
		' Read image
		Puts "Reading " + palImage
		
		img = png_load (palImage)
		
		' Image size
		if ImageInfo (img, w, h, , , , ) then
		   'Error!
		End If
		
		For i = 0 to 15: pal (i) = 0: next i
		Puts "Calculating palette."
		curPalIndx = 0
		For x = 0 To w - 1
			For y = 0 To h - 1
				pixel = point (x, y, img)
				r = RGBA_R (pixel)
				g = RGBA_G (pixel)
				b = RGBA_B (pixel)
				
				' 0000BBB0GGG0RRR0
				' 255->7; divide 
				r = r / divider
				g = g / divider
				b = b / divider
				
				c = (r shl 1) or (g shl 5) or (b shl 9)
				
				' New colour?
				found = 0
				For j = 0 to curPalIndx - 1
					If pal (j) = c Then found = -1: Exit For
				Next j
				If Not found Then
					pal (curPalIndx) = c
					if curPalIndx < 15 Then curPalIndx = curPalIndx + 1
				End If
			Next y
		Next x
		
		' Sort palette.
		Do
			swapped = 0
			For j = 0 to curPalIndx - 2
				if luma(pal (j)) > luma(pal (j + 1)) then
					c = pal (j)
					pal (j) = pal (j + 1)
					pal (j + 1) = c
					swapped = not 0
				End If
			Next j
		Loop Until not swapped
	End If
	
	' Read image
	Puts "Reading " + image
	
	img = png_load (image)
	
	' Image size
	if ImageInfo (img, w, h, , , , ) then
	'Error!
	End If
		
	w = (w\8)*8 : h = (h\8)*8
	ww = w\8
	hh = h\8	
	If w <> 320 or h <> 192 Then 
		isCut = -1 
		Puts "This is a " & ww & "x" & hh & " tiles cut."
	Else 
		isCut = 0
		Puts "This is a full screen image"
	End If
	
	' Build td/ts
	Puts "Building tileset and tilemap"
	tsPtr = 0: tmPtr = 0: tstPtr = 0
	For yy = 0 To h-8 step 8
		For xx = 0 To w-8 step 8
			' Create temporal tile
			tempT = ""
			For y = 0 To 7
				For x = 0 To 7
					c = findInPal (point (xx + x, yy + y, img))
					tempT = tempT & hex (c, 1)
				Next x
			Next y
			
			' Is it a new tile?
			found = 0
			For i = 0 to tstPtr - 1
				If tilesStore (i) = tempT Then found = -1: t = i: Exit for
			Next i
			If Not found Then
				' Create new!
				t = tstPtr
				tilesStore (tstPtr) = tempT
				tstPtr = tstPtr + 1
				
				' Add to ts
				For i = 1 To Len (tempT) Step 2
					tileset (tsPtr) = Val ("&H" & mid (tempT, i, 2))
					tsPtr = tsPtr + 1
					'Puts ">" & i & "]->" & ("&H" & mid (tempT, i, 2))
				Next i
			End If
			
			' Add to tm
			tilemap (tmPtr) = t
			tmPtr = tmPtr + 1
		Next xx
	Next yy
	
	Puts "Unique tiles: " & tstPtr & ", tileset is " & tsPtr & " bytes."

	tempIndex (idx) = fbi
	Puts "Adding to binary ..."
	Puts " "
	
	'' BIG ENDIAN!!
	
	' pal
	For i = 0 To 15
		add2bin MSB (pal (i))
		add2bin LSB (pal (i))
	Next i
	
	' flag integer (for future use)
	if isCut Then
		add2bin ww
		add2bin hh
	Else
		add2bin 0
		add2bin 0
	End If
	
	' tm
	For i = 0 to (hh*ww)-1
		add2bin MSB (tilemap (i))
		add2bin LSB (tilemap (i))
	Next i
	
	' ts
	For i = 0 To tsPtr - 1
		add2bin tileset (i)
	Next i
	
	curCmdP = curCmdP + 1
	idx = idx + 1
Wend

tempIndex (idx) = fbi: idx = idx + 1

Puts "Cool! Writing output..."
Puts "Writing index"
Kill Command (1)
Open Command (1) For Binary as #1
For i = 0 To idx - 1
	' MSB -> LSB (Big endian!)
	indexval = tempIndex (i) + (idx*4) ' Adjust for index size!
	d = indexval Shr 24
	Put #1, , d
	d = (indexval Shr 16) And 255
	Put #1, , d
	d = (indexVal Shr 8) And 255
	Put #1, , d
	d = indexVal And 255
	Put #1, , d
Next i

Puts "Writing data"
For i = 0 To fbi - 1
	Put #1, , fullBinary (i)
Next i

Close #1
