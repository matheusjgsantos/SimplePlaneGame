CHGMOD:		equ 0x005F	; Chamada da BIOS para mudança do modo gráfico
CHPUT:		equ 0x00a2	; Coloca um caracter na tela em modo texto
CHGET:		equ 0x009F	; Aguarda uma tecla ser precionada
LDIRVM: 	equ 0x005C	; Transfere um bloco de tamanho BC do endereço em 
				; DE na RAM para o endereço em HL na VRAM
FORCLR:		equ 0xF3E9	; Variavel de systema referente a cor da fonte
BAKCLR:		equ 0xF3EA	; Variavel de systema referente a cor do fundo
BDRCLR:		equ 0xF3EB	; Variavel de systema referente a cor da borda
CLIKSW: 	equ 0xF3DB 	; Variavel de systema referente ao click do teclado
WRTVRM: 	equ 0x004D  	; Grava o valor em A na posiçao HL da VRAM
RG0SAV:		equ 0xF3DF  	; Obtem o valor atual do registrador 0 do VDP
RG1SAV:		equ 0xF3E0	; Obtem o valor atual do registrador 1 do VDP
WRTVDP:		equ 0x0047	; Envia para o VDP o valor de B no reg C
SPR_PAT:	equ 0x3800	; Endereço da VRAM da tabela de padroes de sprite
SPR_ATT:	equ 0x1b00	; Endereço da VRAM da tabela de atributos de sprite
GTSTCK: 	equ 0x00D5	; Retorna status do joystick
				; Entrada: A  - numero do joystick
                        	; 0 = cursors, 
                        	; 1 = joystick na porta 1
                        	; 2 = joystick na porta 2
				; Saida: A  - Direcao
GRPPRT: 	equ 0x008D	; Escreve um caractere na tela grafica
POSIT:		equ 0x00C6	; Move o cursor para um posicao definida por HL
				; H  - Coordenada Y cursor
           			; L  - Coordenada X cursor
FILVRM:		equ 0x0056	; Preenche BC blocos no endereço HL da VRAM
				; com os dados definidos em A
CHGSND:		equ 0x0135	; liga ou desliga clock do teclado
CSRY:		equ 0xF3DC	;1	Current row-position of the cursor
CSRX:		equ 0xF3DD	;1	Current column-position of the cursor




        org 0x4000
        
; MSX cartridge header @ 0x4000 - 0x400f
	dw 0x4241;4241
        dw start
        dw start
        dw 0
        dw 0
        dw 0
        dw 0
        dw 0

; initialize and print message
start:
	ld hl,FORCLR	; Carrega em HL o endereço da variavel FORCLR
        ld (hl),1	; Define o valor 1 (preto) na variavel FORCLR
        ld hl,BAKCLR	; Carrega em HL o endereço da variavel BAKCLR
        ld (hl),7	; Define o valor 7 (ciano) na variavel BAKCLT
        ld hl,BDRCLR	; Carrega em HL o endereço da variavel BDRCLR
        ld (hl),4	; Define o valor 1 (preto) na variavel BDRCLR
        ld a,(RG1SAV)	; Carrega em A o valor atual do registrador 1 
            		; do VDP
        and $FC		; Altera valor de A para xxxxxx00 
            		; (x=sem mudança)
        or $02		; Altera valor de A para xxxxxx10
        call AtualizaVDP; Vamos enviar o valor atual dos 6 primeiros 
            		; bits do REG1SAV + 10 para o registrador 1
                        ; do VPD, o que altera o modo do sprite de 
                        ; 8x8 para 16x16
                        ; Fonte: https://github.com/gseidler/The-MSX-Red-Book/blob/master/the_msx_red_book.md#mode_register_1
            
        ld a,2		; Coloca 2 em a para chamar CHGMOD
        call CHGMOD	; e trocar o modo de tela para screen 2
        ld hl,CLIKSW	; Carrega a variavel de sistema do som de click
        ld (hl),$00	; e altera o valor para $00 (desligado)
        call CHGSND	; Desliga o som de click das teclas

    
mainLoop:
        call reset_tabela_nomes
        call desenha_borda; chama  rotina de desenho da borda	
        ;call desenha_pista
        call inicia_attributos_aviao
        call mostra_aviao
        call mostra_nuvens
        call mostra_sol
        call mostra_score
       	call movimenta_loop
        ;call CHGET
        ret
            
AtualizaVDP:				
	; Toda atualização do VDP exige que as 
        ; interrupçoes sejam desabilitadas pois
        ; qualquer mudança de outros registradores
        ; afeta o resultado
        di		; Desabilita as interrupçoes 
        ld b, a		; Coloca em B o valor a ser escrito no 
        		; registrador do VDP
        ld c, $01	; Coloca em C o valor do registrador alvo
        call WRTVDP	; Envia para o registrador C os dados em B
        ei		; Habilita novamente as interrupções
        ret

reset_tabela_nomes:
	ld hl,1800H
        ld a,$0
        ld bc,$37F
        call FILVRM
        ret

mostra_aviao:
        ld hl,aviao1a_pattern	; Carrega em HL o endereço do padrao do 
        			; sprite do avião
        ld bc,32		; Carrega em B a quantidade de blocos a
        			; serem enviados pra VRAM
        ld de,SPR_PAT		; Carrega em DE a posiçao inicial da VRAM
        			; para a tabela de sprites (0x3800)
        call LDIRVM		; Envia B blocos do endereço HL da RAM
        			; para o endereço DE da VRAM
        ld hl,aviao1b_pattern	; Carrega em HL o endereço do padrao do 
        			; sprite do avião
        ld bc,32		; Carrega em B a quantidade de blocos a
        			; serem enviados pra VRAM
        ld de,SPR_PAT+32	; Carrega em DE a posiçao inicial da VRAM
        			; para a tabela de sprites (0x3800)
        call LDIRVM		; Envia B blocos do endereço HL da RAM
        			; para o endereço DE da VRAM

        ret			; Volta para a origem da chamada

