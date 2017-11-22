' Genesis Menu Game Script Compiler v0.5 by na_th_an
' Copyleft 2015 by The Mojon Twins
' Make a simple, lame two-pass compiler.

	#define MSB( x ) ( (x) Shr 8 )
	#define LSB( x ) ( (x) And 255 )
	
	Const SIZE_WORDS = 255
	Const SIZE_BINP = 65535
	Const SIZE_BINT = 65535
	Const SIZE_ALIAS = 255
	Const SIZE_ADDRESSES = 1023
	Const SIZE_TEXTS = 1023

	Type Address
		mem As Integer
		label As String
	End Type
	
	Type Subst
		binpOffs as Integer
		addressIdx as Integer
	End Type
	
	Type ScAlias
		nam as String
		value as String
	End Type

	Dim Shared As Subst slist (9999)
	Dim Shared As String w (SIZE_WORDS)
	Dim Shared As uByte binp (SIZE_BINP)
	Dim Shared As uByte bint (SIZE_BINT)
	Dim Shared As Integer bidx, tidx
	Dim Shared as ScAlias listAlias (SIZE_ALIAS)
	Dim Shared As Address addresses_pool (SIZE_ADDRESSES)
	Dim Shared As Integer lidx, sidx, aliasIdx
	Dim Shared As Integer curLine
	Dim Shared As Integer textIndex (SIZE_TEXTS)
	Dim Shared As Integer textIndexI
	
	Dim Shared As Integer debug, trace
	
' Some helpers...

Sub addSubst (offs As Integer, adIdx as Integer)
	slist (sidx).binpOffs = offs
	slist (sidx).addressIdx = adIdx
	sidx = sidx + 1
End Sub

Sub findOrCreateLabelWAddress (s As String, address as Integer)
	Dim As Integer r, i, found
	found = 0
	For i = 0 To lidx
		If addresses_pool (i).label = s Then
			found = -1
			r = i
			Exit For
		End If
	Next i
	If Not found Then
		addresses_pool (lidx).label = s
		addresses_pool (lidx).mem = address
		lidx = lidx + 1
	Else
		If addresses_pool (r).mem <> &HFFFF Then Print "Warning! Duplicate label " & s & " at " & curLine
		addresses_pool (r).mem = address
	End If
End Sub

Function findOrCreateLabel (s As String) as Integer
	Dim As Integer r, i, found
	If debug Then PRINT "DEBUG: findOrCreateLabel (" & s & ")"
	found = 0
	For i = 0 To lidx
		If addresses_pool (i).label = s Then
			found = -1
			r = i
			If debug Then PRINT "DEBUG: Encontrada! en " & r
			Exit For
		End If
	Next i
	If Not found Then 
		addresses_pool (lidx).label = s
		addresses_pool (lidx).mem = &HFFFF
		r = lidx
		lidx = lidx + 1
		If debug Then PRINT "DEBUG: No encontrada. creando en " & r
	End If
	Return r
End Function

Sub parseLine (l As String)
	Dim As Integer i, quotes, windex
	Dim As String m
	quotes = 0
	windex = 0
	l = l & " "
	w (windex) = ""
	For i = 1 To Len (l)
		m = Mid (l, i, 1)
		If m = " " And Not quotes Then
			windex = windex + 1
			w (windex) = ""
		ElseIf m = Chr (34) Then
			quotes = Not quotes
		ElseIf Not quotes And (m = "," Or m = ";") Then
			' Ignore punctuation if not in quotes mode
		Else
			w (windex) = w (windex) & m
		End If
	Next i
End Sub

Function readByte () as uByte
	Dim As uByte r
	r = binp (bidx)
	bidx = bidx + 1
	If bidx = SIZE_BINP+1 Then bidx = 0
	Return r
End Function

Sub addByte (b as uByte)
	binp (bidx) = b
	If bidx < SIZE_BINP Then bidx = bidx + 1
	If trace Then Print Hex (b, 2) & " ";
End Sub

