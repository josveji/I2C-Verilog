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

module receiver_SPI(
    // Inputs
    clk,     // Clock, viene del CPU
    rst,     // Reset del sistema
    CPH,     // Define el flanco de SCK 
    CKP,     // Define la polaridad de SCK
    MOSI,    // Recibe bit por bit la información enviada por el Transmisor
    data_in, // Ingreso de dato que debe enviarse por MOSI
    SS,      // Prepara para iniciar el envío de información (CS)
    SCK,     // Reloj interno que sale del Transmisor
   
    // Outputs
    MISO    // Comunicación Receptor -> Transmisor, bit por bit
    ); 

    // Declaración de entradas (inputs)
    input clk, rst, CPH, CKP, MOSI, SS, SCK; 
    input [15:0] data_in; 

    // Declaración de salidas (outputs)
    output reg MISO;

    // Asignando estados
    localparam WAITING = 2'b00;
    localparam START = 2'b01; 
    localparam TRANSFER = 2'b10;
    
    // Para la frecuencia de SCK
    localparam DIV_FREQ = 2;

    // Variables internas
    reg [2:0] state, nx_state;         // Para manejar los estados
    reg [6:0] count_bit, nx_count_bit; // Para contar los bits que salen 
    reg [DIV_FREQ-1:0] div_freq;       // Para calcular SCK
    reg [15:0] inter_data, nx_inter_data;              // Variable interna, almacena data_in
    wire posedge_sck;                  // Capturar Posedge SCK
    wire negedge_sck;                  // Capturar Negedge SCK

    reg sck_anterior; 
    assign posedge_sck = !sck_anterior && SCK; // Flanco positivo de SCK
    assign negedge_sck = sck_anterior && !SCK; // Flanco negativo de SCK
    
    // Declarando FFs
    always @(posedge clk) begin
        if (!rst) begin
            state        <= WAITING;
            count_bit    <= 0;
            div_freq     <= 0;
            sck_anterior <= 0;
            inter_data <= 0; 
        end else begin
            state        <= nx_state;
            count_bit    <= nx_count_bit;
            div_freq     <= div_freq+1;
            sck_anterior <= SCK;
            inter_data   <= nx_inter_data ; 

        end
    end // Fin declaración de FFs

    // Declaración lógica combinacional
    always @(*)begin
        nx_state = state; 
        nx_count_bit = count_bit;
        nx_inter_data = inter_data;

        /*            CPK     CPH
            Modo 00    0       0
            Modo 01    0       1
            Modo 10    1       0
            Modo 11    1       1
        */
        
        case(state)

        endcase

    end

endmodule // Fin de declaración del módulo