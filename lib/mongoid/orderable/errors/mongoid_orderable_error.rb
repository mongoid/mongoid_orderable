module Mongoid::Orderable
  module Errors
    class MongoidOrderableError < ::Mongoid::Errors::MongoidError

      if ::Mongoid::Compatibility::Version.mongoid2?
        def translate key, options
          [:message, :summary, :resolution].map do |section|
            ::I18n.translate "#{BASE_KEY}.#{key}.#{section}", options
          end.join ' '
        end
      end
    end
  end
end
