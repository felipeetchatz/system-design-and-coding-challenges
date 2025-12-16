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
end
