# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Chronomancer::Range) do
  include ActiveSupport::Testing::TimeHelpers

  subject :range do
    described_class.new(first, last)
  end

  let(:first) { "Jan 1st, 2025".to_time }
  let(:last) { "Dec 31st, 2025".to_time }

  describe "#first" do
    it "returns the first element when n = 1" do
      expect(range.first).to(eq(first))
    end

    it "raises when n is negative" do
      expect { range.first(-1) }.to(raise_error(ArgumentError))
    end

    it "yields the first n elements" do
      expect(range.first(5)).to(eq(Date::MONTHNAMES.compact.first(5).map do |name|
        "#{name} 1st, 2025"
      end.map(&:to_time)))
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
    let(:last) { nil }

    describe "#last" do
      it "raises" do
        expect { range.last }.to(raise_error(Chronomancer::Error))
      end
    end

    describe "#include?" do
      let(:exceptions) { [described_class.new(first + 10.days)] }

      it "returns true for dates in the range" do
        expect(range.include?("March 19th, 4444".to_time)).to(be(true))
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

    describe "#cover?" do
      it "returns true for covered dates" do
        expect(range.cover?("Jan 18th, 2025")).to(be(true))
      end

      it "returns false for covered that arent covered" do
        expect(range.cover?("Jan 1st, 2024")).to(be(false))
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
          break if date.after?("December 31st, 2025".to_time)

          arr << date
        end

        arr
      end

      it "iterates over dates" do
        expect(dates).to(eq(Date::MONTHNAMES.compact.map { |name| "#{name} 1st, 2025" }.map(&:to_time)))
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
        expect(range.last).to(eq("December 1st, 2025".to_time))
      end

      it "raises when n is negative" do
        expect { range.last(-1) }.to(raise_error(ArgumentError))
      end

      it "yields the last n elements" do
        expect(range.last(5)).to(eq(Date::MONTHNAMES.compact.last(5).map do |name|
          "#{name} 1st, 2025"
        end.map(&:to_time)))
      end
    end

    describe "#include?" do
      let(:exceptions) { [described_class.new(first + 10.days, first + 10.days + 1.month)] }

      it "returns true for dates in the range" do
        expect(range.include?("March 19th, 2025".to_time)).to(be(true))
      end

      it "returns false for dates outside range" do
        expect(range.include?("March 19th, 1999".to_time)).to(be(false))
      end

      it "returns false for dates that are exceptions" do
        range.with_exceptions(exceptions) do |r|
          expect(r.include?(first + 11.days)).to(be(false))
        end
      end
    end

    describe "#cover?" do
      it "returns true for covered dates" do
        expect(range.cover?("Jan 18th, 2025")).to(be(true))
      end

      it "returns false for covered that arent covered" do
        expect(range.cover?("Jan 1st, 2026")).to(be(false))
      end

      it "returns false for dates after `last` but in `start..end`" do
        expect(range.cover?("Dec 2nd, 2025")).to(be(false))
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
        expect(range.to_a).to(eq(
          Date::MONTHNAMES.compact.map { |name| "#{name} 1st, 2025" }.map(&:to_time),
        ))
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
end
