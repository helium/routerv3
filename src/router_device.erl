-module(router_device).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
         new/1,
         id/1,
         name/1, name/2,
         app_eui/1, app_eui/2,
         dev_eui/1, dev_eui/2,
         nwk_s_key/1, nwk_s_key/2,
         app_s_key/1, app_s_key/2,
         join_nonce/1, join_nonce/2,
         fcnt/1, fcnt/2,
         fcntdown/1, fcntdown/2,
         offset/1, offset/2,
         channel_correction/1, channel_correction/2,
         queue/1, queue/2,
         update/2,
         serialize/1, deserialize/1
        ]).

-record(device, {
                 id :: binary() | undefined,
                 name :: binary() | undefined,
                 dev_eui :: binary() | undefined,
                 app_eui :: binary() | undefined,
                 nwk_s_key :: binary() | undefined,
                 app_s_key :: binary() | undefined,
                 join_nonce=0 :: non_neg_integer(),
                 fcnt=0 :: non_neg_integer(),
                 fcntdown=0 :: non_neg_integer(),
                 offset=0 :: non_neg_integer(),
                 channel_correction=false :: boolean(),
                 queue=[] :: [any()]
                }).

-type device() :: #device{}.

-export_type([device/0]).

-spec new(binary()) -> device().
new(ID) ->
    #device{id=ID}.

-spec id(device()) -> binary() | undefined.
id(Device) ->
    Device#device.id.

-spec name(device()) -> binary() | undefined.
name(Device) ->
    Device#device.name.

-spec name(binary(), device()) -> device().
name(Name, Device) ->
    Device#device{name=Name}.

-spec app_eui(device()) -> binary() | undefined.
app_eui(Device) ->
    Device#device.app_eui.

-spec app_eui(binary(), device()) -> device().
app_eui(EUI, Device) ->
    Device#device{app_eui=EUI}.

-spec dev_eui(device()) -> binary() | undefined.
dev_eui(Device) ->
    Device#device.dev_eui.

-spec dev_eui(binary(), device()) -> device().
dev_eui(EUI, Device) ->
    Device#device{dev_eui=EUI}.

-spec nwk_s_key(device()) -> binary() | undefined.
nwk_s_key(Device) ->
    Device#device.nwk_s_key.

-spec nwk_s_key(binary(), device()) -> device().
nwk_s_key(Key, Device) ->
    Device#device{nwk_s_key=Key}.

-spec app_s_key(device()) -> binary() | undefined.
app_s_key(Device) ->
    Device#device.app_s_key.

-spec app_s_key(binary(), device()) -> device().
app_s_key(Key, Device) ->
    Device#device{app_s_key=Key}.

-spec join_nonce(device()) -> non_neg_integer().
join_nonce(Device) ->
    Device#device.join_nonce.

-spec join_nonce(non_neg_integer(), device()) -> device().
join_nonce(Nonce, Device) ->
    Device#device{join_nonce=Nonce}.

-spec fcnt(device()) -> non_neg_integer().
fcnt(Device) ->
    Device#device.fcnt.

-spec fcnt(non_neg_integer(), device()) -> device().
fcnt(Fcnt, Device) ->
    Device#device{fcnt=Fcnt}.

-spec fcntdown(device()) -> non_neg_integer().
fcntdown(Device) ->
    Device#device.fcntdown.

-spec fcntdown(non_neg_integer(), device()) -> device().
fcntdown(Fcnt, Device) ->
    Device#device{fcntdown=Fcnt}.

-spec offset(device()) -> non_neg_integer().
offset(Device) ->
    Device#device.offset.

-spec offset(non_neg_integer(), device()) -> device().
offset(Offset, Device) ->
    Device#device{offset=Offset}.

-spec channel_correction(device()) -> boolean().
channel_correction(Device) ->
    Device#device.channel_correction.

-spec channel_correction(boolean(), device()) -> device().
channel_correction(Correct, Device) ->
    Device#device{channel_correction=Correct}.

-spec queue(device()) -> [any()].
queue(Device) ->
    Device#device.queue.

-spec queue([any()], device()) -> device().
queue(Q, Device) ->
    Device#device{queue=Q}.

-spec update([{atom(), any()}], device()) -> device().
update([], Device) ->
    Device;
update([{name, Value}|T], Device) ->
    update(T, ?MODULE:name(Value, Device));
update([{app_eui, Value}|T], Device) ->
    update(T, ?MODULE:app_eui(Value, Device));
update([{dev_eui, Value}|T], Device) ->
    update(T, ?MODULE:dev_eui(Value, Device));
update([{nwk_s_key, Value}|T], Device) ->
    update(T, ?MODULE:nwk_s_key(Value, Device));
