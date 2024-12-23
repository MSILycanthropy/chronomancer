# frozen_string_literal: true

require "spec_helper"

class McuBuilder
  include Chronomancer::Builder

  build do
    {
      iron_man: @iron_man,
      dr_doom: @dr_doom,
      thanos: @thanos,
      avengers: @avengers,
    }
  end

  requires :avengers

  conflicts :iron_man, :dr_doom

  option :iron_man, default: "Tony Stark"

  option :dr_doom

  option :thanos do
    "I am inevitable"
  end

  options :avengers

  validate do
    original_avengers = ["Thor", "Iron Man", "Captain America", "Hulk", "Black Widow", "Hawkeye"]

    raise "not a real avenger" unless @avengers.all? { |a| original_avengers.include?(a) }
  end
end

RSpec.describe(Chronomancer::Builder) do
  subject :builder do
    McuBuilder.new
  end

  describe "singular option" do
    it "defines the method" do
      expect(builder.methods).to(include(:iron_man))
    end

    it "sets the value in the built object" do
      expect(builder.dr_doom("Tony Stark?").avenger("Thor").build[:dr_doom]).to(eq("Tony Stark?"))
    end

    it "respects defaults" do
      expect(builder.avenger("Thor").build[:iron_man]).to(eq("Tony Stark"))
    end
  end

  describe "multiple option" do
    it "defines the method" do
      expect(builder.methods).to(include(:avenger))
    end

    it "sets the value in the built object" do
      expect(builder.avenger("Thor").avenger("Iron Man").build[:avengers]).to(eq(["Thor", "Iron Man"]))
    end
  end

  it "raises on conflicting options" do
    expect { builder.avenger("Thor").dr_doom("Tonicus Stark").iron_man }.to(raise_error(Chronomancer::Error))
  end

  it "raises on missing required options" do
    expect { builder.build }.to(raise_error(Chronomancer::Error))
  end

  it "raises on failed validation" do
    expect { builder.avenger("Spider-Man").build }.to(raise_error(RuntimeError))
  end

  it "builds lazily" do
    expect(builder.avenger("Thor").avenger("Iron Man")[:avengers]).to(eq(["Thor", "Iron Man"]))
  end
end
