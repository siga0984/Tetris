#include "protheus.ch"

/* ========================================================
Função       U_TETRIS
Autor        Júlio Wittwer
Data         03/11/2014
Versão       1.141103
Descriçao    Réplica do jogo Tetris, feito em AdvPL

Para jogar, utilize as letras:

A = Move esquerda
D = Move Direita
S = PAra baixo
W = Rotaciona sentido horario

Pendencias

Calcular e mostrar pontuação / score
Calcular e mostrar tempo de jogo
Mostrar a proxima peça que vai cair
Fazer um High Score

======================================================== */

STATIC aPieces := LoadPieces()
STATIC aColors := { "BLACK","BLUE","RED","GREEN","ORANGE","PURPLE","YELOW","LIGHTBLUE" }


USER Function Tetris()
Local nC
Local nL
Local oDlg
Local aBMPGrid := array(20,10)
Local aGrid := {}
Local oBackGround
Local cAct := ' '
Local oTimer
Local aDropping := {}
Local lRunning := .F.

// Carrega os arrays com as definições das peças
LoadPieces()

DEFINE DIALOG oDlg TITLE "Tetris" FROM 10,10 TO 600,400 PIXEL

// Cria um fundo cinza, "esticando" um bitmap
@ 8, 8 BITMAP oBackGround RESOURCE "GRAY" ;
   SIZE 104,204  Of oDlg ADJUST NOBORDER PIXEL

// Desenha na tela um grid de 20x10 com Bitmaps
// para ser utilizado para desenhar a tela do jogo

For nL := 1 to 20
	For nC := 1 to 10
		
		@ nL*10, nC*10 BITMAP oBmp RESOURCE "GRAY" ;
		   SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		aBMPGrid[nL][nC] := oBmp
		
	Next
Next

// Define um timer, para fazer a peça em jogo 
// descer uma posição a cada um segundo 
// ( Nao pode ser menor, o menor tempo é 1 segundo ) 
oTimer := TTimer():New(1000, ;
   {|| GoDown(oDlg,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer,.f.),oAct:Setfocus() }, oDlg )

// Botão para iniciar o jogo
@ 230,10 BUTTON oDummyBtn PROMPT 'Start' ;
  ACTION (Start(oDlg,@aDropping,oBackGround,aBMPGrid,aGrid),lRunning := .t.,oTimer:Activate(),oAct:Setfocus()) ;
  SIZE 80, 010 OF oDlg PIXEL

// Get de um caractere com 1 Byte de tamanho para obter 
// qual e a ação a ser realizada com a peça em jogo
@ 230,90 GET oAct VAR cAct PICTURE "!" ;
  MESSAGE "Action" SIZE 0,0 ;
  WHEN lRunning ;
  VALID ( DoAction(oDlg,cAct,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer),oAct:Setfocus(),.t. ) OF oDlg PIXEL

ACTIVATE DIALOG oDlg CENTER

Return

/*
Função Start()
Inicia o jogo
*/

STATIC Function Start(oDlg,aDropping,oBackGround,aBmpGrid,aGrid)

// Sorteia a peça em jogo
nPiece := randomize(1,len(aPieces)+1)

// Inicializa o grid de imagens do jogo na memória
InitGrid(@aGrid)

// Define a peça em queda e a sua posição inicial 
// Peca, direcao, linha, coluna
aDropping := {nPiece,1,1,6} 

// Desenha a peça em jogo no Grid
PutPiece(aDropping,aGrid)        

// Atualiza a interface com o Grid
PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)

Return

/* ----------------------------------------------------------
Inicializa o Grid na memoria
Em memoria, o Grid possui 14 colunas e 22 linhas
Na tela, são mostradas apenas 20 linhas e 10 colunas
As 2 colunas da esquerda e direita, e as duas linhas a mais 
sao usadas apenas na memoria, para auxiliar no processo 
de validação de movimentação das peças.
---------------------------------------------------------- */

STATIC Function InitGrid(aGrid)
aGrid := array(20,"11000000000011")
aadd(aGrid,"11111111111111")
aadd(aGrid,"11111111111111")
return

//
// Aplica a peça no Grid.
// Retorna .T. se foi possivel aplicar a peça na posicao atual
// Caso a peça não possa ser aplicada devido a haver 
// sobreposição, a função retorna .F. e o grid não é atualizado
//