inicia_attributos_aviao:

	ld hl,aviao1a_attrib; Carrega em HL o endereço do attributo do
            			; sprite do avião 
	ld bc,4			; Os atributos de sprite sao sempre 4 bytes:
            			; Byte 0: Coordenada X
                                ; Byte 1: Coordenada Y
                                ; Byte 3: Numero do sprite
                                ; Byte 4: Cor do Sprite (MSX1)
	ld de,SPR_ATT		; Carrega em DE a posicao iniciao da VRAM
            			; para a tabela de padroes
	call LDIRVM		; Envia B blocos do endereço HL da RAM
            			; para o endereço DE da VRAM
	ld hl,aviao1b_attrib	; Carrega em HL o endereço do attributo do
            			; sprite do avião 
	ld bc,4			; Os atributos de sprite sao sempre 4 bytes:
            			; Byte 0: Coordenada X
                                ; Byte 1: Coordenada Y
                                ; Byte 3: Numero do sprite
                                ; Byte 4: Cor do Sprite (MSX1)
	ld de,SPR_ATT+4		; Carrega em DE a posicao iniciao da VRAM
            			; para a tabela de padroes
	call LDIRVM		; Envia B blocos do endereço HL da RAM
            			; para o endereço DE da VRAM 
        
        ld a,10
        ld (aviaoV),a		; Coloca o aviao na posicao 10 vertical
        ld (aviaoH),a		; Coloca o aviao na posico 10 horizontal
        call movimenta_aviao	; Chama rotina para desenho do aviao
        
        ret
            
mostra_nuvens:
	ld hl,nuvem01_pattern 	; Carrega o endereço do padrao da 
            			; nuvem01 em HL
	ld bc,32		; Numero de blocos a serem copiados pra VRAM
	ld de,SPR_PAT+64	; Coloca em DE a posicao inicial da tabela
            			; de sprites da VRAM + um offset de 32 bytes
                                ; para copia dos dados do sprite 1
	call LDIRVM		; Transfere BC blocos da posicao HL da RAM
            			; para posicao DE da VRAM
	ld hl,nuvem01_attrib 	; Carrega o endereço do attributo da 
            			; nuvem01 em HL
	ld bc,4			; Os atributos de sprite sao sempre 4 bytes:
            			; Byte 0: Coordenada vertical
                                ; Byte 1: Coordenada horizontal
                                ; Byte 3: Numero do sprite
                                ; Byte 4: Cor do Sprite (MSX1)
	ld de,SPR_ATT+8		; Carrega em DE a posicao iniciao da VRAM
            			; para a tabela de padroes + offset de 4 
                                ; bytes para o sprite 1
	call LDIRVM		; Transfere BC blocos da posicao HL da RAM
            			; para posicao DE da VRAM
	ld hl,nuvem02_pattern 	; Carrega o endereço do padrao da 
            			; nuvem01 em HL
	ld bc,32		; Numero de blocos a serem copiados pra VRAM
	ld de,SPR_PAT+96	; Coloca em DE a posicao inicial da tabela
            			; de sprites da VRAM + um offset de 64 bytes
                                ; para copia dos dados do sprite 2
	call LDIRVM		; Transfere BC blocos da posicao HL da RAM
            			; para posicao DE da VRAM
	ld hl,nuvem02_attrib 	; Carrega o endereço do attributo da 
            			; nuvem01 em HL
	ld bc,4			; Os atributos de sprite sao sempre 4 bytes:
            			; Byte 0: Coordenada vertical
                                ; Byte 1: Coordenada horizontal
                                ; Byte 3: Numero do sprite
                                ; Byte 4: Cor do Sprite (MSX1)
	ld de,SPR_ATT+12	; Carrega em DE a posicao iniciao da VRAM
            			; para a tabela de padroes + offset de 8 
                                ; bytes para o sprite 2
	call LDIRVM		; Transfere BC blocos da posicao HL da RAM
            			; para posicao DE da VRAM
	ret			; retorna para a origem da chamada
            
mostra_sol:
        ld hl,sol01a_pattern; Coloca o endereço do tile em HL
        ld bc,16		; Coloca em BC a quantidade de bytes do tile
        ;ld de,$1010		; Coloca em DE endereço da VRAM da posicao
        ld de,$0080
                                ; para aparecem na área visivel da tela
	call LDIRVM		; Envia os 16 blocos do tile pra VRAM
	ld a,$b7		; Carrega em a o valor das cores:
            			; b=amarelo (11) para bits 1 do tile e
                                ; 7=ciano para os bits 0 do tile que estiver
                                ; ocupando o endereço correspondente na 
                                ; VRAM
	ld bc,16		; carrega a quantidade de blocos em BC
	ld hl,$2080		; 
                                ; tambem precisamos colorir os 16 bytes
	call FILVRM		; Preenche na VRAM entre $2000 e $2015
            			; com os valores de cores $b7 (amarelo para
                                ; bits 1, ciano para bits 0)
            
	ld hl,sol01b_pattern	;
	ld bc,16		; 16 bytes a serem copiados
	ld de,$0080+16		; BC agora aponta para Y=$02 e X=$e0 (224)
	call LDIRVM		; carrega a parte inferior do sol na VRAM
           
	ld a,$b7		; Define a cor da mesma forma que feito
				; para a parte superior do sol
	ld bc,16		; Bloco de 16 bytes
	ld hl,$2080+16		; Preenche a VRAM com o valor $b7
				; para colorir o tile carregado em $02e0
                                ; + $2000 (amarelo e ciano)
	call FILVRM		; Preencher 16 blocos da VRAM com$ b7
        
        ld hl,mapa_sol_01	; carrega em HL o mapa de nome da parte superior 
        			; do sol
        ld de,$185b		; correpondente ao bloco 91 da tela
        ld bc,2			; vamos copiar 2 blocos referentes ao tile
        call LDIRVM		; chama a rotina de copia para VRAM
        
        ld hl,mapa_sol_02	; carrega em HL o mapa de nome da parte superior 
        			; do sol
        ld de,$187b		; correpondente a0 bloco 123 da tela
        ld bc,2
        call LDIRVM
        
	ret			; Volta pra origem

