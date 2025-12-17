require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'validations' do
    it 'requires user_id' do
      notification = Notification.new(
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification).not_to be_valid
      expect(notification.errors[:user_id]).to include("can't be blank")
    end

    it 'requires channel' do
      notification = Notification.new(
        user_id: '123',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification).not_to be_valid
      expect(notification.errors[:channel]).to include("can't be blank")
    end

    it 'requires template_id' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        status: 'queued'
      )
      expect(notification).not_to be_valid
      expect(notification.errors[:template_id]).to include("can't be blank")
    end

    it 'sets default status when not provided' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template'
      )
      # Status should be set to default 'queued' by after_initialize
      expect(notification.status).to eq('queued')
      expect(notification).to be_valid
    end

    it 'is valid with all required attributes' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification).to be_valid
    end
  end

  describe 'enums' do
    describe 'status' do
      it 'has correct status values' do
        expect(Notification.statuses.keys).to match_array(%w[queued processing sent delivered failed bounced])
      end

      it 'accepts valid status values' do
        notification = Notification.new(
          user_id: '123',
          channel: 'email',
          template_id: 'test_template',
          status: 'queued'
        )
        expect(notification).to be_valid
        expect(notification.status).to eq('queued')
      end

      it 'rejects invalid status values' do
        expect {
          Notification.new(
            user_id: '123',
            channel: 'email',
            template_id: 'test_template',
            status: 'invalid_status'
          )
        }.to raise_error(ArgumentError)
      end
    end

    describe 'priority' do
      it 'has correct priority values' do
        expect(Notification.priorities.keys).to match_array(%w[urgent normal low])
      end

      it 'accepts valid priority values' do
        notification = Notification.new(
          user_id: '123',
          channel: 'email',
          template_id: 'test_template',
          status: 'queued',
          priority: 'urgent'
        )
        expect(notification).to be_valid
        expect(notification.priority).to eq('urgent')
      end

      it 'rejects invalid priority values' do
        expect {
          Notification.new(
            user_id: '123',
            channel: 'email',
            template_id: 'test_template',
            status: 'queued',
            priority: 'invalid_priority'
          )
        }.to raise_error(ArgumentError)
      end
    end

    describe 'channel' do
      it 'has correct channel values' do
        expect(Notification.channels.keys).to match_array(%w[email sms push in_app])
      end

      it 'accepts valid channel values' do
        notification = Notification.new(
          user_id: '123',
          channel: 'sms',
          template_id: 'test_template',
          status: 'queued'
        )
        expect(notification).to be_valid
        expect(notification.channel).to eq('sms')
      end

      it 'rejects invalid channel values' do
        expect {
          Notification.new(
            user_id: '123',
            channel: 'invalid_channel',
            template_id: 'test_template',
            status: 'queued'
          )
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'default values' do
    it 'sets default priority to normal' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification.priority).to eq('normal')
    end

    it 'sets default status to queued' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template'
      )
      expect(notification.status).to eq('queued')
    end

    it 'sets default retry_count to 0' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification.retry_count).to eq(0)
    end

    it 'sets default max_retries to 3' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification.max_retries).to eq(3)
    end
  end

  describe 'model creation' do
    it 'can be created with valid attributes' do
      notification = Notification.create!(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
      expect(notification).to be_persisted
      expect(notification.user_id).to eq('123')
      expect(notification.channel).to eq('email')
      expect(notification.template_id).to eq('test_template')
      expect(notification.status).to eq('queued')
    end
  end

  describe '#update_status' do
    let(:notification) do
      Notification.create!(
        user_id: '123',
        channel: 'email',
        template_id: 'test_template',
        status: 'queued'
      )
    end

    it 'updates status to sent and sets sent_at timestamp' do
      expect(notification.sent_at).to be_nil
      notification.update_status('sent')
      expect(notification.status).to eq('sent')
      expect(notification.sent_at).to be_present
      expect(notification.sent_at).to be_within(1.second).of(Time.current)
    end

    it 'updates status to delivered and sets delivered_at timestamp' do
      expect(notification.delivered_at).to be_nil
      notification.update_status('delivered')
      expect(notification.status).to eq('delivered')
      expect(notification.delivered_at).to be_present
      expect(notification.delivered_at).to be_within(1.second).of(Time.current)
    end

    it 'updates status to failed and sets failed_at timestamp' do
      expect(notification.failed_at).to be_nil
      notification.update_status('failed')
      expect(notification.status).to eq('failed')
      expect(notification.failed_at).to be_present
      expect(notification.failed_at).to be_within(1.second).of(Time.current)
    end

    it 'updates status to processing without setting timestamp' do
      notification.update_status('processing')
      expect(notification.status).to eq('processing')
      # No processing_at field exists, so no timestamp should be set
    end

    it 'persists the changes to database' do
      notification.update_status('sent')
      notification.reload
      expect(notification.status).to eq('sent')
      expect(notification.sent_at).to be_present
    end
  end

  describe 'scopes' do
    before do
      Notification.destroy_all
      Notification.create!(user_id: '123', channel: 'email', template_id: 'test1', status: 'queued')
      Notification.create!(user_id: '123', channel: 'sms', template_id: 'test2', status: 'sent')
      Notification.create!(user_id: '456', channel: 'email', template_id: 'test3', status: 'queued')
      Notification.create!(user_id: '456', channel: 'email', template_id: 'test4', status: 'delivered', scheduled_at: Time.current)
    end

    describe '.by_user' do
      it 'returns only notifications for the specified user' do
        notifications = Notification.by_user('123')
        expect(notifications.count).to eq(2)
        expect(notifications.pluck(:user_id).uniq).to eq(['123'])
      end
    end

    describe '.by_channel' do
      it 'returns only notifications for the specified channel' do
        notifications = Notification.by_channel('email')
        expect(notifications.count).to eq(3)
        expect(notifications.pluck(:channel).uniq).to eq(['email'])
      end
    end

    describe '.by_status' do
      it 'returns only notifications with the specified status' do
        notifications = Notification.by_status('queued')
        expect(notifications.count).to eq(2)
        expect(notifications.pluck(:status).uniq).to eq(['queued'])
      end
    end

    describe '.scheduled' do
      it 'returns only notifications with scheduled_at set' do
        notifications = Notification.scheduled
        expect(notifications.count).to eq(1)
        expect(notifications.first.scheduled_at).to be_present
      end
    end
  end

  describe '#can_retry?' do
    it 'returns true when retry_count is less than max_retries' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test',
        status: 'queued',
        retry_count: 2,
        max_retries: 3
      )
      expect(notification.can_retry?).to be true
    end

    it 'returns false when retry_count equals max_retries' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test',
        status: 'queued',
        retry_count: 3,
        max_retries: 3
      )
      expect(notification.can_retry?).to be false
    end

    it 'returns false when retry_count is greater than max_retries' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test',
        status: 'queued',
        retry_count: 4,
        max_retries: 3
      )
      expect(notification.can_retry?).to be false
    end

    it 'returns true when retry_count is 0 and max_retries is 3' do
      notification = Notification.new(
        user_id: '123',
        channel: 'email',
        template_id: 'test',
        status: 'queued',
        retry_count: 0,
        max_retries: 3
      )
      expect(notification.can_retry?).to be true
    end
  end
end
