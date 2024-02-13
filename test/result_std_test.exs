defmodule ResultStdTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  ## Tests - Example based

  describe "unit/1" do
    test "is defined as an empty tuple" do
      assert {} == ResultStd.unit()
    end
  end

  ## Tests - Properties

  describe "ok/1" do
    property "wrap any term in :ok tuple" do
      check all term <- term() do
        assert {:ok, term} == ResultStd.ok(term)
      end
    end
  end

  describe "err/1" do
    property "wrap any term in :error tuple" do
      check all term <- term() do
        assert {:error, term} == ResultStd.err(term)
      end
    end
  end

  describe "is_ok/1" do
    property "returns true for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        assert true == ResultStd.is_ok(ok_result)
      end
    end

    property "returns false for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        assert false == ResultStd.is_ok(err_result)
      end
    end
  end

  describe "is_ok_and/2" do
    property "returns true if input is a :ok tuple and fun return true" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> true end
        assert true == ResultStd.is_ok_and(ok_result, fun)
      end
    end

    property "returns false if input is a :ok tuple and fun return false" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> false end
        assert false == ResultStd.is_ok_and(ok_result, fun)
      end
    end

    property "returns false for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> true end
        assert false == ResultStd.is_ok_and(err_result, fun)
      end
    end
  end

  describe "is_err/1" do
    property "returns false for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        assert false == ResultStd.is_err(ok_result)
      end
    end

    property "returns true for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        assert true == ResultStd.is_err(err_result)
      end
    end
  end

  describe "is_err_and/2" do
    property "returns true if input is a :error tuple and fun return true" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> true end
        assert true == ResultStd.is_err_and(err_result, fun)
      end
    end

    property "returns false if input is a :error tuple and fun return false" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> false end
        assert false == ResultStd.is_err_and(err_result, fun)
      end
    end

    property "returns false for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        fun = fn _ -> true end
        assert false == ResultStd.is_err_and(ok_result, fun)
      end
    end
  end

  describe "map/2" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:wrapper, term} end
        assert {:ok, {:wrapper, term}} == ResultStd.map(ok_result, fun)
      end
    end

    property "returns the input for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> :unused end
        assert err_result == ResultStd.map(err_result, fun)
      end
    end
  end

  describe "map_or/3" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:wrapper, term} end
        assert {:wrapper, term} == ResultStd.map_or(ok_result, :default, fun)
      end
    end

    property "returns the default argument for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> :unused end
        assert :default == ResultStd.map_or(err_result, :default, fun)
      end
    end
  end

  describe "map_or_else/3" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:wrapper, term} end
        default_fun = fn _ -> :unused end
        assert {:wrapper, term} == ResultStd.map_or_else(ok_result, default_fun, fun)
      end
    end

    property "calls the default function for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn _ -> :unused end
        default_fun = fn ^term -> {:wrapper, term} end
        assert {:wrapper, term} == ResultStd.map_or_else(err_result, default_fun, fun)
      end
    end
  end

  describe "map_err/2" do
    property "apply the function to any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> {:wrapper, term} end
        assert {:error, {:wrapper, term}} == ResultStd.map_err(err_result, fun)
      end
    end

    property "returns the input for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        fun = fn _ -> :unused end
        assert ok_result == ResultStd.map_err(ok_result, fun)
      end
    end
  end

  describe "inspect/2" do
    property "apply the function to any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        ref = make_ref()
        parent = self()
        fun = fn ^term -> send(parent, {ref, term}) end

        assert ok_result == ResultStd.inspect(ok_result, fun)
        assert_received {^ref, ^term}
      end
    end

    property "do nothing for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        ref = make_ref()
        parent = self()
        fun = fn term -> send(parent, {ref, term}) end

        assert err_result == ResultStd.inspect(err_result, fun)
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

        assert err_result == ResultStd.inspect_err(err_result, fun)
        assert_received {^ref, ^term}
      end
    end

    property "do nothing for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        ref = make_ref()
        parent = self()
        fun = fn term -> send(parent, {ref, term}) end

        assert ok_result == ResultStd.inspect_err(ok_result, fun)
        refute_received {^ref, ^ok_result}
      end
    end
  end

  describe "expect/2" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        assert term == ResultStd.expect(ok_result, "Unexpected error")
      end
    end

    property "raises an error for any :error tuple (non binary reason)" do
      check all {err_result, term} <- err_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, "Unexpected error: #{inspect(term)}", fn ->
          ResultStd.expect(err_result, "Unexpected error")
        end
      end
    end

    property "raises an error for any :error tuple (binary reason)" do
      check all reason <- string(:utf8) do
        err_result = {:error, reason}

        assert_raise RuntimeError, "Unexpected error: #{reason}", fn ->
          ResultStd.expect(err_result, "Unexpected error")
        end
      end
    end
  end

  describe "unwrap/1" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        assert term == ResultStd.unwrap(ok_result)
      end
    end

    property "raises an error for any :error tuple (non binary reason)" do
      check all {err_result, term} <- err_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, inspect(term), fn ->
          ResultStd.unwrap(err_result)
        end
      end
    end

    property "raises an error for any :error tuple (binary reason)" do
      check all reason <- string(:utf8) do
        err_result = {:error, reason}

        assert_raise RuntimeError, reason, fn ->
          ResultStd.unwrap(err_result)
        end
      end
    end
  end

  describe "expect_err/2" do
    property "raises an error for any :ok tuple (non binary reason)" do
      check all {ok_result, term} <- ok_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, "Unexpected error: #{inspect(term)}", fn ->
          ResultStd.expect_err(ok_result, "Unexpected error")
        end
      end
    end

    property "raises an error for any :ok tuple (binary reason)" do
      check all reason <- string(:utf8) do
        ok_result = {:ok, reason}

        assert_raise RuntimeError, "Unexpected error: #{reason}", fn ->
          ResultStd.expect_err(ok_result, "Unexpected error")
        end
      end
    end

    property "unwrap the term for any :err tuple" do
      check all {err_result, term} <- err_generator() do
        assert term == ResultStd.expect_err(err_result, "Unexpected error")
      end
    end
  end

  describe "unwrap_err/1" do
    property "raises an error for any :ok tuple (non binary reason)" do
      check all {ok_result, term} <- ok_generator(),
                not is_binary(term) do
        assert_raise RuntimeError, inspect(term), fn ->
          ResultStd.unwrap_err(ok_result)
        end
      end
    end

    property "raises an error for any :ok tuple (binary reason)" do
      check all term <- string(:utf8) do
        ok_result = {:ok, term}

        assert_raise RuntimeError, term, fn ->
          ResultStd.unwrap_err(ok_result)
        end
      end
    end

    property "unwrap the term for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        assert term == ResultStd.unwrap_err(err_result)
      end
    end
  end

  describe "and_result/2" do
    property "return the second argument for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator(),
                {result, _term} <- result_generator() do
        assert result == ResultStd.and_result(ok_result, result)
      end
    end

    property "return the first argument for any :error tuple" do
      check all {err_result, _term} <- err_generator(),
                {result, _term} <- result_generator() do
        assert err_result == ResultStd.and_result(err_result, result)
      end
    end
  end

  describe "and_then/2" do
    property "call the callback for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn ^term -> {:ok, {:wrapper, term}} end
        assert {:ok, {:wrapper, term}} == ResultStd.and_then(ok_result, fun)
      end
    end

    property "don't call the callback for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        fun = fn _ -> {:ok, :called} end
        assert err_result == ResultStd.and_then(err_result, fun)
      end
    end
  end

  describe "or_result/2" do
    property "return the first argument for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator(),
                {result, _term} <- result_generator() do
        assert ok_result == ResultStd.or_result(ok_result, result)
      end
    end

    property "return the second argument for any :error tuple" do
      check all {err_result, _term} <- err_generator(),
                {result, _term} <- result_generator() do
        assert result == ResultStd.or_result(err_result, result)
      end
    end
  end

  describe "or_else/2" do
    property "don't call the callback for any :ok tuple" do
      check all {ok_result, _term} <- ok_generator() do
        fun = fn _ -> {:ok, :called} end
        assert ok_result == ResultStd.or_else(ok_result, fun)
      end
    end

    property "call the callback for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> {:ok, {:wrapper, term}} end
        assert {:ok, {:wrapper, term}} == ResultStd.or_else(err_result, fun)
      end
    end
  end

  describe "unwrap_or/2" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        assert term == ResultStd.unwrap_or(ok_result, :default)
      end
    end

    property "returns the default for any :error tuple" do
      check all {err_result, _term} <- err_generator() do
        assert :default == ResultStd.unwrap_or(err_result, :default)
      end
    end
  end

  describe "unwrap_or_else/2" do
    property "unwrap the term for any :ok tuple" do
      check all {ok_result, term} <- ok_generator() do
        fun = fn _ -> {:ok, :called} end
        assert term == ResultStd.unwrap_or_else(ok_result, fun)
      end
    end

    property "call the callback for any :error tuple" do
      check all {err_result, term} <- err_generator() do
        fun = fn ^term -> {:ok, {:wrapper, term}} end
        assert {:ok, {:wrapper, term}} == ResultStd.unwrap_or_else(err_result, fun)
      end
    end
  end

  describe "partition_result/1" do
    property "return a list of :ok tuple as the first elem" do
      check all ok_list <- list_of(vanilla_ok_generator()) do
        term_list = Enum.map(ok_list, &elem(&1, 1))
        assert {term_list, []} == ResultStd.partition_result(ok_list)
      end
    end

    property "return a list of :error tuple as the second elem" do
      check all err_list <- list_of(vanilla_err_generator()) do
        term_list = Enum.map(err_list, &elem(&1, 1))
        assert {[], term_list} == ResultStd.partition_result(err_list)
      end
    end

    property "split :ok and :error tuples" do
      check all {ok_result, ok_term} <- ok_generator(),
                {err_result, err_term} <- err_generator() do
        assert {[ok_term, ok_term], [err_term]} ==
                 ResultStd.partition_result([ok_result, err_result, ok_result])
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
