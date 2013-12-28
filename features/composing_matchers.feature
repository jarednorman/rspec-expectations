Feature: Composing Matchers

  RSpec's matchers are designed to be composable so that you can
  combine them to express the exact details of what you expect
  but nothing more. This can help you avoid writing over-specified
  brittle specs, by using a matcher in place of an exact value to
  specify only the essential aspects of what you expect.

  For RSpec 3, we have updated all matchers to make them accept
  matchers as arguments. This includes the following:

    * `change { }.by(matcher)`
    * `change { }.from(matcher).to(matcher)`
    * `contain_exactly(matcher, matcher, matcher)`
    * `end_with(matcher, matcher)`
    * `include(matcher, matcher)`
    * `include(:key => matcher, :other => matcher)`
    * `match(arbitrary_nested_structure_with_matchers)`
    * `raise_error(ErrorClass, matcher)`
    * `start_with(matcher, matcher)`
    * `throw_symbol(:sym, matcher)`
    * `yield_with_args(matcher, matcher)`
    * `yield_successive_args(matcher, matcher)`

  Note that many built-in matchers do not accept matcher arguments
  because they have precise semantics that do not allow for a matcher
  argument. For example, `equal(some_object)` is designed to pass only
  if the actual and expected arguments are references to the same object.
  It would not make sense to support a matcher argument here.

  All of RSpec's built-in matchers have one or more aliases that allow
  you to use a noun-phrase rather than verb form since they read better
  as composed arguments. They also provide customized failure output so
  that the failure message reads better as well.

  A full list of these aliases is out of scope here, but here are some
  of the aliases used below:

    * `be > 2` => `a_value > 2`
    * `be_an_instance_of` => `an_instance_of`
    * `be_odd` => `a_number_that_is_odd`
    * `be_even` => `a_number_that_is_even`
    * `be_within` => `a_value_within`
    * `contain_exactly` => `a_collection_containing_exactly`
    * `end_with` => `a_string_ending_with`
    * `match` => `a_string_matching`
    * `start_with` => `a_string_starting_with`

  Scenario: Composing matchers with `change`
    Given a file named "change_spec.rb" with:
      """
      describe "Passing matchers to `change`" do
        specify "you can pass a matcher to `by`" do
          k = 0
          expect { k += 1.05 }.to change { k }.
            by( a_value_within(0.1).of(1.0) )
        end

        specify "you can pass matchers to `from` and `to" do
          s = "food"
          expect { s = "barn" }.to change { s }.
            from( a_string_matching(/foo/) ).
            to( a_string_matching(/bar/) )
        end
      end
      """
    When I run `rspec change_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `contain_exactly`
    Given a file named "contain_exactly_spec.rb" with:
      """
      describe "Passing matchers to `contain_exactly`" do
        specify "you can pass matchers in place of exact values" do
          expect(["barn", 2.45]).to contain_exactly(
            a_value_within(0.1).of(2.5),
            a_string_starting_with("bar")
          )
        end
      end
      """
    When I run `rspec contain_exactly_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `end_with`
    Given a file named "end_with_spec.rb" with:
      """
      describe "Passing matchers to `end_with`" do
        specify "you can pass matchers in place of exact values" do
          expect(["barn", "food", 2.45]).to end_with(
            a_string_matching("foo"),
            a_value > 2
          )
        end
      end
      """
    When I run `rspec end_with_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `include`
    Given a file named "include_spec.rb" with:
      """
      describe "Passing matchers to `contain_exactly`" do
        specify "you can use matchers in place of array values" do
          expect(["barn", 2.45]).to include( a_string_starting_with("bar") )
        end

        specify "you can use matchers in place of hash values" do
          expect(:a => "food", :b => "good").to include(:a => a_string_matching(/foo/))
        end

        specify "you can use matchers in place of hash keys" do
          expect("food" => "is good").to include( a_string_matching(/foo/) )
        end
      end
      """
    When I run `rspec include_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `match`:
    Given a file named "match_spec.rb" with:
      """
      describe "Passing matchers to `match`" do
        specify "you can match nested data structures against matchers" do
          hash = {
            :a => {
              :b => ["foo", 5],
              :c => { :d => 2.05 }
            }
          }

          expect(hash).to match(
            :a => {
              :b => a_collection_containing_exactly(
                a_string_starting_with("f"),
                an_instance_of(Fixnum)
              ),
              :c => { :d => (a_value < 3) }
            }
          )
        end
      end
      """
    When I run `rspec match_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `raise_error`
    Given a file named "raise_error_spec.rb" with:
      """
      describe "Passing matchers to `raise_error`" do
        specify "you can pass a matcher in place of the message" do
          expect {
            raise RuntimeError, "this goes boom"
          }.to raise_error(RuntimeError, a_string_ending_with("boom"))
        end
      end
      """
    When I run `rspec raise_error_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `start_with`
    Given a file named "start_with_spec.rb" with:
      """
      describe "Passing matchers to `start_with`" do
        specify "you can pass matchers in place of exact values" do
          expect(["barn", "food", 2.45]).to start_with(
            a_string_matching("bar"),
            a_string_matching("foo")
          )
        end
      end
      """
    When I run `rspec start_with_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `throw_symbol`
    Given a file named "throw_symbol_spec.rb" with:
      """
      describe "Passing matchers to `throw_symbol`" do
        specify "you can pass a matcher in place of a throw arg" do
          expect {
            throw :foo, 3
          }.to throw_symbol(:foo, a_number_that_is_odd)
        end
      end
      """
    When I run `rspec throw_symbol_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `yield_with_args`
    Given a file named "yield_with_args_spec.rb" with:
      """
      describe "Passing matchers to `yield_with_args`" do
        specify "you can pass matchers in place of the args" do
          expect { |probe|
            "food".tap(&probe)
          }.to yield_with_args(a_string_matching(/foo/))
        end
      end
      """
    When I run `rspec yield_with_args_spec.rb`
    Then the examples should all pass

  Scenario: Composing matchers with `yield_successive_args`
    Given a file named "yield_successive_args_spec.rb" with:
      """
      describe "Passing matchers to `yield_successive_args`" do
        specify "you can pass matchers in place of the args" do
          expect { |probe|
            [1, 2, 3].each(&probe)
          }.to yield_successive_args(
            a_number_that_is_odd,
            a_number_that_is_even,
            a_number_that_is_odd
          )
        end
      end
      """
    When I run `rspec yield_successive_args_spec.rb`
    Then the examples should all pass
