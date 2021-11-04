`timescale 1ns / 1ps


module axis_iic_bridge #(
    parameter CLK_PERIOD     = 100000000,
    parameter CLK_I2C_PERIOD = 25000000 ,
    parameter N_BYTES        = 32
) (
    input  logic                     clk          ,
    input  logic                     resetn       ,
    input  logic [((N_BYTES*8)-1):0] s_axis_tdata ,
    input  logic [      N_BYTES-1:0] s_axis_tkeep ,
    input  logic                     s_axis_tvalid,
    output logic                     s_axis_tready,
    input  logic                     s_axis_tlast ,
    output logic [((N_BYTES*8)-1):0] m_axis_tdata ,
    output logic [      N_BYTES-1:0] m_axis_tkeep ,
    output logic                     m_axis_tvalid,
    input  logic                     m_axis_tready,
    output logic                     m_axis_tlast ,
    input  logic                     scl_i        ,
    input  logic                     sda_i        ,
    output logic                     scl_t        ,
    output logic                     sda_t
);


    localparam DURATION = CLK_PERIOD/CLK_I2C_PERIOD;

    logic [$clog2(DURATION):0] clock_counter = '{default:0};
    
    logic internal_i2c_clk = 1'b0;
    logic d_internal_i2c_clk = 1'b0;

    logic clk_assert = 1'b0;
    logic clk_deassert = 1'b0;

    /*Dont forget about DRCs for this component*/

    /*clock counter for i2c clk generation and event flaqs generation*/
    always_ff @(posedge clk) begin 
        if (clock_counter < DURATION-1) 
            clock_counter <= clock_counter + 1;
        else 
            clock_counter <= '{default:0};
    end 


    always_ff @(posedge clk) begin 
        if (clock_counter < (DURATION-1))
            internal_i2c_clk <= internal_i2c_clk;
        else 
            internal_i2c_clk <= ~internal_i2c_clk;
    end 

    always_ff @(posedge clk) begin 
        d_internal_i2c_clk <= internal_i2c_clk;
    end 

    always_ff @(posedge clk) begin 
        if (!d_internal_i2c_clk & internal_i2c_clk)
            clk_assert <= 1'b1;
        else 
            clk_assert <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (d_internal_i2c_clk & !internal_i2c_clk)
            clk_deassert <= 1'b1;
        else 
            clk_deassert <= 1'b0;
    end 



endmodule