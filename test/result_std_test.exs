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
      check all ok_result <- ok_generator() do
        assert true == ResultStd.is_ok(ok_result)
      end
    end

    property "returns false for any :error tuple" do
      check all err_result <- err_generator() do
        assert false == ResultStd.is_ok(err_result)
      end
    end
  end

  describe "is_err/1" do
    property "returns false for any :ok tuple" do
      check all ok_result <- ok_generator() do
        assert false == ResultStd.is_err(ok_result)
      end
    end

    property "returns true for any :error tuple" do
      check all err_result <- err_generator() do
        assert true == ResultStd.is_err(err_result)
      end
    end
  end

  describe "and_then/2" do
    property "call the callback for any :ok tuple" do
      check all ok_result <- ok_generator() do
        fun = fn _ -> {:ok, :called} end
        assert {:ok, :called} == ResultStd.and_then(ok_result, fun)
      end
    end

    property "don't call the callback for any :error tuple" do
      check all err_result <- err_generator() do
        fun = fn _ -> {:ok, :called} end
        assert err_result == ResultStd.and_then(err_result, fun)
      end
    end
  end

  describe "or_else/2" do
    property "don't call the callback for any :ok tuple" do
      check all ok_result <- ok_generator() do
        fun = fn _ -> {:ok, :called} end
        assert ok_result == ResultStd.or_else(ok_result, fun)
      end
    end

    property "call the callback for any :error tuple" do
      check all err_result <- err_generator() do
        fun = fn _ -> {:ok, :called} end
        assert {:ok, :called} == ResultStd.or_else(err_result, fun)
      end
    end
  end

  describe "unwrap_or_else/2" do
    property "unwrap the term for any :ok tuple" do
      check all ok_result <- ok_generator() do
        {:ok, term} = ok_result
        fun = fn _ -> {:ok, :called} end
        assert term == ResultStd.unwrap_or_else(ok_result, fun)
      end
    end

    property "call the callback for any :error tuple" do
      check all err_result <- err_generator() do
        fun = fn _ -> {:ok, :called} end
        assert {:ok, :called} == ResultStd.unwrap_or_else(err_result, fun)
      end
    end
  end

  describe "unwrap/2" do
    property "unwrap the term for any :ok tuple" do
      check all ok_result <- ok_generator() do
        {:ok, term} = ok_result
        assert term == ResultStd.unwrap(ok_result)
      end
    end

    property "raise for any :error tuple" do
      check all err_result <- err_generator() do
        assert_raise FunctionClauseError, fn ->
          ResultStd.unwrap(err_result)
        end
      end
    end
  end

  describe "partition_result/2" do
    property "return a list of :ok tuple as the first elem" do
      check all ok_list <- list_of(ok_generator()) do
        term_list = Enum.map(ok_list, &elem(&1, 1))
        assert {term_list, []} == ResultStd.partition_result(ok_list)
      end
    end

    property "return a list of :error tuple as the second elem" do
      check all err_list <- list_of(err_generator()) do
        term_list = Enum.map(err_list, &elem(&1, 1))
        assert {[], term_list} == ResultStd.partition_result(err_list)
      end
    end

    property "split :ok and :error tuples" do
      check all ok_result <- ok_generator(),
                err_result <- err_generator() do
        {:ok, ok_term} = ok_result
        {:error, err_term} = err_result

        assert {[ok_term, ok_term], [err_term]} ==
                 ResultStd.partition_result([ok_result, err_result, ok_result])
      end
    end
  end

  ## Private functions

  defp ok_generator() do
    gen all term <- term() do
      {:ok, term}
    end
  end

  defp err_generator() do
    gen all term <- term() do
      {:error, term}
    end
  end
end
