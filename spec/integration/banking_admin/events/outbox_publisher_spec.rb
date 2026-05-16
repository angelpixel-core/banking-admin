require "rails_helper"
require "securerandom"

RSpec.describe BankingAdmin::Events::OutboxPublisher do
  let(:publisher) { instance_double("EventBusPublisher") }
  let(:service) { described_class.new(publisher: publisher, batch_size: 10) }

  it "moves pending event to published on successful publish" do
    event = create_outbox_event
    allow(publisher).to receive(:publish).and_return(true)

    processed = service.call

    expect(processed).to eq(1)
    event.reload
    expect(event.state).to eq("published")
    expect(event.published_at).not_to be_nil
    expect(event.attempts).to eq(0)
    expect(event.last_error).to be_nil
  end

  it "returns event to pending and increments attempts on failure" do
    event = create_outbox_event
    allow(publisher).to receive(:publish).and_raise(StandardError, "bus down")

    service.call

    event.reload
    expect(event.state).to eq("pending")
    expect(event.attempts).to eq(1)
    expect(event.last_error).to include("StandardError: bus down")
    expect(event.next_attempt_at).to be > Time.current
  end

  it "marks event as dead once max attempts is reached" do
    event = create_outbox_event(attempts: 4)
    allow(publisher).to receive(:publish).and_raise(StandardError, "permanent failure")

    service.call

    event.reload
    expect(event.state).to eq("dead")
    expect(event.attempts).to eq(5)
    expect(event.last_error).to include("StandardError: permanent failure")
    expect(event.published_at).to be_nil
  end

  def create_outbox_event(attempts: 0)
    BankingAdmin::Persistence::OutboxEventRecord.create!(
      event_name: "ledger.entry.posted",
      event_version: "v1",
      event_id: SecureRandom.uuid,
      occurred_at: Time.current,
      correlation_id: "corr-spec",
      producer: "banking-admin",
      payload: { reference_id: "ref-1" },
      state: "pending",
      attempts: attempts,
      next_attempt_at: Time.current - 1.second
    )
  end
end
