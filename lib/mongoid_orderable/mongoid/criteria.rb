Mongoid::Criteria.delegate :inc, :to => :context
Mongoid::Finders.send :define_method, :inc do |*args|
  criteria.send :inc, *args
end