movimenta_loop:			; Esse é o loop que cuida da movimentação
				; de todos os sprites
	ld a,0			; 0 = Teclas de cursor
	call checa_cursor	; rotina para checar as teclas de cursor
	ld a,1			; 1 = Joystick na porta 1
	call checa_cursor	; rotina para checar as teclas de cursor
	; movimenta_aviao	; Rotina da movimentacao do aviao
	call movimenta_nuvem	; Rotina da movimentacao das nuvens
	;call desenha_pista
	ld bc,$0500		; Carrega em BC o valor para rodina que									; gera um delay no movimento, caso contrario
				; tudo se move muito rapido
	call espera_nuvem	; Rotina de delay
	jp movimenta_loop	; retorna pro inicio do loop
           			            
movimenta_aviao:
	ld hl,SPR_ATT
        ld a,(aviaoV)
        call WRTVRM

        ld hl,SPR_ATT+1		; Coloca em HL a posicao da tabela de 	
        			; atributo de sprite + 1, que define a 
        			; movimentacao horizontal do sprite 0
        ld a,(aviaoH)		; carrega o valor definido em aviaoH em A
        call WRTVRM		; Coloca na posical HL da VRAM o valor de A

        ld hl,SPR_ATT+4
        ld a,(aviaoV)
        call WRTVRM

        ld hl,SPR_ATT+5
        ld a,(aviaoH)
        call WRTVRM

        ret		; retorna pra origem da chamada

mostra_aviao_subindo:
	ld hl,aviao3a_pattern	; Carrega em HL o endereço do padrao do 
				; sprite do avião
	ld bc,32		; Carrega em B a quantidade de blocos a
				; serem enviados pra VRAM
	ld de,SPR_PAT		; Carrega em DE a posiçao inicial da VRAM
				; para a tabela de sprites (0x3800)
	call LDIRVM		; Envia B blocos do endereço HL da RAM
				; para o endereço DE da VRAM
	ld hl,aviao3b_pattern	; Carrega em HL o endereço do padrao do 
				; sprite do avião
	ld bc,32		; Carrega em B a quantidade de blocos a
				; serem enviados pra VRAM
	ld de,SPR_PAT+32	; Carrega em DE a posiçao inicial da VRAM
				; para a tabela de sprites (0x3800)
	call LDIRVM		; Envia B blocos do endereço HL da RAM
				; para o endereço DE da VRAM
	ld a,(status_aviao)
	add a,1
	ld (status_aviao),a

	ret			; Volta para a origem da chamada
        
mostra_aviao_descendo:
	ld hl,aviao2a_pattern; Carrega em HL o endereço do padrao do 
            			; sprite do avião
	ld bc,32		; Carrega em B a quantidade de blocos a
            			; serem enviados pra VRAM
	ld de,SPR_PAT		; Carrega em DE a posiçao inicial da VRAM
            			; para a tabela de sprites (0x3800)
	call LDIRVM		; Envia B blocos do endereço HL da RAM
            			; para o endereço DE da VRAM
	ld hl,aviao2b_pattern	; Carrega em HL o endereço do padrao do 
            			; sprite do avião
	ld bc,32		; Carrega em B a quantidade de blocos a
            			; serem enviados pra VRAM
	ld de,SPR_PAT+32	; Carrega em DE a posiçao inicial da VRAM
            			; para a tabela de sprites (0x3800)
	call LDIRVM		; Envia B blocos do endereço HL da RAM
            			; para o endereço DE da VRAM
	ld a,(status_aviao)
	sub a,1
	ld (status_aviao),a

	ret			; Volta para a origem da chamada

movimenta_nuvem:
	ld hl,SPR_ATT+9		; Coloca em HL a posicao da tabela de 	
            			; atributo de sprite + 5, que define a 
                                ; movimentacao horizontal do sprite 1
	ld a,(nuvem01H)		; carrega o valor definido em nuvem01H em A
	call WRTVRM		; Coloca na posical HL da VRAM o valor de A
	DEC A			; Decrementa A
	cp 8			; Compara A com 0 (inicio da tela)
	jp z,reset_nuvem01	; Se A = 0,chama rotina de reset do
            			; valor de nuvem_h para posicionar o sprite
                                ; no lado direito da tela
	ld (nuvem01H),a		; Coloca o valor de A em nuvem01H
	ld hl,SPR_ATT+13	; Coloca em HL a posicao da tabela de 	
          			; atributo de sprite + 9, que define a 
                                ; movimentacao horizontal do sprite 2
	ld a,(nuvem02H)		; carrega o valor definido em nuvem02H em A
	sub 2			; Subtrai 2 de A para movimentar o sprite 2
            			; mais rapido que os demais
	call WRTVRM		; Coloca na posical HL da VRAM o valor de A
	cp 8			; Compara A com 0 (inicio da tela)
	jp z,reset_nuvem02	; Se A = 0,chama rotina de reset do
            			; valor de nuvem_h para posicionar o sprite
                                ; no lado direito da tela
	ld (nuvem02H),a		; Coloca o valor de A em nuvem02H
	ret			; Retorna pra origem da chamada

reset_nuvem01:			
	ld a,240-8		; Carrega 240 em A (fim da tela)
	ld (nuvem01H),a		; Coloca A em nuvem01H, resetando a posição
	ret			; Retorna pra origem da chamada

