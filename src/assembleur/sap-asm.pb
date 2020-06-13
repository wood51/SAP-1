;- //////////  Définitions  //////////
Enumeration
  #_t_unknown
  #_t_tab
  #_t_newline
  #_t_identifier
  #_t_instruction
  #_t_instruction_operand
  #_t_number
  #_t_hex_number
  #_t_label
  #_t_eof
  #_st_data
  #_st_label
EndEnumeration

Structure _token
  line.i
  type.i
  value.s
EndStructure

Structure _symbol_table
  value.s
  equ_value.i
  real_address.i
  type.a
  line.i
  List reference_address.i()
EndStructure

Structure _source
  line.s
  no_line.i
EndStructure

Structure _instruction
  asOperand.b
  optCode.i
EndStructure

Structure _memory
  address.a
  optcode.a
  operand.a
  hexvalue.a
EndStructure

Global NewList memory._memory()
Global NewList source._source()
Global NewMap instruction._instruction()
Global NewList token._token()
Global NewList symbol_table._symbol_table()

#_memory_max_size = 15

#err_file_not_found = "Erreur : Fichier non trouvé"
#err_lexer_unknown_symbol = "Erreur : ligne %1 : Symbole non reconnu"
#err_lexer_symbol_already_defined = "Erreur : ligne %1 : Un symbole du même type à déja été définis"
#err_syntax = "Erreur de syntaxe ligne %1"
#err_syntax_tab = "Erreur : Tabulation manquante ligne %1"
#err_syntax_instruction_missing = "Erreur : Instruction attendu ligne %1"
#err_syntax_operand_missing = "Erreur : Opérande attendu ligne %1"
#err_syntax_assignation_instruction_is_missing = "Erreur : Instruction d'assignation de données attendu ligne %1"
#err_syntax_value_missing = "Erreur : Valeur attendu ligne %1"
#err_syntax_expected_number = "Erreur : Nombre attendu ligne %1"
#err_semantic_over_memory = "Erreur : Adresse en dehors des limites mémoire ligne %1"
#err_semantic_out_of_memory = "Erreur : Dépassement de la capacité mémoire"

#warming_label_not_use = "Avertissement : Label non utilisé ligne %1"
#err_semantic_duplicate_label = "Erreur : Etiquette déja définie ligne %1"
#err_semantic_label_not_declared = "Erreur : Etiquette non définie ligne %1"


#warming_data_not_use = "Avertissement : Donnée non utilisé ligne %1"
#err_semantic_duplicate_data = "Erreur : Donnée déja définie ligne %1"
#err_semantic_data_not_declared = "Erreur : Donnée non définie ligne %1"
;- //////////  Général  //////////

Procedure DisplayHead()
  PrintN("╔══════════════════════════════════════════╗")
  PrintN("║        SAP-1  Assembler by Wood51        ║")
  PrintN("╠══════════════════════════════════════════╣")
  PrintN("║ - Version : 1.00                         ║")
  PrintN("║ - Usage   : sap1-asm [input]             ║")
  PrintN("╚══════════════════════════════════════════╝")
  PrintN("")
EndProcedure

Procedure Exit(line.i = -1)
  If #PB_Compiler_Debugger 
    PrintN("Appuyer sur ENTREE pour terminer")
    Input() 
  EndIf
  ConsoleColor(7,0)
  CloseConsole()
  End line
EndProcedure  

Procedure _error(strError.s,line.i=0)
  ConsoleColor(12,0)
  strError = ReplaceString(strError,"%1",Str(line))
  PrintN(strError)
  Exit(line)
  ConsoleColor(7,0)
EndProcedure

Procedure _warming(strWarming.s,line.i=0)
  ConsoleColor(14,0)
  strWarming = ReplaceString(strWarming,"%1",Str(line))
  PrintN(strWarming)
  ConsoleColor(7,0)
EndProcedure

