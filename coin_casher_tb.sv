`timescale 1ns/10ps
module coin_casher_tb;
    logic    clk_tb, power_tb, return_coin_tb, coin_insert_tb, game_finish_tb;
    logic    [2:0] inserted_coin_tb;
    logic    coin_reject_tb, eat_coins_tb, spit_coin_tb, wait_ready_tb, game_start_tb;
    //logic    [3:0] next_state_tb;

    coin_casher DUT1(
        clk_tb, power_tb, return_coin_tb, coin_insert_tb, game_finish_tb, 
        inserted_coin_tb,          
        coin_reject_tb, eat_coins_tb, spit_coin_tb, wait_ready_tb, game_start_tb
        //next_state_tb
    );

    initial forever begin
        clk_tb = 1'b0;  #5;
        clk_tb = 1'b1;  #5;
    end

    initial begin
        // initialize state with a rst signal
        power_tb = 1'b1;
        #30;
        power_tb = 1'b0;

        // testing FSM with no input on high, 
        // the state should transition to "wait_game_start" and stay in it (12'b1)
        // output flag "wait_ready" should be 1
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b0;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b0;
        #20;    // @20ns

        // testing return coin function, 
        // expected state trans:
        // wait_game_start(12'b1) --> spit_all_coin (12'b100) --> wait_game_start(12'b1),
        // output flags: "spit_coins", "reset_timer" becomes high @ "spit_all_coin(12'b100)"
        return_coin_tb  = 1'b1;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b0;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b0;
        #10;
        return_coin_tb  = 1'b0;
        #10;    // @40ns

        // testing insert coin function,
        // first, insert a wrong coin type
        // expected state trans:
        // wait_game_start(12'b1) --> check_coin(12'b10) --> reject_coin(12'b10000) --> wait_game_start(12'b1)
        // output flag: "coin_reject" becomes high @ "reject_coin(12'b10000)"
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b1;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b1;  // 5 cents
        #10;
        coin_insert_tb = 1'b0;
        #30;    // @80ns
        // then, insert a correct coin 
        // expected state trans:
        // wait_game_start(12'b1) --> check_coin(12'b10) --> check_coin_num(12'b1000) --> 
        // start_timer(12'b100000000) --> incr_coin_count(12'b1000000000) --> wait_game_start(12'b1)
        // output flag: "timer_enable" becomes high @ "start_timer(12'b100000000)"
        // coin_counter should increament after "incr_coin_count(12'b1000000000)"
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b1;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b100;    // 1 dollar
        #10;
        coin_insert_tb = 1'b0;
        #50;    // @140ns
        // then, insert another coin (we need three in total)
        // this time we will skip the "timer_start" statr
        // expected state trans:
        // wait_game_start(12'b1) --> check_coin(12'b10) --> check_coin_num(12'b1000) --> 
        // incr_coin_count(12'b1000000000) --> wait_game_start(12'b1)
        // output flag: NO CHANGE
        // coin_counter should increament after "incr_coin_count(12'b1000000000)"
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b1;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b100;    // 1 dollar
        #10;
        coin_insert_tb = 1'b0;
        #50;    // @200ns
        // then, insert another coin,
        // this time the game shall start
        // expected state trans:
        // wait_game_start(12'b1) --> check_coin(12'b10) --> check_coin_num(12'b1000) --> 
        // start_game(12'b100000) --> wait_game_fin(12'b10000000) <--> loop back
        // output flag: "game_start", "eat_coins", "reset_timer", and "coin_reject" should be high @ "start_game(12'b100000)"
        // coin counter should be 0 @ "start_game(12'b100000)" 
        // the state should loop in wait_game_fin(12'b10000000) until "game_finish" is high
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b1;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b100;    // 1 dollar
        #10;
        coin_insert_tb = 1'b0;
        #60;    // @270ns
        // tell the FSM play has finish the game, reset 
        game_finish_tb  = 1'b1;
        #10;
        game_finish_tb  = 1'b0;
        #10;    // @290ns

        // testing time out function,
        // first insert a coin, 
        // then wait till time out (external timeout flag)
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b0;
        coin_insert_tb  = 1'b1;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b100;    // 1 dollar
        #10;
        coin_insert_tb = 1'b0;
        #50;    // @350ns
        // expected state trans:
        // wait_game_start(12'b1) --> spit_all_coin (12'b100) --> wait_game_start(12'b1),
        // output flags: "spit_coins", "reset_timer" becomes high @ "spit_all_coin(12'b100)"
        // coin count reset to 0
        return_coin_tb  = 1'b0;
        //timer_finish_tb = 1'b1;
        coin_insert_tb  = 1'b0;
        game_finish_tb  = 1'b0;
        inserted_coin_tb   = 3'b000;
        #10;
        //timer_finish_tb = 1'b0;
        #20;    // @380ns
        $stop;
    end

endmodule