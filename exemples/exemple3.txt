;//////////////////////////////
;/ Compte à rebour depuis 100 /
;//////////////////////////////

	LDA nb_1
loop:	
	OUT
	SUB nb_2
	JMP loop
nb_1	EQU 100
nb_2	EQU 1