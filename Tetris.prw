#include "protheus.ch"

/* ========================================================
Função       U_TETRIS
Autor        Júlio Wittwer
Data         03/11/2014
Versão       1.150224
Descriçao    Réplica do jogo Tetris, feito em AdvPL

Para jogar, utilize as letras :

A ou J = Move esquerda
D ou L = Move Direita
S ou K = Para baixo
W ou I = Rotaciona sentido horario
Barra de Espaço = Dropa a peça

Pendencias

Fazer um High Score

Cores das peças

O = Yellow
I = light Blue
L = Orange
Z = Red
S = Green
J = Blue
T = Purple

======================================================== */

STATIC _aPieces := LoadPieces()
STATIC _aBlockRes := { "BLACK2","YELOW2","LIGHTBLUE2","ORANGE2","RED2","GREEN2","BLUE2","PURPLE2" }
STATIC _nGameClock
STATIC _nNextPiece
STATIC _GlbStatus := 0 // 0 = Running  1 = PAuse 2 == Game Over
STATIC _aBMPGrid  := array(20,10)
STATIC _aBMPNext  := array(4,5)
STATIC _aNext := {}
STATIC _nScore := 0
STATIC _oScore
STATIC _aDropping := {}
STATIC _aMainGrid := {}
STATIC _oTimer
                 


USER Function Tetris()
Local nC , nL
Local oDlg
Local oBackGround , oBackNext
Local oFont , oLabel , oMsg

// Fonte default usada na caixa de diálogo 
// e respectivos componentes filhos
oFont := TFont():New('Courier new',,-16,.T.,.T.)

DEFINE DIALOG oDlg TITLE "Tetris AdvPL" FROM 10,10 TO 450,365 ;
   FONT oFont COLOR CLR_WHITE,CLR_BLACK PIXEL

// Cria um fundo cinza, "esticando" um bitmap
@ 8, 8 BITMAP oBackGround RESOURCE "GRAY" ;
SIZE 104,204  Of oDlg ADJUST NOBORDER PIXEL

// Desenha na tela um grid de 20x10 com Bitmaps
// para ser utilizado para desenhar a tela do jogo

For nL := 1 to 20
	For nC := 1 to 10
		
		@ nL*10, nC*10 BITMAP oBmp RESOURCE "BLACK2" ;
      SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		_aBMPGrid[nL][nC] := oBmp
		
	Next
Next
               
// Monta um Grid 4x4 para mostrar a proxima peça
// ( Grid deslocado 110 pixels para a direita )

@ 8, 118 BITMAP oBackNext RESOURCE "GRAY" ;
	SIZE 54,44  Of oDlg ADJUST NOBORDER PIXEL

For nL := 1 to 4
	For nC := 1 to 5
		
		@ nL*10, (nC*10)+110 BITMAP oBmp RESOURCE "GRAY2" ;
      SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		_aBMPNext[nL][nC] := oBmp
		
	Next
Next

// Label fixo, título do Score.
@ 80,120 SAY oLabel PROMPT "[Score]" SIZE 60,10 OF oDlg PIXEL
                                    
// Label para Mostrar score, timers e mensagens do jogo
@ 90,120 SAY _oScore PROMPT "        " SIZE 60,120 OF oDlg PIXEL
                                     
// Define um timer, para fazer a peça em jogo
// descer uma posição a cada um segundo
// ( Nao pode ser menor, o menor tempo é 1 segundo )
_oTimer := TTimer():New(1000, ;
	{|| MoveDown(.f.) , PaintScore() }, oDlg )

// Botões com atalho de teclado
// para as teclas usadas no jogo
// colocados fora da area visivel da caixa de dialogo

