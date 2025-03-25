.model small
.stack 100h
.data
;CADENAS PARA INTERACTUAR CON EL USUARIO:
	cadena3 DB '------------- BIENVENIDO! -------------- $'
	cadena DB 'Ingrese la cantidad de puntos en la espiral ULAM: $'
	cadena2 DB 'El numero debe estar en el rango de 1-100, ingrese un nuevo numero: $'
;VARIABLES PARA OBTENER UN NUMERO DE 3 DIGITOS
	acumulador DB 3 dup(0) ;es una variable con 3 posiciones, donde vamos a poner los 3 numeros que leemos del teclado
	b DB 100, 10, 1 ;sirve para multiplicarlo por la variable acumulador a la hora de convertirlo
	cantPuntos DW 0 ;cantidad de puntos que ingresa el usuario
	salida DB 3 dup(0), '$'	;variable de salida
;VARIABLES LOGICAS
	puntoX DW 1 ;coordenada inicial en x
	puntoY DW 0 ;coordenada incial en y
	direccion DB 0	;Direccion actual
	contador DW 0 
	limite DW 1 ;LÍMITE DE PASOS ANTES DE CAMBIAR DE DIRECCION
    ciclos DW 0						;CUENTA CUÁNTOS CAMBIOS DE DIRECCIÓN SE HAN HECHO (cada 2 ciclos el límite aumenta)
    color DB 15     				;COLOR DE PIXEL A DIBUAR (blanco)
    centroX DW 160					;CENTRO HORIZONTAL DE LA PANTALLA 320x200
    centroY DW 100					;CENTRO VERTICAL (mitad de 200)

.code
programa:
;Inicializar el segmento de datos
    MOV AX, @data
    MOV DS, AX
    
;Configurar modo gráfico 13h (320x200, 256 colores)
    MOV AX, 0013h
    INT 10h
    
;Mostrar mensaje inicial solicitando la cantidad de puntos
	MOV AH, 09h
    MOV DX, OFFSET cadena3			;ASIGNA LA DIRECCIÓN DONDE SE INCICIA NUESTRA VARIABLE CADENA
    INT 21h
		
	MOV DX, OFFSET cadena	;asigna la direccion donde se inicia nuestra variable cadena
	MOV AH, 09H
	INT 21H
	INICIALIZAR_CONTADOR:
	
		;inicializar el contador:
		MOV DI, 0	;inicializa un registro indice en cero
		
	CAPTURAR_NUMERO:
		MOV AX, 0 ;limpia ax
	;Primero se lee un caracter desde el teclado:
		MOV AH, 01H
		INT 21H
		
		CMP AL, 48
		JL LIMPIAR_ACUMULADOR ;salta si es menor que 48, es decir lo que ingreso el usuario no es un numero
		CMP AL, 57
		JA LIMPIAR_ACUMULADOR ;salta si es mayor que 57

		MOV acumulador[di], al ;el numero que se capturo se mueve a la posicion del contador en la variable acumulador
		SUB acumulador[di], 30H ; convierto de ASCII a numero
		
		INC DI		;incremento en 1 el indice del acumulador
		CMP DI, 3	;comparo el indice del acumulador con 3 para saber cuando ya haya capturado los 3 numeros
		JB CAPTURAR_NUMERO
				
	;cuando ya termino de capturar el numero:
		MOV SI, 2	;si es otro indice
		MOV DI, 0
		JMP CONVERTIR_NUMERO
		
	CONVERTIR_NUMERO:
		MOV AX, 0
		MOV AL, acumulador[SI] ;el numero que quiero multiplicar debe estar en AL
		MUL b[SI] ;el resultado de la multiplicacion queda en al
		
		JO LIMPIAR_ACUMULADOR ;si el numero excede la capacidad del registro, se limpia el acumulador
		JC LIMPIAR_ACUMULADOR ;si el numero excede la capacidad del registro, se limpia el acumulador
		
		ADD cantPuntos, AX ;se suma a cantpuntos, el numero que este en al
		JC LIMPIAR_ACUMULADOR ;si el numero excede la capacidad del registro, se limpia el acumulador
		
		DEC SI
		INC DI		;contador para saber el numero de digitos q hemos convertido
		CMP DI, 3	;se compara con 3 para saber si ya se convirtieron los 3 numeros
		JB CONVERTIR_NUMERO ;sino se vuelve a correr convertir_numero
		
		CMP cantPuntos, 100
		JA LIMPIAR_ACUMULADOR
		
		JMP DIBUJAR_ESPIRAL
	
	LIMPIAR_ACUMULADOR:
	;BORRAR PANTALLA
		MOV AH, 0FH
		INT 10H
		MOV AH, 0
		INT 10H 

		MOV cantPuntos, 0	;limpiamos el numero
	;limpiamos acumulador
		MOV acumulador[0], 0
		MOV acumulador[1], 0	
		MOV acumulador[2], 0
		
		MOV DI, 0	;di es igual a 0, para volver a empezar
		
		MOV DX, OFFSET cadena2	;asigna la direccion donde se inicia nuestra variable cadena
		MOV AH, 09H
		INT 21H
		
		JMP CAPTURAR_NUMERO

