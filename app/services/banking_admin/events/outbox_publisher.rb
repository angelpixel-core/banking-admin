module BankingAdmin
  module Events
    class OutboxPublisher
      DEFAULT_BATCH_SIZE = 100
      MAX_ATTEMPTS = 5

      def initialize(publisher: EventBusPublisher.new, batch_size: DEFAULT_BATCH_SIZE)
        @publisher = publisher
        @batch_size = batch_size
      end

      def call
        selected = 0

        claim_rows.each do |event|
          selected += 1
          publish_event(event)
        end

        selected
      end

      private

      attr_reader :publisher, :batch_size

      def claim_rows
        records = []

        Persistence::OutboxEventRecord.transaction do
          Persistence::OutboxEventRecord.publishable.order(:created_at).limit(batch_size).lock("FOR UPDATE SKIP LOCKED").each do |event|
            event.update!(state: "publishing")
            records << event
          end
        end

        records
      end

      def publish_event(event)
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        BankingAdmin::Observability::TraceSpan.measure(
          workflow_step: "outbox_publish",
          correlation_id: event.correlation_id || "missing-correlation-id",
          reference_type: event.event_name,
          reference_id: event.event_id
        ) do
          envelope = build_envelope(event)
          publisher.publish(envelope)
          mark_published(event, started_at)
        end
      rescue StandardError => e
        mark_failure(event, e, started_at)
      end

      def build_envelope(event)
        {
          event_name: event.event_name,
          event_version: event.event_version,
          event_id: event.event_id,
          occurred_at: event.occurred_at.utc.iso8601,
          correlation_id: event.correlation_id,
          producer: event.producer,
          payload: event.payload
        }
      end

      def mark_published(event, started_at)
        event.update!(state: "published", published_at: Time.current, last_error: nil)
        BankingAdmin::Observability::Logger.info(
          event: "outbox.publish.completed",
          status: "completed",
          correlation_id: event.correlation_id || "missing-correlation-id",
          reference_type: event.event_name,
          reference_id: event.event_id,
          duration_ms: elapsed_ms(started_at)
        )
      end

      def mark_failure(event, error, started_at)
        attempts = event.attempts + 1
        attributes = {
          attempts: attempts,
          last_error: "#{error.class}: #{error.message}",
          next_attempt_at: Time.current + retry_delay(attempts)
        }

        attributes[:state] = attempts >= MAX_ATTEMPTS ? "dead" : "pending"
        event.update!(attributes)

        BankingAdmin::Observability::Logger.info(
          event: "outbox.publish.failed",
          status: "failed",
          correlation_id: event.correlation_id || "missing-correlation-id",
          reference_type: event.event_name,
          reference_id: event.event_id,
          duration_ms: elapsed_ms(started_at),
          error_code: error.class.name
        )
      end

      def retry_delay(attempt)
        case attempt
        when 1 then 5.seconds
        when 2 then 15.seconds
        when 3 then 45.seconds
        when 4 then 2.minutes
        else 5.minutes
        end
      end

      def elapsed_ms(started_at)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      end
    end
  end
end
