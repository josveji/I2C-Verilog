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
    reg [7:0] inter_data_out, nx_inter_data_out; // Variable interna, almacena los bit que se recibirán desde el Master
    reg [15:0] inter_data_in, nx_inter_data_in;  // Variable interna, almacena los bit que se enviarán al Master
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
                nx_inter_addr = I2C_ADDR; // Carga la dirección asignada
                nx_count_bit_each = 0; 
                nx_count_bit_total = 0; 
                // Carga el primer byte en inter_data_out
                if (SDA_OE && posedge_SCL && count_bit_total < 9) begin
                    nx_count_bit_total = count_bit_total +1;
                    nx_inter_data_out = {inter_data_out[15:8], SDA_OUT}; // Carga en el registro interno el primer byte, coloca el más significativo
                end
                if (SDA_OE && posedge_SCL && count_bit_total == 8) begin
                    
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

            WRITE: begin // Inicia con count_bit_total = 8
                SDA_IN_ACK = 0; // Probar si así o hay que mantener
                nx_count_bit_total = 0; // Reiniciar count bit total
                if (SDA_OE && posedge_SCL && count_bit_total <8) begin // Para recibir primer byte
                    // Guardamos lo que llega en un registro interno
                    nx_inter_data_in = {inter_data_in[15:8], SDA_OUT}; // Coloca el que llega como el más significativo (Recibe del 15-8)
                    nx_count_bit_total = count_bit_total+1;
                    nx_count_bit_each = count_bit_each+1;
                    if (count_bit_each == 8) begin 
                        SDA_IN_ACK = 1; 
                        nx_count_bit_each = 0; 
                    end
                end
                else if (SDA_OE && posedge_SCL && count_bit_total >= 8 && count_bit_total <16) begin // Para recibir segundo byte
                    SDA_IN_ACK = 0; // OJO REVISAR SI FUNCIONA bien 
                    // Guardamos lo que llega en un registro interno
                    nx_inter_data_in = {inter_data_in[7:0], SDA_OUT}; // Coloca el que llega como el más significativo (Recive del 7-0)
                    nx_count_bit_total = count_bit_total+1;
                    if (count_bit_each == 8) begin 
                        SDA_IN_ACK = 1; 
                        nx_count_bit_each = 0; 
                    end
                end
                else if (count_bit_total == 24)begin 
                    WR_DATA = inter_data_out; // Saca los datos por WR_DATA
                    nx_state = FINISH;
                end
                 
            end

            READ: begin
                // Cargar datos de RD_DATA en inter_data_in
                nx_inter_data_in = RD_DATA;
                SDA_IN_ACK = 0; 
                nx_count_bit_each = 0; 
                nx_count_bit_total = 0;
                if (posedge_SCL && !SDA_OE) begin 
                    if (count_bit_total < 8) begin // Enviar primer byte a Master
                        nx_count_bit_each = count_bit_each +1;
                        nx_count_bit_total = count_bit_total+1;
                        nx_SDA_OUT = inter_data_out[15-count_bit_each]; // Envía el primer byte
                        // Conviene agregar mantener en alto el ACK?
                    end 
                    else if (count_bit_total == 8) SDA_IN_ACK = 1;

                    else if (count_bit_total >= 8 && count_bit_total <17)begin 
                        SDA_IN_ACK = 0; 
                        nx_count_bit_each = count_bit_each +1;
                        nx_count_bit_total = count_bit_total+1;
                        nx_SDA_OUT = inter_data_out[15-count_bit_each]; // Envía el segundo byte
                    end 
                    else if (count_bit_total == 17) begin 
                        SDA_IN_ACK = 1; 
                        nx_state = FINISH; 
                    end
                end 
            end

            FINISH: begin 
                // Generar condición de parada
                SDA_IN_ACK = 0; 
                nx_SDA_OUT = 1; // Se pone en alto para generar condición de parada
                if (SCL && posedge_SDA_out) begin 
                    nx_state = IDLE;
                end
            end

        endcase

    end

endmodule // Fin de declaración del módulo
