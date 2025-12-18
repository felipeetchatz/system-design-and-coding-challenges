require 'rails_helper'

RSpec.describe PreferenceService do
  describe '#allowed?' do
    let(:service) { described_class.new }

    before do
      NotificationPreference.destroy_all
    end

    context 'when preference exists' do
      context 'and enabled is true' do
        it 'returns true when not in quiet hours' do
          preference = NotificationPreference.create!(
            user_id: '123',
            channel: 'email',
            notification_type: 'transactional',
            enabled: true
          )

          expect(service.allowed?(preference.user_id, preference.channel, preference.notification_type)).to be true
        end

        it 'returns false when within quiet hours' do
          preference = NotificationPreference.create!(
            user_id: '123',
            channel: 'email',
            notification_type: 'transactional',
            enabled: true,
            quiet_hours_start: Time.zone.parse('22:00'),
            quiet_hours_end: Time.zone.parse('08:00'),
            timezone: 'UTC'
          )

          travel_to Time.zone.parse('2025-12-17 23:00:00 UTC') do
            expect(service.allowed?(preference.user_id, preference.channel, preference.notification_type)).to be false
          end
        end
      end

      context 'and enabled is false' do
        it 'returns false regardless of quiet hours' do
          preference = NotificationPreference.create!(
            user_id: '123',
            channel: 'email',
            notification_type: 'transactional',
            enabled: false
          )

          expect(service.allowed?(preference.user_id, preference.channel, preference.notification_type)).to be false
        end
      end

      context 'with multiple preferences for same user and channel' do
        it 'uses the preference that matches notification_type' do
          NotificationPreference.create!(
            user_id: '123',
            channel: 'email',
            notification_type: 'marketing',
            enabled: false
          )

          matching_preference = NotificationPreference.create!(
            user_id: '123',
            channel: 'email',
            notification_type: 'transactional',
            enabled: true
          )

          result = service.allowed?(matching_preference.user_id, matching_preference.channel, 'transactional')

          expect(result).to be true
        end
      end
    end

    context 'when preference does not exist' do
      it 'returns true by default' do
        result = service.allowed?('999', 'email', 'transactional')

        expect(result).to be true
      end
    end

    context 'with incomplete quiet hours configuration' do
      it 'returns true when quiet_hours_start is missing' do
        preference = NotificationPreference.create!(
          user_id: '123',
          channel: 'email',
          notification_type: 'transactional',
          enabled: true,
          quiet_hours_end: Time.zone.parse('08:00'),
          timezone: 'UTC'
        )

        expect(service.allowed?(preference.user_id, preference.channel, preference.notification_type)).to be true
      end

      it 'returns true when quiet_hours_end is missing' do
        preference = NotificationPreference.create!(
          user_id: '123',
          channel: 'email',
          notification_type: 'transactional',
          enabled: true,
          quiet_hours_start: Time.zone.parse('22:00'),
          timezone: 'UTC'
        )

        expect(service.allowed?(preference.user_id, preference.channel, preference.notification_type)).to be true
      end

      it 'returns true when timezone is missing' do
        preference = NotificationPreference.create!(
          user_id: '123',
          channel: 'email',
          notification_type: 'transactional',
          enabled: true,
          quiet_hours_start: Time.zone.parse('22:00'),
          quiet_hours_end: Time.zone.parse('08:00')
        )

        expect(service.allowed?(preference.user_id, preference.channel, preference.notification_type)).to be true
      end
    end
  end

  describe 'caching' do
    let(:redis) { instance_double('Redis') }
    let(:service) { described_class.new(redis: redis) }
    let(:user_id) { '123' }
    let(:channel) { 'email' }
    let(:notification_type) { 'transactional' }
    let(:cache_key) { "pref:#{user_id}:#{channel}:#{notification_type}" }

    before do
      NotificationPreference.destroy_all
    end

    context 'when cache is empty (cache miss)' do
      it 'loads preference from database and writes result to cache' do
        NotificationPreference.create!(
          user_id: user_id,
          channel: channel,
          notification_type: notification_type,
          enabled: true
        )

        allow(redis).to receive(:get).with(cache_key).and_return(nil)
        allow(redis).to receive(:setex)

        result = service.allowed?(user_id, channel, notification_type)

        expect(result).to be true
        expect(redis).to have_received(:setex).with(cache_key, 1.hour.to_i, 'true')
      end

      it 'caches default allow when no preference exists' do
        allow(redis).to receive(:get).with(cache_key).and_return(nil)
        allow(redis).to receive(:setex)

        result = service.allowed?(user_id, channel, notification_type)

        expect(result).to be true
        expect(redis).to have_received(:setex).with(cache_key, 1.hour.to_i, 'true')
      end
    end

    context 'when cache has a value (cache hit)' do
      it 'returns cached true without hitting the database' do
        allow(redis).to receive(:get).with(cache_key).and_return('true')

        expect(NotificationPreference).not_to receive(:for_user_and_channel)

        result = service.allowed?(user_id, channel, notification_type)

        expect(result).to be true
      end

      it 'returns cached false without hitting the database' do
        allow(redis).to receive(:get).with(cache_key).and_return('false')

        expect(NotificationPreference).not_to receive(:for_user_and_channel)

        result = service.allowed?(user_id, channel, notification_type)

        expect(result).to be false
      end
    end

    describe '#invalidate_cache' do
      it 'removes cached preference from Redis' do
        allow(redis).to receive(:del)

        service.invalidate_cache(user_id, channel, notification_type)

        expect(redis).to have_received(:del).with(cache_key)
      end
    end
  end
end

