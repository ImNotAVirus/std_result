defmodule ResultStd do
  @moduledoc """
  TODO: Documentation for `ResultStd`.
  """

  @type ok :: {:ok, any()}
  @type err :: {:error, any()}
  @type result :: ok() | err()

  ## Public API - Macros

  defmacro ok!(term), do: {:ok, term}
  defmacro err!(term), do: {:error, term}
  defmacro unit!(), do: Macro.escape(unit())

  ## Public API - Functions

  @spec ok(any()) :: ok()
  def ok(term), do: ok!(term)

  @spec err(any()) :: err()
  def err(term), do: err!(term)

  @spec unit() :: {}
  def unit(), do: {}

  @spec is_ok(result()) :: boolean()
  def is_ok(ok!(_term)), do: true
  def is_ok(err!(_reason)), do: false

  @spec is_ok_and(result(), (any() -> boolean())) :: boolean()
  def is_ok_and(ok!(term), fun), do: fun.(term)
  def is_ok_and(err!(_reason), _fun), do: false

  @spec is_err(result()) :: boolean()
  def is_err(ok!(_term)), do: false
  def is_err(err!(_reason)), do: true

  @spec is_err_and(result(), (any() -> boolean())) :: boolean()
  def is_err_and(ok!(_term), _fun), do: false
  def is_err_and(err!(reason), fun), do: fun.(reason)

  @spec map(result(), (any() -> any())) :: result()
  def map(ok!(term), fun), do: term |> fun.() |> ok!()
  def map(err!(_reason) = error, _fun), do: error

  @spec map_or(result(), any(), (any() -> any())) :: any()
  def map_or(ok!(term), _default, fun), do: fun.(term)
  def map_or(err!(_reason), default, _fun), do: default

  @spec map_or_else(result(), (any() -> any()), (any() -> any())) :: any()
  def map_or_else(ok!(term), _default, fun), do: fun.(term)
  def map_or_else(err!(reason), default, _fun), do: default.(reason)

  @spec map_err(result(), (any() -> any())) :: result()
  def map_err(ok!(_term) = ok, _fun), do: ok
  def map_err(err!(reason), fun), do: reason |> fun.() |> err!()

  @spec inspect(result(), (any() -> any())) :: result()
  def inspect(result, fun) do
    case result do
      ok!(term) -> fun.(term)
      _ -> :ok
    end

    result
  end

  @spec inspect_err(result(), (any() -> any())) :: result()
  def inspect_err(result, fun) do
    case result do
      err!(reason) -> fun.(reason)
      _ -> :ok
    end

    result
  end

  ###

  @spec and_then(result(), (any() -> result())) :: result()
  def and_then(ok!(term), fun), do: fun.(term)
  def and_then(err!(_reason) = error, _fun), do: error

  @spec or_else(result(), (any() -> result())) :: result()
  def or_else(ok!(_term) = ok, _fun), do: ok
  def or_else(err!(reason), fun), do: fun.(reason)

  @spec unwrap_or_else(result(), (any() -> any())) :: any()
  def unwrap_or_else(ok!(term), _fun), do: term
  def unwrap_or_else(err!(reason), fun), do: fun.(reason)

  @spec unwrap(ok()) :: any()
  def unwrap(ok!(term)), do: term

  @spec partition_result([result()]) :: {[ok()], [err()]}
  def partition_result(results) do
    {oks, errors} =
      Enum.reduce(results, {[], []}, fn
        ok!(ok), {os, es} -> {[ok | os], es}
        err!(err), {os, es} -> {os, [err | es]}
      end)

    {Enum.reverse(oks), Enum.reverse(errors)}
  end
end
