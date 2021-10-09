module coin_casher (
    input   clk, power, return_coin, coin_insert, game_finish, // "coin_insert" is high when coin is inserted into the arcade machine 
    input   [2:0] inserted_coin,          // "inserted_coin" tells the Denomination of the coin, 0001 for 5 cents, 010 for 10 cents, 011 for 25 cents, 100 for 1 dollar, 101 for 2 dollar 
    output  reg coin_reject, eat_coins, spit_coin, wait_ready, game_start    // output flags
    //output  reg [3:0] next_state
);
    parameter power_on          = 4'b0000;            // the start-up/fefault state
    parameter wait_game_start   = 4'b0001;            // where FSM wait for coin to be inserted, theoretically the most common state the FSM stay at
    parameter check_coin        = 4'b0010;           // check if the inseted coin is the desired
    parameter spit_all_coin     = 4'b0011;          // return all holding coins to the player
    parameter check_coin_num    = 4'b0100;         // check the number of inserted coin 
    parameter reject_coin       = 4'b0101;        // output flag to reject the inserted coin
    parameter start_game        = 4'b0110;       // tells the game module (dont care in this project) to start 
    //parameter check_fir_coin    = 12'b1000000;
    parameter wait_game_fin     = 4'b0111;     // wait for the game module to finish 
    parameter start_timer       = 4'b1000;    // tell timer to start when palyer inserted the first coin
    parameter incr_coin_count   = 4'b1001;   // the state that increament the count of the inserted coins

    reg [3:0] coin_counter;    // typical arcade machine accepts no more than 8 coins, default setting: accept 2 coins to start 
    reg [3:0] state; 
    //logic [11:0] next_state;

    parameter desired_coin_type = 3'b100;
    parameter desired_coin_num  = 4'd3;

    wire timer_en, reset_timer;
    wire timer_finish;
    timer wait_for_user(
        clk, timer_en, reset_timer,
        timer_finish
    );

    // state transition & counter increament 
    always_ff @(posedge clk, posedge power) begin 
        if (power) begin
            state <= power_on;
            coin_counter <= 4'b0;
        end
        else begin
            case(state)
                power_on:       begin
                    state <= wait_game_start;
                    coin_counter <= 4'd0;
                end
                wait_game_start: begin
                    if(return_coin || timer_finish)
                        state <= spit_all_coin;
                    else if(coin_insert)
                        state <= check_coin;
                    else
                        state <= wait_game_start;
                end
                check_coin: begin
                    if(inserted_coin == desired_coin_type) // default setting: the machine only accept 1 dollar coin
                        state <= check_coin_num;
                    else
                        state <= reject_coin;
                end
                spit_all_coin: begin
                    state <= wait_game_start;
                    coin_counter <= 4'd0;   // reset coin counter
                end 
                check_coin_num: begin
                    if((coin_counter + 1'b1) == desired_coin_num)   // since non-blocking assignment, here need to compare "coin_counter + 1"
                        state <= start_game;
                    else if ((coin_counter + 1'b1) == 4'd1)
                        state <= start_timer;
                    else 
                        state <= incr_coin_count;
                end
                reject_coin:    state <= wait_game_start;
                start_game: begin
                    state <= wait_game_fin;
                    coin_counter <= 4'd0;   // reset coin counter
                end     
                //check_fir_coin:
                wait_game_fin:  state <= game_finish ? wait_game_start : wait_game_fin;
                start_timer:    state <= incr_coin_count;
                incr_coin_count: begin 
                    state <= wait_game_start;
                    coin_counter <= coin_counter + 4'b1;
                end 
                //12'hxxx: state <= power_on;
                default: state <= power_on;
            endcase
        end
    end
    

    reg timer_en_reg, reset_timer_reg;

    assign timer_en = timer_en_reg;
    assign reset_timer = reset_timer_reg;

    always_comb begin 
        case(state)
                power_on:       begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b1;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end
                wait_game_start: begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b1; 
                    game_start   = 1'b0;             
                end
                check_coin: begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;                
                end
                spit_all_coin: begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b1;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end 
                check_coin_num: begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;                
                end
                reject_coin:    begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b1;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end
                start_game: begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b1;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b1;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b1;
                end     
                //check_fir_coin:
                wait_game_fin:  begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b1;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end
                start_timer:    begin
                    timer_en_reg     = 1'b1;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end
                incr_coin_count: begin 
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end 
                //12'hxxx: state <= power_on;
                default: begin
                    timer_en_reg     = 1'b0;
                    reset_timer_reg  = 1'b0;

                    coin_reject  = 1'b0;
                    eat_coins    = 1'b0;
                    spit_coin    = 1'b0;
                    wait_ready   = 1'b0; 
                    game_start   = 1'b0;
                end
            endcase
    end

endmodule

// module that detect coin and tell the main FSM coin type + flag
// all flags is sync with the main FSM
// module insertcoin (
//     input clk, en, coin_reject, eat_coins, 
//     output coin_insert, return_coin, 
//     output [2:0] coin_type
// );
//      ...
// endmodule

// this module helps the FSM to count down, who wait for the customer to insert the rest of the coin
// the parameter makes this FSM count 60s in default (depends on clk frquency)
// all falgs is sync with the main FSM
// We set the period inside .sdc file to be 100ns,
// so to count down 30 seconds. We need to count 30 * 1000 * 10_000 times
// module one_ms (
//     input clk, en, rst,
//     output reg onems
// );
//     parameter tot_count = 10_000;
//     logic [13:0] counter;       // 10000 is "10_011_100_010_000" in binary, which is 14 bits

//     always_ff @( posedge clk, posedge rst ) begin
//         if(rst)
//             counter <= 14'd0;
//         else if(en)
//             counter <= counter + 14'd1;

//         if(counter >= tot_count) begin
//             onems <= 1'b1;
//             counter <= 14'd0;
//         end
//         else
//             onems <= 1'b0;
//     end
// endmodule

// module one_s (
//     input clk, en, rst,
//     output reg ones
// );
//     parameter tot_count = 1000;
//     logic [9:0] counter;       // 1000 is "1_111_101_000" in binary, which is 10 bits

//     logic ms_done, rst_ms;
//     one_ms get_one_ms(      // instantiation
//         clk, en, rst_ms,
//         ms_done
//     );

//     always_ff @( posedge clk, posedge rst) begin
//         if(rst) begin
//             counter <= 10'd0;
//             rst_ms <= 1'b1;
//         end
//         else if(ms_done) begin
//             rst_ms <= 1'b1;
//             counter <= counter + 10'd1;
//         end
//         else
//             rst_ms <= 1'b0;
            
//         if(counter >= tot_count) begin
//             ones <= 1'b1;
//             counter <= 10'd0;
//         end
//         else
//             ones <= 1'b0;
//     end
// endmodule
module timer #(
    parameter count = 30
) (
    input clk, en, rst,
    output reg timer_fin
);
    logic [1:0] state;
    logic [28:0] counter;    // 300_000_000 is 29 bits in decimal

    parameter wait4start    = 2'b01;
    parameter counting      = 2'b10;
    parameter done          = 2'b11;

    // logic rst_s, start, s_done;
    // one_s get_one_s(
    //     clk, start, rst_s,
    //     s_done
    // );

    always_ff @( posedge clk, posedge rst ) begin
        if(rst) begin
            counter <= 8'd0;
            state <= wait4start;
            timer_fin <= 1'b0;
        end
        else begin
            case(state)
            wait4start: begin
                state <= en ? counting : wait4start;
                timer_fin <= 1'b0;
            end
            counting: begin
                if(counter >= (count * 24'd10_000_000)) begin
                    state <= done;
                end
                else begin
                    state <= counting;
                    counter <= counter + 29'd1;
                end
                timer_fin <= 1'b0;
            end
            done: begin
                counter <= 8'd0;
                state <= wait4start;
                timer_fin <= 1'b1;
            end
            endcase
        end
    end
endmodule

// the game module that start the game when prompt by the coin casher FSM
// also tell the FSM whenn the game is finished
// all flags is sync with the main FSM
// module game (
//     input clk, start,
//     output finish
// );
    
// endmodule
