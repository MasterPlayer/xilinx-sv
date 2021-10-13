`timescale 1ns / 1ps


module axis_fir_filter #(
    parameter N_BYTES          = 4,
    parameter COEFF_ADDR_WIDTH = 6
) (
    input                                 CLK          ,
    input                                 RESET        ,
    input        [(COEFF_ADDR_WIDTH-1):0] COEFF_ADDR   ,
    input        [       (N_BYTES*8)-1:0] COEFF_DATA   ,
    input                                 COEFF_VALID  ,
    input        [       (N_BYTES*8)-1:0] S_AXIS_TDATA ,
    input                                 S_AXIS_TVALID,
    output logic                          S_AXIS_TREADY,
    output logic [       (N_BYTES*8)-1:0] M_AXIS_TDATA ,
    output logic                          M_AXIS_TVALID,
    input                                 M_AXIS_TREADY
);


    localparam DATA_WIDTH    = (N_BYTES*8)          ;
    localparam N_COEFFS      = (2**COEFF_ADDR_WIDTH);
    localparam N_COEFFS_HALF = (N_COEFFS/2)         ;
    localparam DATA_FILL_MPY = (DATA_WIDTH*2) - DATA_WIDTH;

    // logic [((N_COEFFS_HALF)-1):0][(N_BYTES*8)-1:0] coeff_register = '{default:'{default:0}};
    logic [((N_COEFFS_HALF)-1):0][(N_BYTES*8)-1:0] coeff_register = {
           
        16'h2638, 16'h1A83, 16'h09e7, 16'hFD11, 
        16'hF8BC, 16'hFB81, 16'h0056, 16'h02ED, 
        16'h0250, 16'h0042, 16'hFEE0, 16'hFEE9, 
        16'hFFB9, 16'h005D, 16'h0070, 16'h0029, 
        16'hFFE9, 16'hFFDB, 16'hFFEF, 16'h0003, 
        16'h0009, 16'h0005, 16'h0000, 16'hFFFE, 
        16'hFFFF, 16'h0000, 16'h0000, 16'h0000, 
        16'h0000, 16'h0000, 16'h0000, 16'h0000
    };


    logic [0:((N_COEFFS_HALF)-1)][(N_BYTES*8)-1:0] shreg_1   = '{default:'{default:0}};
    logic [((N_COEFFS_HALF)-1):0][(N_BYTES*8)-1:0] shreg_2   = '{default:'{default:0}};
    logic [         DATA_WIDTH:0]                  f_operand                          ;
    logic [         DATA_WIDTH:0]                  s_operand                          ;

    logic [$clog2(N_COEFFS_HALF-1)-1:0] address_reg = '{default:0};

    logic [                             DATA_WIDTH:0] mpy_f_reg  = '{default:0};
    logic [                             DATA_WIDTH:0] mpy_s_reg  = '{default:0};
    logic [                       (DATA_WIDTH*2)-1:0] mpy_result = '{default:0};
    logic [(((DATA_WIDTH*2)+($clog2(N_COEFFS)))-1):0] acc_reg    = '{default:0};

    logic deassert_flaq = 1'b0;

    typedef enum {
        IDLE_ST,
        CALC_ST,
        AWAIT_OUTPUT_ST
    } fsm;


    fsm current_state    = IDLE_ST;
    fsm d_current_state  = IDLE_ST;
    fsm dd_current_state = IDLE_ST;

    logic s_axis_tready_reg = 1'b0;

    logic [((N_BYTES*8)-1):0] m_axis_tdata_reg  = '{default:0};
    logic                     m_axis_tvalid_reg = 1'b0        ;



    always_comb begin 
        S_AXIS_TREADY <= s_axis_tready_reg;
    end 



    always_comb begin 
        M_AXIS_TDATA <= m_axis_tdata_reg;
    end



    always_comb begin 
        M_AXIS_TVALID <= m_axis_tvalid_reg & ~deassert_flaq;
    end



    always_ff @(posedge CLK) begin 
        d_current_state <= current_state;
    end 



    always_ff @(posedge CLK) begin 
        dd_current_state <= d_current_state;
    end 



    always_ff @(posedge CLK) begin : current_state_proc 
        if (RESET) begin 
            current_state <= IDLE_ST;
        end else begin 
            case (current_state) 
                IDLE_ST : 
                    if (S_AXIS_TVALID & s_axis_tready_reg)  
                        current_state <= CALC_ST;
                   

                CALC_ST :
                    if (address_reg == (N_COEFFS_HALF-1))  
                        current_state <= AWAIT_OUTPUT_ST;
                    

                AWAIT_OUTPUT_ST: 
                    if (M_AXIS_TREADY)  
                        current_state <= IDLE_ST;
                    

                default : 
                    current_state <= current_state;
            endcase
        end 
    end 



    always_ff @(posedge CLK) begin : s_axis_tready_reg_proc
        if (RESET) begin 
            s_axis_tready_reg <= 1'b0;
        end else begin 

            case (current_state)
                IDLE_ST : 
                    if (S_AXIS_TVALID & s_axis_tready_reg) begin 
                        s_axis_tready_reg <= 1'b0;
                    end else begin
                        s_axis_tready_reg <= 1'b1;
                    end

                default : 
                    s_axis_tready_reg <= s_axis_tready_reg;
            endcase // current_state
        end 
    end 



    always_ff @(posedge CLK) begin : address_reg_proc
        case (current_state)
            IDLE_ST : 
                address_reg <= '{default:0};

            CALC_ST :  
                address_reg <= address_reg + 1;
        endcase // current_state
    end 



    always_ff @(posedge CLK) begin : shreg_1_proc
        if (S_AXIS_TVALID & s_axis_tready_reg) 
            shreg_1 <= {S_AXIS_TDATA, shreg_1[0:N_COEFFS_HALF-2]};
    end 



    always_ff @(posedge CLK) begin : shreg_2_proc
        if (S_AXIS_TVALID & s_axis_tready_reg) 
            shreg_2 <= {shreg_1[(N_COEFFS_HALF-1)], shreg_2[(N_COEFFS_HALF-1):1]};
    end 



    always_comb begin 
        f_operand = {shreg_1[address_reg][DATA_WIDTH-1], shreg_1[address_reg][DATA_WIDTH-1:0]};
    end 



    always_comb begin 
        s_operand = {shreg_2[address_reg][DATA_WIDTH-1], shreg_2[address_reg][DATA_WIDTH-1:0]};
    end 



    always_ff @(posedge CLK) begin : mpy_f_reg_proc
        mpy_f_reg <= f_operand + s_operand;
    end 



    always_ff @(posedge CLK) begin 
        mpy_s_reg <= {coeff_register[address_reg][DATA_WIDTH-1], coeff_register[address_reg]};
    end 



    always_ff @(posedge CLK) begin 
        mpy_result <= {{DATA_FILL_MPY{mpy_f_reg[DATA_WIDTH]}}, mpy_f_reg} * {{DATA_FILL_MPY{mpy_s_reg[DATA_WIDTH]}}, mpy_s_reg};
    end 



    always_ff @(posedge CLK) begin 
        case (dd_current_state)
            CALC_ST : 
                acc_reg <= acc_reg + mpy_result;

            AWAIT_OUTPUT_ST:
                acc_reg <= acc_reg;

            default : 
                acc_reg <= '{default:0};
        endcase // dd_current_state
    end 

    always_comb begin 
        m_axis_tdata_reg = acc_reg[((DATA_WIDTH-1) + (DATA_WIDTH-1)):(DATA_WIDTH-1)];
    end     



    always_ff @(posedge CLK) begin : m_axis_tvalid_reg_proc
        case (d_current_state)  
            AWAIT_OUTPUT_ST: 
                if (m_axis_tvalid_reg & M_AXIS_TREADY) begin 
                    m_axis_tvalid_reg <= 1'b0;
                end else begin 
                    m_axis_tvalid_reg <= 1'b1;
                end 

            default: 
                m_axis_tvalid_reg <= 1'b0;
        endcase 
    end 



    always_ff @(posedge CLK) begin 
        if (M_AXIS_TREADY & m_axis_tvalid_reg) begin 
            deassert_flaq <= 1'b1;
        end else begin 
            if (S_AXIS_TVALID & s_axis_tready_reg)  
                deassert_flaq <= 1'b0;
           
        end
    end 

endmodule
