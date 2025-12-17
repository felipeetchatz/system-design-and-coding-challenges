require 'rails_helper'

RSpec.describe NotificationValidator do
  describe '#validate' do
    let(:validator) { NotificationValidator.new }

    context 'with valid attributes' do
      it 'returns valid result with all required fields' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
        expect(result.errors).to be_empty
      end

      it 'returns valid result with optional variables hash' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email',
          variables: { name: 'John', app_name: 'MyApp' }
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
        expect(result.errors).to be_empty
      end

      it 'accepts valid channel: email' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
      end

      it 'accepts valid channel: sms' do
        attributes = {
          user_id: '123',
          channel: 'sms',
          template_id: 'welcome_sms'
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
      end

      it 'accepts valid channel: push' do
        attributes = {
          user_id: '123',
          channel: 'push',
          template_id: 'welcome_push'
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
      end

      it 'accepts valid channel: in_app' do
        attributes = {
          user_id: '123',
          channel: 'in_app',
          template_id: 'welcome_in_app'
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
      end
    end

    context 'with missing user_id' do
      it 'returns invalid result with error message' do
        attributes = {
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("user_id can't be blank")
      end

      it 'returns error when user_id is nil' do
        attributes = {
          user_id: nil,
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("user_id can't be blank")
      end

      it 'returns error when user_id is empty string' do
        attributes = {
          user_id: '',
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("user_id can't be blank")
      end
    end

    context 'with missing template_id' do
      it 'returns invalid result with error message' do
        attributes = {
          user_id: '123',
          channel: 'email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("template_id can't be blank")
      end

      it 'returns error when template_id is nil' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: nil
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("template_id can't be blank")
      end

      it 'returns error when template_id is empty string' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: ''
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("template_id can't be blank")
      end
    end

    context 'with invalid channel' do
      it 'returns error for missing channel' do
        attributes = {
          user_id: '123',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("channel can't be blank")
      end

      it 'returns error when channel is nil' do
        attributes = {
          user_id: '123',
          channel: nil,
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("channel can't be blank")
      end

      it 'returns error when channel is empty string' do
        attributes = {
          user_id: '123',
          channel: '',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include("channel can't be blank")
      end

      it 'returns error for invalid channel value' do
        attributes = {
          user_id: '123',
          channel: 'invalid_channel',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include('channel must be one of: email, sms, push, in_app')
      end
    end

    context 'with invalid variables type' do
      it 'returns error when variables is a string' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email',
          variables: 'not_a_hash'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include('variables must be a hash')
      end

      it 'returns error when variables is an array' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email',
          variables: ['not', 'a', 'hash']
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors).to include('variables must be a hash')
      end

      it 'accepts nil variables' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email',
          variables: nil
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
      end

      it 'accepts empty hash for variables' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email',
          variables: {}
        }
        result = validator.validate(attributes)

        expect(result).to be_valid
      end
    end

    context 'with multiple errors' do
      it 'returns all validation errors' do
        attributes = {
          user_id: nil,
          channel: 'invalid',
          template_id: '',
          variables: 'not_a_hash'
        }
        result = validator.validate(attributes)

        expect(result).not_to be_valid
        expect(result.errors.size).to eq(4)
        expect(result.errors).to include("user_id can't be blank")
        expect(result.errors).to include("template_id can't be blank")
        expect(result.errors).to include('channel must be one of: email, sms, push, in_app')
        expect(result.errors).to include('variables must be a hash')
      end
    end

    describe 'return value structure' do
      it 'returns a result object with valid? method' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).to respond_to(:valid?)
        expect(result.valid?).to be_in([true, false])
      end

      it 'returns a result object with errors method' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result).to respond_to(:errors)
        expect(result.errors).to be_an(Array)
      end

      it 'returns empty errors array when valid' do
        attributes = {
          user_id: '123',
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result.valid?).to be true
        expect(result.errors).to eq([])
      end

      it 'returns error messages in errors array when invalid' do
        attributes = {
          user_id: nil,
          channel: 'email',
          template_id: 'welcome_email'
        }
        result = validator.validate(attributes)

        expect(result.valid?).to be false
        expect(result.errors).not_to be_empty
        expect(result.errors.first).to be_a(String)
      end
    end
  end
end

