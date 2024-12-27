# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Chronomancer::Recurrence) do
  include ActiveSupport::Testing::TimeHelpers

  subject :range do
    described_class.new(first, ocurrences)
  end

  around do |example|
    travel_to(date) do
      example.call
    end
  end

  let(:first) { Time.current.beginning_of_year }
  let(:ocurrences) { 12 }
  let(:date) { "Jan 1st, 2024".to_time }

  describe "leap year bullshit" do
    let(:date) { "Jan 31st, 2024".to_time }
    let(:first) { date }
    let(:leap_day) { "Feb 29th, 2024".to_time }

    it "doesnt skip leap days with nth" do
      expect(range[1]).to(eq(leap_day))
    end

    it "doesnt skip leap days with to_a" do
      expect(range.to_a).to(include(leap_day))
    end

    it "doesnt skip leap dates with next_occurence" do
      expect(range.next_occurrence(date)).to(eq(leap_day))
    end
  end

  describe "#first" do
    let(:exceptions) { [described_class.new(first + 6.months, 3, 1.day)] }

    it "returns the first element when n = 1" do
      expect(range.first).to(eq(first))
    end

    it "raises when n is negative" do
      expect { range.first(-1) }.to(raise_error(ArgumentError))
    end

    it "yields the first n elements" do
      expect(range.first(5)).to(eq(Date::MONTHNAMES.compact.first(5).map { |n| n.to_date.to_time }))
    end

    it "works with exceptions, albeit kinda weirdly" do
      range.with_exceptions(exceptions) do |r|
        expect(r.first(7).last).to(be_nil)
      end
    end
  end

  describe "#[]" do
    it "returns the nth element" do
      expect(range[7]).to(eq(first + 7.months))
    end

    it "raises when n is negative" do
      expect { range[-1] }.to(raise_error(ArgumentError))
    end
  end

  context "with infinite ranges" do
    let(:ocurrences) { nil }

    describe "#last" do
      it "raises" do
        expect { range.last }.to(raise_error(Chronomancer::Error))
      end
    end

    describe "#include?" do
      let(:exceptions) { [described_class.new(first + 1.month)] }

      it "returns true for dates in the range" do
        expect(range.include?("March 1st, 4444".to_time)).to(be(true))
      end

      it "returns false for dates misaligned with the range" do
        expect(range.include?("March 19st, 2024".to_time)).to(be(false))
      end

      it "returns false for dates outside range" do
        expect(range.include?("March 1st, 1999".to_time)).to(be(false))
      end

      it "returns false for dates that are exceptions" do
        range.with_exceptions(exceptions) do |r|
          expect(r.include?("March 1st, 4444".to_time)).to(be(false))
        end
      end
    end

    describe "#with_exceptions" do
      let(:exceptions) { [described_class.new(first + 20.days, 30, 1.day)] }

      it "sets exceptions within block" do
        range.with_exceptions(exceptions) do |r|
          expect(r.exceptions).to(eq(exceptions))
        end
      end

      it "resets exceptions outside the block" do
        range.with_exceptions(exceptions) do |_|
          nil
        end

        expect(range.exceptions).to(be_nil)
      end

      it "cant access date within exception" do
        range.with_exceptions(exceptions) do |r|
          expect(r[1]).to(be_nil)
        end
      end
    end

    describe "#each" do
      let(:dates) do
        arr = []

        range.each do |date|
          break unless date.before?(Time.current.next_year.beginning_of_year)

          arr << date
        end

        arr
      end

      it "iterates over dates" do
        expect(dates).to(eq(Date::MONTHNAMES.compact.map { |n| n.to_date.to_time }))
      end
    end

    describe "#next_occurrence" do
      it "returns the next occurrence from Time.current" do
        expect(range.next_occurrence).to(eq("Feb 1st, 2024".to_time))
      end

      it "returns the next occurrence from a given date" do
        expect(range.next_occurrence("Jan 3rd, 2025")).to(eq("Feb 1st, 2025".to_time))
      end
    end
  end

  context "with finite ranges" do
    describe "#last" do
      it "returns the last element when n = 1" do
        expect(range.last).to(eq(Time.current.end_of_year.beginning_of_month))
      end

      it "raises when n is negative" do
        expect { range.last(-1) }.to(raise_error(ArgumentError))
      end

      it "yields the last n elements" do
        expect(range.last(5)).to(eq(Date::MONTHNAMES.compact.last(5).map { |n| n.to_date.to_time }))
      end
    end

    describe "#include?" do
      let(:exceptions) { [described_class.new(first + 10.days, 1.day)] }

      it "returns true for dates in the range" do
        expect(range.include?(Time.new(Time.current.year, 3, 1))).to(be(true))
      end

      it "returns false for dates outside range" do
        expect(range.include?("March 19th, 2025".to_time)).to(be(false))
      end

      it "returns false for dates that are exceptions" do
        range.with_exceptions(exceptions) do |r|
          expect(r.include?(first + 11.days)).to(be(false))
        end
      end
    end

    describe "#with_exceptions" do
      let(:exceptions) { [described_class.new(first + 10.days, first + 10.days + 1.month)] }

      it "sets exceptions within block" do
        range.with_exceptions(exceptions) do |r|
          expect(r.exceptions).to(eq(exceptions))
        end
      end

      it "resets exceptions outside the block" do
        range.with_exceptions(exceptions) do |_|
          nil
        end

        expect(range.exceptions).to(be_nil)
      end
    end

    describe "#each" do
      it "iterates over all dates" do
        expect(range.to_a).to(eq(Date::MONTHNAMES.compact.map { |n| n.to_date.to_time }))
      end
    end

    describe "#next_occurrence" do
      it "returns the next occurrence from Time.current" do
        expect(range.next_occurrence).to(eq("Feb 1st, 2024".to_time))
      end

      it "returns the next occurrence from a given date in the sequence" do
        expect(range.next_occurrence(Time.new(Time.current.year, 3, 1))).to(eq(Time.new(Time.current.year, 4, 1)))
      end

      it "returns the next occurrence from a given date" do
        expect(range.next_occurrence(Time.new(Time.current.year, 3, 2))).to(eq(Time.new(Time.current.year, 4, 1)))
      end
    end
  end
end