reset_nuvem02:
	ld a,240-8		; Carrega 240 em A (fim da tela)
	ld (nuvem02H),a		; Coloca A em nuvem01H, resetando a posição
	ret			; Retorna pra origem da chamada

espera_nuvem:     
	NOP			; Nao executa nada por um ciclo
	DEC BC 			; Decrementa o valor do contador BC
	LD A,C			; Carrega o valor de A em C
	OR B 			; A = C OR B
	JR NZ,espera_nuvem	; Se A = zero termina o loop
	ret			; Retorna para a origem da chamada            
            
checa_cursor:
        call GTSTCK  		; Chama a rotina de checagem do cursor  
        cp 0			; A = 0 - sem tecla pressionada
        jp z,sai_loop		; sai do loop
        jr cursor_esquerda	; proxima checagem

cursor_esquerda:
        cp 7			; a = 1 - tecla para cima
        jr nz,cursor_direita	; se a nao for 1 pula para proxima
        push af			; salva AF na pilha
        ld a,(aviaoV)	; carrega valor de aviaoV em A
        cp 6			; Limita posicao do aviao antes da borda superior
        jp z,sai_cursor_esquerda
        add a,-2		; decresce A        
        ld (aviaoV),a	; Retorna valor de A para aviaoV
        call mostra_aviao_subindo 
        call movimenta_aviao
        ;ld a,(status_aviao)
        ;ld hl,20
        ;add a,(hl)
        ld a,2
        ld (status_aviao),a
        
sai_cursor_esquerda:        
        pop af			; retorna AF da pilha
        jr sai_loop

cursor_direita:
        cp 3
        jr nz,sai_loop
        push af
        ld a,(aviaoV)
        cp 118			; Limita posicao do aviao antes da borda inferior
        jp z,sai_cursor_direita
        add a,2
        ld (aviaoV),a
        call mostra_aviao_descendo
        call movimenta_aviao
        ;ld a,(status_aviao)
        ;ld hl,1
        ;sub (hl)
        ld a,-2
        ld (status_aviao),a
        
sai_cursor_direita:
        pop af
        jr sai_loop
        
sai_loop:
	ld a,(status_aviao)
	cp 0
	jr C,incrementa_status
	jr z,reset_status
        jr nz,decrementa_status
	ret
    
incrementa_status:
	ld hl,2
	add a,(hl)
	ld (status_aviao),a
	cp 0
	jr z,reset_status
	ret

decrementa_status:
	ld hl,2
	sub (hl)
	ld (status_aviao),a
	;cp 0
	;jr z,reset_status
        ret

reset_status:
	call mostra_aviao
    	ret
        
mostra_score:
	ld hl,letras_sc
        ld bc,32
        ld de,$1000+(8*23) ; slot 23 a 26 da tabela de padroes 3o 1/3 da tela
        call LDIRVM
        ld a,$17
        ld bc,32
        ld hl,$3000+(8*23)
        call FILVRM
        
        ld hl,letras_or
        ld bc,32
        ld de,$1000+(8*27) ; slot 27 a 30 da tabela de padroes 3o 1/3 da tela
        call LDIRVM
        ld a,$17
        ld bc,32
        ld hl,$3000+(8*27)
        call FILVRM

        ld hl,letras_ecolon
        ld bc,32
        ld de,$1000+(8*31) ; slot 31 a 34 da tabela de padroes 3o 1/3 da tela
        call LDIRVM
        ld a,$17
        ld bc,32
        ld hl,$3000+(8*31)
        call FILVRM
        
        ld hl,mapa_score_cima
        ld de,$1a00+(8*16+2)
        ld bc,6
        call LDIRVM
        ld hl,mapa_score_baixo
        ld de,$1a00+(8*20+2)
        ld bc,6
        call LDIRVM
        ret

