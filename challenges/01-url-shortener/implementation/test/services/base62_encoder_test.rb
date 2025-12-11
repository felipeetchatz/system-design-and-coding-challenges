require "test_helper"

class Base62EncoderTest < ActiveSupport::TestCase
  test "#encode encodes zero to Base62 with padding" do
    assert_equal "000000", Base62Encoder.encode(0)
  end

  test "#encode encodes single digit numbers" do
    assert_equal "000001", Base62Encoder.encode(1)
    assert_equal "000009", Base62Encoder.encode(9)
  end

  test "#encode encodes numbers up to 61 (last single Base62 digit)" do
    assert_equal "00000a", Base62Encoder.encode(10)
    assert_equal "00000z", Base62Encoder.encode(35)  # 'z' is at index 35 (a-z = 10-35)
    assert_equal "00000Z", Base62Encoder.encode(61)  # 'Z' is at index 61 (A-Z = 36-61)
  end

  test "#encode encodes numbers requiring multiple digits" do
    assert_equal "000010", Base62Encoder.encode(62)
    assert_equal "000100", Base62Encoder.encode(3844)
  end

  test "#encode encodes maximum value for 6 characters" do
    assert_equal "ZZZZZZ", Base62Encoder.encode(56_800_235_583)
  end

  test "#encode always returns exactly 6 characters" do
    [0, 1, 10, 62, 100, 1000, 1_000_000].each do |number|
      result = Base62Encoder.encode(number)
      assert_equal 6, result.length, "Number #{number} should encode to 6 characters"
    end
  end

  test "#encode pads with zeros for small numbers" do
    assert_equal "000001", Base62Encoder.encode(1)
    assert_equal "00000a", Base62Encoder.encode(10)
  end

  test "#encode uses only Base62 alphabet characters" do
    result = Base62Encoder.encode(100)
    assert_match(/^[0-9a-zA-Z]{6}$/, result)
  end

  test "#decode decodes zero" do
    assert_equal 0, Base62Encoder.decode("000000")
  end

  test "#decode decodes single digit numbers" do
    assert_equal 1, Base62Encoder.decode("000001")
    assert_equal 9, Base62Encoder.decode("000009")
  end

  test "#decode decodes numbers up to 61" do
    assert_equal 10, Base62Encoder.decode("00000a")
    assert_equal 35, Base62Encoder.decode("00000z")  # 'z' is at index 35
    assert_equal 61, Base62Encoder.decode("00000Z")  # 'Z' is at index 61
  end

  test "#decode decodes maximum value" do
    assert_equal 56_800_235_583, Base62Encoder.decode("ZZZZZZ")
  end

  test "#decode is inverse of encode" do
    (0..1000).each do |number|
      encoded = Base62Encoder.encode(number)
      decoded = Base62Encoder.decode(encoded)
      assert_equal number, decoded, "Failed round-trip for #{number}"
    end
  end
end
