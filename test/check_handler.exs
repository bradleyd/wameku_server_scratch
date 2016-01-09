defmodule WamekuServerScratch.CheckHandlerTest do
  use ExUnit.Case, async: true

  test "no alerts are triggered from check results" do
    assert {:ok, msg} = WamekuServerScratch.CheckHandler.handle(%{"exit_code" => 0, "history" => [1], "host" => "bradleyd-900X4C", "last_checked" => 1452306568, "name" => "check-disk", "output" => "space used: 60\n"})
  end

  test "an alert is triggered from check results with exit code of 1" do
    assert {:ok, msg} = WamekuServerScratch.CheckHandler.handle(%{"exit_code" => 1, "history" => [1], "host" => "bradleyd-900X4C", "last_checked" => 1452306568, "name" => "check-disk", "output" => "space used: 60\n"})
    IO.inspect msg
  end

end

