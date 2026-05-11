defmodule Mob.NetTest do
  use ExUnit.Case, async: true

  alias Mob.Net

  describe "resolve_ipv4/1" do
    test "passes through IPv4 tuples" do
      assert Net.resolve_ipv4({127, 0, 0, 1}) == {:ok, {127, 0, 0, 1}}
    end

    test "parses dotted IPv4 binaries" do
      assert Net.resolve_ipv4("192.168.1.10") == {:ok, {192, 168, 1, 10}}
    end

    test "parses dotted IPv4 charlists" do
      assert Net.resolve_ipv4(~c"10.0.0.5") == {:ok, {10, 0, 0, 5}}
    end

    test "rejects invalid hosts without raising" do
      assert Net.resolve_ipv4(:pop_os) == {:error, :invalid_host}
      assert Net.resolve_ipv4({256, 0, 0, 1}) == {:error, :invalid_host}
    end
  end
end