desenha_borda:     
				; primeira seçao da tela
        ld hl,frame_supesq_01a	; carrega o padrao do desenho da borda
            			; superior esquerda. Vamos carregar 1 bloco
        ld bc,8			; de 8x8 e colocar na VRAM na posicao do
        ld de,$0008		; Slot 1 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia dos dados pra VRAM
            
        ld hl,frame_supesq_01a
        ld bc,8
        ld de,$1008		; Slot 1 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM
            
        ld hl,frame_supesq_01b ; Esse é a segunda parte do desenho da
        ld bc,8			; borda. Vamos carregar um bloco de 8x8 no
        ld de,$0010		; slot 2 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
            
        ld hl,frame_supesq_01b ; Esse é a segunda parte do desenho da
        ld bc,8			; borda. Vamos carregar um bloco de 8x8 no
        ld de,$1010		; slot 2 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
                            
        ld hl,frame_superior_01a ;bloco 1 do frame superior
	ld bc,8			; bloco de 8x8
        ld de,$0018		; slot 3 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
            
        ld hl,frame_superior_01a ;bloco 1 do frame superior
	ld bc,8			; bloco de 8x8
        ld de,$1018		; slot 3 da tabela de padroes do 2o 3/3 da tela
        call LDIRVM		; Envia pra VRAM

        ld hl,frame_superior_01b ;bloco 2 do frame superior
        ld bc,8			; bloco 8x8
        ld de,$0020		; slot 4 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
            
        ld hl,frame_superior_01b ;bloco 2 do frame superior
        ld bc,8			; bloco 8x8
        ld de,$1020		; slot 4 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
            
        ld hl,frame_supdir_01a	; carrega a primeira parte da borda
            			; superior direita
        ld bc,8			; bloco de 8x8
        ld de,$0028		; slot 4 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; envia pra VRAM
            
        ld hl,frame_supdir_01b	; carrega a primeira parte da borda
            			; superior direita
        ld bc,8			; bloco de 8x8
        ld de,$1028		; slot 4 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; envia pra VRAM
            
        ld hl,frame_supdir_01b; carrega a segunda parte da borda
            			; superior direita
        ld bc,8			; 1 blocos de 8x8
        ld de,$0030		; slot 4 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; envia para VRAM
            
        ld hl,frame_supdir_01b; carrega a segunda parte da borda
            			; superior direita
        ld bc,8			; 1 blocos de 8x8
        ld de,$1030		; slot 4 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; envia para VRAM
            
        ld hl,frame_supesq_02a; carrega o padrao do desenho da borda
            				; superior esquerda. Vamos carregar 2 blocos
        ld bc,8			; de 8x8 e colocar na posição
        ld de,$0038		; slot 5 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia dos dados pra VRAM
            
        ld hl,frame_supesq_02a; carrega o padrao do desenho da borda
            				; superior esquerda. Vamos carregar 2 blocos
        ld bc,8			; de 8x8 e colocar na posição
        ld de,$1038		; slot 5 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; Envia dos dados pra VRAM
            
        ld hl,frame_supesq_02b ; Esse é a segunda parte do desenho da
        ld bc,8		; borda. Vamos carregar novamente dois blocos
            				; de 8x8 e colocar na posicao
        ld de,$0040		; slot 6 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
            
	ld hl,frame_supesq_02b ; Esse é a segunda parte do desenho da
        ld bc,8			; borda. Vamos carregar novamente dois blocos
            				; de 8x8 e colocar na posicao
        ld de,$1040		; slot 6 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; Envia pra VRAM
            
        ld hl,frame_supdir_02a; carrega a primeira parte da borda
            			; superior direita
        ld bc,8			; 2 blocos de 8x8
        ld de,$0048		; slot 7 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; envia pra VRAM
            
        ld hl,frame_supdir_02a	; carrega a primeira parte da borda
            			; superior direita
        ld bc,8			; 2 blocos de 8x8
        ld de,$1048		; slot 7 da tabela de padroes do 2o 1/3 da tela
        call LDIRVM		; envia pra VRAM
            
        ld hl, frame_supdir_02b	; carrega a segunda parte da borda
            			; superior direita
        ld bc,8			; bloco de 8x8
        ld de,$0050		; slot 8 da tabela de padroes do 1o 1/3 da tela 
        call LDIRVM		; envia para VRAM
            
        ld hl, frame_supdir_02b	; carrega a segunda parte da borda
            			; superior direita
        ld bc,8			; bloco de 8x8
        ld de,$1050		; slot 8 da tabela de padroes do 2o 1/3 da tela 
        call LDIRVM		; envia para VRAM
            
        ld hl,mapa_borda_superior ; Mapeia na tela a posicao de cada
            			; tile nas duas linhas superiores da tela
	ld bc,64		; 32 blocos de tiles por linha = 2 linhas
	ld de,$1800		; Endereco na VRAM referente a tabela de nomes
                                ; do 1o 1/3 da tela
	call LDIRVM		; envia para VRAM

        ld hl,frame_infesq_01a	; carrega o padrao do desenho da borda
        			; inferior esquerda. Vamos carregar 1 bloco
        ld bc,8			; de 8x8 e colocar na VRAM na posicao do
        ld de,$1058		; Slot 9 da tabela de padroes do 3o 1/3 da tela
        call LDIRVM		; Envia dos dados pra VRAM

        ld hl,frame_infesq_01b 	; Esse é a segunda parte do desenho da
        ld bc,8			; borda. Vamos carregar um bloco de 8x8 no
        ld de,$1060		; slot 10 da tabela de padroes do 3o 1/3 da tela
        call LDIRVM		; Envia pra VRAM

        ld hl,frame_inferior_01a ;bloco 1 do frame inferior
        ld bc,8			; bloco de 8x8
        ld de,$1068		; slot 11 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia pra VRAM

        ld hl,frame_inferior_01b ;bloco 2 do frame inferior
        ld bc,8			; bloco 8x8
        ld de,$1070		; slot 12 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; Envia pra VRAM

        ld hl,frame_infdir_01a	; carrega a primeira parte da borda
        			; superior direita
        ld bc,8			; bloco de 8x8
        ld de,$1078		; slot 13 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; envia pra VRAM

        ld hl, frame_infdir_01b	; carrega a segunda parte da borda
        			; superior direita
        ld bc,8			; 1 blocos de 8x8
        ld de,$1080		; slot 14 da tabela de padroes do 1o 1/3 da tela
        call LDIRVM		; envia para VRAM

        ld hl,frame_infesq_02a	; carrega o padrao do desenho da borda
        			; superior esquerda. Vamos carregar 2 blocos
        ld bc,8			; de 8x8 e colocar na posição
        ld de,$1088		; slot 5 da tabela de padroes do 3o 1/3 da tela
        call LDIRVM		; Envia dos dados pra VRAM

        ld hl,frame_infesq_02b 	; Esse é a segunda parte do desenho da
        ld bc,8			; borda. Vamos carregar novamente dois blocos
				; de 8x8 e colocar na posicao
        ld de,$1090		; slot 6 da tabela de padroes do 3o 1/3 da tela
        call LDIRVM		; Envia pra VRAM

        ld hl,frame_infdir_02a; carrega a primeira parte da borda
        			; superior direita
        ld bc,8			; 2 blocos de 8x8
        ld de,$1098		; slot 7 da tabela de padroes do 3o 1/3 da tela
        call LDIRVM		; envia pra VRAM

        ld hl, frame_infdir_02b	; carrega a segunda parte da borda
        			; superior direita
        ld bc,8			; bloco de 8x8
        ld de,$10a0		; slot 8 da tabela de padroes do 3o 1/3 da tela 
        call LDIRVM		; envia para VRAM

        ld hl,mapa_borda_inferior ; Mapeia na tela a posicao de cada
        			; tile nas duas linhas superiores da tela
        ld bc,64		; 32 blocos de tiles por linha = 2 linhas
        ld de,$1a00		; Endereco na VRAM referente a tabela de nomes
        			; do 3o 1/3 da tela
        call LDIRVM		; envia para VRAM

        ld hl,frame_esquerdo_01
        ld bc,8
        ld de,$0070		; slot 14 da tabela de padroes 1o 1/3 da tela
        call LDIRVM

        ld hl,frame_direito_01
        ld bc,8
        ld de,$0078		; slot 15 da tabela de padroes 1o 1/3 da tela
        call LDIRVM

        ld hl,frame_esquerdo_01
        ld bc,8
        ld de,$0870		; slot 14 da tabela de padroes 2o 1/3 da tela
        call LDIRVM

        ld hl,frame_direito_01
        ld bc,8
        ld de,$0878		; slot 15 da tabela de padroes 2o 1/3 da tela
        call LDIRVM

        ld b,14
        ld c,0
        ld hl,$1800+64
        ld (posicao),hl
        ld hl,mapa_laterais_secao1
        ld (preenche),hl 	; Aponta preenche para mapa_laterais_secao1 <- MUITO IMPORTANTE
        call desenha_laterais_secao

        			; Segunda seçao da tela  
        ld hl,mapa_borda_superior ; Mapeia na tela a posicao de cada
        			; tile nas duas linhas superiores da tela
        ld bc,64		; 32 blocos de tiles por linha = 2 linhas
        ld de,$1a00+64		; Endereco na VRAM referente a tabela de nomes
        			; do 1o 1/3 da tela
        call LDIRVM		; envia para VRAM

        ld hl,mapa_borda_inferior ; Mapeia na tela a posicao de cada
        			; tile nas duas linhas superiores da tela
        ld bc,64		; 32 blocos de tiles por linha = 2 linhas
        ld de,$1aff-63		; Endereco na VRAM referente a tabela de nomes
        			; do 1o 1/3 da tela
        call LDIRVM		; envia para VRAM  

        ld hl,frame_esquerdo_01
        ld bc,8
        ld de,$10a8		; slot 9 da tabela de padroes 3o 1/3 da tela
        call LDIRVM

        ld hl,frame_direito_01
        ld bc,8
        ld de,$10b0		; slot 10 da tabela de padroes 3o 1/3 da tela
        call LDIRVM

        ld b,2
        ld c,0
        ld hl,$1a00+128
        ld (posicao),hl
        ld hl,mapa_laterais_secao2
        ld (preenche),hl 	; Aponta preenche para mapa_laterais_secao2 <- MUITO IMPORTANTE
        call desenha_laterais_secao

        ret

