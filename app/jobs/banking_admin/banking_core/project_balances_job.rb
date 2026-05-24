module BankingAdmin
  module BankingCore
    class ProjectBalancesJob < ApplicationJob
      queue_as :default

      def perform
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        projected = BankingAdmin::Observability::TraceSpan.measure(
          workflow_step: "projection_job",
          correlation_id: BankingAdmin::RequestContext.correlation_id || "job-no-request-context",
          reference_type: "balances",
          reference_id: "projection"
        ) do
          LedgerService.new.project_balances
        end

        BankingAdmin::Observability::Logger.info(
          event: "projection.job.completed",
          status: "completed",
          correlation_id: BankingAdmin::RequestContext.correlation_id || "job-no-request-context",
          duration_ms: elapsed_ms(started_at),
          reference_type: "balances",
          reference_id: projected.to_s
        )

        BankingAdmin::Observability::Metrics.increment(
          name: "projection_job_total",
          labels: { status: "completed" }
        )
        BankingAdmin::Observability::Metrics.observe(
          name: "projection_latency_ms",
          value: elapsed_ms(started_at)
        )
        BankingAdmin::Observability::Metrics.set(
          name: "projection_lag_seconds",
          value: projection_lag_seconds
        )
      rescue StandardError
        BankingAdmin::Observability::Logger.info(
          event: "projection.job.failed",
          status: "failed",
          correlation_id: BankingAdmin::RequestContext.correlation_id || "job-no-request-context",
          duration_ms: elapsed_ms(started_at),
          error_code: "projection_failed"
        )
        BankingAdmin::Observability::Metrics.increment(
          name: "projection_job_total",
          labels: { status: "failed" }
        )
        BankingAdmin::Observability::Metrics.observe(
          name: "projection_latency_ms",
          value: elapsed_ms(started_at)
        )
        raise
      end

      private

      def elapsed_ms(started_at)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      end

      def projection_lag_seconds
        last_transaction = BankingAdmin::Persistence::LedgerTransactionRecord.maximum(:created_at)
        last_projection = BankingAdmin::Persistence::BalanceRecord.maximum(:updated_at)
        return 0 unless last_transaction && last_projection

        lag = last_transaction.to_f - last_projection.to_f
        lag.positive? ? lag.round : 0
      end
    end
  end
end
