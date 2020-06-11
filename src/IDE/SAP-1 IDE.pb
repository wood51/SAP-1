;{ DataSection : Icônes toolbar
DataSection
  Image_1:   
  IncludeBinary "assets\page.png"
  Image_2:   
  IncludeBinary "assets\folder_page.png"
  Image_3:   
  IncludeBinary "assets\disk.png"
  Image_6:   
  IncludeBinary "assets\arrow_undo.png"
  Image_7:   
  IncludeBinary "assets\arrow_redo.png"
  Image_8:   
  IncludeBinary "assets\cut.png"
  Image_9:   
  IncludeBinary "assets\page_copy.png"
  Image_10:   
  IncludeBinary "assets\page_paste.png"
  Image_12:   
  IncludeBinary "assets\page_go.png"
EndDataSection
;}

Global KeyWord.s = "NOP LDA ADD LDI ADI SUB JMP OUT HLT EQU"

Enumeration 0
  #LexerState_Space
  #LexerState_Comment
  #LexerState_NonKeyword
  #LexerState_Label
  #LexerState_Keyword
  #LexerState_Constant
  #LexerState_String
EndEnumeration

Global isSave=#True
Global strFilename.s = "<Nouveau>"

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  InitScintilla("Scintilla.dll")
CompilerEndIf

