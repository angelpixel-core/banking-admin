module BankingAdmin
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :correlation_id
  end
end