DIBUJAR_ESPIRAL:
;Dibujar el primer punto (1, punto cecntral)
    MOV BX, 1
    CALL DIBUJAR_PUNTO
    
;Si solo es un punto, salta
    CMP cantPuntos, 1
    JBE SALTO_INTERMEDIO  			;SALTO INTERMEDIO PARA EVITAR ERROR DE RANGO

;Inicializar variables de dirección y conteo
    MOV direccion, 0
    MOV contador, 0
    MOV limite, 1
    MOV ciclos, 0
    MOV SI, 2						;COMENZAR A DIBUJAR DESDE EL SEGUNDO PUNTO

BUCLE_PRINCIPAL:
;Compara si ya se llegó al límite de pasos en esa dirección
    MOV AX, contador
    CMP AX, limite
    JB MOVER_DIRECCION

;Cambiar dirección (0 -> 1 -> 2 -> 3 -> 0, cíclicamente)
    INC direccion
    AND direccion, 03h				;MANTENER EL VALOR ENTRE 0 Y 3
    MOV contador, 0
    INC ciclos

;Cada dos cambios de dirección, aumentamos el límite de pasos
    CMP ciclos, 2
    JNE NO_INCREMENTAR
    INC limite
    MOV ciclos, 0

NO_INCREMENTAR:
    INC contador
    JMP ACTUALIZAR_COORD

MOVER_DIRECCION:
    INC contador					;AÚN NO LLEGAMOS AL LÍMITE, SOLO INCREMENTAMOS PASOS

ACTUALIZAR_COORD:
;Según la dirección, se modifica la coordenada
    CMP direccion, 0
    JE DERECHA
    CMP direccion, 1
    JE ARRIBA
    CMP direccion, 2
    JE IZQUIERDA
    JMP ABAJO

SALTO_INTERMEDIO:
	CMP cantPuntos, 1	
	JE FIN
	
DERECHA:
    ADD puntoX, 5
    JMP DIBUJAR

ARRIBA:
    ADD puntoY, 5
    JMP DIBUJAR

IZQUIERDA:
    SUB puntoX, 5
    JMP DIBUJAR

ABAJO:
    SUB puntoY, 5

DIBUJAR:
;Dibuja el punto actual en la pantalla
    MOV BX, SI
    CALL DIBUJAR_PUNTO
    INC SI
    CMP SI, cantPuntos
    JBE BUCLE_PRINCIPAL				;CONTINUAR HASTA DIBUJAR TODOS LOS PUNTOS

FIN:
;Esperar a que el usuario presione una tecla
    MOV AH, 00h
    INT 16h
    
;Restaurar modo texto
    MOV AX, 0003h
    INT 10h
    
;Salir / Finalizar el programa
    MOV AH, 4Ch
    INT 21h

;Procedimiento para dibujar un punto en la pantalla
DIBUJAR_PUNTO PROC
;Calcular posición en pantalla, coordenadas absolutas
    MOV AX, puntoX
    ADD AX, centroX					;AJUSTE RESPECTO AL CENTRO HORIZONTAL 
    MOV CX, AX						;COORDENADA X, SE GUARDA X EN CX
    
    MOV AX, centroY
    SUB AX, puntoY					;AJUSTE RESPECTO AL CENTRO VERTICAL
    MOV DX, AX        				;COORDENADA Y, SE GUARDA Y EN DX
   
;Verificar límites de pantalla
    CMP CX, 320
    JAE SALIR_DIBUJO
    CMP DX, 200
    JAE SALIR_DIBUJO
    
;Dibujar pixel (INT 10h función 0Ch)
    MOV AH, 0Ch
    MOV AL, color					;COLOR DEL PIXEL 
    MOV BH, 00h						;PÁGINA ACTIVA
    INT 10h

SALIR_DIBUJO:
    RET
DIBUJAR_PUNTO ENDP

