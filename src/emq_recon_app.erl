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

-module(emq_recon_app).

-behaviour(application).

-author("Feng Lee <feng@emqtt.io>").

%% Application callbacks
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    emq_recon_cli:load(),
    emq_recon_cli2:register_cli(),
    emq_recon_sup:start_link().

stop(_State) ->
    emq_recon_cli:unload(),
    emq_recon_cli2:unregister_cli().

