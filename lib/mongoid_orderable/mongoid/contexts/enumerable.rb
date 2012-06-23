module MongoidOrderable #:nodoc:
  module Mongoid #:nodoc:
    module Contexts #:nodoc:
      module Enumerable #:nodoc:
        def inc attribute, value
          iterate do |doc|
            doc.inc(attribute, value)
          end
        end
      end
    end
  end
end

Mongoid::Contexts::Enumerable.send :include, MongoidOrderable::Mongoid::Contexts::Enumerable
