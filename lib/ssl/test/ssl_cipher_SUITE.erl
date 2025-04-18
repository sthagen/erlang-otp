%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2008-2025. All Rights Reserved.
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
%%
%% %CopyrightEnd%
%%

-module(ssl_cipher_SUITE).

-behaviour(ct_suite).

-include_lib("common_test/include/ct.hrl").
-include_lib("ssl/src/tls_record.hrl").
-include_lib("ssl/src/ssl_cipher.hrl").
-include_lib("ssl/src/ssl_record.hrl").

%% Callback functions
-export([all/0,
         groups/0,
         init_per_suite/1,
         end_per_suite/1,
         init_per_group/2,
         end_per_group/2,
         init_per_testcase/2,
         end_per_testcase/2]).

%% Testcases
-export([aes_decipher_good/0,
         aes_decipher_good/1,
         aes_decipher_fail/0,
         aes_decipher_fail/1,
         padding_test/1,
         sign_algorithms/1
        ]).


%%--------------------------------------------------------------------
%% Common Test interface functions -----------------------------------
%%--------------------------------------------------------------------
all() ->
    [aes_decipher_good, aes_decipher_fail, padding_test, sign_algorithms].

groups() ->
    [].

init_per_suite(Config) ->
    try application:start(crypto) of
	ok ->
	    Config
    catch _:_  ->
	    {skip, "Crypto did not start"}
    end.

end_per_suite(_Config) ->
    ssl:stop(),
    application:stop(crypto).

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, Config) ->
    Config.

init_per_testcase(_TestCase, Config) ->
    ct:timetrap({seconds, 5}),
    _ = application:load(ssl),
    Previous = case logger:get_module_level(ssl) of
                   [] -> notice;
                   [{ssl,P}] -> P
               end,
    ok = logger:set_application_level(ssl, debug),
    [{app_log_level, Previous}|Config].

end_per_testcase(_TestCase, Config) ->
    Previous = proplists:get_value(app_log_level, Config),
    logger:set_application_level(ssl, Previous),
    Config.

%%--------------------------------------------------------------------
%% Test Cases --------------------------------------------------------
%%--------------------------------------------------------------------
aes_decipher_good() ->
    [{doc,"Decipher a known cryptotext using a correct key"}].

aes_decipher_good(Config) when is_list(Config) ->
    HashSz = 32,
    CipherState = correct_cipher_state(),
    decipher_check_good(HashSz, CipherState, ?TLS_1_0),
    decipher_check_good(HashSz, CipherState, ?TLS_1_1),
    decipher_check_good(HashSz, CipherState, ?TLS_1_2).

%%--------------------------------------------------------------------
aes_decipher_fail() ->
    [{doc,"Decipher a known cryptotext using a incorrect key"}].

aes_decipher_fail(Config) when is_list(Config) ->
    HashSz = 32,
    CipherState = incorrect_cipher_state(),
    decipher_check_fail(HashSz, CipherState, ?TLS_1_0),
    decipher_check_fail(HashSz, CipherState, ?TLS_1_1),
    decipher_check_fail(HashSz, CipherState, ?TLS_1_2).

%%--------------------------------------------------------------------
padding_test(Config) when is_list(Config)  ->
    HashSz = 16,
    CipherState = correct_cipher_state(),
    pad_test(HashSz, CipherState, ?TLS_1_0),
    pad_test(HashSz, CipherState, ?TLS_1_1),
    pad_test(HashSz, CipherState, ?TLS_1_2).

%%--------------------------------------------------------------------
sign_algorithms(Config) when is_list(Config) ->
    [{sha256,rsa_pss_pss},{rsa,sha256}] = ssl_cipher:signature_schemes_1_2([rsa_pss_pss_sha256, {rsa, sha256}]).

%%--------------------------------------------------------------------    
% Internal functions  --------------------------------------------------------
%%--------------------------------------------------------------------
decipher_check_good(HashSz, CipherState, Version) ->
    {Content, _NextIV, Mac} = content_nextiv_mac(Version),
    {Content, Mac, _} = 
	ssl_cipher:decipher(?AES_CBC, HashSz, CipherState, aes_fragment(Version), Version, true).

