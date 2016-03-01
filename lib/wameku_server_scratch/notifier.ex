defmodule WamekuServerScratch.Notifier do
  require Logger
  alias WamekuServerScratch.Config
  use Database

  defmodule Metadata do
    defstruct output: :nil, exit_code: :nil, name: :nil
  end

  def run(notifiers, message) do
    do_run(notifiers, message, [])
  end

  def do_run([], _message, acc) when length(acc) == 0 do
    {:ok, "no need to alert as no notifier was set!"}
  end
  def do_run([], _message, acc) do
    {:ok, "alert sent!", acc}
  end
  def do_run([h|t], message, acc) do
    client = Client.find(message["host"])
    alert  = Config.lookup(h)
    do_run(t, message, send_notification(alert, client.active, message, acc))
  end

  def send_notification(%{"arguments" => arguments, "path" => path}, true, message, acc) do
    [Porcelain.exec(path, [build_config_arguments(arguments), build_notifier_message(message)])| acc]
  end
  def send_notification(nil, _false, _message, acc) do
    Logger.info("Could not find notifier")
    acc
  end
  def send_notification(%{"arguments" => _arguments, "path" => _path}, false, _message, acc) do
    Logger.info("Client is not active..not alerting")
    acc
  end

  def build_config_arguments([]) do
    <<>>
  end
  def build_config_arguments(arguments) do
    arg_string = Enum.join(arguments, " ")
    Poison.encode!(arg_string)
  end

  def build_notifier_message(message) do
    Poison.encode!(%Metadata{name: message["name"], output: message["output"], exit_code: message["exit_code"]})
  end
end
