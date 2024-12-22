# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Chronomancer) do
  it "has a version number" do
    expect(Chronomancer::VERSION).not_to(be_nil)
  end
end