desenha_laterais_secao:
        push bc
        ld hl,(preenche)
        ld bc,32
        ld de,(posicao)
        call LDIRVM
        ld hl,(posicao)
        ld de,32
        ADD HL,DE
        ld (posicao),hl
        POP BC
        djnz desenha_laterais_secao
        ret

desenha_pista:
	ld hl,$0110
        call POSIT
	ld a,(pista_scroll)
        
	cp 0
	jp z,desenha_pista_01

	cp 1
	jp z,desenha_pista_02
            
	cp 2
	jp z,desenha_pista_03
            
	cp 3
	jp z,desenha_pista_04
            
	cp 4
	jp z,desenha_pista_05
            
	cp 5
	jp z,desenha_pista_06
            
	cp 6
	jp z,desenha_pista_07
            
	cp 7
	jp z,desenha_pista_08            
            
	cp 8
	jp z,reset_desenha_pista
            
	ret

            
desenha_pista_01: 
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_01_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
            ld a,(pista_scroll)
            add A,1
            ld (pista_scroll),a
            ret

desenha_pista_02:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_02_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
            ld a,(pista_scroll)
            add A,1
            ld (pista_scroll),a
            ret

desenha_pista_03:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_03_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
            ld a,(pista_scroll)
            add a,1
            ld (pista_scroll),a
            ret

desenha_pista_04:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_04_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela  
            ld a,(pista_scroll)
            add a,1
            ld (pista_scroll),a
            ret            

desenha_pista_05:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_05_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
            ld a,(pista_scroll)
            add a,1
            ld (pista_scroll),a
            ret            

desenha_pista_06:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_06_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
            ld a,(pista_scroll)
            add A,1
            ld (pista_scroll),a
            ret            

desenha_pista_07:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_07_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
            ld a,(pista_scroll)
            add a,1
            ld (pista_scroll),a
            ret            

desenha_pista_08:
            ld b,29			; vamos repetir a chamada a seguir 7 vezes
            ld hl,$1008		; carregando a posicao inicial 
            				; Y = 16 ($02) e X = 248 ($f8)
            ld (posicao),hl	; carregamos as coordenadas na variave posicao
            ld de,$2000
            ADD HL,DE
            ld (preenche),hl
            call desenha_pista_08_loop; e chamamos a rotina para desenhar a
            				; borda direita da tela
		    ld a,(pista_scroll)
            add A,1
            ld (pista_scroll),a
            ret  
            
reset_desenha_pista:
		ld a,(pista_scroll)
            	ld a,0
            	ld (pista_scroll),a
            	;call CHGET
            	ret

desenha_pista_01_loop:
			push BC
            ld hl,pista_01a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_01b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche); carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_01_loop
            ret

desenha_pista_02_loop:
			push BC
            ld hl,pista_02a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_02b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_02_loop
            ret
            
desenha_pista_03_loop:
			push BC
            ld hl,pista_03a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_03b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_03_loop
            ret

desenha_pista_04_loop:
			push BC
            ld hl,pista_04a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_04b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
            ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_04_loop
            ret

desenha_pista_05_loop:
	    push BC
            ld hl,pista_05a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_05b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_05_loop
            RET
            
desenha_pista_06_loop:
			push BC
            ld hl,pista_06a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_06b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_06_loop
            ret           

desenha_pista_07_loop:
	    push BC
            ld hl,pista_07a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_07b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_07_loop
            ret           

