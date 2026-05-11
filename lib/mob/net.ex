defmodule Mob.Net do
  @moduledoc """
  Network helpers for on-device code.

  These helpers are intentionally small wrappers around platform behavior that
  differs from desktop OTP. Use them when app code needs a concrete IP address
  before opening a socket.
  """

  @type ipv4_address :: {0..255, 0..255, 0..255, 0..255}

  @doc """
  Resolves a host name to an IPv4 tuple.

  On iOS and Android this uses Mob's native `getaddrinfo` bridge, avoiding OTP
  resolver paths that may rely on helper executables unavailable inside mobile
  app sandboxes. In non-native environments it falls back to `:inet.getaddr/2`.

      iex> Mob.Net.resolve_ipv4("127.0.0.1")
      {:ok, {127, 0, 0, 1}}

  """
  @spec resolve_ipv4(String.t() | charlist() | ipv4_address()) ::
          {:ok, ipv4_address()} | {:error, term()}
  def resolve_ipv4({a, b, c, d} = address)
      when a in 0..255 and b in 0..255 and c in 0..255 and d in 0..255 do
    {:ok, address}
  end

  def resolve_ipv4(host) when is_binary(host) do
    case parse_ipv4(host) do
      {:ok, address} -> {:ok, address}
      :error -> resolve_hostname(host)
    end
  end

  def resolve_ipv4(host) when is_list(host) do
    host
    |> IO.iodata_to_binary()
    |> resolve_ipv4()
  rescue
    _ -> {:error, :invalid_host}
  end

  def resolve_ipv4(_host), do: {:error, :invalid_host}

  defp parse_ipv4(host) do
    case host |> String.split(".") |> Enum.map(&Integer.parse/1) do
      [{a, ""}, {b, ""}, {c, ""}, {d, ""}]
      when a in 0..255 and b in 0..255 and c in 0..255 and d in 0..255 ->
        {:ok, {a, b, c, d}}

      _other ->
        :error
    end
  end

  defp resolve_hostname(host) do
    if native_resolver_available?() do
      apply(:mob_nif, :resolve_ipv4, [host])
    else
      host
      |> String.to_charlist()
      |> :inet.getaddr(:inet)
    end
  end

  defp native_resolver_available? do
    Code.ensure_loaded?(:mob_nif) and function_exported?(:mob_nif, :resolve_ipv4, 1) and
      native_platform?()
  rescue
    _ -> false
  end

  defp native_platform? do
    apply(:mob_nif, :platform, []) in [:ios, :android]
  rescue
    _ -> false
  end
end
