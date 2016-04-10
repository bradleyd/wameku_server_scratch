defmodule WamekuServerScratch.TimeUtils do
  def date_in_timezone(tz) do
    Calendar.Date.today!(tz) |> Calendar.Date.to_erl
  end

  def start_time(tz, start_time) do
    datetime_from_erl(date_in_timezone(tz), time_to_erl(parse_string_time(start_time)), tz)
  end

  def end_time(tz, end_time) do
    {:ok, formatted_start_time} = Calendar.DateTime.from_erl({date_in_timezone(tz), time_to_erl(parse_string_time(end_time))}, tz)
  end

  def parse_string_time(string_time) do
    Calendar.Time.Parse.iso8601!(string_time)
  end

  def time_to_erl(ts) do
    Calendar.Time.to_erl(ts)
  end

  def datetime_from_erl(date, time, tz) do
    {:ok, dt} = Calendar.DateTime.from_erl({date, time}, tz)
    dt
  end

  def now_in_tz_epoch(tz) do
    now_in_tz(tz) |> datetime_to_epoch
  end

  def now_in_tz(tz) do
    Calendar.DateTime.now!(tz)
  end

  def datetime_to_epoch(ts) do
    Calendar.DateTime.Format.unix(ts)
  end
end
