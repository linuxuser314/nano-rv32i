//The ALU and Comparator unit. Provides addition/subtraction and branch condition evaluation/set less than.

module ALU_comparator(input  logic[31:0] a, b,
                      input  logic       eq, lt, ltu, negate, sub,
                      output logic[31:0] ALU_result,
                      output logic       comparison_flag);
    //ALU flags
    logic Z, V, N, C;

    //Returns a + b if sub is false and a + ~b + 1 (a - b) if sub is true
    adder(
        .a(a), .b(b), .result(ALU_result), .cin(sub), .cout(C)
    );

    //Calculate the comparison results by checking the eq/lt/ltu flags and then negate the result using XOR if negate is set.
    //Zeros are checked using OR reduction operator. S is the sign bit. Z is the zero flag.

    assign Z = ~(|ALU_result);
    assign N = ALU_result[31];
    assign V = (a[31] ^ b[31]) & (a[31] ^ ALU_result[31]);
    assign comparison_result = negate ^ (
                                     eq  & (Z) |
                                     lt  & (N ^ V) |
                                     ltu & (~C)
                                        );
endmodule
