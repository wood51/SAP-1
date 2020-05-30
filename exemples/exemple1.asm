;////////////////////
;/ Ajoute 2 nombres /
;////////////////////

	LDA nb_1 ;Charge nb_1 dans A
	ADD nb_2 ;Additionne A avec nb_2
	OUT 	 ;Affiche le résultat
	HLT	 ;Arrêt du SAP-1
nb_1	EQU 15   ;Définition de nb_1
nb_2	EQU 7	 ;Définition de nb_2