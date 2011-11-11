module MongoidOrderable #:nodoc:
  module Mongoid #:nodoc:
    module Contexts #:nodoc:
      module Enumerable #:nodoc:
        def inc attributes = {}
          iterate do |doc|
            attributes.each do |attribute, value|
              doc.inc(attribute, value)
            end
          end
        end
      end
    end
  end
end

Mongoid::Contexts::Enumerable.send :include, MongoidOrderable::Mongoid::Contexts::Enumerable
