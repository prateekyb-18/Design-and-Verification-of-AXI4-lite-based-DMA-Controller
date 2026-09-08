module cfsm(

    input logic clk,
    input logic rst_n,

    input logic start,

    input logic fifo_empty,
    input logic fifo_full,

    input logic read_done,
    input logic write_done,

    input logic transfer_done,

    output logic load_config,
    output logic read_start,
    output logic write_start,
    output logic update_addr,
    output logic dma_done,
    output logic [3:0]state_dbg

);

typedef enum logic [3:0] {

    IDLE,
    LOAD_CONFIG,

    WAIT_FIFO_SPACE,
    READ_BURST,
    WAIT_READ,

    WAIT_FIFO_DATA,
    WRITE_BURST,

    CHECK_DONE,
    DONE

} state_t;

state_t state;
state_t next_state;
assign state_dbg=state;

// State Register


always_ff @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;

end


// Next State Logic

always_comb
begin

    next_state = state;

    case(state)

        
        IDLE:
        
        begin
            if(start)
                next_state = LOAD_CONFIG;
        end

        //-------------------------------------
        LOAD_CONFIG:
       
        begin
            next_state = WAIT_FIFO_SPACE;
        end

        //-------------------------------------
        WAIT_FIFO_SPACE:
        
        begin
            if(!fifo_full)
                next_state = READ_BURST;
        end

        //-------------------------------------
        READ_BURST:
        
        begin
            next_state = WAIT_READ;
        end

        //-------------------------------------
        WAIT_READ:
  
        begin
            if(read_done)
                next_state = WAIT_FIFO_DATA;
        end

        //-------------------------------------
        WAIT_FIFO_DATA:
       
        begin
            if(!fifo_empty)
                next_state = WRITE_BURST;
        end

        //-------------------------------------
        WRITE_BURST:
        
        begin
            if(write_done)
                next_state = CHECK_DONE;
        end

        //-------------------------------------
        CHECK_DONE:
      
        begin

            if(transfer_done)
                next_state = DONE;
            else
                next_state = WAIT_FIFO_SPACE;

        end

        //-------------------------------------
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

    load_config = 0;
    read_start  = 0;
    write_start = 0;
    update_addr = 0;
    dma_done    = 0;

    case(state)

        LOAD_CONFIG:
            load_config = 1;

        READ_BURST:
            read_start = 1;

        WRITE_BURST:
            write_start = 1;

        CHECK_DONE:
            update_addr = 1;

        DONE:
            dma_done = 1;

        default: ;

    endcase

end

endmodule