Sub addTextByte (b as uByte)
	bint (tidx) = b
	If tidx < SIZE_BINT then tidx = tidx + 1
End Sub

Function pVal (s As String) as uByte
	Dim as uByte r
	Dim as Integer i, t, freeFlag, fnd
	If (left (s, 1) = "#") Then
		r = 128 + pVal (right (s, len (s) - 1))
	ElseIf (left (s, 1) = "$") Then
		r = &HFF
		For i = 0 To SIZE_ALIAS
			If listAlias (i).nam = right (s, len (s) - 1) Then
				r = pVal (listAlias (i).value)
				If debug Then Print "DEBUG: Alias " & right (s, len (s) - 1) & " found @ " & r
				Exit For
			End If
		Next i
		
		If r = &HFF Then
			' Alias does not exist. Create...
			If debug Then Print "DEBUG: Alias " & right (s, len (s) - 1) & " does not exist. Creating..."
			
			freeFlag = 120
			t = 0
			While Not t
				fnd = 0
				For i = 0 To SIZE_ALIAS
					If freeFlag = pVal (listAlias (i).value) Then
						fnd = -1
						Exit For
					End If
				Next i
				If Not fnd Then
					t = -1
				Else 
					freeFlag = freeFlag - 1
					If freeFlag < 1 Then
						Print "FATAL ERROR - Too many aliases!"
						System
					End If
				End If
			Wend
			
			If debug Then Print "DEBUG: Found unused flag: " & freeFlag
			
			listAlias (aliasIdx).nam = right (s, len (s) - 1)
			listAlias (aliasIdx).value = Str (freeFlag)
			
			If debug Then Print "DEBUG: added alias #" & aliasIdx & " to listAlias"
			
			aliasIdx = aliasIdx + 1
			
			r = freeFlag
		End If
	ElseIf (left (s, 1) = "/") Then
		r = pVal (right (s, len (s) - 1)) \ 8
	Else
		r = val (s)
	End If
	Return r
End Function

' Now on to the business

	Dim As String cl, cmd, prefix
	Dim As Integer textIdx, addIdx, i, j, asaddr, lnt, rlv, branches
	Dim As uByte d
	
	Sub usage
		Print "Usage: gmgsc in.spt outS.bin"
	End Sub

	Print "VANE Script Compiler v0.5 by The Mojon Twins"
	If Len (Command (2)) = 0 Then usage: System
	
	Print "Reading your shit from " & Command (1) & "..."
	Open trim (Command (1), Any Chr (34)) For Input as #1

	debug = 0
	trace = 0
	If Command (3) = "debug" Or Command (4) = "debug" Then debug = -1
	If Command (3) = "trace" Or Command (4) = "trace" Then trace = -1
	
