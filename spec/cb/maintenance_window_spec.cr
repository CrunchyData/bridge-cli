require "../spec_helper"
include CB

Spectator.describe MaintenanceWindow do
  describe "initialize" do
    it "reject invalid window-start " do
      expect { MaintenanceWindow.new(-1) }.to raise_error Program::Error, /start should either be nil or between 0 and 23/

      expect { MaintenanceWindow.new(24) }.to raise_error Program::Error, /start should either be nil or between 0 and 23/
    end
  end
  describe "explain" do
    def explain(window, now = nil)
      MaintenanceWindow.new(window).explain(now)
    end

    it "explains no maintenance window" do
      expect(explain(nil)).to match(/no window set/)
    end

    it "return the maintenance window start and duration" do
      expect(explain(14)).to match(/14:00 - 17:00 UTC/)
    end

    it "give the proper duration before the next window" do
      now = Time.local(2022, 11, 5, 14, 0, 0, location: Time::Location.load("America/New_York"))
      expect(explain(14, now)).to match(/Next window is in 20 hours and 0 minutes/)

      now = Time.local(2022, 11, 5, 14, 0, 1, location: Time::Location.load("Europe/London"))
      expect(explain(14, now)).to match(/Next window is in 23 hours and 59 minutes/)

      now = Time.local(2022, 11, 5, 14, 0, 0, location: Time::Location.load("Europe/Moscow"))
      expect(explain(14, now)).to match(/Next window is in 3 hours and 0 minutes/)
    end

    it "warns if the maintenance window is now" do
      now = Time.utc(2022, 11, 5, 16, 30, 0)
      expect(explain(14, now)).to match(/Currently in the maintenance window/)

      one_hour_later = now + Time::Span.new(hours: 1)
      expect(explain(14, one_hour_later)).not_to match(/Currently in the maintenance window/)
    end
  end
end
