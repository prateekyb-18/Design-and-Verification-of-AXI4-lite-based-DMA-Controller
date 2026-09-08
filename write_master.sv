module write_master #(

    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BURST_LEN  = 4

)(

    input logic clk,
    input logic rst_n,

    
    // Control FSM
 
    input logic write_start,

    
    // Address Generator
    
    input logic [ADDR_WIDTH-1:0] dst_addr,

    
    // FIFO Interface


    input logic fifo_empty,
    input logic [DATA_WIDTH-1:0] fifo_rd_data,

    output logic fifo_rd_en,

 
    // AXI AW Channel
   

    output logic [ADDR_WIDTH-1:0] awaddr,
    output logic [7:0] awlen,
    output logic [2:0] awsize,
    output logic awvalid,

    input logic awready,

   
    // AXI W Channel
    

    output logic [DATA_WIDTH-1:0] wdata,
    output logic wvalid,
    output logic wlast,

    input logic wready,

   
    // AXI B Channel
   

    input logic bvalid,
    output logic bready,

  
    // Control FSM
  

    output logic write_done,

    
    // Debug
    

    output logic [2:0] state_dbg

);


// State Declaration

typedef enum logic [2:0]{

    IDLE,
    SEND_AW,
    WRITE_DATA,
    WAIT_RESPONSE,
    DONE

}state_t;

state_t state;
state_t next_state;


// Internal Registers


logic [ADDR_WIDTH-1:0] awaddr_reg;
logic [7:0] awlen_reg;
logic [2:0] awsize_reg;

logic [$clog2(BURST_LEN+1)-1:0] beat_count;

assign state_dbg = state;


// State Register


always_ff @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;

end


// Transaction Register

always_ff @(posedge clk or negedge rst_n)
begin

    if(!rst_n)

    begin

        awaddr_reg <= '0;
        awlen_reg  <= '0;
        awsize_reg <= '0;

    end

    else if(state==IDLE && write_start)

    begin

        awaddr_reg <= dst_addr;
        awlen_reg  <= BURST_LEN-1;
        awsize_reg <= 3'b010;

    end

end


// Beat Counter

always_ff @(posedge clk or negedge rst_n)
begin

    if(!rst_n)

        beat_count <= '0;

    else if(state==IDLE)

        beat_count <= '0;

    else if(state==WRITE_DATA && wvalid && wready)

        beat_count <= beat_count + 1;

end

// Next State Logic


always_comb
begin

    next_state = state;

    case(state)

        //-------------------------------------
       // IDLE
       
        IDLE:
        begin
            if(write_start)
                next_state = SEND_AW;
        end

        //-------------------------------------
        // SEND WRITE ADDRESS
       
        SEND_AW:
        begin
            if(awvalid && awready)
                next_state = WRITE_DATA;
        end

        //-------------------------------------
        // WRITE DATA
       
        WRITE_DATA:
        begin

            if(wvalid && wready && wlast)
                next_state = WAIT_RESPONSE;

        end

        //-------------------------------------
        // WAIT FOR WRITE RESPONSE
      
        WAIT_RESPONSE:
        begin

            if(bvalid && bready)
                next_state = DONE;

        end

        //-------------------------------------
        // DONE
        
        DONE:
        begin
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
    

    awaddr = awaddr_reg;
    awlen  = awlen_reg;
    awsize = awsize_reg;

    awvalid = 0;

    wdata = '0;
    wvalid = 0;
    wlast = 0;

    fifo_rd_en = 0;

    bready = 0;

    write_done = 0;

    
    // State Outputs
    
    case(state)

        //-------------------------------------
        // SEND ADDRESS
        
        SEND_AW:
        begin

            awvalid = 1;

        end

        //-------------------------------------
        // WRITE DATA
      
        WRITE_DATA:
        begin

            if(!fifo_empty)

            begin

                wvalid = 1;

                wdata = fifo_rd_data;

                fifo_rd_en = wvalid && wready;

                if(beat_count == BURST_LEN-1)
                    wlast = 1;

            end

        end

        //-------------------------------------
        // WAIT RESPONSE
     
        WAIT_RESPONSE:
        begin

            bready = 1;

        end

        //-------------------------------------
        // DONE
       
        DONE:
        begin

            write_done = 1;

        end

        default:;

    endcase

end

endmodule
