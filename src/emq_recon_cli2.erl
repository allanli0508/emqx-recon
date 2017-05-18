%%--------------------------------------------------------------------
%% Copyright (c) 2013-2017 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emq_recon_cli2).

-export([register_cli/0, unregister_cli/0]).

-include_lib("emqttd/include/emqttd_cli.hrl").

-export([run/1]).

-behaviour(clique_handler).

-import(proplists, [get_value/2]).

register_cli() ->
    F = fun() -> emqttd_mnesia:running_nodes() end,
    clique:register_node_finder(F),
    clique:register_usage(["recon"], recon_usage()),
    register_cmd().

run(Cmd) ->
    clique:run(Cmd).

register_cmd() ->
    recon_memory(),
    recon_allocated(),
    recon_bin_leak(),
    recon_node_stats(),
    recon_remote_load().

unregister_cli() ->
    clique:unregister_usage(["recon"]),
    unregister_cmd().

unregister_cmd() ->
    clique:unregister_command(["recon", "memory"]),
    clique:unregister_command(["recon", "allocated"]),
    clique:unregister_command(["recon", "bin_leak"]),
    clique:unregister_command(["recon", "node_stats"]),
    clique:unregister_command(["recon", "remote_load"]).

recon_memory() ->
    Cmd = ["recon", "memory"],
    Callback =
        fun (_, _, _) ->
            Print = fun(Key, Keyword) ->
                    io_lib:format("~-20s: ~w~n", [concat(Key, Keyword), recon_alloc:memory(Key, Keyword)])
                    end,
            Text = [Print(Key, Keyword) || Key <- [usage, used, allocated, unused],
                            Keyword <- [current, max]],
            [clique_status:text(Text)]
        end,
    clique:register_command(Cmd, [], [], Callback).

recon_allocated() ->
    Cmd = ["recon", "allocated"],
    Callback =
        fun (_, _, _) ->
            Print = fun(Keyword, Key, Val) ->
                    io_lib:format("~-20s: ~w~n", [concat(Key, Keyword), Val])
                    end,
            Alloc = fun(Keyword) -> recon_alloc:memory(allocated_types, Keyword) end,
            Text = [Print(Keyword, Key, Val) || Keyword <- [current, max],
                                 {Key, Val} <- Alloc(Keyword)],
            [clique_status:text(Text)]
        end,
    clique:register_command(Cmd, [], [], Callback).

recon_bin_leak() ->
    Cmd = ["recon", "bin_leak"],
    Callback = 
        fun(_, _, _) ->
        Text = [io_lib:format("~p~n", [Row]) || Row <- recon:bin_leak(100)],
        [clique_status:text(Text)]
        end,
    clique:register_command(Cmd, [], [], Callback).

recon_node_stats() ->
    Cmd = ["recon", "node_stats"],
    Callback = 
        fun(_, _, _) ->
        Text = recon:node_stats_print(10, 1000),
        [clique_status:text(Text)]
        end,
    clique:register_command(Cmd, [], [], Callback).

recon_remote_load() ->
    Cmd = ["recon", "remote_load"],
    KeySpecs = [{'mod', [{typecast, fun(Mod) -> list_to_atom(Mod) end}]}],
    Callback = fun(_, Params, _) ->
                Text = 
                case get_value('mod', Params) of
                undefined ->
                    recon_usage();
                Mod ->
                    case catch recon:remote_load(Mod) of
                        {[],[]} -> io_lib:format("The Mod: ~p load successfully", [Mod]);
                        {'EXIT', Reason} -> io_lib:format("The Mod: ~p load error: ~p", [Mod, Reason])
                    end
               end,
               [clique_status:text(Text)]
               end,
    clique:register_command(Cmd, KeySpecs, [], Callback).

recon_usage() ->
    ["\nrecon memory                recon_alloc:memory/2\n",
     "recon allocated             recon_alloc:memory(allocated_types, current|max)\n",
     "recon bin_leak              recon:bin_leak(100)\n",
     "recon node_stats            recon:node_stats(10, 1000)\n",
     "recon remote_load mod=<Mod> recon:remote_load(Mod)\n"].

concat(Key, Keyword) ->
    lists:concat([atom_to_list(Key), "/", atom_to_list(Keyword)]).
