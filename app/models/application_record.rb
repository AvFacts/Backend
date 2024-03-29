# frozen_string_literal: true

# @abstract
#
# Abstract superclass for all models in AvFacts.

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
