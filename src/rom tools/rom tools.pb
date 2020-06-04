; - Signaux du SAP-1
#AI =   %0000000000000001
#AO =   %0000000000000010
#BI =   %0000000000000100
#FI =   %0000000000001000
#EO =   %0000000000010000
#SU =   %0000000000100000
#CO =   %0000000001000000
#CE =   %0000000010000000
#Jump = %0000000100000000
#RI =   %0000001000000000
#RO =   %0000010000000000
#Halt = %0000100000000000
#OI =   %0001000000000000
#MI =   %0010000000000000
#II =   %0100000000000000
#IO =   %1000000000000000

#ROM_SIZE = 1024
#INSTRUCTION_NUMBER = 16

;{ 1 Instruction se fait en 5 Cycles les 2 premiers sont le fetch cycle pour toutes instrcutions
; Instruction NOP OptCode = 0000
; Cycle   OptCode   MicroInstrcutions
; 0000    0000      #MI | #CO
; 0001    0000      #II | #RO | #CE
; 0010    0000      Rien
; 0011    0000      Rien
; 0100    0000      Rien


; Instruction LDA OptCode = 0001
; Cycle   OptCode   MicroInstrcutions
; 0000    0001      #MI | #CO
; 0001    0001      #II | #RO | #CE
; 0010    0001      #IO | #MI
; 0011    0001      #RO | #AI
; 0100    0001      Rien

; Instruction ADD OptCode = 0010
; Cycle   OptCode   MicroInstrcutions
; 0000    0010      #MI | #CO
; 0001    0010      #II | #RO | #CE
; 0010    0010      #IO | #MI
; 0011    0010      #RO | #BI
; 0100    0010      #EO | #AI | #FI
;}

DataSection
  Instructions:
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; NOP OptCode 0000
  Data.i #MI|#CO , #II|#RO|#CE , #IO|#MI   , #RO|#AI , 0                ; LDA OptCode 0001
  Data.i #MI|#CO , #II|#RO|#CE , #IO|#MI   , #RO|#BI , #EO|#AI|#FI      ; ADD OptCode 0010
  Data.i #MI|#CO , #II|#RO|#CE , #IO|#MI   , #RO|#BI , #SU|#EO|#AI|#FI  ; SUB OptCode 0011
  Data.i #MI|#CO , #II|#RO|#CE , #IO|#AI   , 0       , 0                ; LDI OptCOde 0100
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ;  
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
  Data.i #MI|#CO , #II|#RO|#CE , #IO|#Jump , 0       , 0                ; JMP OptCode 1101
  Data.i #MI|#CO , #II|#RO|#CE , #AO|#OI   , 0       , 0                ; OUT OptCode 1110
  Data.i #MI|#CO , #II|#RO|#CE , #Halt     , 0       , 0                ; HLT OptCode 1111
EndDataSection

Dim ROM(#ROM_SIZE)

If OpenConsole()
  
  ; Gestion des paramètres du programme
  nbProgramParameters = CountProgramParameters()
  If CountProgramParameters()
    If ProgramParameter() = "-o"
      strFileName.s = ProgramParameter()
    Else
      PrintN("Usage : rom_tools -o [output_file]")
      Input()
      CloseConsole()
      End
    EndIf
    
    ; Création du fichier
    If FileSize(strFileName) => 0 
      hFile = CreateFile(#PB_Any,strFileName)
      PrintN("Fichier déja existant , voulez-vous l'écraser ? [o/n]")
      strChoix.s{1} = UCase(Input())
      If strChoix = "N"
        CloseFile(hFile)
        Input()
        CloseConsole()
        End
      EndIf
    Else
      hFile = CreateFile(#PB_Any,strFileName)
    EndIf
    
    
    ; Remplissage du tableau mémoire par des zéro
    For i = 0 To  (ArraySize(ROM()) - 1)
      ROM(i)=0
    Next
    
    ; Génération suivant les instructions et les cycles
    Restore Instructions
    For i= 0 To 15 ; Pour chaque instruction 
      For j = 0 To 4 ; Pour chaque cycle
        Read Inst
        Adr = j << 4 + i ; Adrresse en ROM -> jjjj iiii => j :-> cycle # i :-> optcode
        ROM(Adr) = Inst
      Next
    Next
        
    ; Ecriture de l'entête 
    WriteStringN(hFile,"v2.0 raw")
    ; Dump mémoire
    For i = 0 To  (ArraySize(ROM()) - 1)
      If (i+1) % 16 <> 0
        WriteString(hFile,(RSet(Hex(ROM(i)),4,"0")+" "))
        Print(RSet(Hex(ROM(i)),4,"0")+" ")
      Else
        WriteStringN(hFile,(RSet(Hex(ROM(i)),4,"0")+" "))
        PrintN(RSet(Hex(ROM(i)),4,"0")+" ")
      EndIf
    Next
    
    ;Fermeture du fichier 
    CloseFile(hFile)
    
  EndIf 
  
  Input()
  CloseConsole()
EndIf
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 54
; FirstLine = 36
; Folding = -
; EnableXP