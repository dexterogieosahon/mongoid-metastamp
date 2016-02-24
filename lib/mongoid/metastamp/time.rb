module Mongoid #:nodoc:
  module Metastamp
    class Time < ::Time

      class << self

        # Get the time object from its mongo friendly ruby type to this time type.
        #
        # @example Demongoize the object.
        #   Mongoid::Metastamp::Time.demongoize(object)
        #
        # @param [ Object ] The object to demongoize.
        #
        # @return [ ActiveSupport::TimeWithZone ] The time object.
        def demongoize(object)
          return nil if object.blank?
          return super(object) if object.instance_of?(::Time)
          time = object['time'].getlocal unless Mongoid::Config.use_utc?
          zone = ActiveSupport::TimeZone[object['zone']]
          zone = ActiveSupport::TimeZone[object['offset']] if zone.nil?
          time.in_time_zone(zone)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Mongoid::Metastamp::Time.mongoize(Time.now)
        #
        # @param [ Object ] The object to mongoize.
        #
        # @return [ Hash ] The mongoized object.
        def mongoize(object)
          return nil if object.blank?
          time = super(object)
          local_time = time.in_time_zone(::Time.zone)
          {
            time:         time,
            normalized:   normalized_time(local_time),
            cweek:        local_time.to_date.cweek,
            year:         local_time.year,
            month:        local_time.month,
            day:          local_time.day,
            wday:         local_time.wday,
            hour:         local_time.hour,
            min:          local_time.min,
            sec:          local_time.sec,
            zone:         ::Time.zone.name,
            offset:       local_time.utc_offset
          }.stringify_keys
        end

        # Evolve the object into a mongo-friendly value to query with.
        #
        # @example Evolve the object.
        #   Mongoid::Metastamp::Time.evolve(object)
        #
        # @param [ Object ] The object to evolve.
        #
        # @return [ Object ] The evolved object.
        def evolve(object)
          case object
          when Date, Time, ActiveSupport::TimeWithZone then { "time" => object.mongoize }
          else object
          end
        end

      protected

        def normalized_time(time)
          ::Time.parse("#{ time.strftime("%F %T") } -0000").utc
        end
      end
    end
  end
end