STATIC Function PutPiece(aOnePiece,aGrid)
Local nPiece := aOnePiece[1]
Local nPos := aOnePiece[2]
Local nRow := aOnePiece[3]
Local nCol := aOnePiece[4]
Local nL
Local nOver := 0
Local aTecos := {}
cPieceStr := str(nPiece,1)
For nL := nRow to nRow+3
	cTeco := substr(aGrid[nL],nCol,4)
	cPeca := aPieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1)=='1'
			If substr(cTeco,nC,1)!='0'
				nOver++
				EXIT
			Else
				cTeco := Stuff(cTeco,nC,1,cPieceStr)
			Endif
		Endif
	Next
	aadd(aTecos,cTeco)
	If nOver <> 0
		EXIT
	Endif
Next

If nOver == 0
	For nL := nRow to nRow+3
		aGrid[nL] := stuff(aGrid[nL],nCol,4,aTecos[nL-nRow+1])
	Next
Endif

Return ( nOver == 0 )


/* ----------------------------------------------------------
Função PaintGrid()
Pinta o Grid do jogo da memória para a Interface
---------------------------------------------------------- */


STATIC Function PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
Local nL
Local nC

oBackGround:SetBmp("Gray")

for nL := 1 to 20
	cLine := aGrid[nL]
	For nC := 1 to 10
		nCor := val(substr(cLine,nC+2,1))
		aBmpGrid[nL][nC]:SetBmp(aColors[nCor+1])
		// aBmpGrid[nL][nC]:Refresh()
	Next
Next

Return


STATIC Function LoadPieces()
Local aLocalPieces := {}
                        
// Peça "O" , uma posição 
aadd(aLocalPieces,{'O',	{	'0000','0110','0110','0000'}})

// Peça "I" , em pé e deitada
aadd(aLocalPieces,{'I',	{	'0000','1111','0000','0000'},;
                        {	'0010','0010','0010','0010'}})

// Peça "S", em pé e deitada
aadd(aLocalPieces,{'S',	{	'0000','0011','0110','0000'},;
                        {	'0010','0011','0001','0000'}})

// Peça "Z", em pé e deitada
aadd(aLocalPieces,{'Z',	{	'0000','0110','0011','0000'},;
                        {	'0001','0011','0010','0000'}})

// Peça "L" , nas 4 posições possiveis
aadd(aLocalPieces,{'L',	{	'0000','0111','0100','0000'},;
                        {	'0010','0010','0011','0000'},;
                        {	'0001','0111','0000','0000'},;
                        {	'0110','0010','0010','0000'}})

// Peça "J" , nas 4 posições possiveis
aadd(aLocalPieces,{'J',	{	'0000','0111','0001','0000'},;
                        {	'0011','0010','0010','0000'},;
                        {	'0100','0111','0000','0000'},;
                        {	'0010','0010','0110','0000'}})

// Peça "T" , nas 4 posições possiveis
aadd(aLocalPieces,{'T',	{	'0000','0111','0010','0000'},;
                        {	'0010','0011','0010','0000'},;
                        {	'0010','0111','0000','0000'},;
                        {	'0010','0110','0010','0000'}})


Return aLocalPieces


/* ----------------------------------------------------------
Função GoDown()

Movimenta a peça em jogo uma posição para baixo. 
Caso a peça tenha batido em algum obstáculo no movimento 
para baixo, a mesma é fica e incorporada ao grid, e uma nova 
peça é colocada em jogo. Caso não seja possivel colocar uma
nova peça, a pilha de peças bateu na tampa -- Game Over

---------------------------------------------------------- */

STATIC Function GoDown(oDlg,oBackGround,aBMPGrid,aGrid,aDropping,lRunning,oTimer,lDrop)
Local aOldPiece

// Clona a peça em queda na posição atual 
aOldPiece := aClone(aDropping)

If lDrop
	
	// Dropa a peca ate bater embaixo
	While .T.
		
		// Remove a peça do Grid atual
		DelPiece(aDropping,aGrid)
		
		// uma linha pra baixo
		aDropping[3]++
		
		If PutPiece(aDropping,aGrid)
			// Encaixou, remove e tenta de novo
			DelPiece(aDropping,aGrid)
			aOldPiece := aClone(aDropping)
			LOOP
		Endif
		
		// Nao deu mais pra pintar, ^bateu^
		// Volta a peça anterior
		// pinta o grid e retorna
		
		aDropping := aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
		PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
		Return
		
	Enddo
	
Endif

