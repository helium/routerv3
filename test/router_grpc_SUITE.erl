-module(router_grpc_SUITE).

-export([
    all/0,
    init_per_testcase/2,
    end_per_testcase/2
]).

-export([
    join_grpc_test/1,
    join_from_unknown_device_grpc_test/1,
    packet_from_known_device_no_downlink/1
]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include("lorawan_vars.hrl").
-include("console_test.hrl").

%%--------------------------------------------------------------------
%% COMMON TEST CALLBACK FUNCTIONS
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% @public
%% @doc
%%   Running tests for this suite
%% @end
%%--------------------------------------------------------------------
all() ->
    [
        join_grpc_test,
        join_from_unknown_device_grpc_test,
        packet_from_known_device_no_downlink
    ].

%%--------------------------------------------------------------------
%% TEST CASE SETUP
%%--------------------------------------------------------------------
init_per_testcase(TestCase, Config) ->
    %% setup test dirs
    Config0 = test_utils:init_per_testcase(TestCase, Config),
    Config0.

%%--------------------------------------------------------------------
%% TEST CASE TEARDOWN
%%--------------------------------------------------------------------
end_per_testcase(TestCase, Config) ->
    test_utils:end_per_testcase(TestCase, Config).

%%--------------------------------------------------------------------
%% TEST CASES
%%--------------------------------------------------------------------

%% send a packet from a known device
%% verify we get a response
join_grpc_test(Config) ->
    AppKey = proplists:get_value(app_key, Config),
    {ok, PubKey, SigFun, _} = blockchain_swarm:keys(),
    PubKeyBin = libp2p_crypto:pubkey_to_bin(PubKey),

    %% create a join packet
    JoinNonce = crypto:strong_rand_bytes(2),

    {ok, #{msg := {response, ResponseMsg}} = Result, #{headers := Headers, trailers := _Trailers}} = helium_router_client:route(
        join_packet_map(PubKeyBin, SigFun, AppKey, JoinNonce, -40)
    ),
    ct:pal("Response Headers: ~p", [Headers]),
    ct:pal("Response Body: ~p", [Result]),
    #{<<":status">> := HttpStatus} = Headers,
    ?assertEqual(HttpStatus, <<"200">>),
    ?assertEqual(ResponseMsg, ResponseMsg#{accepted := true}),

    ok.

%% send a packet from an unknown device
%% we will fail to get a response
join_from_unknown_device_grpc_test(_Config) ->
    {ok, PubKey, SigFun, _} = blockchain_swarm:keys(),
    PubKeyBin = libp2p_crypto:pubkey_to_bin(PubKey),

    %% create a join packet
    JoinNonce = crypto:strong_rand_bytes(2),
    BadAppKey = crypto:strong_rand_bytes(16),

    {error, {_ErrorCode, ResponseMsg}, #{headers := Headers, trailers := _Trailers}} = helium_router_client:route(
        join_packet_map(PubKeyBin, SigFun, BadAppKey, JoinNonce, -40)
    ),
    ct:pal("Response Headers: ~p", [Headers]),
    ct:pal("Response Body: ~p", [ResponseMsg]),
    #{<<":status">> := HttpStatus} = Headers,
    ?assertEqual(HttpStatus, <<"200">>),
    ?assertEqual(ResponseMsg, <<"not_found">>),

    ok.

packet_from_known_device_no_downlink(Config) ->
    AppKey = proplists:get_value(app_key, Config),
    {ok, PubKey, SigFun, _} = blockchain_swarm:keys(),
    PubKeyBin = libp2p_crypto:pubkey_to_bin(PubKey),

    %% create a join packet
    JoinNonce = crypto:strong_rand_bytes(2),

    {ok, #{msg := {response, ResponseMsg}}, #{headers := Headers, trailers := _Trailers}} = helium_router_client:route(
        join_packet_map(PubKeyBin, SigFun, AppKey, JoinNonce, -40)
    ),
    #{<<":status">> := HttpStatus} = Headers,
    ?assertEqual(HttpStatus, <<"200">>),
    ?assertEqual(ResponseMsg, ResponseMsg#{accepted := true}),

    %% We are joined
    {ok, DB, CF} = router_db:get_devices(),
    WorkerID = router_devices_sup:id(?CONSOLE_DEVICE_ID),
    {ok, Device} = router_device:get_by_id(DB, CF, WorkerID),

    %% Send first packet to get CFList response
    timer:sleep(router_utils:frame_timeout()),
    {ok, #{msg := {response, Resp0}}, #{headers := Headers1}} = helium_router_client:route(
        data_packet_map(
            ?UNCONFIRMED_UP,
            1,
            PubKeyBin,
            Device,
            SigFun,
            #{}
        )
    ),

    #{<<":status">> := HttpStatus1} = Headers1,
    ?assertEqual(HttpStatus1, <<"200">>),
    ?assertEqual(Resp0, Resp0#{accepted := true}),

    %% Send another uplink now that we have our cflist, confirming the change, we expect no downlink
    timer:sleep(router_utils:frame_timeout()),
    {ok, #{msg := {response, Resp1}}, #{}} = helium_router_client:route(
        data_packet_map(
            ?UNCONFIRMED_UP,
            2,
            PubKeyBin,
            Device,
            SigFun,
            #{fopts => [{link_adr_ans, 1, 1, 1}]}
        )
    ),

    ?assertEqual(Resp1, Resp1#{accepted := true}),
    ?assertNot(maps:is_key(downlink, Resp1)),

    ok.

%% ------------------------------------------------------------------
%% Helper functions
%% ------------------------------------------------------------------

join_packet_map(PubKeyBin, SigFun, AppKey, DevNonce, RSSI) ->
    RoutingInfo = {devaddr, 1},
    PacketMap = #{
        oui => 0,
        type => lorawan,
        payload => test_utils:join_payload(AppKey, DevNonce),
        timestamp => 1000,
        signal_strength => RSSI,
        frequency => 923.3,
        datarate => <<"SF8BW125">>,
        snr => 0.0,
        routing => #{data => RoutingInfo},
        rx2_window => undefined
    },
    SCPacketMap0 = #{
        packet => PacketMap,
        hotspot => PubKeyBin,
        region => 'US915',
        hold_time => 100
    },
    Signature = signature(SCPacketMap0, SigFun),
    PacketMap1 = maps:put(signature, Signature, SCPacketMap0),
    #{msg => {packet, PacketMap1}}.

data_packet_map(MType, Fcnt, PubKeyBin, Device, SigFun, Options) ->
    DevAddr0 = <<33554431:25/integer-unsigned-little, $H:7/integer>>,
    <<DevAddr:32/integer-unsigned-little>> = DevAddr0,
    PMap = #{
        oui => 0,
        type => lorawan,
        timestamp => 1000,
        signal_strength => -40,
        frequency => 923.3,
        datarate => <<"SF8BW125">>,
        snr => 0.0,
        routing => #{data => {devaddr, DevAddr}},
        rx2_window => undefined,
        %%
        payload => test_utils:frame_payload(
            MType,
            DevAddr0,
            router_device:nwk_s_key(Device),
            router_device:app_s_key(Device),
            Fcnt,
            Options
        )
    },
    SCPMap = #{packet => PMap, hotspot => PubKeyBin, region => 'US915', hold_time => 100},
    Signature = signature(SCPMap, SigFun),
    PacketMap = maps:put(signature, Signature, SCPMap),

    #{msg => {packet, PacketMap}}.

signature(SCPacketMap, SigFun) ->
    #{
        packet := #{
            type := Type,
            payload := Payload,
            timestamp := Timestamp,
            signal_strength := RSSI,
            frequency := Frequency,
            datarate := DataRate,
            snr := SNR,
            routing := #{data := RoutingInfo}
        },
        hotspot := Hotspot,
        region := Region,
        hold_time := HoldTime
    } = SCPacketMap,
    Packet = blockchain_helium_packet_v1:new(
        Type, Payload, Timestamp, RSSI, Frequency, DataRate, SNR, RoutingInfo
    ),
    SCPacket = blockchain_state_channel_packet_v1:new(Packet, Hotspot, Region, HoldTime),
    SignedSCPacket = blockchain_state_channel_packet_v1:sign(SCPacket, SigFun),
    blockchain_state_channel_packet_v1:signature(SignedSCPacket).