End programa.model small
.stack 100h
.data
;CADENAS PARA INTERACTUAR CON EL USUARIO:
	cadena3 DB '------------- BIENVENIDO! -------------- $'
	cadena DB 'Ingrese la cantidad de puntos en la espiral ULAM: $'
	cadena2 DB 'El numero debe estar en el rango de 1-100, ingrese un nuevo numero: $'
;VARIABLES PARA OBTENER UN NUMERO DE 3 DIGITOS
	acumulador DB 3 dup(0) ;es una variable con 3 posiciones, donde vamos a poner los 3 numeros que leemos del teclado
	b DB 100, 10, 1 ;sirve para multiplicarlo por la variable acumulador a la hora de convertirlo
	cantPuntos DW 0 ;cantidad de puntos que ingresa el usuario
	salida DB 3 dup(0), '$'	;variable de salida
;VARIABLES LOGICAS
	puntoX DW 1 ;coordenada inicial en x
	puntoY DW 0 ;coordenada incial en y
	direccion DB 0	;Direccion actual
	contador DW 0 
	limite DW 1 ;LÍMITE DE PASOS ANTES DE CAMBIAR DE DIRECCION
    ciclos DW 0						;CUENTA CUÁNTOS CAMBIOS DE DIRECCIÓN SE HAN HECHO (cada 2 ciclos el límite aumenta)
    color DB 15     				;COLOR DE PIXEL A DIBUAR (blanco)
    centroX DW 160					;CENTRO HORIZONTAL DE LA PANTALLA 320x200
    centroY DW 100					;CENTRO VERTICAL (mitad de 200)

.code
programa:
;Inicializar el segmento de datos
    MOV AX, @data
    MOV DS, AX
    
;Configurar modo gráfico 13h (320x200, 256 colores)
    MOV AX, 0013h
    INT 10h
    
;Mostrar mensaje inicial solicitando la cantidad de puntos
	MOV AH, 09h
    MOV DX, OFFSET cadena3			;ASIGNA LA DIRECCIÓN DONDE SE INCICIA NUESTRA VARIABLE CADENA
    INT 21h
		
	MOV DX, OFFSET cadena	;asigna la direccion donde se inicia nuestra variable cadena
	MOV AH, 09H
	INT 21H
	INICIALIZAR_CONTADOR:
	
		;inicializar el contador:
		MOV DI, 0	;inicializa un registro indice en cero
		
	CAPTURAR_NUMERO:
		MOV AX, 0 ;limpia ax
	;Primero se lee un caracter desde el teclado:
		MOV AH, 01H
		INT 21H
		
		CMP AL, 48
		JL LIMPIAR_ACUMULADOR ;salta si es menor que 48, es decir lo que ingreso el usuario no es un numero
		CMP AL, 57
		JA LIMPIAR_ACUMULADOR ;salta si es mayor que 57

		MOV acumulador[di], al ;el numero que se capturo se mueve a la posicion del contador en la variable acumulador
		SUB acumulador[di], 30H ; convierto de ASCII a numero
		
		INC DI		;incremento en 1 el indice del acumulador
		CMP DI, 3	;comparo el indice del acumulador con 3 para saber cuando ya haya capturado los 3 numeros
		JB CAPTURAR_NUMERO
				
	;cuando ya termino de capturar el numero:
		MOV SI, 2	;si es otro indice
		MOV DI, 0
		JMP CONVERTIR_NUMERO
		
	CONVERTIR_NUMERO:
		MOV AX, 0
		MOV AL, acumulador[SI] ;el numero que quiero multiplicar debe estar en AL
		MUL b[SI] ;el resultado de la multiplicacion queda en al
		
		JO LIMPIAR_ACUMULADOR ;si el numero excede la capacidad del registro, se limpia el acumulador
		JC LIMPIAR_ACUMULADOR ;si el numero excede la capacidad del registro, se limpia el acumulador
		
		ADD cantPuntos, AX ;se suma a cantpuntos, el numero que este en al
		JC LIMPIAR_ACUMULADOR ;si el numero excede la capacidad del registro, se limpia el acumulador
		
		DEC SI
		INC DI		;contador para saber el numero de digitos q hemos convertido
		CMP DI, 3	;se compara con 3 para saber si ya se convirtieron los 3 numeros
		JB CONVERTIR_NUMERO ;sino se vuelve a correr convertir_numero
		
		CMP cantPuntos, 100
		JA LIMPIAR_ACUMULADOR
		
		JMP DIBUJAR_ESPIRAL
	
	LIMPIAR_ACUMULADOR:
	;BORRAR PANTALLA
		MOV AH, 0FH
		INT 10H
		MOV AH, 0
		INT 10H 

		MOV cantPuntos, 0	;limpiamos el numero
	;limpiamos acumulador
		MOV acumulador[0], 0
		MOV acumulador[1], 0	
		MOV acumulador[2], 0
		
		MOV DI, 0	;di es igual a 0, para volver a empezar
		
		MOV DX, OFFSET cadena2	;asigna la direccion donde se inicia nuestra variable cadena
		MOV AH, 09H
		INT 21H
		
		JMP CAPTURAR_NUMERO

