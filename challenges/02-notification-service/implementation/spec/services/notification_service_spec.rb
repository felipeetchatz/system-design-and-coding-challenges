require 'rails_helper'

RSpec.describe NotificationService do
  describe '#create' do
    let(:service) { described_class.new }

    context 'with valid attributes' do
      let(:attributes) do
        {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email',
          variables: { name: 'John' }
        }
      end

      it 'creates a notification with queued status and generated notification_id' do
        expect do
          @notification = service.create(attributes)
        end.to change(Notification, :count).by(1)

        expect(@notification).to be_persisted
        expect(@notification.user_id).to eq('123')
        expect(@notification.channel).to eq('email')
        expect(@notification.template_id).to eq('welcome_email')
        expect(@notification.status).to eq('queued')
        expect(@notification.notification_id).to be_present
        expect(@notification.queued_at).to be_present
      end

      it 'relies on NotificationValidator to validate attributes' do
        validator = instance_double(NotificationValidator)
        result = instance_double(NotificationValidator::ValidationResult, valid?: true, errors: [])

        allow(NotificationValidator).to receive(:new).and_return(validator)
        allow(validator).to receive(:validate).with(attributes).and_return(result)

        service.create(attributes)

        expect(NotificationValidator).to have_received(:new)
        expect(validator).to have_received(:validate).with(attributes)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) do
        {
          user_id: nil,
          channel: 'email',
          template_id: 'welcome_email'
        }
      end

      it 'does not create a notification and raises ValidationError' do
        expect do
          service.create(invalid_attributes)
        end.to raise_error(NotificationService::ValidationError) do |error|
          expect(error.errors).to include("user_id can't be blank")
        end

        expect(Notification.count).to eq(0)
      end
    end

    context 'when validator returns multiple errors' do
      let(:attributes_with_multiple_errors) do
        {
          user_id: nil,
          channel: 'invalid',
          template_id: ''
        }
      end

      it 'raises ValidationError with all validator errors' do
        expect do
          service.create(attributes_with_multiple_errors)
        end.to raise_error(NotificationService::ValidationError) do |error|
          expect(error.errors).to include("user_id can't be blank")
          expect(error.errors).to include("template_id can't be blank")
          expect(error.errors).to include('channel must be one of: email, sms, push, in_app')
        end
      end
    end
  end
end

{
  "cells": [],
  "metadata": {
    "language_info": {
      "name": "python"
    }
  },
  "nbformat": 4,
  "nbformat_minor": 2
}