update([{app_s_key, Value}|T], Device) ->
    update(T, ?MODULE:app_s_key(Value, Device));
update([{join_nonce, Value}|T], Device) ->
    update(T, ?MODULE:join_nonce(Value, Device));
update([{fcnt, Value}|T], Device) ->
    update(T, ?MODULE:fcnt(Value, Device));
update([{fcntdown, Value}|T], Device) ->
    update(T, ?MODULE:fcntdown(Value, Device));
update([{offset, Value}|T], Device) ->
    update(T, ?MODULE:offset(Value, Device));
update([{channel_correction, Value}|T], Device) ->
    update(T, ?MODULE:channel_correction(Value, Device));
update([{queue, Value}|T], Device) ->
    update(T, ?MODULE:queue(Value, Device)).

-spec serialize(device()) -> binary().
serialize(Device) ->
    erlang:term_to_binary(Device).

-spec deserialize(binary()) -> device().
deserialize(Binary) ->
    erlang:binary_to_term(Binary).

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

%% ------------------------------------------------------------------
%% EUNIT Tests
%% ------------------------------------------------------------------
-ifdef(TEST).

new_test() ->
    ?assertEqual(#device{id= <<"id">>}, new(<<"id">>)).

name_test() ->
    Device = new(<<"id">>),
    ?assertEqual(undefined, name(Device)),
    ?assertEqual(<<"name">>, name(name(<<"name">>, Device))).

app_eui_test() ->
    Device = new(<<"id">>),
    ?assertEqual(undefined, app_eui(Device)),
    ?assertEqual(<<"app_eui">>, app_eui(app_eui(<<"app_eui">>, Device))).

dev_eui_test() ->
    Device = new(<<"id">>),
    ?assertEqual(undefined, dev_eui(Device)),
    ?assertEqual(<<"dev_eui">>, dev_eui(dev_eui(<<"dev_eui">>, Device))).

nwk_s_key_test() ->
    Device = new(<<"id">>),
    ?assertEqual(undefined, nwk_s_key(Device)),
    ?assertEqual(<<"nwk_s_key">>, nwk_s_key(nwk_s_key(<<"nwk_s_key">>, Device))).

app_s_key_test() ->
    Device = new(<<"id">>),
    ?assertEqual(undefined, app_s_key(Device)),
    ?assertEqual(<<"app_s_key">>, app_s_key(app_s_key(<<"app_s_key">>, Device))).

join_nonce_test() ->
    Device = new(<<"id">>),
    ?assertEqual(0, join_nonce(Device)),
    ?assertEqual(1, join_nonce(join_nonce(1, Device))).

fcnt_test() ->
    Device = new(<<"id">>),
    ?assertEqual(0, fcnt(Device)),
    ?assertEqual(1, fcnt(fcnt(1, Device))).

fcntdown_test() ->
    Device = new(<<"id">>),
    ?assertEqual(0, fcntdown(Device)),
    ?assertEqual(1, fcntdown(fcntdown(1, Device))).

offset_test() ->
    Device = new(<<"id">>),
    ?assertEqual(0, offset(Device)),
    ?assertEqual(1, offset(offset(1, Device))).

channel_correction_test() ->
    Device = new(<<"id">>),
    ?assertEqual(false, channel_correction(Device)),
    ?assertEqual(true, channel_correction(channel_correction(true, Device))).

queue_test() ->
    Device = new(<<"id">>),
    ?assertEqual([], queue(Device)),
    ?assertEqual([a], queue(queue([a], Device))).

update_test() ->
    Device = new(<<"id">>),
    Updates = [
               {name, <<"name">>},
               {app_eui, <<"app_eui">>},
               {dev_eui, <<"dev_eui">>},
               {nwk_s_key, <<"nwk_s_key">>},
               {app_s_key, <<"app_s_key">>},
               {join_nonce, 1},
               {fcnt, 1},
               {fcntdown, 1},
               {offset, 1},
               {channel_correction, true},
               {queue, [a]}
              ],
    UpdatedDevice = #device{
                       id = <<"id">>,
                       name = <<"name">>,
                       app_eui = <<"app_eui">>,
                       dev_eui = <<"dev_eui">>,
                       nwk_s_key = <<"nwk_s_key">>,
                       app_s_key = <<"app_s_key">>,
                       join_nonce = 1,
                       fcnt = 1,
                       fcntdown = 1,
                       offset = 1,
                       channel_correction = true,
                       queue = [a]
                      },
    ?assertEqual(UpdatedDevice, update(Updates, Device)).

serialize_deserialize_test() ->
    Device = new(<<"id">>),
    ?assertEqual(Device, deserialize(serialize(Device))).

-endif.