Procedure SCI_Undo(gadget)
  ScintillaSendMessage(gadget,#SCI_UNDO)
EndProcedure

Procedure SCI_Redo(gadget)
  ScintillaSendMessage(gadget,#SCI_REDO)
EndProcedure

Procedure SCI_Cut(gadget)
  ScintillaSendMessage(gadget,#SCI_CUT)
EndProcedure

Procedure SCI_Copy(gadget)
  ScintillaSendMessage(gadget,#SCI_COPY)
EndProcedure

Procedure SCI_Paste(gadget)
  ScintillaSendMessage(gadget,#SCI_PASTE)
EndProcedure

Procedure SCI_SelectAll(gadget)
  ScintillaSendMessage(gadget,#SCI_SELECTALL)
EndProcedure

Procedure SCI_UpdateStatusBar(gadget)
  pos = ScintillaSendMessage(gadget, #SCI_GETCURRENTPOS)
  column = ScintillaSendMessage(gadget, #SCI_GETCOLUMN, pos)
  line  = ScintillaSendMessage(gadget,#SCI_LINEFROMPOSITION,Pos)
  
  StatusBarText(0,0,"Ligne: " + LSet(Str(line),3," ") + " Colonne: " + LSet(Str(column),3," "))
EndProcedure

Procedure SCI_SetDirtyDocument()
  If Right(GetWindowTitle(0),1) <> "*"
    SetWindowTitle(0,GetWindowTitle(0)+"*")
  EndIf
EndProcedure

Procedure SCI_RemoveDirtyDocument()
  If Right(GetWindowTitle(0),1) = "*"
    SetWindowTitle(0, Left( GetWindowTitle(0), Len(GetWindowTitle(0))-1))
  EndIf
EndProcedure

Procedure SCI_GetLineEndPosition(gadget, line)
  ProcedureReturn ScintillaSendMessage(gadget,#SCI_GETLINEENDPOSITION,line)
EndProcedure

Procedure SCI_LineFromPosition(gadget, Pos)
  ProcedureReturn ScintillaSendMessage(gadget,#SCI_LINEFROMPOSITION,Pos)
EndProcedure

Procedure SCI_IsKeyWord(key.s)
  Protected n
  If key=""
    ProcedureReturn -1
  EndIf
  
  For n=1 To CountString(KeyWord, " ") + 1
    If LCase(StringField(KeyWord, n, " ")) = LCase(key)
      ProcedureReturn #LexerState_Keyword
    EndIf
  Next n
  ProcedureReturn -1
EndProcedure

Procedure SCI_LoadText(gadget.i,txt.s)
  *utf8Buffer = UTF8(txt)
  If *utf8Buffer 
    ScintillaSendMessage(gadget, #SCI_SETTEXT, 0, *utf8Buffer)
    FreeMemory(*utf8Buffer)
  EndIf
EndProcedure

Procedure SCI_InitStyle(gadget)
  ; Choose a lexer
  ScintillaSendMessage(0, #SCI_SETLEXER, #SCLEX_CONTAINER, 0)
  
  ;Style 
  ScintillaSendMessage(0, #SCI_STYLESETBACK, #STYLE_DEFAULT, $000000)
  
  ; Set default font
  *font =  UTF8("Consolas")
  ScintillaSendMessage(0, #SCI_STYLESETFONT, #STYLE_DEFAULT,*font)
  ScintillaSendMessage(0, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 10)
  ScintillaSendMessage(0, #SCI_STYLECLEARALL)
  
  ; Set caret line colour
  ScintillaSendMessage(0, #SCI_SETCARETLINEBACK, RGB(192,192,192))
  ScintillaSendMessage(0, #SCI_SETCARETFORE, RGB(255,255,255))
  ScintillaSendMessage(0, #SCI_SETCARETLINEBACKALPHA, 64)
  ScintillaSendMessage(0, #SCI_SETCARETLINEVISIBLE, #True)
  
  ; Set styles for custom lexer
  ScintillaSendMessage(0, #SCI_STYLESETFORE, #LexerState_Comment, RGB(128,128,128))
  ScintillaSendMessage(0, #SCI_STYLESETFORE, #LexerState_NonKeyword, RGB(0,128,192))
  ScintillaSendMessage(0, #SCI_STYLESETFORE, #LexerState_Keyword, RGB(204, 204, 0))
  ScintillaSendMessage(0, #SCI_STYLESETBOLD, #LexerState_Keyword,#True)
  ScintillaSendMessage(0, #SCI_STYLESETFORE, #LexerState_Label, RGB(128, 255, 255))
  ; Margins
  ScintillaSendMessage(0, #SCI_SETMARGINTYPEN, 0, #SC_MARGIN_NUMBER)
  ScintillaSendMessage(0, #SCI_STYLESETFORE, #STYLE_LINENUMBER, RGB(128, 128, 255))
  ScintillaSendMessage(0, #SCI_STYLESETBACK, #STYLE_LINENUMBER, RGB(0, 0, 94))
  ScintillaSendMessage(0, #SCI_SETMARGINWIDTHN, 0, 31)
  
  ;Nb espace dans une tabulation
  ScintillaSendMessage(Gadget, #SCI_SETINDENT, 10)
EndProcedure

Procedure SCI_SaveFile(gadget)
  Protected windowsTitle.s
  If strFilename = "<Nouveau>"
    strFilename = SaveFileRequester("Enregistrer sous ...","Nouveau.asm","Fichiers assembleurs (*.asm)|*.asm|Tous les fichiers (*.*)|*.*",0) 
    If strFilename <> ""
      hFile=OpenFile(#PB_Any,strFilename)
      If hFile
        numBytes = ScintillaSendMessage(gadget, #SCI_GETLENGTH)
        If numBytes
          *Buffer  = AllocateMemory(numBytes+1)
          ScintillaSendMessage(id, #SCI_GETTEXT, numBytes + 1, *Buffer)
          text.s = PeekS(*Buffer, -1, #PB_UTF8)
          WriteData(hFile,*Buffer,numBytes)
          CloseFile(hfile)
          FreeMemory(*Buffer)
          
          SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ") + " - " + GetFilePart(strFilename))
          ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
        EndIf
      EndIf
    EndIf
  Else
    hFile=OpenFile(#PB_Any,strFilename)
    If hFile
      numBytes = ScintillaSendMessage(gadget, #SCI_GETLENGTH)
      If numBytes
        *Buffer  = AllocateMemory(numBytes+1)
        ScintillaSendMessage(id, #SCI_GETTEXT, numBytes + 1, *Buffer)
        text.s = PeekS(*Buffer, -1, #PB_UTF8)
        WriteData(hFile,*Buffer,numBytes)
        CloseFile(hfile)
        FreeMemory(*Buffer)
        
        SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ") + " - " + GetFilePart(strFilename))
        ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure SCI_SaveFileAs(gadget)
  strFilename = SaveFileRequester("Enregistrer sous ...","Nouveau.asm","Fichiers assembleurs (*.asm)|*.asm|Tous les fichiers (*.*)|*.*",0) 
  If strFilename <> ""
    hFile=OpenFile(#PB_Any,strFilename)
    If hFile
      numBytes = ScintillaSendMessage(gadget, #SCI_GETLENGTH)
      If numBytes
        *Buffer  = AllocateMemory(numBytes+1)
        ScintillaSendMessage(id, #SCI_GETTEXT, numBytes + 1, *Buffer)
        text.s = PeekS(*Buffer, -1, #PB_UTF8)
        WriteData(hFile,*Buffer,numBytes)
        CloseFile(hfile)
        FreeMemory(*Buffer)
        
        SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ") + " - " + GetFilePart(strFilename))
        ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure SCI_OpenFile(gadget)
  Protected windowsTitle.s
  strFilename = OpenFileRequester("Ouvrir...","Nouveau.asm","Fichiers assembleurs (*.asm)|*.asm|Tous les fichiers (*.*)|*.*",0) 
  If strFilename <> ""
    size = FileSize(strFilename)
    If size >0
      
      hFile=ReadFile(#PB_Any,strFilename,#PB_UTF8)
      If hFile
        
        SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ") + " - " + GetFilePart(strFilename))
        *Buffer = AllocateMemory(size+1)
        If *Buffer
          ReadData(hFile,*Buffer,size+1)
          CloseFile(hFile)
        EndIf
        txt.s = PeekS(*Buffer,size+1,#PB_UTF8)
        SCI_LoadText(gadget,txt)
        ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
        ScintillaSendMessage(gadget,#SCI_EMPTYUNDOBUFFER)
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure SCI_NewFile(gadget.i)
  If ScintillaSendMessage(gadget,#SCI_GETMODIFY)
    Select MessageRequester("SAP-1 IDE","Voulez-vous enregistrer vos modification ?",#PB_MessageRequester_YesNoCancel)
      Case #PB_MessageRequester_Yes
        SCI_SaveFile(gadget)
        SCI_LoadText(gadget,"")
        strFilename = "<Nouveau>"
        SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ")+" - "+strFilename)   
        ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
        ScintillaSendMessage(gadget,#SCI_EMPTYUNDOBUFFER)
      Case #PB_MessageRequester_No
        SCI_LoadText(gadget,"")
        strFilename = "<Nouveau>"
        SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ")+" - "+strFilename)
        ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
        ScintillaSendMessage(gadget,#SCI_EMPTYUNDOBUFFER)
      Case #PB_MessageRequester_Cancel
    EndSelect
  Else
    SCI_LoadText(gadget,"")
    strFilename = "<Nouveau>"
    SetWindowTitle(0,StringField(GetWindowTitle(0),1," - ")+" - "+strFilename)   
    ScintillaSendMessage (gadget,#SCI_SETSAVEPOINT)
    ScintillaSendMessage(gadget,#SCI_EMPTYUNDOBUFFER)
  EndIf
EndProcedure

Procedure SCI_Highlight(sciptr.l, endpos.l)
  Protected Char.l, keyword.s, state.i
  Protected CurrentPos.l = 0, endlinepos.l, startkeyword
  Protected currentline.l = 0
  endpos = SCI_GetLineEndPosition(sciptr, SCI_LineFromPosition(sciptr, endpos))
  ScintillaSendMessage(sciptr, #SCI_STARTSTYLING, CurrentPos, $1F | #INDICS_MASK)
  
  While CurrentPos <= endpos
    Char = ScintillaSendMessage(sciptr, #SCI_GETCHARAT, CurrentPos)
    Select Char
      Case 10
        ScintillaSendMessage(sciptr, #SCI_SETSTYLING, 1, #LexerState_NonKeyword)
        
      Case 'a' To 'z', 'A' To 'Z',':'
        endlinepos = SCI_GetLineEndPosition(sciptr, SCI_LineFromPosition(sciptr, currentpos))
        
        keyword = Chr(char)
        While currentpos < endlinepos
          currentpos + 1
          char = ScintillaSendMessage(sciptr, #SCI_GETCHARAT, currentpos)
          If Not ((char => 'a' And char <= 'z') Or (char >= 'A' And char <= 'Z') Or char = '_' Or char = ':' Or(char >= '0' And char <= '9') )
            currentpos-1
            Break
          EndIf            
          keyword + Chr(char)          
        Wend
        
        If SCI_IsKeyWord(keyword) = #LexerState_Keyword
          state = #LexerState_Keyword
        Else
          state = #LexerState_NonKeyword
        EndIf
        If Right(keyword,1) = ":"
          state = #LexerState_Label
        EndIf
        ScintillaSendMessage(sciptr, #SCI_SETSTYLING, Len(keyword), state)
      Case ';'
        endlinepos = SCI_GetLineEndPosition(sciptr, SCI_LineFromPosition(sciptr, currentpos))
        startkeyword = 1
        While currentpos < endlinepos
          currentpos + 1
          startkeyword + 1
        Wend
        ScintillaSendMessage(sciptr, #SCI_SETSTYLING, startkeyword, #LexerState_Comment)        
      Case 9, ' '
        ScintillaSendMessage(sciptr, #SCI_SETSTYLING, 1, #LexerState_Space)
      Default
        ScintillaSendMessage(sciptr, #SCI_SETSTYLING, 1, #LexerState_NonKeyword)
    EndSelect
    currentpos+1
  Wend
EndProcedure

ProcedureDLL SCI_ScintillaCallBack(Gadget, *scinotify.SCNotification)
  Select *scinotify\nmhdr\code
    Case #SCN_SAVEPOINTREACHED ; Point de sauvegarde du texte
      SCI_RemoveDirtyDocument()
    Case #SCN_SAVEPOINTLEFT ; Modification du texte
      SCI_SetDirtyDocument()
    Case #SCN_UPDATEUI
      SCI_UpdateStatusBar(gadget)      
    Case #SCN_STYLENEEDED
      SCI_Highlight(Gadget, *scinotify\position)
  EndSelect
EndProcedure

Procedure Compile()
  
  ClearGadgetItems(1)
  
  numBytes = ScintillaSendMessage(gadget, #SCI_GETLENGTH)
  If numBytes
    SCI_SaveFile(0)
    hFile = CreateFile(#PB_Any,"sap.tmp") 
    If hFile
      If numBytes
        
      *Buffer  = AllocateMemory(numBytes+1)
      ScintillaSendMessage(id, #SCI_GETTEXT, numBytes + 1, *Buffer)
      text.s = PeekS(*Buffer, -1, #PB_UTF8)
      WriteData(hFile,*Buffer,numBytes+1)
      CloseFile(hfile)
      FreeMemory(*Buffer)
    EndIf
    
    EndIf
    dest_file.s = StringField(GetFilePart(strFilename),1,".")+".bin"
    dest_path.s = GetPathPart(strFilename)
    Debug "sapasm.exe -s -i sap.tmp -o " +dest_path+dest_file
    Compilateur = RunProgram("sapasm.exe","-s -i " +"sap.tmp -o " +dest_path+dest_file,"",#PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
    If Compilateur 
      While ProgramRunning(Compilateur)
        If AvailableProgramOutput(Compilateur)
          AddGadgetItem(1,-1,ReadProgramString(Compilateur))
        EndIf
      Wend
      If ProgramExitCode(Compilateur) = -1
        AddGadgetItem(1,-1,"Compilation terminer avec succès !!!")
      Else 
        line = ProgramExitCode(Compilateur)
        ScintillaSendMessage(0,#SCI_GOTOLINE,line-1)
      EndIf
      CloseProgram(Compilateur) ; Ferme la connection vers le programme
    EndIf
  EndIf
  
  If FileSize("sap.tmp") => 0
    DeleteFile("sap.tmp")
  EndIf
EndProcedure

;- ///// Main //// 
;{ 
If OpenWindow(0, 0, 0, 800, 600, "SAP-1 IDE - "+strFilename, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget )
  UsePNGImageDecoder()
  
  If UseGadgetList(WindowID(0))
    If CreateMenu(0, WindowID(0))
      MenuTitle("Fichier")
      MenuItem(1,"Nouveau"+Chr(9)+"Ctrl+N")
      MenuItem(2,"Ouvrir"+Chr(9)+"Ctrl+O")
      MenuItem(3,"Enregistrer"+Chr(9)+"Ctrl+S")
      MenuItem(4,"Enregistrer sous")
      MenuBar()
      MenuItem(5,"Quitter")
      
      MenuTitle("Edition")
      MenuItem(6,"&Annuler"+Chr(9)+"Ctrl+Z")
      MenuItem(7,"&Rétablir"+Chr(9)+"Ctrl+R")
      MenuBar()
      MenuItem(8,"Couper"+Chr(9)+"Ctrl+X")
      MenuItem(9,"Copier"+Chr(9)+"Ctrl+C")
      MenuItem(10,"Coller"+Chr(9)+"Ctrl+V")
      MenuBar()
      MenuItem(11,"Tout sélectionner"+Chr(9)+"Ctrl+A")
      
      MenuTitle("Assembleur")
      MenuItem(12,"Assembler"+Chr(9)+"F5")
      
      MenuTitle("Aide")
      MenuItem(13,"A propos de ...")
    EndIf
    
    If CreateToolBar(0,WindowID(0))
      ToolBarImageButton(1,CatchImage(12,?Image_1)) ;nouveau
      ToolBarImageButton(2,CatchImage(12,?Image_2)) ;ouvrir
      ToolBarImageButton(3,CatchImage(12,?Image_3)) ;enregistrer
      ToolBarSeparator()
      ToolBarImageButton(6,CatchImage(12,?Image_6)) ;annuler
      ToolBarImageButton(7,CatchImage(12,?Image_7)) ;retablir
      ToolBarSeparator()
      ToolBarImageButton(8,CatchImage(12,?Image_8)) ;couper
      ToolBarImageButton(9,CatchImage(12,?Image_9)) ;copier
      ToolBarImageButton(10,CatchImage(12,?Image_10)) ;coller
      ToolBarSeparator()
      ToolBarImageButton(12,CatchImage(12,?Image_12)) ;assembler
    EndIf
    
    
    If CreateStatusBar(0, WindowID(0))
      AddStatusBarField(#PB_Ignore)
      StatusBarText(0, 0, "Ligne: 0   Colonne: 0  ")
    EndIf
    
    If ListViewGadget(1,0,435,WindowWidth(0),120)
      SetGadgetColor(1, #PB_Gadget_BackColor, RGB(0,0,0))
      SetGadgetColor(1, #PB_Gadget_FrontColor, RGB(0,128,0))
      ;For a=1 To 2
      ;  AddGadgetItem (1,-1,"Elément "+Str(a)+" de la boîte à liste")   ; défini le contenu de la boîte de liste
      ;Next
    EndIf
    
    
    ScintillaGadget(0, 0, 0+ToolBarHeight(0), 800, 600-ToolBarHeight(0)-StatusBarHeight(0)-MenuHeight()-GadgetHeight(1), @SCI_ScintillaCallBack())
    ScintillaSendMessage(0,#SCI_SETHSCROLLBAR,#False)
    SplitterGadget(2,0,ToolBarHeight(0),800,600-ToolBarHeight(0)-StatusBarHeight(0)-MenuHeight(),0,1)
    SetGadgetState(2,WindowHeight(0)*0.7)
    
    ; Réactivation de la tabulation 
    RemoveKeyboardShortcut(0, #PB_Shortcut_Tab)
    AddKeyboardShortcut(0,#PB_Shortcut_Control | #PB_Shortcut_N,1)
    AddKeyboardShortcut(0,#PB_Shortcut_Control | #PB_Shortcut_O,2)
    AddKeyboardShortcut(0,#PB_Shortcut_Control | #PB_Shortcut_S,3)
    AddKeyboardShortcut(0, #PB_Shortcut_F5,12)
    
    ; Activation du gadget scintilla
    SetActiveGadget(0)
    SCI_InitStyle(0)
    
  EndIf
  
  Repeat
    event = WaitWindowEvent()   
    Select event
      Case #PB_Event_Menu
        Select EventMenu() 
          Case 1 ; Nouveau
            SCI_NewFile(0)
          Case 2 ; Ouvrir
            SCI_OpenFile(0)
          Case 3 ;Enregistrer
            SCI_SaveFile(gadget)
          Case 4 ;Enregistrer sous
            SCI_SaveFileAs(gadget)
          Case 5 ;Quitter
            Quit = 1
          Case 6 ; Annuler
            SCI_Undo(gadget)
          Case 7 ; Rétablir
            SCI_Redo(gadget)
          Case 8 ; Couper
            SCI_Cut(gadget)
          Case 9 ; Copier
            SCI_Copy(gadget)
          Case 10; Coller
            SCI_Paste(gadget)
          Case 11; Tout selectionner
            SCI_SelectAll(gadget)
          Case 12 ; Assembler  
            Compile()
          Case 13 ; A propos          
        EndSelect
      Case #PB_Event_CloseWindow
        Quit = 1
    EndSelect  
  Until  Quit = 1
EndIf
;}
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 171
; Folding = AAQQ-
; EnableXP