desenha_pista_08_loop:
			push BC
            ld hl,pista_08a	; carrega a primeira parte da borda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao) ; Y = 120 ($10*8) e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            LD HL,(posicao)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (posicao),hl	; e salva o resultado na variavel "posicao"
         
            ld hl,pista_08b; carrega a segunda parte da borda
            				; inferior esquerda
            ld bc,8			; 1 bloco de 8x8
            ld de,(posicao); Y = 136 ($11*8)  e X = 16 ($10)
            call LDIRVM		; envia para VRAM
            ;call espera		; delay
            
            ld hl,pista_pattern
	    ld de,(preenche)
            ld bc,$0010
            call LDIRVM
			
            LD HL,(preenche)	; carrega o valor da "variavel" posicao em HL
            ld bc,$0008		; Carrega $0100 em BC
            add hl,bc		; "Soma" HL com BC, 
            ld (preenche),hl; e salva o resultado na variavel "posicao"
            
            POP BC
            
            djnz desenha_pista_08_loop
            ret     

espera:
	PUSH BC		; Salva BC na pilha
	LD BC,$008f	; Executa NOP por 1535 vezes
        
espera_loop:
	NOP		; Nao executa nada por um ciclo
	DEC BC 		; Decrementa o valor do contador BC
	LD A,C		; Carrega o valor de A em C
	OR B 		; A = C OR B
	JR NZ,espera_loop; Se A = zero termina o loop
	pop BC
	ret		; Retorna para a origem da chamada
            

; Sprites gerados usando o TinySprite: http://msx.jannone.org/tinysprite/tinysprite.html
aviao1a_pattern:
        db $00,$00,$00,$00,$E0,$B1,$96,$9C
        db $82,$44,$39,$13,$0E,$00,$00,$00
        db $00,$00,$00,$00,$78,$94,$12,$09
        db $47,$82,$FC,$00,$00,$00,$00,$00

aviao1b_pattern:
        DB $00,$00,$00,$00,$00,$40,$61,$63
        DB $7D,$3B,$06,$0C,$00,$00,$00,$00
        DB $00,$00,$00,$00,$00,$68,$EC,$F6
        DB $B8,$7C,$00,$00,$00,$00,$00,$00

aviao2a_pattern:
        DB $00,$0E,$1A,$32,$24,$22,$11,$08
        DB $3F,$40,$60,$1F,$00,$00,$00,$00
        DB $00,$00,$00,$00,$00,$00,$E0,$78
        DB $0C,$12,$12,$D2,$8A,$64,$18,$00

aviao2b_pattern:
        DB $00,$00,$04,$0C,$18,$1C,$0E,$07
        DB $00,$3F,$1F,$00,$00,$00,$00,$00
        DB $00,$00,$00,$00,$00,$00,$00,$80
        DB $F0,$EC,$EC,$2C,$74,$18,$00,$00

aviao3a_pattern:
        DB $00,$00,$00,$00,$01,$01,$03,$02
        DB $02,$74,$48,$61,$32,$1C,$00,$00
        DB $00,$78,$84,$8A,$72,$04,$14,$18
        DB $90,$90,$90,$90,$90,$A0,$60,$00

aviao3b_pattern:
	DB $00,$00,$00,$00,$00,$00,$00,$01
        DB $01,$03,$37,$1E,$0C,$00,$00,$00
        DB $00,$00,$78,$74,$8C,$F8,$E8,$E0
        DB $60,$60,$60,$60,$60,$40,$00,$00

mapa_sol_01:
	db 16,17
mapa_sol_02:	
	db 18,19
            
mapa_borda_superior:
	DB 1,2,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,5,6
	DB 7,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,10   

mapa_borda_inferior:
	DB 11,12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,15,16 
	DB 17,18,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,13,14,19,20

mapa_laterais_secao1:
	DB 14,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,15
            
mapa_laterais_secao2:
	DB 21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,22

mapa_score_cima:
	DB 23,25,27,29,31,33
mapa_score_baixo:
	DB 24,26,28,30,32,34
            

nuvem01_pattern:
; color 15
              DB $00,$00,$00,$30,$79,$ED,$F7,$7F
              DB $7F,$34,$00,$00,$00,$00,$00,$00
              DB $00,$00,$30,$F8,$CE,$F7,$BF,$4E
              DB $FC,$70,$00,$00,$00,$00,$00,$00
; 
nuvem02_pattern:
; color 15
              DB $00,$00,$00,$00,$38,$ED,$F7,$7F
              DB $7F,$35,$18,$0F,$03,$00,$00,$00
              DB $00,$00,$00,$78,$CE,$F7,$BF,$4E
              DB $FC,$4C,$F8,$80,$00,$00,$00,$00

sol01a_pattern: 
		DB $03,$0F,$1F,$3F,$7F,$7F,$FF,$FF
		DB $C0,$F0,$F8,$FC,$FE,$FE,$FF,$FF          


sol01b_pattern:
		DB $FF,$FF,$7F,$7F,$3F,$1F,$0F,$03
            	DB $FF,$FF,$FE,$FE,$FC,$F8,$F0,$C0 
            
; Atributos inciais dos sprites: Horizontal, Vertical, Numero e Cor
aviao1a_attrib:
		DB $20,$08,$00,$04

aviao1b_attrib:
		DB $20,$08,$04,$0F

nuvem01_attrib:
		DB $10,$ff,$08,$0f

nuvem02_attrib:
		DB $60,$30,$0C,$0f            

; Tiles gerados no TinySprite do Jannone
frame_supesq_01a:
            	DB $39,$67,$CC,$97,$A2,$34,$59,$D3
            
frame_supesq_01b:           
            	DB $C7,$3F,$E0,$8F,$32,$CF,$32,$C7

frame_supesq_02a:
		DB $A5,$AD,$4A,$5A,$54,$D5,$DF,$D5
            