// Vamos mover apenas uma linha pra baixo

// Remove a peça do Grid atual
DelPiece(aDropping,aGrid)

// Move a peça apenas uma linha pra baixo
aDropping[3]++

// Recoloca a peça no Grid
If PutPiece(aDropping,aGrid)
	
	// Se deu pra encaixar, beleza
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	Return
	
Endif

// opa ... bateu no final ...
// Volta a peça pro lugar anterior e chumba ...
aDropping :=  aClone(aOldPiece)
PutPiece(aDropping,aGrid)

// Beleza, agora verifica se da pra limpar alguma linha
CheckLines(@aGrid)

// agora cria uma peça nova
nPiece := randomize(1,len(aPieces)+1)
aDropping := {nPiece,1,1,6} // Peca, direcao, linha, coluna

If PutPiece(aDropping,aGrid)
	// se a peca tem onde entrar, beleza
	// Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
Else
  // Acabou, a peça nova nao entra (cabe) no Grid
  // Desativa o Timer e mostra "game over"
	lRunning := .f.
	oTimer:Deactivate()
	MsgStop("*** GAME OVER ***")
Endif

return

/* ----------------------------------------------------------
Recebe uma ação da interface, através de uma das letras 
de movimentação de peças, e realiza a movimentação caso 
haja espaço para tal. 
---------------------------------------------------------- */
STATIC Function DoAction(oDlg,cAct,oBackGround,aBMPGrid,aGrid,aDropping,lRunning,oTimer)
Local aOldPiece

// conout("Action  = ["+cAct+"]")

// Clona a peça em queda
aOldPiece := aClone(aDropping)

if cAct $ 'AJ'
	// Movimento para a Esquerda
	// uma coluna a menos
	// Remove a peça do grid
	DelPiece(aDropping,aGrid)
	aDropping[4]--
	If !PutPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a peça de volta
		aDropping :=  aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
	Endif
	// Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	
Elseif cAct $ 'DL'
	// Movimento para a Direita
	// uma coluna a mais
	// Remove a peça do grid
	DelPiece(aDropping,aGrid)
	aDropping[4]++'
	If !PutPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a peça de volta
		aDropping :=  aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
	Endif
	// Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	
Elseif cAct $ 'WI'
	
  // ( Movimento para cima ) 
	// Rotaciona sentido horario
	
	DelPiece(aDropping,aGrid)
	
	aDropping[2]--
	If aDropping[2] < 1
		aDropping[2] := len(aPieces[aDropping[1]])-1
	Endif
	
	If !PutPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a peça de volta
		aDropping :=  aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
	Endif
	
	// E Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	
ElseIF cAct $ 'SK'
	
	// Empurra pra baixo uma linha
	GoDown(oDlg,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer,.f.)
	
ElseIF cAct == ' '
	
	// Dropa a peca - empurra para baixo até a última linha
	// antes de baer a peça no fundo do Grid
	GoDown(oDlg,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer,.t.)
	
Endif

Return .T.


/* -----------------------------------------------------------------------
Remove uma peça do Grid atual 
----------------------------------------------------------------------- */
STATIC Function DelPiece(aDropping,aGrid)

Local nPiece := aDropping[1]
Local nPos   := aDropping[2]
Local nRow   := aDropping[3]
Local nCol   := aDropping[4]
Local nL, nC
Local cTeco, cPeca

For nL := nRow to nRow+3
  cTeco := substr(aGrid[nL],nCol,4)
  cPeca := aPieces[nPiece][1+nPos][nL-nRow+1]
  For nC := 1 to 4
    If Substr(cPeca,nC,1)=='1'
      cTeco := Stuff(cTeco,nC,1,'0')
    Endif
  Next
  aGrid[nL] := stuff(aGrid[nL],nCol,4,cTeco)
Next

Return

/* -----------------------------------------------------------------------
Verifica se alguma linha esta completa e pode ser eliminada
----------------------------------------------------------------------- */
STATIC Function CheckLines(aGrid)
For nL := 20 to 2 step -1
	cTeco := substr(aGrid[nL],3)
	cNewTeco := strtran(cTeco,'0','')
	If len(cNewTeco) == len(cTeco)
		// Linha cheia, elimina a linha e acrescenta 
		// Uma nova linha em branco no topo do Grid
	  adel(aGrid,nL)
    ains(aGrid,1)
    aGrid[1] := "11000000000011"
    nL++
	Endif
Next
Return
