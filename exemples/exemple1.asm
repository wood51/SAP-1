	  LDI 15 ; On charge 15 dans le registre A
moins:	  OUT ; Affiche la valeur du registre A
	  JZ  fin ; Si A = 0 alors on va a fin
	  SBI 1 ; Soustrait 1 au registre A
	  JMP moins ; continue et on va à moins
fin:	  HLT ; On arrête le CPU�te le CPU