#encoding: utf-8

require "spec_helper"

describe "Mongoid::Metastamp::Time" do

  let :now do
    Time.zone.now
  end

  describe "compatibility with Time class" do

    class Legacy
      include Mongoid::Document
      field :timestamp, type: Time
    end

    let :instance do
      Legacy.create(timestamp: now).reload
    end

    context "before upgrade" do

      it "should store timestamp as a Time" do
        instance['timestamp'].class.should == Time
      end

      it "should return timestamp as an ActiveSupport::TimeWithZone" do
        instance.timestamp.class.should == ActiveSupport::TimeWithZone
      end

      it "should contain the same timestamp" do
        format_time(instance.timestamp).should == format_time(now)
      end

    end

    context "after Mongoid::Metastamp upgrade" do

      before :each do
        instance
        Legacy.field(:timestamp, type: Mongoid::Metastamp::Time)
      end

      let :legacy do
        Legacy.find(instance.id)
      end

      it "should still be able to read legacy timestamps" do
        format_time(legacy.timestamp).should == format_time(now)
      end
      
      describe "updating timestamp with the same time" do

        before :each do
          legacy.update_attribute(:timestamp, now)
        end

        it "should now store timestamp as a Hash" do
          legacy['timestamp'].class.should == Hash
        end

        it "should still be compatible with the legacy timestamp" do
          format_time(legacy.timestamp).should == format_time(now)
        end

        it "should still store timestamp as a Time" do
          legacy['timestamp']['time'].class.should == Time
          legacy['timestamp']['time'] == now.to_time
        end

        it "should still return timestamp as an ActiveSupport::TimeWithZone" do
          legacy.timestamp.class.should == ActiveSupport::TimeWithZone
        end

      end

    end

    # Below mehotd avoids that time-with-zone comparison fails due of hidden
    # millisecond differences
    # @param time [TimeWithZone]
    # @return [String], formatted time with zone
    def format_time(time)
      strftime_preset = '%Y-%m-%dT%l:%M:%S%z'
      time.strftime(strftime_preset)
    end

  end

end
