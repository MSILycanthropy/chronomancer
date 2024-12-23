# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Chronomancer::Recurrence::Builder) do
  include ActiveSupport::Testing::TimeHelpers

  subject :builder do
    described_class.new
  end

  around do |example|
    travel_to "Jan 1st, 2024".to_time do
      example.call
    end
  end

  it "requires interval" do
    expect { builder.build }.to(raise_error(Chronomancer::Error))
  end

  it "cant call the same method twice" do
    expect { builder.monthly.monthly }.to(raise_error(Chronomancer::Error))
  end

  it "conflicts on interval methods" do
    expect { builder.daily.weekly }.to(raise_error(Chronomancer::Error))
  end

  it "conflicts on occurrence methods" do
    expect { builder.forever.total(4) }.to(raise_error(Chronomancer::Error))
  end

  it "raises if occurrences are negative" do
    expect { builder.daily.total(-5).build }.to(raise_error(Chronomancer::Error))
  end

  it "sets the start date" do
    expect(builder.daily.starting(Time.current + 11.days).first).to(eq(Time.current + 11.days))
  end

  it "sets daily interval" do
    expect(builder.daily.interval).to(eq(1.day))
  end

  it "sets weekly interval" do
    expect(builder.weekly.interval).to(eq(1.week))
  end

  it "sets monthly interval" do
    expect(builder.monthly.interval).to(eq(1.month))
  end

  it "sets yearly interval" do
    expect(builder.yearly.interval).to(eq(1.year))
  end

  it "sets unique intervals" do
    expect(builder.every(4.months + 8.days).interval).to(eq(4.months + 8.days))
  end

  it "sets finite occurrences" do
    expect(builder.daily.total(15).occurrences).to(eq(15))
  end

  it "sets infinite occurrences" do
    expect(builder.daily.forever.occurrences).to(be_nil)
  end

  it "sets occurrences from end date" do
    expect(builder.daily.until(Time.current + 10.days).occurrences).to(eq(11))
  end

  it "sets occurrences from end date when the end ate doesnt align" do
    expect(builder.monthly.until(Time.current + 10.months + 10.days).occurrences).to(eq(11))
  end
end
