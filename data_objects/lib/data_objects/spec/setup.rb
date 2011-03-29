RSpec::Matchers.define :be_array_case_insensitively_equal_to do |attribute|
  match do |model|
    model.map { |f| f.downcase } == attribute
  end
end