@ 480,10 BUTTON oDummyBtn PROMPT '&A' ;
  ACTION ( DoAction('A'));
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&S' ;
  ACTION ( DoAction('S') ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&D' ;
  ACTION ( DoAction('D') ) ;
  SIZE 1, 1 OF oDlg PIXEL
  
@ 480,20 BUTTON oDummyBtn PROMPT '&W' ;
  ACTION ( DoAction('W') ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&J' ;
  ACTION ( DoAction('J') ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&K' ;
  ACTION ( DoAction('K') ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&L' ;
  ACTION ( DoAction('L') ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&I' ;
  ACTION ( DoAction('I') ) ;
  SIZE 1, 1 OF oDlg PIXEL
                                                  
@ 480,20 BUTTON oDummyBtn PROMPT '& ' ; // Espaço = Dropa
  ACTION ( DoAction(' ') ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&P' ; // Pause
  ACTION ( DoPause() ) ;
  SIZE 1, 1 OF oDlg PIXEL

// Na inicialização do Dialogo uma partida é iniciada
oDlg:bInit := {|| Start(oDlg),;
                  _GlbStatus := 0 ,;
                  _oTimer:Activate() }

ACTIVATE DIALOG oDlg CENTER

Return

/* ------------------------------------------------------------
Função Start() Inicia o jogo
------------------------------------------------------------ */

STATIC Function Start()
Local aDraw

// Inicializa o grid de imagens do jogo na memória
// Sorteia a peça em jogo
// Define a peça em queda e a sua posição inicial
// [ Peca, direcao, linha, coluna ]
// e Desenha a peça em jogo no Grid
// e Atualiza a interface com o Grid
InitGrid()
nPiece := randomize(1,len(_aPieces)+1)
_aDropping := {nPiece,1,1,6}
SetGridPiece(_aDropping,_aMainGrid)
PaintMainGrid()

// Sorteia a proxima peça e desenha 
// ela no grid reservado para ela 
InitNext()
_nNextPiece := randomize(1,len(_aPieces)+1)
aDraw := {_nNextPiece,1,1,1}
SetGridPiece(aDraw,_aNext)
PaintNext()

// Marca timer do inicio de jogo 
_nGameClock := seconds()

Return

/* ----------------------------------------------------------
Inicializa o Grid na memoria
Em memoria, o Grid possui 14 colunas e 22 linhas
Na tela, são mostradas apenas 20 linhas e 10 colunas
As 2 colunas da esquerda e direita, e as duas linhas a mais
sao usadas apenas na memoria, para auxiliar no processo
de validação de movimentação das peças.
---------------------------------------------------------- */

STATIC Function InitGrid()
_aMainGrid := array(20,"11000000000011")
aadd(_aMainGrid,"11111111111111")
aadd(_aMainGrid,"11111111111111")
return

STATIC Function InitNext()
_aNext := array(4,"00000")
return

//
// Aplica a peça no Grid.
// Retorna .T. se foi possivel aplicar a peça na posicao atual
// Caso a peça não possa ser aplicada devido a haver
// sobreposição, a função retorna .F. e o grid não é atualizado
//

STATIC Function SetGridPiece(aOnePiece,aGrid)
Local nPiece := aOnePiece[1] // Numero da peça
Local nPos   := aOnePiece[2] // Posição ( para rotacionar ) 
Local nRow   := aOnePiece[3] // Linha atual no Grid
Local nCol   := aOnePiece[4] // Coluna atual no Grid
Local nL , nC
Local aTecos := {}
Local cTeco, cPeca , cPieceStr

cPieceStr := str(nPiece,1)

For nL := nRow to nRow+3
	cTeco := substr(aGrid[nL],nCol,4)
	cPeca := _aPieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1) == '1'
			If substr(cTeco,nC,1) != '0'
				// Vai haver sobreposição,
				// Nao dá para desenhar a peça
				Return .F.
			Endif
			cTeco := Stuff(cTeco,nC,1,cPieceStr)
		Endif
	Next
  // Array temporario com a peça já colocada
	aadd(aTecos,cTeco)
Next

// Aplica o array temporario no array do grid
For nL := nRow to nRow+3
	aGrid[nL] := stuff(_aMainGrid[nL],nCol,4,aTecos[nL-nRow+1])
Next

Return .T.


/* ----------------------------------------------------------
Função PaintMainGrid()
Pinta o Grid do jogo da memória para a Interface

Release 20150222 : Optimização na camada de comunicação, apenas setar
o nome do resource / bitmap caso o resource seja diferente do atual.
---------------------------------------------------------- */

STATIC Function PaintMainGrid()
Local nL, nc , cLine, nPeca

for nL := 1 to 20
	cLine := _aMainGrid[nL]
	For nC := 1 to 10
		nPeca := val(substr(cLine,nC+2,1))
		If _aBMPGrid[nL][nC]:cResName != _aBlockRes[nPeca+1]
			// Somente manda atualizar o bitmap se houve
			// mudança na cor / resource desta posição
			_aBMPGrid[nL][nC]:SetBmp(_aBlockRes[nPeca+1])
		endif
	Next
Next

Return

// Pinta na interface a próxima peça 
// a ser usada no jogo 
STATIC Function PaintNext()
Local nL, nC, cLine , nPeca

For nL := 1 to 4
	cLine := _aNext[nL]
	For nC := 1 to 5
		nPeca := val(substr(cLine,nC,1))
		If _aBMPNext[nL][nC]:cResName != _aBlockRes[nPeca+1]
			_aBMPNext[nL][nC]:SetBmp(_aBlockRes[nPeca+1])
		endif
	Next
Next

Return

/* -----------------------------------------------------------------
Carga do array de peças do jogo 
Array multi-dimensional, contendo para cada 
linha a string que identifica a peça, e um ou mais
arrays de 4 strings, onde cada 4 elementos 
representam uma matriz binaria de caracteres 4x4 
para desenhar cada peça 

Exemplo - Peça "O"      

aLPieces[1][1] C "O"
aLPieces[1][2][1] "0000" 
aLPieces[1][2][2] "0110" 
aLPieces[1][2][3] "0110" 
aLPieces[1][2][4] "0000" 

----------------------------------------------------------------- */

STATIC Function LoadPieces()
Local aLPieces := {}

// Peça "O" , uma posição
aadd(aLPieces,{'O',	{	'0000','0110','0110','0000'}})

// Peça "I" , em pé e deitada
aadd(aLPieces,{'I',	{	'0000','1111','0000','0000'},;
                    {	'0010','0010','0010','0010'}})

// Peça "S", em pé e deitada
aadd(aLPieces,{'S',	{	'0000','0011','0110','0000'},;
                    {	'0010','0011','0001','0000'}})

// Peça "Z", em pé e deitada
aadd(aLPieces,{'Z',	{	'0000','0110','0011','0000'},;
                    {	'0001','0011','0010','0000'}})

// Peça "L" , nas 4 posições possiveis
aadd(aLPieces,{'L',	{	'0000','0111','0100','0000'},;
                    {	'0010','0010','0011','0000'},;
                    {	'0001','0111','0000','0000'},;
                    {	'0110','0010','0010','0000'}})

// Peça "J" , nas 4 posições possiveis
aadd(aLPieces,{'J',	{	'0000','0111','0001','0000'},;
                    {	'0011','0010','0010','0000'},;
                    {	'0100','0111','0000','0000'},;
                    {	'0010','0010','0110','0000'}})

// Peça "T" , nas 4 posições possiveis
aadd(aLPieces,{'T',	{	'0000','0111','0010','0000'},;
                    {	'0010','0011','0010','0000'},;
                    {	'0010','0111','0000','0000'},;
                    {	'0010','0110','0010','0000'}})


Return aLPieces


/* ----------------------------------------------------------
Função MoveDown()

Movimenta a peça em jogo uma posição para baixo.
Caso a peça tenha batido em algum obstáculo no movimento
para baixo, a mesma é fica e incorporada ao grid, e uma nova
peça é colocada em jogo. Caso não seja possivel colocar uma
nova peça, a pilha de peças bateu na tampa -- Game Over

---------------------------------------------------------- */

STATIC Function MoveDown(lDrop)
Local aOldPiece
              
If _GlbStatus != 0
   Return
Endif

// Clona a peça em queda na posição atual
aOldPiece := aClone(_aDropping)

If lDrop
	
	// Dropa a peça até bater embaixo
	// O Drop incrementa o score em 1 ponto 
	// para cada linha percorrida. Quando maior a quantidade
	// de linhas vazias, maior o score acumulado com o Drop
	
	// Guarda a peça na posição atual
	aOldPiece := aClone(_aDropping)
	
	// Remove a peça do Grid atual
	DelPiece(_aDropping,_aMainGrid)
	
	// Desce uma linha pra baixo
	_aDropping[3]++
	
	While SetGridPiece(_aDropping,_aMainGrid)
		
		// Encaixou, remove e tenta de novo
		DelPiece(_aDropping,_aMainGrid)
		
		// Guarda a peça na posição atual
		aOldPiece := aClone(_aDropping)
		
		// Desce a peça mais uma linha pra baixo
		_aDropping[3]++

		// Incrementa o Score
		_nScore++
				
	Enddo
	
	// Nao deu mais pra pintar, "bateu"
	// Volta a peça anterior, pinta o grid e retorna
	// isto permite ainda movimentos laterais
	// caso tenha espaço.
	
	_aDropping := aClone(aOldPiece)
	SetGridPiece(_aDropping,_aMainGrid)
	PaintMainGrid()
	
Else
	
	// Move a peça apenas uma linha pra baixo
	
	// Primeiro remove a peça do Grid atual
	DelPiece(_aDropping,_aMainGrid)
	
	// Agora move a peça apenas uma linha pra baixo
	_aDropping[3]++
	
	// Recoloca a peça no Grid
	If SetGridPiece(_aDropping,_aMainGrid)
		
		// Se deu pra encaixar, beleza
		// pinta o novo grid e retorna
		PaintMainGrid()
		Return
		
	Endif
	
	// Opa ... Esbarrou em alguma coisa
	// Volta a peça pro lugar anterior
	// e recoloca a peça no Grid
	_aDropping :=  aClone(aOldPiece)
	SetGridPiece(_aDropping,_aMainGrid)

	// Incrementa o score em 4 pontos 
	// Nao importa a peça ou como ela foi encaixada
	_nScore += 4

	// Agora verifica se da pra limpar alguma linha
	ChkMainLines()
	
	// Pega a proxima peça
	nPiece := _nNextPiece
	_aDropping := {nPiece,1,1,6} // Peca, direcao, linha, coluna

	If !SetGridPiece(_aDropping,_aMainGrid)
		
		// Acabou, a peça nova nao entra (cabe) no Grid
		// Desativa o Timer e mostra "game over"
		// e fecha o programa

		// e volta os ultimos 4 pontos ...		
		_GlbStatus := 2 // GAme Over
		_nScore -= 4
		_nGameClock := round(seconds()-_nGameClock,0)
		If _nGameClock < 0 
			// Ficou negativo, passou da meia noite 		
			_nGameClock += 86400
		Endif

		_oTimer:Deactivate()                             
		
	Endif
	
	// Se a peca tem onde entrar, beleza
	// -- Repinta o Grid -- 
	PaintMainGrid()

	// Sorteia a proxima peça
	// e mostra ela no Grid lateral 
	InitNext()
	_nNextPiece := randomize(1,len(_aPieces)+1)
	SetGridPiece( {_nNextPiece,1,1,1} , _aNext)
	PaintNext()
	
Endif

Return

/* ----------------------------------------------------------
Recebe uma ação da interface, através de uma das letras
de movimentação de peças, e realiza a movimentação caso
haja espaço para tal.
---------------------------------------------------------- */
STATIC Function DoAction(cAct)
Local aOldPiece

// conout("Action  = ["+cAct+"]")

If _GlbStatus != 0 
   Return
Endif

// Clona a peça em queda
aOldPiece := aClone(_aDropping)

if cAct $ 'AJ'

	// Movimento para a Esquerda (uma coluna a menos)
	// Remove a peça do grid
	DelPiece(_aDropping,_aMainGrid)
	_aDropping[4]--
	If !SetGridPiece(_aDropping,_aMainGrid)
		// Se nao foi feliz, pinta a peça de volta
		_aDropping :=  aClone(aOldPiece)
		SetGridPiece(_aDropping,_aMainGrid)
	Endif
	// Repinta o Grid
	PaintMainGrid()
	
Elseif cAct $ 'DL'

	// Movimento para a Direita ( uma coluna a mais )
	// Remove a peça do grid
	DelPiece(_aDropping,_aMainGrid)
	_aDropping[4]++'
	If !SetGridPiece(_aDropping,_aMainGrid)
		// Se nao foi feliz, pinta a peça de volta
		_aDropping :=  aClone(aOldPiece)
		SetGridPiece(_aDropping,_aMainGrid)
	Endif
	// Repinta o Grid
	PaintMainGrid()
	
Elseif cAct $ 'WI'
	
	// Movimento para cima  ( Rotaciona sentido horario )
	
	// Remove a peça do Grid
	DelPiece(_aDropping,_aMainGrid)
	
	// Rotaciona
	_aDropping[2]--
	If _aDropping[2] < 1
		_aDropping[2] := len(_aPieces[_aDropping[1]])-1
	Endif
	
	If !SetGridPiece(_aDropping,_aMainGrid)
		// Se nao consegue colocar a peça no Grid
		// Nao é possivel rotacionar. Pinta a peça de volta
		_aDropping :=  aClone(aOldPiece)
		SetGridPiece(_aDropping,_aMainGrid)
	Endif
	
	// E Repinta o Grid
	PaintMainGrid()
	
ElseIF cAct $ 'SK'
	
	// Desce a peça para baixo uma linha intencionalmente 
	MoveDown(.F.)
	
	// se o movimento foi intencional, ganha + 1 ponto 
	_nScore++
	
ElseIF cAct == ' '
	
	// Dropa a peça - empurra para baixo até a última linha
	// antes de baer a peça no fundo do Grid
	MoveDown(.T.)
	
Endif

// Antes de retornar, repinta o score
PaintScore()

Return .T.

Static function DoPause()

If _GlbStatus == 0
	// Pausa
	_GlbStatus := 1
	_oTimer:Deactivate()
Else
	// Sai da pausa
	_GlbStatus := 0
	_oTimer:Activate()
Endif

// Antes de retornar, repinta o score
PaintScore()

Return


/* -----------------------------------------------------------------------
Remove uma peça do Grid atual
----------------------------------------------------------------------- */
STATIC Function DelPiece(aPiece,aGrid)

Local nPiece := aPiece[1]
Local nPos   := aPiece[2]
Local nRow   := aPiece[3]
Local nCol   := aPiece[4]
Local nL, nC
Local cTeco, cPeca

// Como a matriz da peça é 4x4, trabalha em linhas e colunas
// Separa do grid atual apenas a área que a peça está ocupando
// e desliga os pontos preenchidos da peça no Grid.
For nL := nRow to nRow+3
	cTeco := substr(aGrid[nL],nCol,4)
	cPeca := _aPieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1)=='1'
			cTeco := Stuff(cTeco,nC,1,'0')
		Endif
	Next
	aGrid[nL] := stuff(_aMainGrid[nL],nCol,4,cTeco)
Next

Return

/* -----------------------------------------------------------------------
Verifica se alguma linha esta completa e pode ser eliminada
----------------------------------------------------------------------- */
STATIC Function ChkMainLines()
Local nErased := 0 


For nL := 20 to 2 step -1
	
	// Sempre varre de baixo para cima
	// Pega uma linha, e remove os espaços vazios
	cTeco := substr(_aMainGrid[nL],3)
	cNewTeco := strtran(cTeco,'0','')
	
	If len(cNewTeco) == len(cTeco)
		// Se o tamanho da linha se manteve, não houve
		// nenhuma redução, logo, não há espaços vazios
		// Elimina esta linha e acrescenta uma nova linha
		// em branco no topo do Grid
		adel(_aMainGrid,nL)
		ains(_aMainGrid,1)
		_aMainGrid[1] := "11000000000011"
		nL++
		nErased++
	Endif
	
Next

// Pontuação por linhas eliminadas 
// Quanto mais linhas ao mesmo tempo, mais pontos
If nErased == 4
	_nScore += 100
ElseIf nErased == 3
	_nScore += 50
ElseIf nErased == 2
	_nScore += 25
ElseIf nErased == 1
	_nScore += 10
Endif

Return

/* ------------------------------------------------------
Seta o score do jogo na tela
Caso o jogo tenha terminado, acrescenta 
a mensagem  de "GAME OVER"
------------------------------------------------------*/
STATIC Function PaintScore()

If _GlbStatus == 0

	// JOgo em andamento, apenas atualiza score e timer
	_oScore:SetText(str(_nScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+str(seconds()-_nGameClock,7,0)+' s.')

ElseIf _GlbStatus == 1

	// Pausa, acresenta a mensagem de "GAME OVER"
	_oScore:SetText(str(_nScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+str(seconds()-_nGameClock,7,0)+' s.'+CRLF+CRLF+;
		"*********"+CRLF+;
		"* PAUSE *"+CRLF+;
		"*********")

ElseIf _GlbStatus == 2

	// Terminou, acresenta a mensagem de "GAME OVER"
	_oScore:SetText(str(_nScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+str(_nGameClock,7,0)+' s.'+CRLF+CRLF+;
		"********"+CRLF+;
		"* GAME *"+CRLF+;
		"********"+CRLF+;
		"* OVER *"+CRLF+;
		"********")

Endif

Return
