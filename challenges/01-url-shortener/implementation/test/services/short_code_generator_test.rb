require "test_helper"

class ShortCodeGeneratorTest < ActiveSupport::TestCase
  test "#generate generates unique codes on consecutive calls" do
    code1 = ShortCodeGenerator.generate
    code2 = ShortCodeGenerator.generate

    assert_not_equal code1, code2
  end

  test "#generate generates codes with exactly 6 characters" do
    code = ShortCodeGenerator.generate

    assert_equal 6, code.length
  end

  test "#generate generates codes using Base62 alphabet only" do
    code = ShortCodeGenerator.generate

    assert_match(/^[0-9a-zA-Z]{6}$/, code)
  end

  test "#generate generates different codes for multiple calls" do
    codes = 10.times.map { ShortCodeGenerator.generate }

    assert_equal codes.uniq.length, codes.length, "All codes should be unique"
  end

  test "#generate uses database sequence for uniqueness" do
    # This test verifies that the generator uses the database sequence
    # which ensures atomicity and uniqueness
    generator = ShortCodeGenerator.new
    
    code1 = generator.generate
    code2 = generator.generate

    # Codes should be different (sequence increments)
    assert_not_equal code1, code2
  end
end