DIBUJAR_ESPIRAL:
;Dibujar el primer punto (1, punto cecntral)
    MOV BX, 1
    CALL DIBUJAR_PUNTO
    
;Si solo es un punto, salta
    CMP cantPuntos, 1
    JBE SALTO_INTERMEDIO  			;SALTO INTERMEDIO PARA EVITAR ERROR DE RANGO

;Inicializar variables de dirección y conteo
    MOV direccion, 0
    MOV contador, 0
    MOV limite, 1
    MOV ciclos, 0
    MOV SI, 2						;COMENZAR A DIBUJAR DESDE EL SEGUNDO PUNTO

BUCLE_PRINCIPAL:
;Compara si ya se llegó al límite de pasos en esa dirección
    MOV AX, contador
    CMP AX, limite
    JB MOVER_DIRECCION

;Cambiar dirección (0 -> 1 -> 2 -> 3 -> 0, cíclicamente)
    INC direccion
    AND direccion, 03h				;MANTENER EL VALOR ENTRE 0 Y 3
    MOV contador, 0
    INC ciclos

;Cada dos cambios de dirección, aumentamos el límite de pasos
    CMP ciclos, 2
    JNE NO_INCREMENTAR
    INC limite
    MOV ciclos, 0

NO_INCREMENTAR:
    INC contador
    JMP ACTUALIZAR_COORD

MOVER_DIRECCION:
    INC contador					;AÚN NO LLEGAMOS AL LÍMITE, SOLO INCREMENTAMOS PASOS

ACTUALIZAR_COORD:
;Según la dirección, se modifica la coordenada
    CMP direccion, 0
    JE DERECHA
    CMP direccion, 1
    JE ARRIBA
    CMP direccion, 2
    JE IZQUIERDA
    JMP ABAJO

SALTO_INTERMEDIO:
	CMP cantPuntos, 1	
	JE FIN
	
DERECHA:
    ADD puntoX, 5
    JMP DIBUJAR

ARRIBA:
    ADD puntoY, 5
    JMP DIBUJAR

IZQUIERDA:
    SUB puntoX, 5
    JMP DIBUJAR

ABAJO:
    SUB puntoY, 5

DIBUJAR:
;Dibuja el punto actual en la pantalla
    MOV BX, SI
    CALL DIBUJAR_PUNTO
    INC SI
    CMP SI, cantPuntos
    JBE BUCLE_PRINCIPAL				;CONTINUAR HASTA DIBUJAR TODOS LOS PUNTOS

FIN:
;Esperar a que el usuario presione una tecla
    MOV AH, 00h
    INT 16h
    
;Restaurar modo texto
    MOV AX, 0003h
    INT 10h
    
;Salir / Finalizar el programa
    MOV AH, 4Ch
    INT 21h

;Procedimiento para dibujar un punto en la pantalla
DIBUJAR_PUNTO PROC
;Calcular posición en pantalla, coordenadas absolutas
    MOV AX, puntoX
    ADD AX, centroX					;AJUSTE RESPECTO AL CENTRO HORIZONTAL 
    MOV CX, AX						;COORDENADA X, SE GUARDA X EN CX
    
    MOV AX, centroY
    SUB AX, puntoY					;AJUSTE RESPECTO AL CENTRO VERTICAL
    MOV DX, AX        				;COORDENADA Y, SE GUARDA Y EN DX
   
;Verificar límites de pantalla
    CMP CX, 320
    JAE SALIR_DIBUJO
    CMP DX, 200
    JAE SALIR_DIBUJO
    
;Dibujar pixel (INT 10h función 0Ch)
    MOV AH, 0Ch
    MOV AL, color					;COLOR DEL PIXEL 
    MOV BH, 00h						;PÁGINA ACTIVA
    INT 10h

SALIR_DIBUJO:
    RET
DIBUJAR_PUNTO ENDP

End programa
