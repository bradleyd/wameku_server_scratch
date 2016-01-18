defmodule WamekuServerScratch.CheckHandler do
  require Logger

  def handle(result=%{"exit_code" => 0}) do
    Logger.info("nothing to do for 0 exit code")
    {:ok, "noop"}
  end

  def handle(message=%{"exit_code" => 1, "notifier" => notifiers}) when is_list(notifiers) do
    Logger.info(inspect(message))
    Logger.info("got return code 1")
    config = load_config
    result = exec_notifier(notifiers, message, [])
    Logger.info("sent alert for #{inspect(result)}")
    {:ok, "sent an alert since we go a 1"}
  end
  def handle(message=%{"exit_code" => 1}) do
    Logger.info("checked returned code 1")
    config = load_config
    # TODO break out into notifier handler
    result = exec_notifier(Map.get(message, "notifier", []), message, [])
    Logger.info("sent alert for #{inspect(result)}")
    {:ok, "sent an alert since we go a 1"}
  end

  def handle(result=%{"exit_code" => 2}) do
    # if notify on exit code 2 then alert
    Logger.info("got return code 2")
    {:ok, "only warn for exit code 2"}
  end
  def handle(message=%{"exit_code" => 2, "notifier" => notifier, "notfiy_on_warning" => true}) do
    # if notify on exit code 2 then alert
    Logger.info("got return code 2")
    config   = load_config
    # TODO break out into notifier handler
    # TODO stop reading config file everytime
    result   = exec_notifier(notifier, message, [])

    {:ok, "sent an alert for exit code 2"}
  end

  def handle(result=%{"exit_code" => rc}) do
    Logger.info("got message #{inspect(result)}")
    {:error, "do not know how to handle #{rc} exit status"}
  end
  def handle(message) do
    Logger.error("I do not know how to handle msg: #{inspect(message)}")
    {:error, 0}
  end

  def load_config do
    Poison.decode!(File.read!("/tmp/checks/config/notify/notifiers.json"))
  end

  def exec_notifier([], _message, acc) when length(acc) == 0 do
    {:ok, "no need to alert as no notifier was set!"} 
  end
  def exec_notifier([], _message, acc) do
    {:ok, "alert sent!", acc} 
  end
  def exec_notifier([h|t], message, acc) do
    config = load_config
    alert  = Map.get(config, to_string(h))
    result =
    if alert do
      # send to stdin name, exit_code, and output
      [Porcelain.exec(alert["path"], alert["arguments"])| acc]
    else
      Logger.info("Could not find notifier #{h}, ignoring")
      acc
    end
    exec_notifier(t, message, result)
  end
end
