struct LookLikeMatcher(ExpectedType) < Spectator::Matchers::ValueMatcher(ExpectedType)
  def description : String
    "is visually equal to #{expected.label}"
  end

  private def match?(actual : Spectator::Expression(T)) : Bool forall T
    strip(actual.value.to_s) == strip(expected.value)
  end

  private def strip(str) : String
    str.to_s.strip.gsub(/\s+\n/, '\n')
  end

  private def failure_message(actual : Spectator::Expression(T)) : String forall T
    "#{actual.label} isn't visually equal to #{expected.label}"
  end
end

macro look_like(expected)
  %value = ::Spectator::Value.new({{expected}}, {{expected.stringify}})
  LookLikeMatcher.new(%value)
end
