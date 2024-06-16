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
    12C_ADDR,     // Dirección del receptor [6:0]
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
    input [6:0] 12C_ADDR;
    input [15:0] WR_DATA; 

    // Declaración de salidas (outputs)
    output reg SDA_OU, SDA_OU; 
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
    reg [6:0] count_bit, nx_count_bit;            // Para contar los bits que salen 
    reg [DIV_FREQ-1:0] div_freq;                  // Para calcular SCL (25% clk)
    reg [15:0] inter_data_out, nx_inter_data_out; // Variable interna, almacena los bit que se enviarán
    reg [15:0] inter_data_in, nx_inter_data_in;   // Variable interna, almacena los bit que se reciben
    wire posedge_SCL;                             // Capturar Posedge SCL

    // Almacenar total d bits que se enviarán 

    // Para manejar reloj SCL
    reg SCL_anterior; 
    assign posedge_SCL = !SCL_anterior && SCL; // Flanco positivo de SCL
    
    // Declarando FFs
    always @(posedge clk) begin
        if (!rst) begin
            state          <= IDLE;
            count_bit      <= 0;
            div_freq       <= 0;
            SCL_anterior   <= 0;
            inter_data_out <= 0; 
            inter_data_in  <= 0;
        end else begin
            state          <= nx_state;
            count_bit      <= nx_count_bit;
            div_freq       <= div_freq+1;
            SCL_anterior   <= SCL;
            inter_data_out <= nx_inter_data_out ; 
            inter_data_in  <= nx_inter_data_in ; 

        end
    end // Fin declaración de FFs

    // Declaracación lógica combinacional
    always @(*)begin
        nx_state = state; 
        nx_count_bit = count_bit;
        nx_inter_data_out = inter_data_out;
        nx_inter_data_in = inter_data_out;
        
        case(state)

            IDLE: begin 
                if (!RNW && START_STB) begin // Se preparan las cosas para Escritura
                // Se cargan los datos en el registro interno
                
                nx_state = WRITE;
                end
                else if (RNW && START_STB) begin // Se preparan las cosas para Lectura
                nx_state = READ; 
                end
            end

            WRITE: begin 
                if ()
            end

            READ: begin
            
            end


        endcase

    end

endmodule // Fin de declaración del módulo
