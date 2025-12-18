require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe SendNotificationJob, type: :job do
  describe '.perform_async' do
    it 'enqueues a job' do
      Sidekiq::Testing.fake! do
        expect {
          described_class.perform_async('some-notification-id')
        }.to change(described_class.jobs, :size).by(1)
      end
    end
  end

  describe '#perform' do
    let(:notification) do
      Notification.create!(
        notification_id: SecureRandom.uuid,
        user_id: 'user-123',
        channel: 'email',
        template_id: 'welcome_email',
        status: initial_status
      )
    end

    context 'when notification exists and is queued' do
      let(:initial_status) { 'queued' }

      it "updates status to 'processing'" do
        described_class.new.perform(notification.notification_id)

        expect(notification.reload.status).to eq('processing')
      end
    end

    context 'when notification is already in a terminal state' do
      let(:initial_status) { 'sent' }

      it 'does not change the status' do
        described_class.new.perform(notification.notification_id)

        expect(notification.reload.status).to eq('sent')
      end
    end

    context 'when notification does not exist' do
      it 'handles missing notification gracefully' do
        expect {
          described_class.new.perform('non-existent-id')
        }.not_to raise_error
      end
    end
  end
end


