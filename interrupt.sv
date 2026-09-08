module interrupt(

input logic clk,

input logic rst_n,

input logic dma_done,

input logic irq_enable,

input logic irq_clear,

output logic irq);



always_ff@ (posedge clk or negedge rst_n)

begin

if (!rst_n)

begin

irq <= 1'b0;

end

else if (dma_done && irq_enable)

begin

irq <= 1'b1;

end

else if (irq_clear)

begin irq <=1'b0;

end

end

endmodule
