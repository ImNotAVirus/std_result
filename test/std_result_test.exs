defmodule StdResultTest do
  use ExUnit.Case, async: true

  doctest StdResult

  ## Tests - Example based

  describe "unit/1" do
    test "is defined as an empty tuple" do
      assert {} == StdResult.unit()
    end
  end

  describe "normalize_result/1" do
    test "return a :ok tuple for :ok value" do
      assert {:ok, {}} == StdResult.normalize_result(:ok)
    end

    test "return a :error tuple for :error value" do
      assert {:error, {}} == StdResult.normalize_result(:error)
    end

    test "return the given input for a :ok tuple" do
      assert {:ok, :foo} == StdResult.normalize_result({:ok, :foo})
    end

    test "return the given input for a :error tuple" do
      assert {:error, :bar} == StdResult.normalize_result({:error, :bar})
    end
  end

  ## Tests - Properties

  use ExUnitProperties

  describe "ok/1" do
    property "wrap any term in :ok tuple" do
      check all term <- term() do
        assert {:ok, term} == StdResult.ok(term)
      end
    end
  end

  describe "err/1" do
    property "wrap any term in :error tuple" do
      check all term <- term() do
        assert {:error, term} == StdResult.err(term)
      end
    end
  end

  describe "ok?/1" do
    property "returns true for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        assert true == StdResult.ok?(ok_result)
      end
    end

    property "returns false for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        assert false == StdResult.ok?(err_result)
      end
    end
  end

  describe "ok_and?/2" do
    property "returns true if input is a :ok tuple and fun return true" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> true end
        assert true == StdResult.ok_and?(ok_result, fun)
      end
    end

    property "returns false if input is a :ok tuple and fun return false" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> false end
        assert false == StdResult.ok_and?(ok_result, fun)
      end
    end

    property "returns false for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> true end
        assert false == StdResult.ok_and?(err_result, fun)
      end
    end
  end

  describe "err?/1" do
    property "returns false for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        assert false == StdResult.err?(ok_result)
      end
    end

    property "returns true for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        assert true == StdResult.err?(err_result)
      end
    end
  end

  describe "err_and?/2" do
    property "returns true if input is a :error tuple and fun return true" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> true end
        assert true == StdResult.err_and?(err_result, fun)
      end
    end

    property "returns false if input is a :error tuple and fun return false" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> false end
        assert false == StdResult.err_and?(err_result, fun)
      end
    end

    property "returns false for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        fun = fn _ -> true end
        assert false == StdResult.err_and?(ok_result, fun)
      end
    end
  end

  describe "map/2" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:wrapper, term} end
        assert {:ok, {:wrapper, term}} == StdResult.map(ok_result, fun)
      end
    end

    property "returns the input for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> :unused end
        assert err_result == StdResult.map(err_result, fun)
      end
    end
  end

  describe "map_or/3" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:wrapper, term} end
        assert {:wrapper, term} == StdResult.map_or(ok_result, :default, fun)
      end
    end

    property "returns the default argument for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> :unused end
        assert :default == StdResult.map_or(err_result, :default, fun)
      end
    end
  end

  describe "map_or_else/3" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:wrapper, term} end
        default_fun = fn _ -> :unused end
        assert {:wrapper, term} == StdResult.map_or_else(ok_result, default_fun, fun)
      end
    end

    property "calls the default function for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn _ -> :unused end
        default_fun = fn ^term -> {:wrapper, term} end
        assert {:wrapper, term} == StdResult.map_or_else(err_result, default_fun, fun)
      end
    end
  end

  describe "map_err/2" do
    property "apply the function to any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> {:wrapper, term} end
        assert {:error, {:wrapper, term}} == StdResult.map_err(err_result, fun)
      end
    end

    property "returns the input for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        fun = fn _ -> :unused end
        assert ok_result == StdResult.map_err(ok_result, fun)
      end
    end
  end

  describe "inspect/2" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        ref = make_ref()
        parent = self()
        fun = fn ^term -> send(parent, {ref, term}) end

        assert ok_result == StdResult.inspect(ok_result, fun)
        assert_received {^ref, ^term}
      end
    end

    property "do nothing for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        ref = make_ref()
        parent = self()
        fun = fn term -> send(parent, {ref, term}) end

        assert err_result == StdResult.inspect(err_result, fun)
        refute_received {^ref, ^err_result}
      end
    end
  end

  describe "inspect_err/2" do
    property "apply the function to any :error tuple" do
      check all {err_result, term} <- err_generator() do
        ref = make_ref()
        parent = self()
        fun = fn ^term -> send(parent, {ref, term}) end

        assert err_result == StdResult.inspect_err(err_result, fun)
        assert_received {^ref, ^term}
      end
    end

    property "do nothing for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        ref = make_ref()
        parent = self()
        fun = fn term -> send(parent, {ref, term}) end

        assert ok_result == StdResult.inspect_err(ok_result, fun)
        refute_received {^ref, ^ok_result}
      end
    end
  end

  describe "expect/2" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        assert term == StdResult.expect(ok_result, "Unexpected error")
      end
    end

    property "raises an error for any :error tuple (non binary reason)" do
      check all {err_result, term} <- err_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, "Unexpected error: #{inspect(term)}", fn ->
          StdResult.expect(err_result, "Unexpected error")
        end
      end
    end

    property "raises an error for any :error tuple (binary reason)" do
      check all reason <- string(:utf8) do
        err_result = {:error, reason}

        assert_raise RuntimeError, "Unexpected error: #{reason}", fn ->
          StdResult.expect(err_result, "Unexpected error")
        end
      end
    end
  end

  describe "unwrap/1" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        assert term == StdResult.unwrap(ok_result)
      end
    end

    property "raises an error for any :error tuple (non binary reason)" do
      check all {err_result, term} <- err_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, inspect(term), fn ->
          StdResult.unwrap(err_result)
        end
      end
    end

    property "raises an error for any :error tuple (binary reason)" do
      check all reason <- string(:utf8) do
        err_result = {:error, reason}

        assert_raise RuntimeError, reason, fn ->
          StdResult.unwrap(err_result)
        end
      end
    end
  end

  describe "expect_err/2" do
    property "raises an error for any :ok tuple (non binary reason)" do
      check all {ok_result, term} <- ok_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, "Unexpected error: #{inspect(term)}", fn ->
          StdResult.expect_err(ok_result, "Unexpected error")
        end
      end
    end

    property "raises an error for any :ok tuple (binary reason)" do
      check all reason <- string(:utf8) do
        ok_result = {:ok, reason}

        assert_raise RuntimeError, "Unexpected error: #{reason}", fn ->
          StdResult.expect_err(ok_result, "Unexpected error")
        end
      end
    end

    property "unwrap the term for any :err tuple" do
      check all {err_result, term} <- err_generator() do
        assert term == StdResult.expect_err(err_result, "Unexpected error")
      end
    end
  end

  describe "unwrap_err/1" do
    property "raises an error for any :ok tuple (non binary reason)" do
      check all {ok_result, term} <- ok_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, inspect(term), fn ->
          StdResult.unwrap_err(ok_result)
        end
      end
    end

    property "raises an error for any :ok tuple (binary reason)" do
      check all term <- string(:utf8) do
        ok_result = {:ok, term}

        assert_raise RuntimeError, term, fn ->
          StdResult.unwrap_err(ok_result)
        end
      end
    end

    property "unwrap the term for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        assert term == StdResult.unwrap_err(err_result)
      end
    end
  end

  describe "and_result/2" do
    property "return the second argument for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator(),
                {result, _term} <- result_generator() do
        assert result == StdResult.and_result(ok_result, result)
      end
    end

    property "return the first argument for any :error tuple" do
      check all {err_result, _term} <- err_generator(),
                {result, _term} <- result_generator() do
        assert err_result == StdResult.and_result(err_result, result)
      end
    end
  end

  describe "and_then/2" do
    property "call the callback for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:ok, {:wrapper, term}} end
        assert {:ok, {:wrapper, term}} == StdResult.and_then(ok_result, fun)
      end
    end

    property "don't call the callback for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> {:ok, :called} end
        assert err_result == StdResult.and_then(err_result, fun)
      end
    end
  end

  describe "or_result/2" do
    property "return the first argument for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator(),
                {result, _term} <- result_generator() do
        assert ok_result == StdResult.or_result(ok_result, result)
      end
    end

    property "return the second argument for any :error tuple" do
      check all {err_result, _term} <- err_generator(),
                {result, _term} <- result_generator() do
        assert result == StdResult.or_result(err_result, result)
      end
    end
  end

  describe "or_else/2" do
    property "don't call the callback for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        fun = fn _ -> {:ok, :called} end
        assert ok_result == StdResult.or_else(ok_result, fun)
      end
    end

    property "call the callback for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> {:ok, {:wrapper, term}} end
        assert {:ok, {:wrapper, term}} == StdResult.or_else(err_result, fun)
      end
    end
  end

  describe "unwrap_or/2" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        assert term == StdResult.unwrap_or(ok_result, :default)
      end
    end

    property "returns the default for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        assert :default == StdResult.unwrap_or(err_result, :default)
      end
    end
  end

  describe "unwrap_or_else/2" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn _ -> {:ok, :called} end
        assert term == StdResult.unwrap_or_else(ok_result, fun)
      end
    end

    property "call the callback for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> {:ok, {:wrapper, term}} end
        assert {:ok, {:wrapper, term}} == StdResult.unwrap_or_else(err_result, fun)
      end
    end
  end

  describe "partition_result/1" do
    property "return a list of :ok tuple as the first elem" do
      check all ok_list <- list_of(vanilla_ok_generator()) do
        term_list = Enum.map(ok_list, &elem(&1, 1))
        assert {term_list, []} == StdResult.partition_result(ok_list)
      end
    end

    property "return a list of :error tuple as the second elem" do
      check all err_list <- list_of(vanilla_err_generator()) do
        term_list = Enum.map(err_list, &elem(&1, 1))
        assert {[], term_list} == StdResult.partition_result(err_list)
      end
    end

    property "split :ok and :error tuples" do
      check all {ok_result, ok_term} <- ok_generator(),
                {err_result, err_term} <- err_generator() do
        assert {[ok_term, ok_term], [err_term]} ==
                 StdResult.partition_result([ok_result, err_result, ok_result])
      end
    end
  end

  ## Private functions

  defp vanilla_ok_generator() do
    gen all term <- term() do
      {:ok, term}
    end
  end

  defp vanilla_err_generator() do
    gen all term <- term() do
      {:error, term}
    end
  end

  defp ok_generator() do
    gen all term <- term() do
      {{:ok, term}, term}
    end
  end

  defp err_generator() do
    gen all term <- term() do
      {{:error, term}, term}
    end
  end

  defp result_generator() do
    gen all result_tuple <- one_of([ok_generator(), err_generator()]) do
      result_tuple
    end
  end
end