' 1st pass - bytecode & placeholder addresses

	aliasIdx = 0
	textIdx = 0
	addIdx = 0
	bidx = 2 ' Leave room for script length!
	tidx = 0
	textIndexI = 0
	
	curLine = 0
	While Not Eof (1)
		Line Input #1, cl
		curLine = curLine + 1
		cl = trim (cl, Any Chr (32) + Chr (9))	
		parseLine cl
		cmd = lcase (w (0))
	
		If trace Then 
			If len(cmd) > 1 Then
				If left (cmd, 1) <> "#" And left (cmd, 1) <> ":" And cmd <> "alias" Then
					Print
					Print curLine & ": " & cl
					Print "    ";
				End If
			End If
		End If
		
		select case cmd
			case "alias":
				' Create alias ALIAS = 42
				listAlias (aliasIdx).nam = w (1)
				listAlias (aliasIdx).value = w (3)
				aliasIdx = aliasIdx + 1
			case "let":
				addByte &H40
				addByte pVal (w (1)) And &HFF
				addByte pVal (w (3)) And &HFF
			case "image":
				addByte &H01
				addByte pVal (w (1)) And &HFF
			case "cut_load"
				addByte &H02
				addByte pVal (w (1)) And &HFF
				addByte pVal (w (2)) And &HFF
			case "clear"
				addByte &H03
			case "cut_show"
				addByte &H04
				addByte pVal (w (1)) And &HFF
				addByte pVal (w (2)) And &HFF
				addByte pVal (w (3)) And &HFF
			case "fancy"
				If lcase (w (1)) = "on" then
					addByte &H05
				Else
					addByte &H06
				End If
			case "scroll_bg"
				addByte &H07
				addByte pVal (w (1)) And &HFF
			case "restore_bg"
				addByte &H08
			case "cut_ovl"
				addByte &H09
				addByte pVal (w (1)) And &HFF
				addByte pVal (w (2)) And &HFF
				addByte pVal (w (3)) And &HFF
			case "text", "tw":
				' text TEXT, WT
				' Add text to pool
				' Create entry on index
				textIndex (textIndexI) = tidx
				textIndexI = textIndexI + 1
				' Add trailing space. Needed for the parser
				w (1) = w (1) & " "
				' Make sure that text plus ending 0 has even length
				If 0 = (Len (w (1)) And 1) Then w (1) = w (1) & " "
				' Write string
				For i = 1 To Len (w (1))
					addTextByte Asc (Mid (w (1), i, 1))
				Next i
				' Terminate 
				addTextByte 0
				' write bytecode
				If lcase (w (2)) = "wt" Or cmd = "tw" Then 
					addByte &H11 
				Else 
					addByte &H10
				End If
				addByte textIdx
				textIdx = textIdx + 1
			case "sleep"
				i = val (w (1))
				addByte &H1D
				addByte MSB (i)
				addByte LSB (i)
			case "cleartext"
				addByte &H1E
			case "wt"
				addByte &H1F
			case "clear_menu":
				addByte &H20
			case "add_item":
				' Add Item 0x30 X X X X X X X X X X (10 bytes)
				If Len (w (1)) < 10 Then w (1) = w (1) & String (10, "@") ' safe & cheeeeeesy!
				
				If w (2) = "->" Then
					addByte &H23
					addByte pVal (w (3))
				Else
					d = val (w (2))
					If d = 0 Then
						addByte &H21
					Else
						addByte &H22
						addByte d
					End If
				End If
				For i = 1 To 10
					addByte Asc (Mid (w (1), i, 1))
				Next i
			case "set_menu_opts":
				d = val (w (1))
				addByte &H23
				addByte d		
			case "if":
				' if A op B LABEL
				Select Case w (2)
					case "=":
						addByte &H30
					case "<>":
						addByte &H31
					case "<":
						addByte &H32
					case ">":
						addByte &H33
				End Select
				addByte pVal (w (1))
				addByte pVal (w (3))
				i = findOrCreateLabel (lcase (w (4)))
				addSubst bidx, i
				' Make room
				addByte &HFF
				addByte &HFF
			case "goto":
				addByte &H3F
				i = findOrCreateLabel (lcase (w (1)))
				addSubst bidx, i
				' Make room
				addByte &HFF
				addByte &HFF
			case "do_menu":
				addByte &H50
			case "talk":
				If lcase (w (1)) = "off" Then
					addByte &H61
				Else
					If Len (w (1)) < 10 Then w (1) = w (1) & String (10, "@") ' safe & cheeeeeesy!
					addByte &H60
					For i = 1 To 10
					addByte Asc (Mid (w (1), i, 1))
				Next i	
				End If
			case "cdplay"
				addByte &H70
				addByte pVal (w (1)) And &HFF
			case "cdstop"
				addByte &H71
			case "cdpause"
				addByte &H72
			case "cdunpause"
				addByte &H73
			case "clr"
				addByte &H80
				addByte pVal (w (1)) And &HFF
			case "cls"
				AddByte &H80
				AddByte 0
			case "scroll_set"
				'i = val (w (1))
				AddByte &H88
				'AddByte MSB (i)
				'AddByte LSB (i)
				AddByte pVal (w (1))
			case "scroll_to"
				'i = val (w (1))
				AddByte &H89
				'AddByte MSB (i)
				'AddByte LSB (i)
				AddByte pVal (w (1))
				AddByte pVal (w (2))
			case "inc"
				AddByte &H90
				AddByte pVal (w (1)) And &HFF
			case "dec"
				AddByte &H91
				AddByte pVal (w (1)) And &HFF
			case "clear_samples"
				AddByte &HA0
			case "add_sample"
				AddByte &HA1
				AddByte pVal (w (1)) And &HFF
			case "play_sample"
				AddByte &HA2
				AddByte pVal (w (1)) And &HFF
			case "set"
				AddByte &HE0
				AddByte Val (w (1)) And &HFF
				AddByte Val (w (3)) And &HFF
			case "run_slot"
				AddByte &HE1
				AddByte Val (w (1))
			case "menu"
				AddByte &HE1
				AddByte 0
			case "battle"
				AddByte &HE1
				AddByte 2
			case "gameover"
				AddByte &HE1
				AddByte 3
			case "ending"
				AddByte &HE1
				AddByte 4
			case "chapter"
				Select Case lcase (w (1))
					Case "next"
						addByte &HFE
					Case "prev"
						addByte &HFD
					Case "repeat"
						addByte &HFC
					Case Else
						addByte &HFB
						addByte pVal (w (1))
				End Select
			case "autobranch"
				prefix = w (1)
				branches = val (w (2))
				' Tenemos que crear branches sentencias IF que salten a prefix_n
				' Veamos:
				For j = 1 To branches
					' IF =
					addByte &H30
					' flags (0)
					addByte 128
					' i
					addByte j
					' Creamos la etiqueta prefix & "_" & i
					i = findOrCreateLabel (lcase (prefix & "_" & ltrim (str (j))))
					' Add substitution to list
					addSubst bidx, i
					' Make room for jump address
					addByte &HFF
					addByte &HFF
				Next j
			Case Else
				If len (cmd) > 1 Then
					If Left (cmd, 1) = ":" Then
						findOrCreateLabelWAddress (Right (lcase (cmd), Len (cmd) - 1), bidx)
					Else
						If Left (cmd, 1) <> "#" Then
							Print "Warning! Unrecognized command " & cmd & " @ " & curLine
						End If
					End If
				End If
		end select
	Wend

