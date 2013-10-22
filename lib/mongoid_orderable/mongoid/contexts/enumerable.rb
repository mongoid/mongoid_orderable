module MongoidOrderable #:nodoc:
  module Mongoid #:nodoc:
    module Contexts #:nodoc:
      module Enumerable #:nodoc:
        def inc attribute, value
          iterate do |doc|
            MongoidOrderable.inc doc, attribute, value
          end
        end
      end
    end
  end
end

Mongoid::Contexts::Enumerable.send :include, MongoidOrderable::Mongoid::Contexts::Enumerable
