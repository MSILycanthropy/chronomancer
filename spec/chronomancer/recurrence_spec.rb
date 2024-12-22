# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Chronomancer::Recurrence) do
  include ActiveSupport::Testing::TimeHelpers

  subject :range do
    described_class.new(first, ocurrences)
  end

  let(:first) { Time.current.beginning_of_year }
  let(:ocurrences) { 12 }

  describe "#first" do
    it "returns the first element when n = 1" do
      expect(range.first).to(eq(first))
    end

    it "raises when n is negative" do
      expect { range.first(-1) }.to(raise_error(ArgumentError))
    end

    it "yields the first n elements" do
      expect(range.first(5)).to(eq(Date::MONTHNAMES.compact.first(5).map { |n| n.to_date.to_time }))
    end
  end

  describe "#nth" do
    let(:n) { 7 }

    it "returns the nth element" do
      expect(range.nth(7)).to(eq(first + 7.months))
    end

    it "raises when n is negative" do
      expect { range.nth(-1) }.to(raise_error(ArgumentError))
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
      let(:exceptions) { [described_class.new(first + 10.days)] }

      it "returns true for dates in the range" do
        expect(range.include?("March 1st, 4444".to_time)).to(be(true))
      end

      it "returns false for dates outside range" do
        expect(range.include?("March 19th, 1999".to_time)).to(be(false))
      end

      it "returns false for dates that are exceptions" do
        range.with_exceptions(exceptions) do |r|
          expect(r.include?("March 19th, 4444".to_time)).to(be(false))
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
        travel_to "Jan 3rd, 2025".to_time do
          expect(range.next_occurrence).to(eq("Feb 1st, 2025".to_time))
        end
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
      let(:exceptions) { [described_class.new(first + 10.days, 1, interval_type: :days)] }

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
        travel_to "Jan 3rd, 2025".to_time do
          expect(range.next_occurrence).to(eq("Feb 1st, 2025".to_time))
        end
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
