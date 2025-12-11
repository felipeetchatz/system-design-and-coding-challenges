class ShortCodeGenerator
  def self.generate
    # Get next number from database sequence (atomic operation)
    # Using execute instead of select_value to avoid caching issues
    result = ActiveRecord::Base.connection.execute(
      "SELECT nextval('short_urls_id_seq') as val"
    )
    next_number = result.first["val"].to_i

    # Convert to Base62 and return 6-character code
    Base62Encoder.encode(next_number)
  end

   def generate
    self.class.generate
  end
end