module DatetimeFormatter
  def to_s
    if utc_offset < 0
      offset = -utc_offset
      sign = "-"
    else
      offset = utc_offset
      sign = "+"
    end
    strftime("%Y-%m-%dT%H:%M:%S") + sign +(Time.mktime(0) + offset).strftime("%H:%M")
  end
end
