;Programa en ensamblador que recibe la cantidad de puntos y dibuja sus coordenadas en forma de listado

.model small
.stack 100h
.data
;Cadenas para interactuar con el usuario
;Mensajes de entrada y error
    cadena DB 'Ingrese la cantidad de puntos: $'
    cadena2 DB 'ERROR: Vuelva a ingresar el numero$'

;Variables para obtener un número de 3 dígitos
    acumulador DB 3 dup(0)			;ES UNA VARIABLE CON 3 POSICIONES, DONDE VAMOS A PONER LOS 3 NÚMEROS QUE LEEMOS DEL TECLADO
									;(SE ESPERAN HASTA 3 DIGITOS)

    b DB 100, 10, 1					;FACTORES DE CONVERSION (para centenas, decenas y unidades)
									;SIRVE PARA MULTIPLICARLO POR LA VARIABLE ACUMULADOR A LA HORA DE CONVERTIRLO
    cantPuntos DW 0					;CANTIDAD DE PUNTOS QUE INGRESA EL USUARIO

;Variables lógicas
;Variables que controlan el dibujo
    puntoX DW 0						;COORDENADA X ACTUAL DEL PUNTO A DIBUJAR
    puntoY DW 0						;COORDENADA Y ACTUAL
    direccion DB 0					;DIRECCION DE MOVIMIENTO (0 = derecha, 1 = arriba, 2 = izquierda, 3 = abajo)
    contador DW 0					;CUENTA CUÁNTOS PASOS SE HAN DADO EN LA DIRECCIÓN ACTUAL
    limite DW 1						;LÍMITE DE PASOS ANTES DE CAMBIAR DE DIRECCION
    ciclos DW 0						;CUENTA CUÁNTOS CAMBIOS DE DIRECCIÓN SE HAN HECHO (cada 2 ciclos el límite aumenta)
    color DB 15      				;COLOR DE PIXEL A DIBUAR (blanco)
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
    MOV DX, OFFSET cadena			;ASIGNA LA DIRECCIÓN DONDE SE INCICIA NUESTRA VARIABLE CADENA
    INT 21h

INICIALIZAR_CONTADOR:
    MOV DI, 0						;INICIA UN REGISTRO INDICE EN CERO, LUEGO ACUMULA LOS DÍGITOS EN ACUMULADOR

CAPTURAR_NUMERO:
;Leer un carácter del teclado
    MOV AH, 01h
    INT 21h
    CMP AL, 13       				;TERMINAR CON ENTER PARA FINALIZAR LA CAPTURA (ascii 13)
    JE FIN_CAPTURA

;Validar que sea un dígito (48 a 57 en ASCII) 
    CMP AL, 48
    JL ERROR
    CMP AL, 57
    JA ERROR

;Guardar el dígito en el acumulador como número (no como ASCII)
    MOV acumulador[di], al
    SUB acumulador[di], 30H			;CONVERTIR CARÁCTER A NÚMERO 
    INC DI							;PASAR AL SIGUIENTE INDICE
    CMP DI, 3						;VER SI YA SE INGRESARON 3 DÍGITOS
    JB CAPTURAR_NUMERO				;SI NO, SE SIGUE CAPTURANDO

FIN_CAPTURA:
;Comenzar conversión del número ingresado a un calor decimal
    MOV SI, 2						;EMPIEZA DESDE EL DÍGITO MENOS SIGNIFICATIVO
    MOV DI, 0
    JMP CONVERTIR_NUMERO

ERROR:
;Mostrar un mensaje de error y volver a capturar
    MOV AH, 09h
    MOV DX, OFFSET cadena2
    INT 21h
    JMP INICIALIZAR_CONTADOR

CONVERTIR_NUMERO:
    MOV AX, 0
    MOV AL, acumulador[SI]			;EL NUMERO QUE QUIERO MULTIPLICAR DEBE ESTAR EN 'AL'
									;TOMAMOS EL DÍGITO A CONVERTIR
    MUL b[SI]						;EL RESULTADO DE LA MULTIPLICACION QUEDA EN AL
    ADD cantPuntos, AX				;SE SUMA A cantPuntos, EL NUMERO QUE ESTÉ EN AL, ES DECIR, SE SUMA AL TOTAL
    DEC SI
    INC DI							;CONTADOR PARA SABER EL NUMERO DE DIGITOS QUE HEMOS CONVERTIDO
    CMP DI, 3						;SE COMPARA CON 3 PARA SABER SI YA SE CONVIRTIERON LOS 3 NUMEROS
    JB CONVERTIR_NUMERO				;SI NO SE HA CONVERTIDO, SE VUELVE A CONVERTIR DE NUEVO EN CONVERTIR_NUMERO, ENTONCES S REPITE PARA LOS OTROS NÚMEROS
    
;Limitar máximo de puntos para visualización a 1000
    CMP cantPuntos, 1000
    JA ERROR

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
    INC puntoX
    JMP DIBUJAR

ARRIBA:
    INC puntoY
    JMP DIBUJAR

IZQUIERDA:
    DEC puntoX
    JMP DIBUJAR

ABAJO:
    DEC puntoY

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