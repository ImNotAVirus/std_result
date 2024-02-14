# StdResult

<!-- MDOC !-->

[![Hex.pm version](https://img.shields.io/hexpm/v/std_result.svg?style=flat)](https://hex.pm/packages/std_result)
[![Hex.pm license](https://img.shields.io/hexpm/l/std_result.svg?style=flat)](https://hex.pm/packages/std_result)
[![Build Status](https://github.com/ImNotAVirus/std_result/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/ImNotAVirus/std_result/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/ImNotAVirus/std_result/badge.svg?branch=main)](https://coveralls.io/github/ImNotAVirus/std_result?branch=main)

## Table of Contents

* [Description](#description)
* [Installation](#installation)
* [The original issue](#the-original-issue)
* [Usage](#usage)
* [Contributing](#contributing)

## Description

`StdResult` is a library heavily inspired by Rust's `Result` type for handling 
function results in a consistent manner in Elixir.

Handling function results in Elixir can sometimes be inconsistent, with some 
functions returning `:ok` or `:error`, while others return tuples like 
`{:ok, term}` or `{:error, reason}`.

`StdResult` provides macros and functions to create and manipulate results,
promoting a unified approach to error handling.

Detailed documentation can be found at [https://hexdocs.pm/std_result](https://hexdocs.pm/std_result).

## Installation

Add `std_result` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:std_result, "~> 0.1"}
  ]
end
```

And that's all.

## The original issue

Let's take a simple example.  
Let's say we need to retrieve an environment variable, convert it to an integer 
and check that it's positive. Our function should return `{:ok, value}` or 
`{:error, reason}`.

One of the most popular solutions is to use `with` which would give something like: 

```elixir
with {:ok, port_str} <- System.fetch_env("PORT"),
     port when port > 0 <- String.to_integer(port_str) do
  {:ok, port}
else
  # Return by System.fetch_env/1
  :error -> {:error, "PORT env required"}
  # Returned by `port when port > 0`
  value when is_integer(value) -> {:error, "PORT must be a positive number, got: #{value}"}
end
```

I think you're beginning to understand what I'm getting at.  
Here our error handling is very complicated to reread because the returns of the 
functions used in the `with` are not normalized.

This is a simple example, but the more conditions there are, the more confusing 
the `else` block becomes.

The simplest solution would be to wrap each function in another, normalizing the 
returns. But you'd soon find yourself with lots of functions that just normalize 
each other's returns.

`StdResult` overcomes this problem.

## Usage

Here is the same problem as above, but with `StdResult` :

```elixir
import StdResult

System.fetch_env("PORT")
# This will transform `:error` into a `:error` tuple
|> normalize_result()
# If there is an error, explicit the message
|> or_result(err("PORT env required"))
# If no error, parse the string as an integer
# We could also have used `Integer.parse/1` but for simplicity's sake we won't.
|> map(&String.to_integer/1)
# Test if the number is positive
|> and_then(&(if &1 >= 0, do: ok(&1), else: err("PORT must be a positive number, got: #{&1}")))

# The result will be either:
# - `{:ok, port}`
# - `{:error, "PORT env required"}`
# - `{:error, "PORT must be a positive number, got: <value>"}`
```

**NOTE**: This lib is not intended to replace `with`, but rather to complement it in certain cases.

# Contributing

Contributions are welcome and appreciated. If you have any ideas, suggestions, or bugs to report,
please open an issue or a pull request on GitHub.
