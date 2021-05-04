`timescale 1ns / 1ps


module sys_mng_wrapper(
    input               CLK        ,
    input               RESET      ,

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

    logic [ 7:0] drp_addr   ;
    logic [15:0] drp_di     ;
    logic [15:0] drp_do     ;
    logic        drp_en     ;
    logic        drp_rdy    ;
    logic        drp_we     ;

    // ila_drp ila_drp_inst (
    //     .clk   (CLK     ), // input wire clk
    //     .probe0(drp_addr), // input wire [7:0]  probe0
    //     .probe1(drp_di  ), // input wire [15:0]  probe1
    //     .probe2(drp_do  ), // input wire [15:0]  probe2
    //     .probe3(drp_en  ), // input wire [0:0]  probe3
    //     .probe4(drp_rdy ), // input wire [0:0]  probe4
    //     .probe5(drp_we  )  // input wire [0:0]  probe5
    // );

    sys_mng_drp_ctrlr sys_mng_drp_ctrlr_inst (
        .CLK         (CLK         ),
        .RESET       (RESET       ),
        .DRP_ADDR    (drp_addr    ),
        .DRP_DI      (drp_di      ),
        .DRP_DO      (drp_do      ),
        .DRP_EN      (drp_en      ),
        .DRP_RDY     (drp_rdy     ),
        .DRP_WE      (drp_we      ),

        .TEMP        (TEMP        ),
        .TEMP_MAX    (TEMP_MAX    ),
        .TEMP_MIN    (TEMP_MIN    ),
        
        .VCCINT      (VCCINT      ),
        .VCCINT_MAX  (VCCINT_MAX  ),
        .VCCINT_MIN  (VCCINT_MIN  ),
        
        .VCCAUX      (VCCAUX      ),
        .VCCAUX_MAX  (VCCAUX_MAX  ),
        .VCCAUX_MIN  (VCCAUX_MIN  ),
        
        .VCCBRAM     (VCCBRAM     ),
        .VCCBRAM_MAX (VCCBRAM_MAX ),
        .VCCBRAM_MIN (VCCBRAM_MIN )
    );

    sys_mng sys_mng_inst (
        .di_in      (drp_di  ), // input wire [15 : 0] di_in
        .daddr_in   (drp_addr), // input wire [7 : 0] daddr_in
        .den_in     (drp_en  ), // input wire den_in
        .dwe_in     (drp_we  ), // input wire dwe_in
        .drdy_out   (drp_rdy ), // output wire drdy_out
        .do_out     (drp_do  ), // output wire [15 : 0] do_out
        .dclk_in    (CLK     ), // input wire dclk_in
        .reset_in   (RESET   ), // input wire reset_in
        .channel_out(        ), // output wire [5 : 0] channel_out
        .eoc_out    (        ), // output wire eoc_out
        .alarm_out  (        ), // output wire alarm_out
        .eos_out    (        ), // output wire eos_out
        .busy_out   (        )  // output wire busy_out
    );

endmodule
