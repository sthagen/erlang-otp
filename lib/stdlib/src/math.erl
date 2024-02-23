%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1996-2024. All Rights Reserved.
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
-module(math).
-moduledoc """
Mathematical functions.

This module provides an interface to a number of mathematical functions.
For details about what each function does, see the the C library documentation
on your system. On Unix systems the easiest way it to run `man sin`. On
Windows you should check the [Math and floating-point support](https://learn.microsoft.com/en-us/cpp/c-runtime-library/floating-point-support)
documentation.

## Limitations

As these are the C library, the same limitations apply.
""".

-export([pi/0,tau/0]).

%%% BIFs

-export([sin/1, cos/1, tan/1, asin/1, acos/1, atan/1, atan2/2, sinh/1,
         cosh/1, tanh/1, asinh/1, acosh/1, atanh/1, exp/1, log/1,
         log2/1, log10/1, pow/2, sqrt/1, erf/1, erfc/1,
         ceil/1, floor/1,
         fmod/2]).

-doc "Inverse cosine of `X`, return value is in radians.".
-spec acos(X) -> float() when
      X :: number().
acos(_) ->
    erlang:nif_error(undef).

-doc "Inverse hyperbolic cosine of `X`.".
-spec acosh(X) -> float() when
      X :: number().
acosh(_) ->
    erlang:nif_error(undef).

-doc "Inverse sine of `X`, return value is in radians.".
-spec asin(X) -> float() when
      X :: number().
asin(_) ->
    erlang:nif_error(undef).

-doc "Inverse hyperbolic sine of `X`.".
-spec asinh(X) -> float() when
      X :: number().
asinh(_) ->
    erlang:nif_error(undef).

-doc "Inverse tangent of `X`, return value is in radians.".
-spec atan(X) -> float() when
      X :: number().
atan(_) ->
    erlang:nif_error(undef).

-doc "Inverse 2-argument tangent of `X`, return value is in radians.".
-spec atan2(Y, X) -> float() when
      Y :: number(),
      X :: number().
atan2(_, _) ->
    erlang:nif_error(undef).

-doc "Inverse hyperbolic tangent of `X`.".
-spec atanh(X) -> float() when
      X :: number().
atanh(_) ->
    erlang:nif_error(undef).

-doc "The ceiling of `X`.".
-doc(#{since => <<"OTP 20.0">>}).
-spec ceil(X) -> float() when
      X :: number().
ceil(_) ->
    erlang:nif_error(undef).

-doc "The cosine of `X` in radians.".
-spec cos(X) -> float() when
      X :: number().
cos(_) ->
    erlang:nif_error(undef).

-doc "The hyperbolic cosine of `X`.".
-spec cosh(X) -> float() when
      X :: number().
cosh(_) ->
    erlang:nif_error(undef).

-doc """
Returns the error function (or Gauss error function) of `X`.

Where:

```text
erf(X) = 2/sqrt(pi)*integral from 0 to X of exp(-t*t) dt.
```
""".
-spec erf(X) -> float() when
      X :: number().
erf(_) ->
    erlang:nif_error(undef).

-doc """
[`erfc(X)`](`erfc/1`) returns `1.0` - [`erf(X)`](`erf/1`), computed by methods
that avoid cancellation for large `X`.
""".
-spec erfc(X) -> float() when
      X :: number().
erfc(_) ->
    erlang:nif_error(undef).

-doc """
Raise e by `X`, that is `eˣ`.

Where e is the base of the natural logarithm.
""".
-spec exp(X) -> float() when
      X :: number().
exp(_) ->
    erlang:nif_error(undef).

-doc "The floor of `X`.".
-doc(#{since => <<"OTP 20.0">>}).
-spec floor(X) -> float() when
      X :: number().
floor(_) ->
    erlang:nif_error(undef).

-doc "Returns `X` modulus `Y`.".
-doc(#{since => <<"OTP 20.0">>}).
-spec fmod(X, Y) -> float() when
      X :: number(), Y :: number().
fmod(_, _) ->
    erlang:nif_error(undef).

-doc "The natural (base-e) logarithm of `X`.".
-spec log(X) -> float() when
      X :: number().
log(_) ->
    erlang:nif_error(undef).

-doc "The base-2 logarithm of `X`.".
-doc(#{since => <<"OTP 18.0">>}).
-spec log2(X) -> float() when
      X :: number().
log2(_) ->
    erlang:nif_error(undef).

-doc "The base-10 logarithm of `X`.".
-spec log10(X) -> float() when
      X :: number().
log10(_) ->
    erlang:nif_error(undef).

-doc "Raise `X` by `N`, that is `xⁿ`.".
-spec pow(X, N) -> float() when
      X :: number(),
      N :: number().
pow(_, _) ->
    erlang:nif_error(undef).

-doc "Sine of `X` in radians.".
-spec sin(X) -> float() when
      X :: number().
sin(_) ->
    erlang:nif_error(undef).

-doc "Hyperbolic sine of `X`.".
-spec sinh(X) -> float() when
      X :: number().
sinh(_) ->
    erlang:nif_error(undef).

-doc "Square root of `X`.".
-spec sqrt(X) -> float() when
      X :: number().
sqrt(_) ->
    erlang:nif_error(undef).

-doc "Tangent of `X` in radians.".
-spec tan(X) -> float() when
      X :: number().
tan(_) ->
    erlang:nif_error(undef).

-doc "Hyperbolic tangent of `X`.".
-spec tanh(X) -> float() when
      X :: number().
tanh(_) ->
    erlang:nif_error(undef).

%%% End of BIFs

-doc """
Ratio of the circumference of a circle to its diameter.

Floating point approximation of mathematical constant pi.
""".
-spec pi() -> float().
pi() -> 3.1415926535897932.

-doc """
Ratio of the circumference of a circle to its radius.

This constant is equivalent to a full turn when described in radians.

The same as `2 * pi()`.
""".
-doc(#{since => <<"OTP 26.0">>}).
-spec tau() -> float().
tau() -> 6.2831853071795864.
