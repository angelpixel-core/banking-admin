module BankingAdmin
  module Observability
    class TraceSpan
      def self.measure(workflow_step:, correlation_id:, reference_type: nil, reference_id: nil)
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        yield

        Logger.info(
          event: "trace.span",
          status: "completed",
          correlation_id: correlation_id,
          workflow_step: workflow_step,
          reference_type: reference_type,
          reference_id: reference_id,
          duration_ms: elapsed_ms(started_at),
          error_code: nil
        )
      rescue StandardError => e
        Logger.info(
          event: "trace.span",
          status: "failed",
          correlation_id: correlation_id,
          workflow_step: workflow_step,
          reference_type: reference_type,
          reference_id: reference_id,
          duration_ms: elapsed_ms(started_at),
          error_code: e.class.name
        )
        raise
      end

      def self.elapsed_ms(started_at)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      end
      private_class_method :elapsed_ms
    end
  end
end
