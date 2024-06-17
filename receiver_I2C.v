/* 
Tarea 5
Estudiante: Josué María Jiménez Ramírez, C13987 
Profesor: Enrique Coen Alfaro
Curso: Circuitos Digitales II
Periodo: I - 2024

Descripción del archivo: Este es el código que implementa el
módulo receiver_I2C (Slave). 
*/

// Declaración del módulo 

module receiver_I2C(
    // Inputs
    clk,          // Clock, viene del CPU
    rst,          // Reset del sistema
    I2C_ADDR,     // Dirección del receptor [6:0]
    RD_DATA,       // Carga los datos que se desean enviar al transmisor [15:0]
    SCL,          // Salida del reoj para el I2C
    SDA_OUT,      // Recibe bit por bit (enviado del Transmiso) al receptor
    SDA_OE,       // Habilita/Deshabilita quien tiene el control en la transaccion 

    // Outputs
    SDA_IN,       // Recibe bit por bit respuesta del receptor
    WR_DATA,      // salida [15:0] paralalela, muestra lo que llegó del Transmisor
    SDA_IN_ACK    // Envía señal de ACK
    
    ); 

    // Declaración de entradas (inputs)
    input clk, rst, SCL, SDA_OUT, SDA_OE;
    input [6:0] I2C_ADDR;
    input [15:0] RD_DATA; 

    // Declaración de salidas (outputs)
    reg nx_SDA_OUT, nx_SDA_OE;
    output reg [15:0] WR_DATA; 
    output reg SCL;
    


    // Asignando estados
    localparam IDLE = 2'b00;       // Esperando instrucciones, prepara 
    localparam WRITE = 2'b01;      // Estado para recibir info del Transmisor
    localparam READ = 2'b10;       // Estado para reviar info al Transmisor
    localparam FINISH = 2'b11;     // Estado finalizar 
    
    // Para la frecuencia de SCL
    localparam DIV_FREQ = 2;

    // Variables internas
    reg [2:0] state, nx_state;                    // Para manejar los estados
    reg [6:0] count_bit_each, nx_count_bit_each;  // Para contar los bits que sale por byte
    reg [6:0] count_bit_total, nx_count_bit_total;  // Para contar los bits que sale por byte
    reg [DIV_FREQ-1:0] div_freq;                  // Para calcular SCL (25% clk)
    wire posedge_SCL;                             // Capturar Posedge SCL
    wire negedge_SDA_out;

    // Almacenar total de bits que se enviarán 
    reg [7:0] inter_data_out, nx_inter_data_out; // Variable interna, almacena los bit que se recibirán
    reg [15:0] inter_data_in, nx_inter_data_in;  // Variable interna, almacena los bit que se enviarán
    reg [6:0] inter_addr, nx_inter_addr;         // Almacenar variable interna la dirección 

    // Para manejar reloj SCL
    reg SCL_anterior; 
    assign posedge_SCL = !SCL_anterior && SCL; // Flanco positivo de SCL

    // Para manejar condiciones de inicio
    reg SDA_out_anterior;
    // Flanco negativo de SDA_out
    assign negedge_SDA_out = SDA_out_anterior && !SDA_OUT;
    // Flanco positivo de SDA_out
    assign posedge_SDA_out = !SDA_out_anterior && SDA_OUT;
    
    // Declarando FFs
    always @(posedge clk) begin
        if (!rst) begin
            state          <= IDLE;
            count_bit_each <= 0;
            count_bit_total<= 0;
            div_freq       <= 0;
            SCL_anterior   <= 0;
            SDA_out_anterior <= 0;
            SDA_OUT <= 0; 
            SDA_OE <= 0; 
            inter_data_out <= 0; 
            inter_data_in  <= 0;
            inter_addr <=0; 
        end else begin
            state          <= nx_state;
            count_bit_each <= nx_count_bit_each;
            count_bit_total<= nx_count_bit_total;
            div_freq       <= div_freq+1;
            SCL_anterior   <= SCL;
            SDA_out_anterior <= SDA_OUT;
            SDA_OUT <= nx_SDA_OUT;
            SDA_OE <= nx_SDA_OE; 
            inter_data_out <= nx_inter_data_out ; 
            inter_data_in  <= nx_inter_data_in ; 
            inter_addr     <= nx_inter_addr;

        end
    end // Fin declaración de FFs

    // Declaracación lógica combinacional
    always @(*)begin
        nx_state = state; 
        nx_count_bit_each = count_bit_each;
        nx_count_bit_total= count_bit_total;
        nx_inter_data_out = inter_data_out;
        nx_inter_data_in = inter_data_out;
        nx_SDA_OUT = SDA_OUT;
        nx_inter_addr = inter_addr;

        //NOTA VERIS  SI AGREGAR nx SDA_OE 
        
        case(state)

            IDLE: begin
                // Carga el I2CADDR en variable interna
                nx_inter_addr = I2C_ADDR;
                // Carga el primer byte en inter_data_out
                if (SDA_OE && posedge_SCL) begin
                    //nx_count_bit_total = count_bit_total +1;
                    nx_inter_data_out = {inter_data_out[15:1], SDA_OUT};
                    if (inter_data_out[15:9] == inter_addr && inter_data_out[8]) begin 
                        SDA_IN_ACK = 1; 
                        nx_state = READ;
                    end 
                    else if (inter_data_out[15:9] == inter_addr && !inter_data_out[8]) begin 
                        SDA_IN_ACK = 1; 
                        nx_state = WRITE;
                    end

                end

            end

            WRITE: begin 
                SDA_OE = 1;                  // Activa el Output Enable /// Ver si sirve dejarlo acá en la jerarquía o arriba
                nx_SDA_OUT = 0;              // Se pone en bajo para generar condiciones de inicio      
                if (SCL && negedge_SDA_out)begin // Si se cumplen las condiciones de inicio
                    SCL = div_freq[DIV_FREQ-1];  // Inicia  oscilación de SCL
                    nx_SDA_OUT = 0;                 // Baja para iniciar a enviar el primer byte
                    // Acá iba el SDA_OE
                    if (posedge_SCL && count_bit_total < 9) begin // Para el byte de Adress+RNW;
                        nx_count_bit_each = count_bit_each +1;
                        nx_count_bit_total = count_bit_total+1;
                        nx_SDA_OUT = inter_data_out[7-count_bit_each]; // Va a ir enviando bit por bit desde el 0 hasta el 7
                    end
                    else if (count_bit_total >= 8 && count_bit_total <17) begin // Para el primer byte de WR_DATA
                        nx_inter_data_out = WR_DATA[15:8]; // Carga el primer byte de WR_DATA
                        nx_count_bit_each = 0;             // reinicia el contador de bits a cero
                        if (posedge_SCL && SDA_IN_ACK) begin 
                            nx_count_bit_each = count_bit_each +1;
                            nx_count_bit_total = count_bit_total+1;
                            nx_SDA_OUT = inter_data_out[7-count_bit_each];
                        end;
                    end
                    else if (count_bit_total >= 16 && count_bit_total <25)begin // Para el segundo byte de WR_DATA
                        nx_inter_data_out = WR_DATA[7:0];  // Carga el segundo byte de WR_DATA
                        nx_count_bit_each = 0;             // reinicia el contador de bits a cero
                        if (posedge_SCL && SDA_IN_ACK) begin 
                            nx_count_bit_each = count_bit_each +1;
                            nx_count_bit_total = count_bit_total+1;
                            nx_SDA_OUT = inter_data_out[7-count_bit_each];
                        end;
                    end
                    else if (count_bit_total==24) begin 
                        nx_SDA_OUT = 0; // Hace cero para luego en FINISH hacer uno y generar posedge para condicion de parada
                        nx_state = FINISH; 
                    end
                end
                 
            end

            READ: begin
                SDA_OE = 1;                  // Activa el Output Enable /// Ver si sirve dejarlo acá en la jerarquía o arriba
                nx_SDA_OUT = 0;              // Se pone en bajo para generar condiciones de inicio      
                if (SCL && negedge_SDA_out)begin // Si se cumplen las condiciones de inicio
                    SCL = div_freq[DIV_FREQ-1];  // Inicia  oscilación de SCL
                    SDA_OUT = 0;                 // Baja para iniciar a enviar el primer byte
                    // Acá iba el SDA_OE
                    if (posedge_SCL && count_bit_total < 9) begin // Para el byte de Adress+RNW;
                        nx_count_bit_each = count_bit_each +1;
                        nx_count_bit_total = count_bit_total+1;
                        nx_SDA_OUT = inter_data_out[7-count_bit_each]; // Va a ir enviando bit por bit desde el 0 hasta el 7
                    end
                    if (posedge_SCL && SDA_IN_ACK && count_bit_total > 8 && count_bit_total < 17) begin // Se recibe ACK considerando que se confirmó la dirección
                        SDA_OE = 0; // A partir de acá toma el control el receptor
                        nx_inter_data_in = {inter_data_in[15:1], SDA_IN};
                        nx_count_bit_total = count_bit_total+1;
                    end
                    if (count_bit_total == 16)begin 
                        nx_SDA_OUT = 0; // Hace cero para luego en FINISH hacer uno y generar posedge para condicion de parada
                        nx_state = FINISH; 
                    end
                end 
            end

            FINISH: begin 
                // Generar condición de parada
                SCL = 1; // Pone en alto SCL para la condición de parada
                nx_SDA_OUT = 1; // Se pone en alto para generar condición de parada
                if (SCL && posedge_SDA_out) begin 
                    nx_state = IDLE;
                end
            end

        endcase

    end

endmodule // Fin de declaración del módulo
