module BankingAdmin
  module BankingCore
    class UnitOfWork
      def transaction(&block)
        ActiveRecord::Base.transaction(&block)
      end
    end
  end
end
