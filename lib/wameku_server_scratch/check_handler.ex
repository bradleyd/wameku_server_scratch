defmodule WamekuServerScratch.CheckHandler do
  require Logger
  alias WamekuServerScratch.Notifier

  def handle(%{"exit_code" => 0}) do
    Logger.info("nothing to do for 0 exit code")
    {:ok, "noop"}
  end
  def handle(message=%{"exit_code" => 2, "notifier" => notifiers}) when is_list(notifiers) do
    Logger.info(inspect(message))
    Logger.info(inspect(notifiers))
    Logger.info("got return code 2 - CRITICAL")
    result = Notifier.run(notifiers, message)
    Logger.info("sent alert for #{inspect(result)}")
    {:ok, "sent an alert since we got a 2"}
  end
  def handle(message=%{"exit_code" => 2}) do
    Logger.info("checked returned code 2 - CRITICAL")
    result = Notifier.run(Map.get(message, "notifier", []), message)
    Logger.info("sent alert for #{inspect(result)}")
    {:ok, "sent an alert since we got a 2"}
  end

  def handle(result=%{"exit_code" => 1}) do
    # if notify on exit code 1 then warn
    Logger.info("got return code 1")
    {:ok, "only warn for exit code 1"}
  end
  def handle(message=%{"exit_code" => 1, "notifier" => notifiers, "notfiy_on_warning" => true}) do
    # if notify on exit code 2 then alert
    Logger.info("got return code 1 - WARNING")
    result   = Notifier.run(notifiers, message)
    {:ok, "sent an alert for exit code 1"}
  end

  def handle(result=%{"exit_code" => rc}) do
    Logger.info("got message #{inspect(result)}")
    {:error, "do not know how to handle #{rc} exit status"}
  end
  def handle(message) do
    Logger.error("I do not know how to handle msg: #{inspect(message)}")
    {:error, 0}
  end
end
