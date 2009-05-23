class OCI8
  module BindType
    module Util # :nodoc:

      # store default offset without DST
      @@time_offset = ::Time.now.utc_offset
      @@datetime_offset = ::DateTime.now.offset
      if ::Time.now.dst?
        @@time_offset -= 3600
        @@datetime_offset -= Rational(1,24)
      end

      # support just UTC or local timezone to avoid DST correct handling issues
      # (as DATE values are converted to TIMESTAMP using current UTC offset)
      def ocitimestamp_to_time(ary)
        year, month, day, hour, minute, sec, fsec, tz_hour, tz_min = ary
        
        if year >= 139
          timezone = tz_hour == 0 && tz_min == 0 ? :utc : :local
          begin
            # Ruby 1.9 Time class's resolution is nanosecond.
            # But the last argument type is millisecond.
            # 'fsec' is converted to a Float to pass sub-millisecond part.
            return ::Time.send(timezone, year, month, day, hour, minute, sec, fsec / 1000.0)
          rescue StandardError
          end
        end
        ocitimestamp_to_datetime(ary)
      end

      # TODO: this method also uses current offset to datetime and not based on date
      # def ocidate_to_datetime(ary)
      #   year, month, day, hour, minute, sec = ary
      #   if @@default_timezone == :local
      #     offset = @@datetime_offset
      #   else
      #     offset = 0
      #   end
      #   ::DateTime.civil(year, month, day, hour, minute, sec, offset)
      # end

    end
  end
end