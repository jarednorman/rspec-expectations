require 'spec_helper'

module ExampleExpectations

  class ArbitraryMatcher
    def initialize(*args, &block)
      if args.last.is_a? Hash
        @expected = args.last[:expected]
      end
      @expected = block.call if block
      @block = block
    end

    def matches?(target)
      @target = target
      return @expected == target
    end

    def with(new_value)
      @expected = new_value
      self
    end

    def failure_message
      "expected #{@expected}, got #{@target}"
    end

    def failure_message_when_negated
      "expected not #{@expected}, got #{@target}"
    end
  end

  class PositiveOnlyMatcher < ArbitraryMatcher
    undef failure_message_when_negated rescue nil
  end

  def arbitrary_matcher(*args, &block)
    ArbitraryMatcher.new(*args, &block)
  end

  def positive_only_matcher(*args, &block)
    PositiveOnlyMatcher.new(*args, &block)
  end

end

module RSpec
  module Expectations
    describe PositiveExpectationHandler do
      describe "#handle_matcher" do
        it "asks the matcher if it matches" do
          matcher = double("matcher")
          actual = Object.new
          expect(matcher).to receive(:matches?).with(actual).and_return(true)
          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)
        end

        it "returns the match value" do
          matcher = double("matcher")
          actual = Object.new
          expect(matcher).to receive(:matches?).with(actual).and_return(:this_value)
          expect(RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)).to eq :this_value
        end

        it "calls failure_message if the matcher implements it" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)
        end

        it "calls fail if matcher.diffable?" do
          matcher = double("matcher",
            :diffable? => true,
            :failure_message => "message",
            :matches? => false,
            :expected => 1,
            :actual   => 2
          )
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message", 1, 2)

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)
        end

        it "calls failure_message if the matcher does not implement failure_message" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)

        end

        it "uses the custom failure message when one is provided" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher, "custom")
        end

        it "uses the custom failure message when one is provided as a callable object" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          failure_message = double("failure message", :call => "custom")

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher, failure_message)
        end
      end
    end

    describe NegativeExpectationHandler do
      describe "#handle_matcher" do
        it "asks the matcher if it doesn't match when the matcher responds to #does_not_match?" do
          matcher = double("matcher", :does_not_match? => true, :failure_message_when_negated => nil)
          actual = Object.new
          expect(matcher).to receive(:does_not_match?).with(actual).and_return(true)
          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)
        end

        it "asks the matcher if it matches when the matcher doesn't respond to #does_not_match?" do
          matcher = double("matcher")
          actual = Object.new
          allow(matcher).to receive(:failure_message_when_negated)
          expect(matcher).to receive(:matches?).with(actual).and_return(false)
          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)
        end

        it "returns the match value" do
          matcher = double("matcher")
          actual = Object.new
          expect(matcher).to receive(:matches?).with(actual).and_return(false)
          allow(matcher).to receive(:failure_message_when_negated).and_return("ignore")
          expect(RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)).to be_falsey
        end

        it "calls fail if matcher.diffable?" do
          matcher = double("matcher",
            :diffable? => true,
            :failure_message_when_negated => "message",
            :matches? => true,
            :expected => 1,
            :actual   => 2
          )
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message", 1, 2)

          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)
        end

        it "uses the custom failure message when one is provided" do
          matcher = double("matcher", :failure_message_when_negated => "message", :matches? => true)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher, "custom")
        end

        it "uses the custom failure message when one is provided as a callable object" do
          matcher = double("matcher", :failure_message_when_negated => "message", :matches? => true)
          actual = Object.new

          failure_message = double("failure message", :call => "custom")

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher, failure_message)
        end
      end
    end

    describe PositiveExpectationHandler do
      include ExampleExpectations

      it "handles submitted args" do
        expect(5).to arbitrary_matcher(:expected => 5)
        expect(5).to arbitrary_matcher(:expected => "wrong").with(5)
        expect { expect(5).to arbitrary_matcher(:expected => 4) }.to fail_with("expected 4, got 5")
        expect { expect(5).to arbitrary_matcher(:expected => 5).with(4) }.to fail_with("expected 4, got 5")
        expect(5).not_to arbitrary_matcher(:expected => 4)
        expect(5).not_to arbitrary_matcher(:expected => 5).with(4)
        expect { expect(5).not_to arbitrary_matcher(:expected => 5) }.to fail_with("expected not 5, got 5")
        expect { expect(5).not_to arbitrary_matcher(:expected => 4).with(5) }.to fail_with("expected not 5, got 5")
      end

      it "handles the submitted block" do
        expect(5).to arbitrary_matcher { 5 }
        expect(5).to arbitrary_matcher(:expected => 4) { 5 }
        expect(5).to arbitrary_matcher(:expected => 4).with(5) { 3 }
      end

    end
  end
end