frame_supesq_02b:
            	DB $58,$E0,$40,$80,$80,$00,$00,$00 

frame_supdir_01a:
            	DB $E3,$FC,$03,$F8,$4E,$F3,$4C,$E3
            
frame_supdir_01b:
            	DB $9C,$C6,$33,$E9,$45,$2E,$9A,$CB

frame_supdir_02a:
            	DB $1A,$07,$02,$01,$01,$00,$00,$00
            
frame_supdir_02b:
            	DB $AD,$A5,$56,$52,$2A,$AB,$FB,$AB

frame_infesq_01a:
            	DB $D5,$DF,$D5,$54,$4A,$6A,$A5,$B5
            
frame_infesq_01b:
            	DB $00,$00,$00,$80,$80,$40,$E0,$58

frame_infesq_02a:
            	DB $D3,$59,$74,$A2,$97,$CC,$63,$39
            
frame_infesq_02b:
            	DB $C7,$32,$CF,$72,$1F,$C0,$3F,$C7

frame_infdir_01a:
            	DB $00,$00,$00,$01,$01,$02,$07,$1A
            
frame_infdir_01b:            
            	DB $AB,$FB,$AB,$2A,$5A,$52,$B5,$A5
            
frame_infdir_02a:
            	DB $E3,$4C,$F3,$4C,$F1,$07,$FC,$E3
            
frame_infdir_02b:            
            	DB $CB,$9A,$2C,$45,$E9,$33,$E6,$9C
            
frame_superior_01a:
            	DB $FE,$C3,$18,$FF,$4A,$BB,$A4,$FF
            
frame_superior_01b:
            	DB $7F,$C3,$18,$FF,$4A,$BB,$A4,$FF
            
frame_direito_01:
            	DB $EB,$9B,$E9,$AD,$BD,$C9,$BB,$AA

frame_direito_02:
            	DB $EA,$9B,$E9,$AD,$BD,$C9,$BB,$AB

frame_inferior_01a:
            	DB $FF,$25,$DD,$52,$FF,$18,$C3,$FE
            
frame_inferior_01b:            
           	 DB $FF,$25,$DD,$52,$FF,$18,$C3,$7F
            
frame_esquerdo_01:
            	DB $D5,$DD,$93,$BD,$B5,$97,$D9,$57

frame_esquerdo_02:
		DB $55,$DD,$93,$BD,$B5,$97,$D9,$D7
            
pista_01a:
        	DB $0,$0,$f0,$0,$1,$20,$8,$80
pista_01b:
        	DB $0,$0,$f0,$0,$0,$21,$4,$80
pista_02a:
        	DB $0,$0,$e1,$0,$2,$40,$10,$1
pista_02b:
        	DB $0,$0,$e1,$0,$0,$42,$8,$1
pista_03a:
        	DB $0,$0,$c3,$0,$4,$80,$20,$2
pista_03b:            
        	DB $0,$0,$c3,$0,$0,$84,$10,$2
pista_04a:
        	DB $0,$0,$87,$0,$8,$1,$40,$4
pista_04b:
        	DB $0,$0,$87,$0,$0,$9,$20,$4
pista_05a:
        	DB $0,$0,$f,$0,$10,$2,$80,$8
pista_05b:
        	DB $0,$0,$f,$0,$0,$12,$40,$8
pista_06a:
        	DB $0,$0,$1e,$0,$20,$4,$1,$10
pista_06b:
        	DB $0,$0,$1e,$0,$0,$24,$80,$10
pista_07a:
        	DB $0,$0,$3c,$0,$40,$8,$2,$20
pista_07b:
        	DB $0,$0,$3c,$0,$0,$48,$1,$20
pista_08a:
        	DB $0,$0,$78,$0,$80,$10,$4,$40
pista_08b:
        	DB $0,$0,$78,$0,$0,$90,$2,$40

pista_pattern:
		DB $07,$07,$1e,$1e,$bc,$bc,$bc,$bc
                DB $07,$07,$1e,$1e,$bc,$bc,$bc,$bc
                
letras_AB:
                DB $00,$0C,$1E,$12,$13,$13,$33,$73
                DB $73,$7F,$73,$73,$73,$73,$73,$00
                DB $00,$1C,$12,$12,$12,$1C,$32,$73
                DB $73,$73,$73,$73,$73,$73,$7E,$00
letras_SC:
                DB $00,$1C,$36,$62,$60,$30,$18,$0C
                DB $26,$66,$C6,$C6,$E6,$6C,$38,$00
                DB $00,$3C,$76,$66,$62,$C0,$C0,$C0
                DB $C0,$C0,$C0,$62,$66,$76,$3C,$00
letras_OR:
                DB $00,$08,$1C,$36,$36,$77,$77,$63
                DB $63,$77,$77,$36,$36,$1C,$08,$00
                DB $00,$5C,$7E,$37,$23,$21,$23,$36
                DB $3C,$6E,$66,$66,$66,$63,$63,$00
letras_ecolon:
                DB $00,$1E,$3B,$33,$21,$60,$71,$7F
                DB $7F,$71,$60,$21,$33,$3B,$1E,$00
                DB $00,$08,$18,$3C,$3C,$18,$10,$00
                DB $08,$18,$3C,$3C,$18,$10,$00,$00

            
; Usado pela rotina Sprites_On         
VDP:        	DS 28,0
            
message:
		db "Debug: ",0
                
		org $8000	; Area de memoria RAM para gravacao de variaveis
pista_scroll:	
		db $0
status_aviao:	
		db 0
aviaoH:	
		db 0	; Posicao horizontal do sprite do aviao
aviaoV: 	
		db 0  ; posicao vertical do sprite do aviao
nuvem01H:      
		db $10	; posisao horizontal do sprite da nuvem01
nuvem02H:      
		db $20	; posicao horizontal do sprite da nuvem02
posicao:	
		dw $00
preenche:	
		dw $00