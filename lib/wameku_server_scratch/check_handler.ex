defmodule WamekuServerScratch.CheckHandler do
  require Logger
  alias WamekuServerScratch.Notifier
  alias WamekuServerScratch.TimeUtils

  # TODO check for action taken
  def handle(%{"auto_pilot" => %{"start" => start_time, "end" => end_time, "timezone" => timezone}}=message) do
    erl_date                    = TimeUtils.date_in_timezone(timezone)
    {:ok, formatted_start_time} = Calendar.DateTime.from_erl({erl_date, Calendar.Time.to_erl(Calendar.Time.Parse.iso8601!(start_time))}, timezone)
    {:ok, formatted_end_time}   = Calendar.DateTime.from_erl({erl_date, Calendar.Time.to_erl(Calendar.Time.Parse.iso8601!(end_time))}, timezone)
    now_epoch                   = TimeUtils.now_in_tz_epoch(timezone)
    Logger.debug("formatted st/et: #{inspect([formatted_start_time, formatted_end_time])}")
    Logger.debug("now epoch #{inspect(erl_date)}")
    st_epoch  = TimeUtils.datetime_to_epoch(formatted_start_time) #Calendar.DateTime.Format.unix(formatted_start_time)
    et_epoch  = TimeUtils.datetime_to_epoch(formatted_start_time) #Calendar.DateTime.Format.unix(formatted_end_time)
    Logger.debug(inspect([st_epoch, et_epoch]))
    Logger.debug("now >= st_epoch: #{now_epoch}, #{st_epoch}")
    Logger.debug("now <= et_epoch: #{now_epoch}, #{et_epoch}")
    # update audit trail with action taken update_digest(message)
    if (now_epoch >= st_epoch) && (now_epoch <= et_epoch) do
      # dont alert
      Logger.info("Autopilot is on and no need to alert")
      {:ok, "noop"}
    else
      Logger.info("We are not in auto pilot range #{inspect([now: now_epoch, start: st_epoch, end: et_epoch])}")
      # Remove AutoPilot from map and recurse
      handle(Map.drop(message, ["auto_pilot"]))
    end
  end
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
