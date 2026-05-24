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
      rescue StandardError
        BankingAdmin::Observability::Logger.info(
          event: "projection.job.failed",
          status: "failed",
          correlation_id: BankingAdmin::RequestContext.correlation_id || "job-no-request-context",
          duration_ms: elapsed_ms(started_at),
          error_code: "projection_failed"
        )
        raise
      end

      private

      def elapsed_ms(started_at)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      end
    end
  end
end
