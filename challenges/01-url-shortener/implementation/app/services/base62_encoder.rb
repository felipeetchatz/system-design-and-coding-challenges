class Base62Encoder
    BASE62_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
    BASE = 62
    CODE_LENGTH = 6
  
    def self.encode(number)
      return "0" * CODE_LENGTH if number.zero?
  
      result = ""
      num = number
  
      while num > 0
        result = BASE62_ALPHABET[num % BASE] + result
        num /= BASE
      end
  
      # Pad with zeros to ensure 6 characters
      result.rjust(CODE_LENGTH, "0")
    end
  
    def self.decode(encoded_string)
      number = 0
      encoded_string.each_char do |char|
        number = number * BASE + BASE62_ALPHABET.index(char)
      end
      number
    end
  end
  