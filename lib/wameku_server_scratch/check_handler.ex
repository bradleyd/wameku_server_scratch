defmodule WamekuServerScratch.CheckHandler do
  require Logger

  def handle(result=%{"exit_code" => 0}) do
    Logger.info("nothing to do")
    {:ok, "noop"}
  end

  def handle(result=%{"exit_code" => 1}) do
    Logger.info("got return code 1")
    config = load_config
    # TODO break out into notifier handler
    notifier = Map.get(result, "notifier")
    result = exec_notifier(notifier)
    # if result not ok then send out to backup alert notification
    Logger.info("sent alert for #{inspect(result)}")
    {:ok, "sent an alert since we go a 1"}
  end
  def handle(result=%{"exit_code" => 1, "notifier" => notifiers}) do
    Logger.info("got return code 1")
    config = load_config
    result = Enum.each(notifiers, fn(n) -> exec_notifier(n) end)
    # if result not ok then send out to backup alert notification
    Logger.info("sent alert for #{inspect(result)}")
    {:ok, "sent an alert since we go a 1"}
  end

  def handle(result=%{"exit_code" => 2}) do
    # if notify on exit code 2 then alert
    Logger.info("got return code 2")
    {:ok, "sent an alert since we go a 2"}
  end
  def handle(result=%{"exit_code" => rc}) do
    Logger.info("got message #{inspect(result)}")
    {:error, "do not know how to handle #{rc} exit status"}
  end
  def handle(message) do
    IO.puts(inspect(message))
    Logger.error("I do not know how to handle msg: #{inspect(message)}")
    {:error, 0}
  end

  def load_config do
    Poison.decode!(File.read!("/tmp/checks/config/notify/notifiers.json"))
  end

  def exec_notifier(l=[]) when is_list(l) do
    {:ok, "alert sent"} 
  end
  def exec_notifier(l=[h|t]) when is_list(l) do
    config = load_config
    alert  = Map.get(config, to_string(h))
    if alert do
      Porcelain.exec(alert["path"], alert["arguments"])
    else
      #Enum.each(config, fn(x) -> 
      #  Logger.info(inspect(Porcelain.exec(elem(x,1)["path"], elem(x,1)["arguments"]))) 
      #end)
    end
    exec_notifier(t)
  end
  def exec_notifier(notifier) when is_binary(notifier) do
    config = load_config
    alert  = Map.get(config, to_string(notifier))
    if alert do
      Porcelain.exec(alert["path"], alert["arguments"])
    else
      Enum.each(config, fn(x) -> 
        Logger.info(inspect(Porcelain.exec(elem(x,1)["path"], elem(x,1)["arguments"]))) 
      end)
    end
    {:ok, "alert sent"}
  end
  def exec_notifier(notifier) do
    Logger.info("no notifier")
  end

end
