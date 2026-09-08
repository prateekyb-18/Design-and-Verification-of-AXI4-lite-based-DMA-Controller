
module read_master #(

    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BURST_LEN  = 4

)(
    input logic clk,
    input logic rst,
    input logic read_start,
    input logic [ADDR_WIDTH-1:0] src_addr,
    input logic fifo_full,
    output logic fifo_wr_en,
    output logic [DATA_WIDTH-1:0] fifo_wr_data,
  
    
    
    output logic [ADDR_WIDTH-1:0] araddr,
    output logic [7:0] arlen,
    output logic [2:0] arsize,
    output logic arvalid,
    input logic arready,

    

   
    input logic [DATA_WIDTH-1:0] rdata,
    input logic rvalid,
    input logic rlast,

    output logic rready,


       
    output logic read_done,

   
  
    output logic [1:0] state_dbg

);

// State Declaration

typedef enum logic [1:0]{

    IDLE,
    SEND_AR,
    READ_DATA,
    DONE

}state_t;

state_t state;
state_t next_state;


// Internal Registers

logic [ADDR_WIDTH-1:0] araddr_reg;
logic [7:0] arlen_reg;
logic [2:0] arsize_reg;

logic [$clog2(BURST_LEN+1)-1:0] beat_count;

assign state_dbg = state;

// State Register

always_ff @(posedge clk or negedge rst)
begin

    if(!rst)
        state <= IDLE;
    else
        state <= next_state;

end


// Transaction Registers

always_ff @(posedge clk or negedge rst)
begin

    if(!rst)

    begin

        araddr_reg <= '0;
        arlen_reg  <= '0;
        arsize_reg <= '0;

    end

    else if(state==IDLE && read_start)

    begin

        araddr_reg <= src_addr;
        arlen_reg  <= BURST_LEN-1;
        arsize_reg <= 3'b010;

    end

end

// Beat Counter

always_ff @(posedge clk or negedge rst)
begin

    if(!rst)

        beat_count <= '0;

    else if(state==IDLE)

        beat_count <= '0;
    else if(rlast)
        beat_count<='0;
    else if(state==READ_DATA && rvalid && rready)

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

            if(read_start)
                next_state = SEND_AR;

        end

        //-------------------------------------
        // SEND READ ADDRESS
       
        SEND_AR:
        begin

            if(arvalid && arready)
                next_state = READ_DATA;

        end

        //-------------------------------------
        // READ DATA
        
        READ_DATA:
        begin
            
            if(rvalid && rready && rlast)
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
    
    araddr = araddr_reg;
    arlen  = arlen_reg;
    arsize = arsize_reg;

    arvalid = 0;

    rready = 0;

    fifo_wr_en   = 0;
    fifo_wr_data = '0;

    read_done = 0;

    
    // State Outputs
    
    case(state)

        //-------------------------------------
        // SEND ADDRESS
        
        SEND_AR:
        begin

            arvalid = 1;

        end

        //-------------------------------------
        // READ DATA
        
        READ_DATA:
        begin

            rready = !fifo_full;
          
            if(rvalid && rready)

            begin
               
                fifo_wr_en   = 1;
                fifo_wr_data = rdata;
                
            end

        end

        //-------------------------------------
        // DONE
       
        DONE:
        begin

            read_done = 1;

        end

        default:;

    endcase

end

endmodule