' 2nd pass: Perform address substitutions
	
	For i = 0 To sidx - 1
		asaddr = addresses_pool (slist (i).addressIdx).mem - 2 ' Adjust for two byte header
		binp (slist (i).binpOffs) = MSB (asaddr)
		binp (slist (i).binpOffs + 1) = LSB (asaddr)
	Next i
	
	Close #1, #2

' Last thing to do: write binary file
	
	lnt = 2 * textIndexI + tidx
	
	? "Done processing. Alias " & aliasIdx & ", texts " & textIdx & " (" & lnt & " bytes), labels " & lidx & ", branches " & sidx & "."
	
	? "Writing your shit @ " & Command (2)
	Kill Command (2)
	Open Trim (Command (2), Any Chr (34)) For Binary as #2
		' END mark
		binp (bidx) = &HFF
		
		' make bidx EVEN
		if (bidx And 1) = 0 Then bidx = bidx + 1
			
		' Write length:
		binp (0) = MSB (bidx + 1)
		binp (1) = LSB (bidx + 1)	
		For i = 0 To bidx
			Put #2, , binp (i)
		Next i
		' Add texts.
		' Write length
		
		d = MSB (lnt)
		Put #2, , d
		d = LSB (lnt)
		Put #2, , d
		' First of all, index
		For i = 0 To textIndexI - 1
			rlv = textIndex (i) + 2 * textIndexI
			d = MSB (rlv)
			Put #2, , d
			d = LSB (rlv)
			Put #2, , d
		Next i
		' Texts binary
		For i = 0 To tidx - 1
			Put #2, , bint (i)
		Next i
	Close #2
