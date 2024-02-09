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
  def ok(term), do: {:ok, term}

  @spec err(any()) :: err()
  def err(term), do: {:error, term}

  @spec unit() :: {}
  def unit(), do: {}

  @spec is_ok(result()) :: boolean()
  def is_ok({:ok, _term}), do: true
  def is_ok({:error, _reason}), do: false

  @spec is_err(result()) :: boolean()
  def is_err({:ok, _term}), do: false
  def is_err({:error, _reason}), do: true

  @spec and_then(result(), (any() -> result())) :: result()
  def and_then({:ok, term}, fun), do: fun.(term)
  def and_then({:error, _reason} = error, _fun), do: error

  @spec or_else(result(), (any() -> result())) :: result()
  def or_else({:ok, _term} = ok, _fun), do: ok
  def or_else({:error, reason}, fun), do: fun.(reason)

  @spec unwrap_or_else(result(), (any() -> any())) :: any()
  def unwrap_or_else({:ok, term}, _fun), do: term
  def unwrap_or_else({:error, reason}, fun), do: fun.(reason)

  @spec unwrap(ok()) :: any()
  def unwrap({:ok, term}), do: term

  @spec partition_result([result()]) :: {[ok()], [err()]}
  def partition_result(results) do
    {oks, errors} =
      Enum.reduce(results, {[], []}, fn
        {:ok, ok}, {os, es} -> {[ok | os], es}
        {:error, err}, {os, es} -> {os, [err | es]}
      end)

    {Enum.reverse(oks), Enum.reverse(errors)}
  end
end
