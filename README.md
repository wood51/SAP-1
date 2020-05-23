# SAP-1 CPU

Simulation de "l'ordinateur" SAP-1 décrit dans le livre Digital Computer Electronics à l'aide du logiciel logisim (présent dans le dépo ou [téléchargement](http://www.cburch.com/logisim/download.html)). 

## Caractéristiques 
Mémoire : 16 bytes de RAM pour les données et le programme
Bus de Donnée : 8 Bits
Bus d'adresse : 4 Bits 
Sortie : Affichage décimale sur 8 Bits (3 digits de 0 à 255)
Maximum 5 cycles d'horloge par instruction .
7 Instructions .

## Instructions

 - LDA Adresse : Charger registre A avec le contenu de l'adresse 
 - ADD Adresse : Additionner A avec le contenu de l'adresse et le
   placer dans A
 - SUB Adresse : Soustraire A avec le contenu de l'adresse et le
   placer dans A
 - JMP Adresse : Sauter à l'adresse
 - OUT : Charger le contenu du registre A dans le registre de sortie (Affichage)
 - NOP : Ne rien faire
 - HLT : Stopper le CPU

## Programmation

Il faut éditer le contenu de la RAM dans le sous-circuit (double clique sur RAM puis clique droit sur la RAM > Edit contents ou Load Image si vous avez un fichier bin)  .
Chaque instruction correspond a un Optcode (sur 4 bits) suivit de son opérande (sur 4 bits également) . 

 - LDA Adresse : 0001 aaaa (aaaa correspond au 4 bits de l'adresse mémoire)

 - ADD Adresse : 0010 aaaa
 - SUB Adresse : 0011 aaaa
 - JMP Adresse : 1101 aaaa
 - OUT  : 1110
 - NOP : 0000
 - HLT : 1111

 
 Exemple : Additioner 15+7 et l'afficher . 

    Adresse 0 : LDA 4 : 0001 0100 
    Adresse 1 : ADD 5 : 0010 0101
    Adresse 2 : OUT   : 1110 0000
    Adresse 3 : HLT   : 1111 0000
    Adresse 4 : 15    : 0000 1111
    Adresse 5 : 7     : 000 00111

Soit en hexadécimal le contenu de la RAM à éditer :
14 25 E0 F0 0F 07

## Exécution

Une fois de retour sur le circuit principal , Dans le menu simulate , vérifier que la simulation est activé (Ctrl+E) , que l'horloge est activé (Ctrl+K) . L'outil Poke (la main en haut a gauche de la barre de menu Ctrl+1) doit être activé aussi .

 - Le signal Step/Run permet de sélectionner le mode pas à pas ou run (actif à 1)
 - Step permet d'effectuer un cycle d'horloge
 - Clr permet de faire un Reset de tout les circuit sauf les ROMs et la RAM
 
## Assembleur

Afin d'éditer des programmes sans tout coder en binaire à la main, j'ai programmer un assembleur (sapasm.exe présent dans le dépo) sous windows (pas essayé, mais sous wine çà doit fonctionner) qui génère directement un fichier utilisable par logisim .

 - Syntaxe :
 Label < retour à la ligne> (exemple: label:)
 Label Instruction (exemple: OUT)
 Label Instruction Operand (exemple: ADD nombre)
 Data EQU Value (Exemple: nombre EQU 15)

Une opérande peut être une valeur décimale (0-255) , hexadécimale (0x00-0xFF), un identifiant correspondant à une donné déclarer avec la pseudo-instruction EQU ou un identifiant correspondant à un label (cas de l'instruction JMP)

Une identifiant commence par une lettre mais peut contenir par la suite un nombre et un underscore .
Exemple identifiant valide :
 - data_1
 - un_nombre
 - donnee10_12

Voici l'exemple du programme précédant qui ajoute 15+7 :

		LDA nombre1
		ADD nombre2
		OUT
		HLT
    nombre1 EQU 15
    nombre2 EQU 7

Une fois saisi, lancer une ligne de commande avec :

    sapasm -i programme.txt -o hex_programme.bin

le fichier hex_programme.bin peut être charger directement dans la RAM du SAP-1 et être exécuter ;-)

Quelques exemple de programme sont présent dans le dépo. Je suis en train de programmer un IDE afin de tous avoir sous la main ...
