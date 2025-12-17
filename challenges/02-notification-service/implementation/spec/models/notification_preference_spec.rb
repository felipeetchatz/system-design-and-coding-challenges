require 'rails_helper'

RSpec.describe NotificationPreference, type: :model do
  describe 'validations' do
    before do
      NotificationPreference.destroy_all
    end

    it 'requires user_id' do
      preference = NotificationPreference.new(
        channel: 'email',
        notification_type: 'marketing'
      )
      expect(preference).not_to be_valid
      expect(preference.errors[:user_id]).to include("can't be blank")
    end

    it 'requires channel' do
      preference = NotificationPreference.new(
        user_id: '123',
        notification_type: 'marketing'
      )
      expect(preference).not_to be_valid
      expect(preference.errors[:channel]).to include("can't be blank")
    end

    it 'requires notification_type' do
      preference = NotificationPreference.new(
        user_id: '123',
        channel: 'email'
      )
      expect(preference).not_to be_valid
      expect(preference.errors[:notification_type]).to include("can't be blank")
    end

    it 'enforces uniqueness of (user_id, channel, notification_type)' do
      NotificationPreference.create!(
        user_id: '123',
        channel: 'email',
        notification_type: 'marketing'
      )

      duplicate = NotificationPreference.new(
        user_id: '123',
        channel: 'email',
        notification_type: 'marketing'
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:notification_type]).to include('has already been taken')
    end

    it 'allows same notification_type for different users' do
      NotificationPreference.create!(
        user_id: '123',
        channel: 'email',
        notification_type: 'marketing'
      )

      different_user = NotificationPreference.new(
        user_id: '456',
        channel: 'email',
        notification_type: 'marketing'
      )
      expect(different_user).to be_valid
    end

    it 'allows same user and channel with different notification_type' do
      NotificationPreference.create!(
        user_id: '123',
        channel: 'email',
        notification_type: 'marketing'
      )

      different_type = NotificationPreference.new(
        user_id: '123',
        channel: 'email',
        notification_type: 'transactional'
      )
      expect(different_type).to be_valid
    end
  end

  describe 'model creation' do
    before do
      NotificationPreference.destroy_all
    end

    it 'can be created with valid attributes' do
      preference = NotificationPreference.create!(
        user_id: '123',
        channel: 'email',
        notification_type: 'marketing'
      )
      expect(preference).to be_persisted
      expect(preference.user_id).to eq('123')
      expect(preference.channel).to eq('email')
      expect(preference.notification_type).to eq('marketing')
      expect(preference.enabled).to eq(true) # default value
    end
  end

  describe 'default values' do
    before do
      NotificationPreference.destroy_all
    end

    it 'sets default enabled to true' do
      preference = NotificationPreference.new(
        user_id: '123',
        channel: 'email',
        notification_type: 'marketing'
      )
      expect(preference.enabled).to eq(true)
    end
  end

  describe 'scopes' do
    before do
      NotificationPreference.destroy_all
      NotificationPreference.create!(user_id: '123', channel: 'email', notification_type: 'marketing')
      NotificationPreference.create!(user_id: '123', channel: 'email', notification_type: 'transactional')
      NotificationPreference.create!(user_id: '123', channel: 'sms', notification_type: 'marketing')
      NotificationPreference.create!(user_id: '456', channel: 'email', notification_type: 'marketing')
    end

    describe '.for_user_and_channel' do
      it 'returns preferences for specific user and channel' do
        preferences = NotificationPreference.for_user_and_channel('123', 'email')
        expect(preferences.count).to eq(2)
        expect(preferences.pluck(:user_id).uniq).to eq(['123'])
        expect(preferences.pluck(:channel).uniq).to eq(['email'])
      end

      it 'returns empty for non-existent user and channel combination' do
        preferences = NotificationPreference.for_user_and_channel('999', 'push')
        expect(preferences.count).to eq(0)
      end
    end
  end

  describe '#enabled?' do
    context 'when enabled is false' do
      it 'returns false' do
        preference = NotificationPreference.new(
          user_id: '123',
          channel: 'email',
          notification_type: 'marketing',
          enabled: false
        )
        expect(preference.enabled?).to eq(false)
      end
    end

    context 'when enabled is true' do
      context 'without quiet hours' do
        it 'returns true' do
          preference = NotificationPreference.new(
            user_id: '123',
            channel: 'email',
            notification_type: 'marketing',
            enabled: true
          )
          expect(preference.enabled?).to eq(true)
        end
      end

      context 'with quiet hours' do
        context 'when current time is within quiet hours' do
          it 'returns false' do
            # Set quiet hours to 22:00 - 08:00 UTC
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              quiet_hours_end: Time.parse('08:00'),
              timezone: 'UTC'
            )

            # Mock current time to be 23:00 UTC (within quiet hours)
            allow(Time).to receive(:current).and_return(Time.parse('2025-12-17 23:00:00 UTC'))
            expect(preference.enabled?).to eq(false)
          end

          it 'returns false when time spans midnight' do
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              quiet_hours_end: Time.parse('08:00'),
              timezone: 'UTC'
            )

            # Test at 02:00 UTC (within quiet hours that span midnight)
            allow(Time).to receive(:current).and_return(Time.parse('2025-12-17 02:00:00 UTC'))
            expect(preference.enabled?).to eq(false)
          end
        end

        context 'when current time is outside quiet hours' do
          it 'returns true' do
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              quiet_hours_end: Time.parse('08:00'),
              timezone: 'UTC'
            )

            # Mock current time to be 10:00 UTC (outside quiet hours)
            allow(Time).to receive(:current).and_return(Time.parse('2025-12-17 10:00:00 UTC'))
            expect(preference.enabled?).to eq(true)
          end
        end

        context 'with timezone conversion' do
          it 'respects timezone when checking quiet hours' do
            # User in America/Sao_Paulo (UTC-3)
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              quiet_hours_end: Time.parse('08:00'),
              timezone: 'America/Sao_Paulo'
            )

            # Current time: 23:00 UTC = 20:00 BRT (outside quiet hours 22:00-08:00 BRT)
            allow(Time).to receive(:current).and_return(Time.parse('2025-12-17 23:00:00 UTC'))
            # Convert to user's timezone: 23:00 UTC = 20:00 BRT (UTC-3)
            # 20:00 is outside quiet hours (22:00-08:00), so should return true
            expect(preference.enabled?).to eq(true)
          end

          it 'returns false when time in user timezone is within quiet hours' do
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              quiet_hours_end: Time.parse('08:00'),
              timezone: 'America/Sao_Paulo'
            )

            # Current time: 01:00 UTC = 22:00 BRT (within quiet hours 22:00-08:00 BRT)
            allow(Time).to receive(:current).and_return(Time.parse('2025-12-17 01:00:00 UTC'))
            # Convert to user's timezone: 01:00 UTC = 22:00 BRT (UTC-3)
            # 22:00 is within quiet hours (22:00-08:00), so should return false
            expect(preference.enabled?).to eq(false)
          end
        end

        context 'when quiet hours are not fully configured' do
          it 'returns true if quiet_hours_start is missing' do
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_end: Time.parse('08:00'),
              timezone: 'UTC'
            )
            expect(preference.enabled?).to eq(true)
          end

          it 'returns true if quiet_hours_end is missing' do
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              timezone: 'UTC'
            )
            expect(preference.enabled?).to eq(true)
          end

          it 'returns true if timezone is missing' do
            preference = NotificationPreference.new(
              user_id: '123',
              channel: 'email',
              notification_type: 'marketing',
              enabled: true,
              quiet_hours_start: Time.parse('22:00'),
              quiet_hours_end: Time.parse('08:00')
            )
            expect(preference.enabled?).to eq(true)
          end
        end
      end
    end
  end
end

