defmodule WamekuServerScratchTest do
  use ExUnit.Case, async: true

  setup do
    #{:ok, } = KV.Registry.start_link
    #{:ok, registry: registry}
  end
end
