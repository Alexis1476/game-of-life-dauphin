; ETML - CID3A 
; Auteur : Alexis Rojas 
; Date : 2022  
; Description : Projet jeu de la vie pour le module I242 
 
POSX 	        	= H'700	; Pos X du pixel courant 
POSY	        	= H'702	; Pos Y du pixel courant 
PIXELSON		= H'703	; Nombre de pixels voisins en vie 
SCREENCOPY	= H'600	; Adresse de la pile 
SCREENSIZE      	= 96	; Taille de l'écran en octects 
 
	CALL	PUTMOTIF 
 
; Boucle du jeu 
GAMELOOP : 	 
	CALL	INIT 
	CALL	SCREEN_TO_COPY 
 
; Parcoure l'écran 
BROWSE_SCREEN : 
	CALL	CHECK_NEIGHBOURS 
	INC	X 

	; Tant qu'on arrive pas à la dernière colonne
	COMP 	#_BITMAPWIDTH, X	
	JUMP 	LO,  BROWSE_SCREEN 
	
	JUMP	NEW_LINE 
 
; Descende d'une ligne de l'écran
NEW_LINE :  
	CLR	X 
	INC	Y 
	
	; Tant que n'arrive pas à la dernière ligne
	COMP 	#_BITMAPHEIGHT, Y
	JUMP 	LO, BROWSE_SCREEN 

	;  Fin de lecture de l'écran 
	CALL	_ClearScreen
	CALL	COPY_TO_SCREEN 
	JUMP	GAMELOOP 
 
; Vérifie l'état des pixels voisins
CHECK_NEIGHBOURS : 
	; Garde les coordonnées
	MOVE	X, POSX		 
	MOVE	Y, POSY	

	; En haut à gauche 
	DEC	X		
	DEC	Y 
	CALL	TEST_PIXEL 
	
	; En haut 
	INC	X		
	CALL	TEST_PIXEL
	
	; En haut à droite 
	INC	X		
	CALL	TEST_PIXEL 
	
	; A droite 
	INC	Y		
	CALL	TEST_PIXEL 
	
	; A gauche 
	SUB #2, X			
	CALL	TEST_PIXEL 
	
	; En bas à gauche 
	INC	Y		
	CALL	TEST_PIXEL 

	; En bas 
	INC	X		
	CALL	TEST_PIXEL 

	; En bas à droite 
	INC	X		
	CALL	TEST_PIXEL 

	; Reprend les coordonnées du pixel courant
	MOVE 	POSX, X
	MOVE 	POSY, Y

	; Conditions avec le nb de pixel allumés 
	CALL	CHECK_NB_ON
	CLR	PIXELSON		; Reinitialisation NBALIVE 
	RET 
 
; Vérifie le nombre de pixels voisins actifs 
CHECK_NB_ON: 
	; Si le pixel est actif 
	CALL	_TestPixel 
	JUMP, NE SURVIVE

	; Si le pixel est éteint
	JUMP, EQ NAIT 
	RET 
 
; Conditions si le pixel est éteint
NAIT: 
	;Naissance par réproduction 
	COMP	#D'3, PIXELSON 
	JUMP, EQ SET_PIXEL 
	RET

 ; Conditions si le pixel est déjà actif
SURVIVE: 
	; Reste en vie si 2 voisins
	COMP	#D'2, PIXELSON 
	JUMP, EQ SET_PIXEL

	; Reste en vie si 3 voisins
	COMP	#D'3, PIXELSON 
	JUMP, EQ SET_PIXEL

	; Mort par sous-population 
	COMP	#D'2, PIXELSON 
	JUMP, LS	CLR_PIXEL 

	; Mort par surpopulation 
	COMP	#D'3, PIXELSON 
	JUMP, HI	CLR_PIXEL 
	RET 
 
; Eteint un pixel dans la copie d'écran (Modification de _ClrPixel) 
CLR_PIXEL: 
	PUSH	B 
	PUSH	X 
	PUSH	Y 
	AND	#H'1F, Y 
	RL	Y 
	RL	Y 
	MOVE	X, B 
	XOR	#H'07, B 
	RR	X 
	RR	X 
	RR	X 
	AND	#H'3, X 
	MOVE	#0, A 
	TCLR	SCREENCOPY+{X}+{Y} :B 
	POP	Y 
	POP	X 
	POP	B 
	RET 
 
; Allume un pixel dans la copie d'écran (Modification de _SetPixel) 
SET_PIXEL: 
	PUSH	B 
	PUSH	X 
	PUSH	Y 
	AND	#H'1F, Y 
	RL	Y 
	RL	Y 
	MOVE	X, B 
	XOR	#H'07, B 
	RR	X 
	RR	X 
	RR	X 
	AND	#H'3, X 
	MOVE	#0, A 
	TSET	SCREENCOPY+{X}+{Y} :B 
	POP	Y 
	POP	X 
	POP	B 
	RET 
 
; Incrémente PIXELSON si le pixel est actif
TEST_PIXEL:
	; Si ça dépasse la largeur de l'écran 
	COMP	#31, X 
	JUMP,HI	NEXT_PIXEL
	
	; Si ça dépasse la hauteur de l'écran 
	COMP	#23, Y 
	JUMP,HI	NEXT_PIXEL 
	
	; Si pixel actif, PIXELSON est incrementé
	CALL	_TestPixel 
	JUMP, NE	INC_PIXELSON
	RET
; Ne fait pas de condition si ça dépase les bordes de l'écran 
NEXT_PIXEL: 
	RET 
 
; Initialise le registre X et Y 
INIT :				 
	CLR	X 
	CLR	Y 
	RET 
 
; Incremente le nb de pixels actifs
INC_PIXELSON: 
	INC	PIXELSON 
	RET	 
 
; Copie l'écran vers la copie d'écran. 
SCREEN_TO_COPY: 
	CALL	INIT 
	MOVE	#SCREENSIZE, B
; Boucle avec le nombre d'octets de l'écran
LOOP1: 
	MOVE	_BITMAP+{X}+{Y}, A 
	MOVE	A, SCREENCOPY+{X}+{Y} 
	INC	X 
	DEC	B 
	JUMP,NE	LOOP1 
	RET 
 
; Copie la copie d'écran vers l'écran. 
COPY_TO_SCREEN: 
	CALL	INIT 
	MOVE	#SCREENSIZE, B
; Boucle avec le nombre d'octets de l'écran
LOOP2: 
	MOVE	SCREENCOPY+{X}+{Y}, A 
	MOVE	A, _BITMAP+{X}+{Y} 
	INC	X 
	DEC	B 
	JUMP,NE	LOOP2 
	RET 
 
; Affiche une figure dans l'écran 
PUTMOTIF:  
	MOVE	#H'40, _BITMAP+41 
	MOVE	#H'10, _BITMAP+45 
	MOVE	#H'CE, _BITMAP+49 
	RET
