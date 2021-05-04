`timescale 1ns / 1ps


module sys_mng_drp_ctrlr (
    input               CLK        ,
    input               RESET      ,
    output logic [ 7:0] DRP_ADDR   ,
    output logic [15:0] DRP_DI     ,
    input        [15:0] DRP_DO     ,
    output logic        DRP_EN     ,
    input               DRP_RDY    ,
    output logic        DRP_WE     ,

    output logic [15:0] TEMP       ,
    output logic [15:0] TEMP_MAX   ,
    output logic [15:0] TEMP_MIN   ,
    
    output logic [15:0] VCCINT     ,
    output logic [15:0] VCCINT_MAX ,
    output logic [15:0] VCCINT_MIN ,
    
    output logic [15:0] VCCAUX     ,
    output logic [15:0] VCCAUX_MAX ,
    output logic [15:0] VCCAUX_MIN ,
    
    output logic [15:0] VCCBRAM    ,
    output logic [15:0] VCCBRAM_MAX,
    output logic [15:0] VCCBRAM_MIN 
);

    typedef enum {
        IDLE_ST                 ,
        ESTABLISH_DRP_ADDR_ST   ,
        WAIT_FOR_RDY_ST         
    } fsm;

    fsm current_state = IDLE_ST;

    logic [7:0] drp_mem [0:11] = {
        'h00, //Temp
        'h20, //MaxTemp
        'h24, //MinTemp
        'h01, //VCCint
        'h21, //MaxVccINT
        'h25, //MinVccInt
        'h02, //VccAux
        'h22, //MaxVccAux
        'h26, //MinVccAUX
        'h06, //VccBRAM
        'h23, //MaxVccBRAM
        'h27  //MinVccBRAM
    };

    logic [7:0] drp_mem_addr = '{default:0}; 

    logic [15:0] temp_reg;
    logic [15:0] temp_max_reg;
    logic [15:0] temp_min_reg;
    logic [15:0] vccint_reg;
    logic [15:0] vccint_max_reg;
    logic [15:0] vccint_min_reg;
    logic [15:0] vccaux_reg;
    logic [15:0] vccaux_max_reg;
    logic [15:0] vccaux_min_reg;
    logic [15:0] vccbram_reg;
    logic [15:0] vccbram_max_reg;
    logic [15:0] vccbram_min_reg;

    always_comb begin 
        DRP_WE = 1'b0;
        DRP_ADDR = drp_mem[drp_mem_addr];
        DRP_DI = '{default:0};
        TEMP = temp_reg;
        TEMP_MAX = temp_max_reg;
        TEMP_MIN = temp_min_reg;
        VCCINT = vccint_reg;
        VCCINT_MAX = vccint_max_reg;
        VCCINT_MIN = vccint_min_reg;
        VCCAUX = vccaux_reg;
        VCCAUX_MAX = vccaux_max_reg;
        VCCAUX_MIN = vccaux_min_reg;
        VCCBRAM = vccbram_reg;
        VCCBRAM_MAX = vccbram_max_reg;
        VCCBRAM_MIN = vccbram_min_reg;

    end 



    always_ff @(posedge CLK) begin : current_state_processing 
        if (RESET)
            current_state <= IDLE_ST;
        else
            case (current_state)

                IDLE_ST : 
                    current_state <= ESTABLISH_DRP_ADDR_ST;
                
                ESTABLISH_DRP_ADDR_ST : 
                    current_state <= WAIT_FOR_RDY_ST;

                WAIT_FOR_RDY_ST : 
                    if (DRP_RDY)
                        current_state <= ESTABLISH_DRP_ADDR_ST;

            endcase 
    end 

    always_ff @(posedge CLK) begin : drp_mem_addr_processing
        if (RESET)
            drp_mem_addr <= '{default:0};
        else
            case (current_state)
                WAIT_FOR_RDY_ST :
                    if (DRP_RDY) 
                        if (drp_mem_addr < 11)
                            drp_mem_addr <= drp_mem_addr + 1;
                        else
                            drp_mem_addr <= '{default:0};
            endcase
    end 

    always_ff @(posedge CLK) begin : drp_en_processing 
        if (RESET)
            DRP_EN <= 1'b0;
        else
            case (current_state)
                ESTABLISH_DRP_ADDR_ST : 
                    DRP_EN <= 1'b1;

                default : 
                    DRP_EN <= 1'b0;

            endcase
    end 


    always_ff @(posedge CLK) begin : temp_processing 
        if ((drp_mem_addr == 'h00) & DRP_RDY)
            temp_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : temp_max_processing 
        if ((drp_mem_addr == 'h01) & DRP_RDY)
            temp_max_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : temp_min_processing 
        if ((drp_mem_addr == 'h02) & DRP_RDY)
            temp_min_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccint_processing 
        if ((drp_mem_addr == 'h03) & DRP_RDY)
            vccint_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccint_max_processing 
        if ((drp_mem_addr == 'h04) & DRP_RDY)
            vccint_max_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccint_min_processing 
        if ((drp_mem_addr == 'h05) & DRP_RDY)
            vccint_min_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccaux_processing 
        if ((drp_mem_addr == 'h06) & DRP_RDY)
            vccaux_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccaux_max_processing 
        if ((drp_mem_addr == 'h07) & DRP_RDY)
            vccaux_max_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccaux_min_processing 
        if ((drp_mem_addr == 'h08) & DRP_RDY)
            vccaux_min_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccbram_processing 
        if ((drp_mem_addr == 'h09) & DRP_RDY)
            vccbram_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccbram_max_processing 
        if ((drp_mem_addr == 'h0a) & DRP_RDY)
            vccbram_max_reg <= DRP_DO;
    end 

    always_ff @(posedge CLK) begin : vccbram_min_processing 
        if ((drp_mem_addr == 'h0b) & DRP_RDY)
            vccbram_min_reg <= DRP_DO;
    end 



endmodule
