# encoding: utf-8
require 'spec_helper'
require 'ostruct'

module RSpec
  module Expectations
    describe DiffPresenter do
      let(:differ) { RSpec::Expectations::DiffPresenter.new }
      context "without --color" do

      before { allow(RSpec::Matchers.configuration).to receive_messages(:color? => false) }

      describe '#diff_as_string' do
        subject { differ.diff_as_string(@actual, @expected) }

        it "outputs unified diff of two strings" do
          @expected = "foo\nzap\nbar\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nanother\nline\n"
          @actual   = "foo\nbar\nzap\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nline\n"
          expect(subject).to eq(<<-'EOD')


@@ -1,6 +1,6 @@
 foo
-zap
 bar
+zap
 this
 is
 soo
@@ -9,6 +9,5 @@
 equal
 insert
 a
-another
 line
EOD

        end

        if String.method_defined?(:encoding)
          it 'copes with encoded strings' do
            @expected = "Tu avec carte {count} item has".encode('UTF-16LE')
            @actual   = "Tu avec carté {count} itém has".encode('UTF-16LE')
            expect(subject).to eql(<<-EOD.encode('UTF-16LE'))

@@ -1,2 +1,2 @@
-Tu avec carte {count} item has
+Tu avec carté {count} itém has
EOD
          end

          it 'handles differently encoded strings that are compatible' do
            @expected = "abc".encode('us-ascii')
            @actual   = "강인철".encode('UTF-8')
            expect(subject).to eql "\n@@ -1,2 +1,2 @@\n-abc\n+강인철\n"
          end

          it 'uses the default external encoding when the two strings have incompatible encodings' do
            @expected = "Tu avec carte {count} item has"
            @actual   = "Tu avec carté {count} itém has".encode('UTF-16LE')
            expect(subject).to eq("\n@@ -1,2 +1,2 @@\n-Tu avec carte {count} item has\n+Tu avec carté {count} itém has\n")
            expect(subject.encoding).to eq(Encoding.default_external)
          end

          it 'handles any encoding error that occurs with a helpful error message' do
            expect(Differ).to receive(:new).and_raise(Encoding::CompatibilityError)
            @expected = "Tu avec carte {count} item has".encode('us-ascii')
            @actual   = "Tu avec carté {count} itém has"
            expect(subject).to match(/Could not produce a diff/)
            expect(subject).to match(/actual string \(UTF-8\)/)
            expect(subject).to match(/expected string \(US-ASCII\)/)
          end
        end
      end

      describe '#diff_as_object' do
        it "outputs unified diff message of two objects" do
          animal_class = Class.new do
            def initialize(name, species)
              @name, @species = name, species
            end

            def inspect
              <<-EOA
<Animal
  name=#{@name},
  species=#{@species}
>
              EOA
            end
          end

          expected = animal_class.new "bob", "giraffe"
          actual   = animal_class.new "bob", "tortoise"

          expected_diff = <<'EOD'

@@ -1,5 +1,5 @@
 <Animal
   name=bob,
-  species=tortoise
+  species=giraffe
 >
EOD

          diff = differ.diff_as_object(expected,actual)
          expect(diff).to eq expected_diff
        end

        it "outputs unified diff message of two arrays" do
          expected = [ :foo, 'bar', :baz, 'quux', :metasyntactic, 'variable', :delta, 'charlie', :width, 'quite wide' ]
          actual   = [ :foo, 'bar', :baz, 'quux', :metasyntactic, 'variable', :delta, 'tango'  , :width, 'very wide'  ]

          expected_diff = <<'EOD'


@@ -5,7 +5,7 @@
  :metasyntactic,
  "variable",
  :delta,
- "tango",
+ "charlie",
  :width,
- "very wide"]
+ "quite wide"]
EOD

          diff = differ.diff_as_object(expected,actual)
          expect(diff).to eq expected_diff
        end

        it "outputs unified diff message of two hashes" do
          expected = { :foo => 'bar', :baz => 'quux', :metasyntactic => 'variable', :delta => 'charlie', :width =>'quite wide' }
          actual   = { :foo => 'bar', :metasyntactic => 'variable', :delta => 'charlotte', :width =>'quite wide' }

          expected_diff = <<'EOD'

@@ -1,4 +1,5 @@
-:delta => "charlotte",
+:baz => "quux",
+:delta => "charlie",
 :foo => "bar",
 :metasyntactic => "variable",
 :width => "quite wide",
EOD

          diff = differ.diff_as_object(expected,actual)
          expect(diff).to eq expected_diff
        end

        it 'outputs unified diff message of two hashes with differing encoding' do
          expected_diff = %Q{
@@ -1,2 +1,2 @@
-"a" => "a",
#{ (RUBY_VERSION.to_f > 1.8) ?  %Q{+"ö" => "ö"} : '+"\303\266" => "\303\266"' },
}

          diff = differ.diff_as_object({'ö' => 'ö'}, {'a' => 'a'})
          expect(diff).to eq expected_diff
        end

        it 'outputs unified diff message of two hashes with encoding different to key encoding' do
          expected_diff = %Q{
@@ -1,2 +1,2 @@
-:a => "a",
#{ (RUBY_VERSION.to_f > 1.8) ?  %Q{+\"한글\" => \"한글2\"} : '+"\355\225\234\352\270\200" => "\355\225\234\352\270\2002"' },
}

          diff = differ.diff_as_object({ "한글" => "한글2"}, { :a => "a"})
          expect(diff).to eq expected_diff
        end

        it "outputs unified diff message of two hashes with object keys" do
          expected_diff = %Q{
@@ -1,2 +1,2 @@
-["a", "c"] => "b",
+["d", "c"] => "b",
}

          diff = differ.diff_as_object({ ['d','c'] => 'b'}, { ['a','c'] => 'b' })
          expect(diff).to eq expected_diff
        end

        it "outputs unified diff of single line strings" do
          expected = "this is one string"
          actual   = "this is another string"

          expected_diff = <<'EOD'

@@ -1,2 +1,2 @@
-"this is another string"
+"this is one string"
EOD

          diff = differ.diff_as_object(expected,actual)
          expect(diff).to eq expected_diff
        end

        it "outputs unified diff of multi line strings" do
          expected = "this is:\n  one string"
          actual   = "this is:\n  another string"

          expected_diff = <<'EOD'

@@ -1,3 +1,3 @@
 this is:
-  another string
+  one string
EOD

          diff = differ.diff_as_object(expected,actual)
          expect(diff).to eq expected_diff
        end
      end
    end

    context "with --color" do
      before { allow(RSpec::Matchers.configuration).to receive_messages(:color? => true) }

      it "outputs colored diffs" do
        expected = "foo bar baz"
        actual = "foo bang baz"
        expected_diff = "\e[0m\n\e[0m\e[34m@@ -1,2 +1,2 @@\n\e[0m\e[31m-foo bang baz\n\e[0m\e[32m+foo bar baz\n\e[0m"


        diff = differ.diff_as_string(expected,actual)
        expect(diff).to eq expected_diff
      end
    end

    end
  end
end