decipher_check_fail(HashSz, CipherState, Version) ->
    {Content, NextIV, Mac} = content_nextiv_mac(Version),
    true = {Content, Mac, #cipher_state{iv = NextIV}} =/= 
	ssl_cipher:decipher(?AES_CBC, HashSz, CipherState, aes_fragment(Version), Version, true).

pad_test(HashSz, CipherState, ?TLS_1_0 = Version) ->
    %% 3.1 should have padding test, but may be disabled
    {Content, NextIV, Mac} = badpad_content_nextiv_mac(Version),
    BadCont = badpad_content(Content),
    {Content, Mac, #cipher_state{iv = NextIV}} = 
	ssl_cipher:decipher(?AES_CBC, HashSz, CipherState, badpad_aes_fragment(?TLS_1_0) , ?TLS_1_0, false),
    {BadCont, Mac, #cipher_state{iv = NextIV}} = 
	ssl_cipher:decipher(?AES_CBC, HashSz, CipherState, badpad_aes_fragment(?TLS_1_0), ?TLS_1_0, true);
pad_test(HashSz, CipherState, Version) ->
    %% 3.2 and 3.3 must have padding test
    {Content, NextIV, Mac} = badpad_content_nextiv_mac(Version),
    BadCont = badpad_content(Content),
    {BadCont, Mac, #cipher_state{iv = NextIV}} = ssl_cipher:decipher(?AES_CBC, HashSz, CipherState, 
									      badpad_aes_fragment(Version), Version, false),
    {BadCont, Mac, #cipher_state{iv = NextIV}} = ssl_cipher:decipher(?AES_CBC, HashSz, CipherState,  
								     badpad_aes_fragment(Version), Version, true).
    
aes_fragment(?TLS_1_0) ->
    <<197,9,6,109,242,87,80,154,85,250,110,81,119,95,65,185,53,206,216,153,246,169,
      119,177,178,238,248,174,253,220,242,81,33,0,177,251,91,44,247,53,183,198,165,
      63,20,194,159,107>>;
	
aes_fragment(_) ->
    <<220,193,179,139,171,33,143,245,202,47,123,251,13,232,114,8,
      190,162,74,31,186,227,119,155,94,74,119,79,169,193,240,160,
      198,181,81,19,98,162,213,228,74,224,253,168,156,59,195,122,
      108,101,107,242,20,15,169,150,163,107,101,94,93,104,241,165>>.

badpad_aes_fragment(?TLS_1_0) ->
    <<186,139,125,10,118,21,26,248,120,108,193,104,87,118,145,79,225,55,228,10,105,
      30,190,37,1,88,139,243,210,99,65,41>>;
badpad_aes_fragment(_) ->
    <<137,31,14,77,228,80,76,103,183,125,55,250,68,190,123,131,117,23,229,180,207,
      94,121,137,117,157,109,99,113,61,190,138,131,229,201,120,142,179,172,48,77,
      234,19,240,33,38,91,93>>.

content_nextiv_mac(?TLS_1_0) ->
    {<<"HELLO\n">>,
     <<72,196,247,97,62,213,222,109,210,204,217,186,172,184, 197,148>>,
     <<71,136,212,107,223,200,70,232,127,116,148,205,232,35,158,113,237,174,15,217,192,168,35,8,6,107,107,233,25,174,90,111>>};
content_nextiv_mac(_) ->
    {<<"HELLO\n">>,
     <<183,139,16,132,10,209,67,86,168,100,61,217,145,57,36,56>>,
     <<71,136,212,107,223,200,70,232,127,116,148,205,232,35,158,113,237,174,15,217,192,168,35,8,6,107,107,233,25,174,90,111>>}.

badpad_content_nextiv_mac(?TLS_1_0) ->
    {<<"HELLO\n">>,
     <<225,55,228,10,105,30,190,37,1,88,139,243,210,99,65,41>>,
      <<183,139,16,132,10,209,67,86,168,100,61,217,145,57,36,56>>
    };
badpad_content_nextiv_mac(_) ->
    {<<"HELLO\n">>,
     <<133,211,45,189,179,229,56,86,11,178,239,159,14,160,253,140>>,
      <<183,139,16,132,10,209,67,86,168,100,61,217,145,57,36,56>>
    }.

badpad_content(Content) ->
    %% BadContent will fail mac test 
    <<16#F0, Content/binary>>.
  
correct_cipher_state() ->
    #cipher_state{iv = <<59,201,85,117,188,206,224,136,5,109,46,70,104,79,4,9>>,
		  key = <<72,196,247,97,62,213,222,109,210,204,217,186,172,184,197,148>>}.

incorrect_cipher_state() ->
    #cipher_state{iv = <<59,201,85,117,188,206,224,136,5,109,46,70,104,79,4,9>>,
		  key = <<72,196,247,97,62,213,222,109,210,204,217,186,172,184,197,254>>}.
    