;- ////////// Table des symboles //////////
; ////////// Etiquettes
Procedure _label_generate(value.s,line.i) ; Créer un label ds table des symboles
  ForEach symbol_table()
    If symbol_table()\value = value And symbol_table()\type = #_st_label
      _error(#err_semantic_duplicate_label,line)
    EndIf
  Next
  
  AddElement(symbol_table())
  With symbol_table()
    \value = value
    \line = line
    \type = #_st_label
    \equ_value = -1
    \real_address = -1
  EndWith
  ;Debug "Lexer : Génération d'un label :" + value
EndProcedure

Procedure _label_reference(value.s,address.i,line.i) ; Definis l'address référence du label
  Define isGenerated.i = #False
  ForEach symbol_table()
    If symbol_table()\value = value And symbol_table()\type = #_st_label
      isGenerated = #True
      Break
    EndIf
  Next
  
  If isGenerated
    AddElement(symbol_table()\reference_address())
    symbol_table()\reference_address() = address
  Else
    _label_generate(value,line)
  EndIf
  ;Debug "Parser : Référence au label :" + value + " Adr:"+address
EndProcedure

Procedure _label_declare(value.s,address.i) ; Definis l'address réelle du label
  ForEach symbol_table()
    If symbol_table()\value = value And symbol_table()\type = #_st_label
      Break
    EndIf
  Next
  symbol_table()\real_address = address
  ;Debug "Parser : Déclaration label :" + value + " Adr réel:"+address
EndProcedure

Procedure _label_correct()
  ForEach  symbol_table()
    If symbol_table()\type = #_st_label 
      If symbol_table()\real_address <> -1 
        If ListSize(symbol_table()\reference_address())
          ForEach symbol_table()\reference_address()
            SelectElement(memory(),symbol_table()\reference_address())
            memory()\operand = symbol_table()\real_address
          Next
        Else
          _warming(#warming_label_not_use,symbol_table()\line)
        EndIf
      Else
        _error(#err_semantic_label_not_declared,symbol_table()\line)
      EndIf   
    EndIf
  Next
EndProcedure

; ////////// Données
Procedure _data_generate(value.s,line.i) ; Créer un label ds table des symboles
  ForEach symbol_table()
    If symbol_table()\value = value And symbol_table()\type = #_st_data 
      ProcedureReturn
    EndIf
  Next
  
  AddElement(symbol_table())
  With symbol_table()
    \value = value
    \line = line
    \type = #_st_data
    \equ_value = -1
    \real_address = -1
  EndWith
  ;Debug "Parser : Génération d'une data :" + value
EndProcedure

Procedure _data_reference(value.s,address.i,line.i) ; Definis l'address référence du label
  Define isGenerated.i = #False
  ResetList(symbol_table())
  ForEach symbol_table()
    If symbol_table()\value = value And symbol_table()\type = #_st_data
      isGenerated = #True
      Break
    EndIf
  Next
  
  If isGenerated = #True
    AddElement(symbol_table()\reference_address())
    symbol_table()\reference_address() = address
  Else
    _data_generate(value,line)
    AddElement(symbol_table()\reference_address())
    symbol_table()\reference_address() = address
  EndIf
  ;Debug "Parser : Référence au data :" + value + " Adr:"+address
EndProcedure

Procedure _data_declare(value.s,data_value.s,address.i) ; Definis l'address réelle du label
  ForEach symbol_table()
    If symbol_table()\value = value And symbol_table()\type = #_st_data
      Break
    EndIf
  Next
  symbol_table()\real_address = address
  symbol_table()\equ_value = Val(data_value)
  ;Debug "Parser : Déclaration data :" + value + " Adr réel:"+address
EndProcedure

Procedure _data_correct()
  ResetList(symbol_table())
  ForEach symbol_table()
    If symbol_table()\type = #_st_data And symbol_table()\equ_value <> -1
      If ListSize(memory()) < #_memory_max_size
        LastElement(memory())
        AddElement(memory())
        symbol_table()\real_address = ListIndex(memory())
        memory()\operand = symbol_table()\equ_value
      Else
        _error(#err_semantic_out_of_memory)
      EndIf
    EndIf
  Next 
  
  ResetList(symbol_table())
  ForEach symbol_table()
    If symbol_table()\type = #_st_data
      ForEach symbol_table()\reference_address()
        SelectElement(memory(),symbol_table()\reference_address())
        memory()\operand = symbol_table()\real_address
      Next
    EndIf
  Next
EndProcedure

;- //////////  Lexer  //////////
Procedure _lex_fill_instruction_map()
  instruction("NOP")\asOperand = #False
  instruction()\optCode = %00000000
  instruction("LDA")\asOperand = #True
  instruction()\optCode = %00010000
  instruction("ADD")\asOperand = #True
  instruction()\optCode = %00100000
  instruction("SUB")\asOperand = #True
  instruction()\optCode = %00110000
  instruction("LDI")\asOperand = #True
  instruction()\optCode = %01000000
  instruction("ADI")\asOperand = #True
  instruction()\optCode = %01010000
  instruction("SBI")\asOperand = #True
  instruction()\optCode = %01100000
  instruction("STA")\asOperand = #True
  instruction()\optCode = %01110000
  instruction("JC")\asOperand = #True
  instruction()\optCode = %10000000
  instruction("JZ")\asOperand = #True
  instruction()\optCode = %10010000
  instruction("JNC")\asOperand = #True
  instruction()\optCode = %10100000
  instruction("JNZ")\asOperand = #True
  instruction()\optCode = %10110000
  instruction("JMP")\asOperand = #True
  instruction()\optCode = %11010000
  instruction("OUT")\asOperand = #False
  instruction()\optCode = %11100000
  instruction("HLT")\asOperand = #False
  instruction()\optCode = %11110000
  instruction("EQU")\asOperand = #True ;Pseudo instruction (aucun cde généré) pour attriber des adresse aux données 
  instruction()\optCode = %00000000
EndProcedure

Procedure.i _lex_open_assembler_file(strFilename.s)
  hFile = ReadFile(#PB_Any,strFilename,#PB_UTF8)
  If hFile
    While Eof(hFile) = 0
      AddElement(source())
      source()\line = ReadString(hFile)
    Wend
    CloseFile(hFile)
    ProcedureReturn 1
  Else
    _error(#err_file_not_found)
    Exit()
    ProcedureReturn -1
  EndIf
EndProcedure

Procedure.s _lex_pack_string(string.s, separator.s) 
  Protected Chaine$,Chaine2$
  Chaine$=Trim(string)
  Repeat
    Chaine2$=Chaine$
    Chaine$ = ReplaceString(Chaine$, separator+separator, separator)
  Until Chaine2$=Chaine$
  ProcedureReturn Chaine$
EndProcedure

Procedure _lex_clean_file()
  no_line.i=1
  ForEach source()
    inComment = #False
    tmp$ = ""
    For  i = 1 To Len(source()\line)
      char$ = Mid(source()\line,i,1)
      If  char$ = ";"
        inComment = #True
      EndIf
      If inComment = #False
        tmp$ + char$
      EndIf
    Next
    source()\line = tmp$
    source()\line = source()\line + " " + #CRLF$  + " "
    source()\line = ReplaceString(source()\line,Chr(9)," ")
    source()\line = _lex_pack_string(source()\line," ")
    source()\no_line = no_line
    no_line + 1
  Next
EndProcedure

Procedure _lex_tokenize_file()
  line = 1
  ForEach source()
    nbToken = CountString(source()\line," ") + 1
    For i = 1 To nbToken
      AddElement(token())
      token()\line = line
      token()\type = #_t_unknown
      token()\value =  UCase(StringField(source()\line,i," "))
    Next 
    line + 1
  Next
  AddElement(token())
  token()\line = line
  token()\type = #_t_eof
  token()\value = "<EOF>"
EndProcedure

Procedure.i _lex_is_tab(token_value.s)
  RE = CreateRegularExpression(#PB_Any,"\t")
  If RE
    Result.a = MatchRegularExpression(RE,token_value)
    FreeRegularExpression(RE)  
  EndIf 
  ProcedureReturn Result
EndProcedure

Procedure.i _lex_is_newline(token_value.s)
  RE = CreateRegularExpression(#PB_Any,"\n")
  If RE
    Result.a = MatchRegularExpression(RE,token_value)
    FreeRegularExpression(RE)  
  EndIf 
  ProcedureReturn Result
EndProcedure

Procedure _lex_is_identifier(token_value.s)
  For i = 2 To Len(token_value)
    EXPREG$ + "[A-Z a-z _ 0-9]"
  Next 
  RE = CreateRegularExpression(#PB_Any,"[A-Z a-z]"+EXPREG$)
  If RE
    Result.a = MatchRegularExpression(RE,token_value)
    FreeRegularExpression(RE)
  EndIf
  ProcedureReturn Result
EndProcedure

Procedure _lex_is_label(token_value.s)
  For i = 2 To Len(token_value) - 1 ; Ne pas compter le caractère ":" dans la longeur du token puisque rajouter après
    EXPREG$ + "[A-Z a-z _ 0-9]"
  Next 
  RE = CreateRegularExpression(#PB_Any,"[A-Z a-z]"+EXPREG$+"[:]")
  If RE
    Result.a = MatchRegularExpression(RE,token_value)
    FreeRegularExpression(RE)
  EndIf
  ProcedureReturn Result
EndProcedure

Procedure _lex_is_number(token_value.s)
  For i = 2 To Len(token_value)
    EXPREG$ +"[0-9]"
  Next
  RE = CreateRegularExpression(#PB_Any,"^[0-9]"+EXPREG$)
  If RE
    Result.a = MatchRegularExpression(RE,token_value)
    FreeRegularExpression(RE)
  EndIf
  ProcedureReturn Result
EndProcedure

Procedure _lex_is_hex_number(token_value.s)
  For i = 3 To Len(token_value)
    EXPREG$ + "([0-9]|[A-E])"
  Next
  RE = CreateRegularExpression(#PB_Any,"^0(x|X)"+EXPREG$)
  If RE
    Result.a = MatchRegularExpression(RE,token_value)
    FreeRegularExpression(RE)
  EndIf
  ProcedureReturn Result
EndProcedure

Procedure _lex_evaluate_token()
  ForEach token()
    If _lex_is_tab(token()\value)
      token()\type = #_t_tab
      Continue
    EndIf
    
    If _lex_is_newline(token()\value)
      token()\type = #_t_newline
      Continue
    EndIf
    
    If _lex_is_identifier(token()\value)
      If FindMapElement(instruction(),token()\value)
        If instruction()\asOperand
          token()\type = #_t_instruction_operand
        Else
          token()\type = #_t_instruction
        EndIf
      Else
        token()\type = #_t_identifier
      EndIf
      Continue
    EndIf
    
    If _lex_is_label(token()\value)
      token()\value = Left(token()\value,Len(token()\value)-1) ; extraction du label
      token()\type = #_t_label
      _label_generate(token()\value,token()\line) ; Table des symbole
    EndIf
    
    
    If _lex_is_hex_number(token()\value)
      token()\value = "$" + Mid(token()\value,3) ; Extration du nombre + formatage format purebasic
      token()\type = #_t_hex_number
      Continue
    EndIf
    
    If _lex_is_number(token()\value)
      token()\type = #_t_number
      Continue
    EndIf
    
    If token()\type = #_t_eof
    EndIf
    
    If token()\type = #_t_unknown
      _error(#err_lexer_unknown_symbol,token()\line)
      Debug "Unknown :" + token()\value + "#"
    EndIf  
  Next
EndProcedure

;- /////////// Génération du code ////////
Procedure.a _code_get_memory_address()
  ProcedureReturn ListSize(memory())
EndProcedure

Procedure _code_generation_dump_memory()
  If ListSize(memory()) >= 0
    ForEach memory()
      address.s = RSet(Hex(ListIndex(memory()),#PB_Byte),2,"0")
      content.s = RSet(Hex(memory()\optcode+memory()\operand,#PB_Byte),2,"0")
      PrintN(address + ": " + content)
    Next
  EndIf
EndProcedure

Procedure _code_generate_instruction(memory.a,operand.a=0)  
  If ListSize(memory()) <= #_memory_max_size
    AddElement(memory())
    memory()\optcode = memory 
    memory()\operand = operand
  Else
    _error(#err_semantic_out_of_memory)
  EndIf
EndProcedure

Procedure _code_generate_hex(strFilename.s)
  hFile = CreateFile(#PB_Any,strFilename)
  If hFile 
    WriteStringN(hFile,"v2.0 raw")
    If ListSize(memory()) >= 0
      ForEach memory()
        address.s = RSet(Hex(ListIndex(memory()),#PB_Byte),2,"0")
        content.s = RSet(Hex(memory()\optcode+memory()\operand,#PB_Byte),2,"0")
        If (ListIndex(memory())+1) % 16 <> 0 
          WriteString(hFile,content + " ")
        Else
          WriteString(hFile,content + " "+Chr(13)+Chr(10))
        EndIf
      Next
    EndIf
  EndIf
EndProcedure

;- //////////  Syntax  //////////
Procedure _parser_next_token()
  NextElement(token())
EndProcedure

Procedure _parser_vide()
EndProcedure

Procedure _parser_nl()
  If token()\type = #_t_newline
    _parser_next_token()
    _parser_nl()
  EndIf
EndProcedure

Procedure _parser_nl_opt()
  If token()\type = #_t_newline
    _parser_next_token()
    _parser_nl_opt()
  Else
    _parser_vide()
  EndIf
EndProcedure

Procedure _parser_instruction() 
  If FindMapElement(instruction(),token()\value)
    _code_generate_instruction(instruction()\optCode)
  EndIf
  _parser_next_token()
EndProcedure

Procedure _parser_instruction_operand()
  If FindMapElement(instruction(),token()\value)
    memory.a = instruction()\optCode
    _parser_next_token()
    operand.a = Val(token()\value)
    Select token()\type
        
      Case #_t_number,#_t_hex_number
        If operand >= 0 And operand <= #_memory_max_size
          _code_generate_instruction(memory,operand)
          _parser_next_token()
        Else
          _error(#err_semantic_over_memory,token()\line)
        EndIf
        
      Case #_t_identifier 
        If MapKey(instruction()) = "JMP" Or MapKey(instruction()) = "JZ" Or MapKey(instruction()) = "JC"
          _label_reference(token()\value, _code_get_memory_address(),token()\line)
          _code_generate_instruction(memory) ; code bidon histoire de pas décalé tout le reste      
        ElseIf MapKey(instruction()) = "LDI" Or MapKey(instruction()) = "ADI" Or MapKey(instruction()) = "SBI"; Instruction prenant une valeur immédiate
          _error(#err_syntax_expected_number,token()\line)          
        Else ; Autres instructions qui n'utilisent pas les label mais adresse de données
          _data_reference(token()\value,_code_get_memory_address(),token()\line)
          _code_generate_instruction(memory) ; code bidon histoire de pas décalé tout le reste
        EndIf
        _parser_next_token()        
      Default
        _error(#err_syntax_operand_missing,token()\line)
    EndSelect 
  EndIf
EndProcedure

Procedure _parser_instructions()
  If token()\type = #_t_instruction
    _parser_instruction()
  ElseIf token()\type = #_t_instruction_operand
    _parser_instruction_operand()
  Else
    _error(#err_syntax_instruction_missing,token()\line)
  EndIf   
EndProcedure

Procedure _parser_data_assignation()
  data_name.s = token()\value
  _data_generate(data_name,token()\line)
  _parser_next_token()
  If FindMapElement(instruction(),token()\value)
    If MapKey(instruction()) = "EQU"
      _parser_next_token()
      Select token()\type
        Case #_t_number
          _data_declare(data_name,"$"+Hex(Val(token()\value)),_code_get_memory_address())
          _parser_next_token()
        Case  #_t_hex_number
          _data_declare(data_name,token()\value,_code_get_memory_address())
          _parser_next_token()
        Default
          _error(#err_syntax_value_missing,token()\line)
      EndSelect
    Else
      _error(#err_syntax_assignation_instruction_is_missing,token()\line)
    EndIf
  Else
    _error(#err_syntax_assignation_instruction_is_missing,token()\line)
  EndIf
  
EndProcedure

Procedure _parser_statement()
  Select token()\type
    Case #_t_label
      _label_declare(token()\value, _code_get_memory_address()) ; declaration de l'adresse réel du label puisque c'est un label et pas une référence à ce label
      _parser_next_token()
      
      Select  token()\type
        Case #_t_instruction , #_t_instruction_operand
          _parser_instructions()
          _parser_nl() 
        Case #_t_newline
          _parser_nl()
        Default
          _error(#err_syntax_instruction_missing,token()\line)
      EndSelect
      
    Case #_t_instruction,#_t_instruction_operand
      _parser_instructions()
      _parser_nl() 
      
    Case #_t_identifier
      _parser_data_assignation()
      _parser_nl()
      
    Default
      _error(#err_syntax,token()\line)
  EndSelect
EndProcedure

Procedure _parser_statements()
  If token()\type = #_t_tab Or token()\type = #_t_identifier Or token()\type = #_t_instruction Or token()\type = #_t_instruction_operand Or 
     token()\type = #_t_hex_number Or token()\type = #_t_number Or token()\type = #_t_label
    _parser_statement()
    _parser_statements()
  Else
    _parser_vide()
  EndIf
EndProcedure

Procedure _parser_start()
  _parser_nl_opt()
  _parser_statements()
EndProcedure

Procedure.i _parser_parse()
  ResetList(token())
  _parser_next_token()
  _parser_start()
  
  If token()\type =#_t_eof
    ProcedureReturn 1
  EndIf
  ProcedureReturn -1
EndProcedure

;- //////////  Main  //////////
If OpenConsole()
  nbParam.i = CountProgramParameters()
  standalone_mode = #True
  For i = 0 To nbParam -1
    Select ProgramParameter(i)
      Case "-i"
        asm_file.s = ProgramParameter(i+1)
        Continue
      Case "-s"
        standalone_mode = #False
      Case "-o"
        output_file.s = ProgramParameter(i+1)
        Continue
    EndSelect   
  Next
  
  If  standalone_mode
    DisplayHead()
  EndIf
  
  If _lex_open_assembler_file(asm_file)   
    _lex_fill_instruction_map()
    _lex_clean_file() 
    _lex_tokenize_file()
    _lex_evaluate_token()
    
    _parser_parse() 
    
    _label_correct()
    _data_correct()
    
    ;_code_generation_dump_memory()
    _code_generate_hex(output_file)
  EndIf
    
  If #PB_Compiler_Debugger 
    PrintN("Appuyer sur ENTREE pour terminer")
    Input() 
  EndIf
  
Else
  MessageRequester("Erreur","Une erreur inatendue s'est produite !",#PB_MessageRequester_Error)
EndIf
End -1
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 283
; FirstLine = 112
; Folding = GABAAAw
; EnableXP