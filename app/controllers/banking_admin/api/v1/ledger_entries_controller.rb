require "securerandom"

module BankingAdmin
  module API
    module V1
      class LedgerEntriesController < BaseController
        def create
          started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          payload = create_ledger_params
          transaction = BankingAdmin::Observability::TraceSpan.measure(
            workflow_step: "ledger_post",
            correlation_id: correlation_id,
            reference_type: payload[:reference_type],
            reference_id: payload[:reference_id]
          ) do
            ledger_service.post_transaction(
              reference_type: payload[:reference_type],
              reference_id: payload[:reference_id],
              entries: build_entries(payload[:entries] || [])
            )
          end

          BankingAdmin::BankingCore::ProjectBalancesJob.perform_later

          BankingAdmin::Observability::Logger.info(
            event: "ledger.post.accepted",
            status: "accepted",
            correlation_id: correlation_id,
            reference_type: transaction.reference_type,
            reference_id: transaction.reference_id,
            duration_ms: elapsed_ms(started_at)
          )

          BankingAdmin::Observability::Metrics.increment(
            name: "ledger_post_total",
            labels: { status: "accepted" }
          )
          BankingAdmin::Observability::Metrics.observe(
            name: "ledger_post_latency_ms",
            value: elapsed_ms(started_at)
          )

          render json: {
            reference_type: transaction.reference_type,
            reference_id: transaction.reference_id,
            entry_count: transaction.entries.size,
            correlation_id: correlation_id
          }, status: :created
        rescue StandardError
          BankingAdmin::Observability::Metrics.increment(
            name: "ledger_post_total",
            labels: { status: "failed" }
          )
          BankingAdmin::Observability::Metrics.observe(
            name: "ledger_post_latency_ms",
            value: elapsed_ms(started_at)
          )
          raise
        end

        private

        def create_ledger_params
          params.require(:ledger_entry).permit(:reference_type, :reference_id, entries: %i[id account_id side asset_code amount])
        end

        def build_entries(entries)
          entries.map do |entry|
            ::BankingCore::Entities::LedgerEntry.new(
              id: entry[:id] || SecureRandom.uuid,
              account_id: entry[:account_id],
              side: entry[:side],
              money: ::BankingCore::ValueObjects::Money.new(amount: entry[:amount], asset_code: entry[:asset_code]),
              reference_type: create_ledger_params[:reference_type],
              reference_id: create_ledger_params[:reference_id]
            )
          end
        end

        def ledger_service
          @ledger_service ||= BankingAdmin::BankingCore::LedgerService.new
        end

        def elapsed_ms(started_at)
          ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
        end
      end
    end
  end
end
