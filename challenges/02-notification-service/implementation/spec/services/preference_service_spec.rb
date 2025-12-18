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
end


