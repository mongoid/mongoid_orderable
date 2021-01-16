# frozen_string_literal: true

require 'active_support'

I18n.enforce_available_locales = false if I18n.respond_to?(:enforce_available_locales)
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

require 'mongoid'

require 'mongoid/orderable/version'

require 'mongoid/orderable'
require 'mongoid/orderable/configs/global_config'
require 'mongoid/orderable/configs/field_config'
require 'mongoid/orderable/errors/invalid_target_position'
require 'mongoid/orderable/mixins/helpers'
require 'mongoid/orderable/mixins/callbacks'
require 'mongoid/orderable/mixins/listable'
require 'mongoid/orderable/mixins/movable'
require 'mongoid/orderable/generators/base'
require 'mongoid/orderable/generators/listable'
require 'mongoid/orderable/generators/movable'
require 'mongoid/orderable/generators/position'
require 'mongoid/orderable/generators/scope'
require 'mongoid/orderable/generators/helpers'
require 'mongoid/orderable/installer'
