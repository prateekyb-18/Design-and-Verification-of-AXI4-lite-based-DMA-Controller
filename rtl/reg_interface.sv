module reg_interface #(

    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32

)(

 
    // Clock & Reset
    
    input logic clk,
    input logic rst_n,

   
    // Write Address Channel
    

    input logic [ADDR_WIDTH-1:0] awaddr,
    input logic awvalid,
    output logic awready,

    
   // Write Data Channel
    
    input logic [DATA_WIDTH-1:0] wdata,
    input logic wvalid,
    output logic wready,

   
    // Write Response
  

    output logic bvalid,
    input logic bready,

    
    // Read Address Channel

    input logic [ADDR_WIDTH-1:0] araddr,
    input logic arvalid,
    output logic arready,

    
    // Read Data Channel
 

    output logic [DATA_WIDTH-1:0] rdata,
    output logic rvalid,
    input logic rready,

       // DMA
    

    input logic dma_done,

    output logic [31:0] src_addr,
    output logic [31:0] dst_addr,
    output logic [31:0] length,
    output logic start,

    
    // Debug
  
    output logic [2:0] state_dbg

);

// State Declaration

typedef enum logic[2:0]{

    IDLE,
    WRITE_ADDR,
    WRITE_DATA,
    WRITE_RESP,
    READ_ADDR,
    READ_DATA

}state_t;

state_t state,next_state;

assign state_dbg = state;
assign awready=1'b1;
// Internal Registers


logic [31:0] src_addr_reg;
logic [31:0] dst_addr_reg;
logic [31:0] length_reg;
logic [31:0] status_reg;

logic [31:0] awaddr_reg;
logic [31:0] araddr_reg;


// State Register


always_ff @(posedge clk or negedge rst_n)

begin

    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;

end

/////////////////////////////////////////////////
// Register Storage
/////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst_n)

begin

    if(!rst_n)

    begin

        src_addr_reg <= 0;
        dst_addr_reg <= 0;
        length_reg   <= 0;

        status_reg   <= 0;

        awaddr_reg   <= 0;
        araddr_reg   <= 0;

        start        <= 0;

    end

    else

    begin

        
        // Default Start Pulse
        

        start <= 0;

        
        // Capture Addresses
        

        if(state==WRITE_ADDR && awvalid && awready)

            awaddr_reg <= awaddr;

        if(state==READ_ADDR && arvalid && arready)
            araddr_reg <= araddr;

          // DMA Done
        
        if(dma_done)
            status_reg <= 32'h1;

        
        // Register Write
        
        if(state==WRITE_DATA && wvalid && wready)

        begin

            case(awaddr_reg)

                32'h00:
                    src_addr_reg <= wdata;

                32'h04:
                    dst_addr_reg <= wdata;

                32'h08:
                    length_reg <= wdata;

                32'h0C:
                    start <= 1;

                default:;

            endcase

        end

    end

end


// Output Registers

assign src_addr = src_addr_reg;
assign dst_addr = dst_addr_reg;
assign length   = length_reg;

// Next State Logic


always_comb
begin

    next_state = state;

    case(state)

        //-------------------------------------
        // IDLE
        

        IDLE:
        begin

            if(awvalid)
                next_state = WRITE_ADDR;

            else if(arvalid)
                next_state = READ_ADDR;

        end

        //-------------------------------------
        // WRITE ADDRESS
       
        WRITE_ADDR:
        begin
            if(awvalid && awready) begin
$display("[%0t] aw hanshake detected",$time);
                next_state = WRITE_DATA;
end
        end

        //-------------------------------------
        // WRITE DATA
       

        WRITE_DATA:
        begin

           
       if(wvalid && wready)
         next_state = WRITE_RESP;

        end

        //-------------------------------------
        // WRITE RESPONSE
       
        WRITE_RESP:
        begin

            if(bvalid && bready)
                next_state = IDLE;

        end

        //-------------------------------------
        // READ ADDRESS
      

        READ_ADDR:
        begin

            if(arvalid && arready)
                next_state = READ_DATA;

        end

        //-------------------------------------
        // READ DATA
       

        READ_DATA:
        begin

            if(rvalid && rready)
                next_state = IDLE;

        end

        default:

            next_state = IDLE;

    endcase

end


// Output Logic

always_comb
begin

    
    // Defaults
  

    awready = 0;
    wready  = 0;

    bvalid  = 0;

    arready = 0;

    rvalid  = 0;
    rdata   = '0;

    
    // State Outputs
   

    case(state)

        //-------------------------------------
        // WRITE ADDRESS
        

        WRITE_ADDR:
        begin

            awready = 1;

        end

        //-------------------------------------
        // WRITE DATA
        

        WRITE_DATA:
        begin



            wready = 1;

        end

        //-------------------------------------
        // WRITE RESPONSE
    

        WRITE_RESP:
        begin

            bvalid = 1;

        end

        //-------------------------------------
        // READ ADDRESS
        
        READ_ADDR:
        begin

            arready = 1;

        end

        //-------------------------------------
        // READ DATA
       
        READ_DATA:
        begin

            rvalid = 1;

            case(araddr_reg)

                32'h00:
                    rdata = src_addr_reg;

                32'h04:
                    rdata = dst_addr_reg;

                32'h08:
                    rdata = length_reg;

                32'h0C:
                    rdata = 32'h1;

                32'h10:
                    rdata = status_reg;

                default:
                    rdata = 32'h0;

            endcase

        end

        default:;

    endcase

end

endmodule
