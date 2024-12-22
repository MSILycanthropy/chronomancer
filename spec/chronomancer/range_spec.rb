# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Chronomancer::Range) do
  include ActiveSupport::Testing::TimeHelpers

  subject :range do
    described_class.new(first, last)
  end

  # context "with infinite ranges" do
  # end

  context "with finite ranges" do
    let(:first) { "Jan 1st, 2025".to_time }
    let(:last) { "Dec 31st, 2025".to_time }

    describe "#cover?" do
      it "returns true for covered dates" do
        expect(range.cover?("Jan 18th, 2025")).to(be(true))
      end

      it "returns false for covered that arent covered" do
        expect(range.cover?("Jan 1st, 2026")).to(be(false))
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
