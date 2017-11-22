'
' mktextcluster.bas

Sub usage 
	Print "makecluster out.bin list.txt"
	Print "list contains a list of raw files to be included"
	System
End Sub

Dim As Integer curCmdP, i, j, x, y, xx, yy, c, t, pixel, curPalIndx, found
Dim As uByte d, r, g, b

Dim Shared As uByte fullBinary (1024*256-1)	' 2Mbit max
Dim Shared as uInteger fbi 
Dim As Long tempIndex (1024), indexval
Dim As Integer idx
Dim As String curLine

Sub add2bin (c as uByte)
	fullBinary (fbi) = c
	fbi = fbi + 1
End Sub

if Len (Command (2)) = 0 Then usage: System

Open Command(2) For Input As #1

idx = 0

Print "Reading texts in " & Command (2)
While Not Eof (1)
	Line Input #1, curLine
	curLine = Trim (curLine) & " "
	
	? "Reading " & curLine
	i = 0
	
	tempIndex (idx) = fbi: idx = idx + 1
	
	Open curLine For Binary As #3
	? "  Writing bytes"
	While Not Eof (3)
		Get #3, , d
		add2bin d
		i = i + 1
	Wend
	Close #3
	If (i And 1) = 1 Then
		Print "  Odd - padding"
		add2bin 0
	End If
	
Wend
tempIndex (idx) = fbi: idx = idx + 1

Close #1

Print "Writing index"
Open Command (1) For Binary as #1
For i = 0 to idx -1
	indexval = tempIndex (i) + (idx * 4)
	d = indexval Shr 24
	Put #1, , d
	d = (indexval Shr 16) And 255
	Put #1, , d
	d = (indexVal Shr 8) And 255
	Put #1, , d
	d = indexVal And 255
	Put #1, , d
next i
Print "Writing texts"
For i = 0 To fbi - 1
	Put #1, , fullBinary (i)
Next i

Close #1
