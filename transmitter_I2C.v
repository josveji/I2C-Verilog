/* 
Tarea 5
Estudiante: Josué María Jiménez Ramírez, C13987 
Profesor: Enrique Coen Alfaro
Curso: Circuitos Digitales II
Periodo: I - 2024

Descripción del archivo: Este es el código que implementa el
módulo trasmitter_I2C (Master). 
*/

// Declaración del módulo 

module transmitter_I2C(
    // Inputs
    clk,          // Clock, viene del CPU
    rst,          // Reset del sistema
    RNW,          // Indica si es lectura (0) o escritura (1)
    I2C_ADDR,     // Dirección del receptor [6:0]
    WR_DATA,      // Recibe los bits que se desean enviar [15:0]
    START_STB,    // Indica que se desea iniciar una transaccion 
    SDA_IN,       // Recive bit por bit respuesta del receptor

    // Outputs
    SCL,          // Salida del reoj para el I2C
    SDA_OUT,      // Envía bit por bit info al receptor
    SDA_OU,       // Habilita/Deshabilita quien tiene el control en la transaccion 
    RD_DATA       // Muestrar los 16 bits recibidos desde el receptor [15:0]
    ); 

    // Declaración de entradas (inputs)
    input clk, rst, RNW, START_STB, SDA_IN;
    input [6:0] I2C_ADDR;
    input [15:0] WR_DATA; 

    // Declaración de salidas (outputs)
    output reg SDA_OUT, SDA_OU; 
    reg nx_SDA_OUT, nx_SDA_OE;
    output reg SCL;
    output reg [15:0] RD_DATA; 


    // Asignando estados
    localparam IDLE = 2'b00;       // Esperando instrucciones, prepara 
    localparam WRITE = 2'b01;      // Estado para enviar info al receptor
    localparam READ = 2'b10;       // Estado para recibir info del receptor
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
    reg [7:0] inter_data_out, nx_inter_data_out; // Variable interna, almacena los bit que se enviarán
    reg [15:0] inter_data_in, nx_inter_data_in;   // Variable interna, almacena los bit que se reciben

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

        //NOTA VERIS  SI AGREGAR nx SDA_OE 
        
        case(state)

            IDLE: begin 
                SDA_OUT = 1;                    // Inicia en 1 para luego generar condiciones de inicio
                SCL = 1;                        // Inicia en 1 para luego generar condiciones de inicio
                nx_count_bit_each = 0; 
                if (!RNW && START_STB) begin    // Se preparan las cosas para Escritura
                    nx_inter_data_out = {I2C_ADDR, RNW}; // Se cargan los datos en el registro interno (1 byte)
                    nx_state = WRITE;           // Prox. estado es WRITE
                end
                else if (RNW && START_STB) begin // Se preparan las cosas para Lectura
                    nx_inter_data_out = {I2C_ADDR, RNW}; // Se cargan los datos en el registro interno (1 byte)
                    nx_state = READ;            // Prox. estado es READ
                end
            end

            WRITE: begin 

                if (SCL && negedge_SDA_out)begin // Si se cumplen las condiciones de inicio
                    SCL = div_freq[DIV_FREQ-1];  // Inicia  oscilación de SCL
                    SDA_OUT = 0;                 // Baja para iniciar a enviar el primer byte
                    SDA_OU = 1;                  // Activa el Output Enable
                    if (posedge_SCL && count_bit_each < 9) begin
                        nx_count_bit_each = count_bit_each +1;
                        nx_count_bit_total = count_bit_total+1;
                        nx_SDA_OUT = inter_data_out[7-count_bit_each]; // Va a ir enviando bit por bit desde el 0 hasta el 7
                    end

                    else if ()
                    //else if (posedge_SCL )
                
                end
                 
            end

            READ: begin
            
            end


        endcase

    end

endmodule // Fin de declaración del módulo
