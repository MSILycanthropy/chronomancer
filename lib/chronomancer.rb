# frozen_string_literal: true

require_relative "chronomancer/version"

require "chronomancer/builder"
require "chronomancer/recurrence"
require "chronomancer/recurrence/builder"
require "chronomancer/sequence"
require "chronomancer/sequence/builder"

module Chronomancer
  class Error < StandardError; end
end
