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

#ROM_SIZE = 256
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
  Data.i #MI|#CO , #II|#RO|#CE , 0         , 0       , 0                ; 
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

OpenConsole()

; Remplissage du tableau mémoire par des zéro
For i = 0 To  (ArraySize(ROM()) - 1)
  ROM(i)=0
Next

; Génération suivant les instructions et cycle
Restore Instructions
For i= 0 To 15 ; Pour chaque instruction 
  For j = 0 To 4 ; Pour chaque cycle
    Read Inst
    Adr = j << 4 + i ; Adr -> jjjj iiii => j :-> cycle # i :-> optcode
    ROM(Adr) = Inst
  Next
Next

; Dump mémoire
For i = 0 To  (ArraySize(ROM()) - 1)
  If (i+1) % 16 <> 0
    Print(" " + RSet(Hex(ROM(i)),4,"0"))
  Else
    PrintN(" " + RSet(Hex(ROM(i)),4,"0"))
  EndIf
Next

Input()
CloseConsole()

; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 79
; FirstLine = 59
; Folding = -
; EnableXP