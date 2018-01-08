module MongoidOrderable #:nodoc:
  module Mongoid #:nodoc:
    module Contextual #:nodoc:
      module Memory #:nodoc:
        def inc(*args)
          each do |document|
            document.inc *args
          end
        end
      end
    end
  end
end

Mongoid::Contextual::Memory.send :include, MongoidOrderable::Mongoid::Contextual::Memory
