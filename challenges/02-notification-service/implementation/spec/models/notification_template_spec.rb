require 'rails_helper'

RSpec.describe NotificationTemplate, type: :model do
  describe 'validations' do
    before do
      NotificationTemplate.destroy_all
    end

    let(:valid_attributes) do
      {
        template_id: 'welcome_email',
        channel: 'email',
        body: 'Hello {{name}}'
      }
    end

    it 'requires template_id' do
      template = NotificationTemplate.new(
        channel: 'email',
        body: 'Hello {{name}}'
      )
      expect(template).not_to be_valid
      expect(template.errors[:template_id]).to include("can't be blank")
    end

    it 'requires channel' do
      template = NotificationTemplate.new(
        template_id: 'welcome_email',
        body: 'Hello {{name}}'
      )
      expect(template).not_to be_valid
      expect(template.errors[:channel]).to include("can't be blank")
    end

    it 'requires body' do
      template = NotificationTemplate.new(
        template_id: 'welcome_email',
        channel: 'email'
      )
      expect(template).not_to be_valid
      expect(template.errors[:body]).to include("can't be blank")
    end

    it 'enforces uniqueness of template_id' do
      NotificationTemplate.create!(valid_attributes)

      duplicate = NotificationTemplate.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:template_id]).to include('has already been taken')
    end

    it 'is valid with all required attributes' do
      template = NotificationTemplate.new(valid_attributes)
      expect(template).to be_valid
    end

    it 'does not allow same template_id for different channels' do
      NotificationTemplate.create!(
        template_id: 'welcome',
        channel: 'email',
        body: 'Hello {{name}}'
      )

      different_channel = NotificationTemplate.new(
        template_id: 'welcome',
        channel: 'sms',
        body: 'Hello {{name}}'
      )
      expect(different_channel).not_to be_valid
      expect(different_channel.errors[:template_id]).to include('has already been taken')
    end
  end

  describe 'model creation' do
    before do
      NotificationTemplate.destroy_all
    end

    it 'can be created with valid attributes' do
      template = NotificationTemplate.create!(
        template_id: 'welcome_email',
        channel: 'email',
        body: 'Hello {{name}}'
      )
      expect(template).to be_persisted
      expect(template.template_id).to eq('welcome_email')
      expect(template.channel).to eq('email')
      expect(template.body).to eq('Hello {{name}}')
      expect(template.active).to eq(true) # default value
    end
  end

  describe 'default values' do
    before do
      NotificationTemplate.destroy_all
    end

    it 'sets default active to true' do
      template = NotificationTemplate.new(
        template_id: 'welcome_email',
        channel: 'email',
        body: 'Hello {{name}}'
      )
      expect(template.active).to eq(true)
    end
  end

  describe '.active' do
    before do
      NotificationTemplate.destroy_all
      NotificationTemplate.create!(
        template_id: 'active_template',
        channel: 'email',
        body: 'Hello',
        active: true
      )
      NotificationTemplate.create!(
        template_id: 'inactive_template',
        channel: 'email',
        body: 'Hello',
        active: false
      )
    end

    it 'returns only active templates' do
      active_templates = NotificationTemplate.active
      expect(active_templates.count).to eq(1)
      expect(active_templates.first.template_id).to eq('active_template')
    end

    it 'does not return inactive templates' do
      active_templates = NotificationTemplate.active
      expect(active_templates.pluck(:template_id)).not_to include('inactive_template')
    end
  end

  describe '#render' do
    before do
      NotificationTemplate.destroy_all
    end

    let(:template) do
      NotificationTemplate.create!(
        template_id: 'welcome_email',
        channel: 'email',
        body: 'Hello {{name}}, welcome to {{app_name}}!'
      )
    end

    context 'when all required variables are provided' do
      it 'substitutes all variables correctly' do
        result = template.render({ name: 'John', app_name: 'MyApp' })
        expect(result).to eq('Hello John, welcome to MyApp!')
      end

      it 'handles single variable' do
        single_var_template = NotificationTemplate.create!(
          template_id: 'simple',
          channel: 'email',
          body: 'Hello {{name}}'
        )
        result = single_var_template.render({ name: 'Jane' })
        expect(result).to eq('Hello Jane')
      end

      it 'handles multiple occurrences of same variable' do
        multi_template = NotificationTemplate.create!(
          template_id: 'multi',
          channel: 'email',
          body: '{{name}} says hello to {{name}}'
        )
        result = multi_template.render({ name: 'John' })
        expect(result).to eq('John says hello to John')
      end
    end

    context 'when required variables are missing' do
      it 'raises ArgumentError when variable is missing' do
        expect {
          template.render({ name: 'John' })
        }.to raise_error(ArgumentError, /Missing required variable: app_name/)
      end

      it 'raises ArgumentError when all variables are missing' do
        expect {
          template.render({})
        }.to raise_error(ArgumentError, /Missing required variables: name, app_name/)
      end

      it 'raises ArgumentError with correct message for single missing variable' do
        single_var_template = NotificationTemplate.create!(
          template_id: 'simple',
          channel: 'email',
          body: 'Hello {{name}}'
        )
        expect {
          single_var_template.render({})
        }.to raise_error(ArgumentError, /Missing required variable: name/)
      end
    end

    context 'when body has no variables' do
      let(:no_var_template) do
        NotificationTemplate.create!(
          template_id: 'no_vars',
          channel: 'email',
          body: 'Hello, this is a static message'
        )
      end

      it 'returns body unchanged' do
        result = no_var_template.render({})
        expect(result).to eq('Hello, this is a static message')
      end

      it 'returns body unchanged even with extra variables provided' do
        result = no_var_template.render({ name: 'John', extra: 'value' })
        expect(result).to eq('Hello, this is a static message')
      end
    end

    context 'when body has multiple variables' do
      let(:multi_var_template) do
        NotificationTemplate.create!(
          template_id: 'multi_vars',
          channel: 'email',
          body: '{{greeting}} {{name}}, your order {{order_id}} is ready!'
        )
      end

      it 'substitutes all variables correctly' do
        result = multi_var_template.render({
          greeting: 'Hi',
          name: 'John',
          order_id: '12345'
        })
        expect(result).to eq('Hi John, your order 12345 is ready!')
      end

      it 'raises error if any variable is missing' do
        expect {
          multi_var_template.render({
            greeting: 'Hi',
            name: 'John'
          })
        }.to raise_error(ArgumentError, /Missing required variable: order_id/)
      end
    end

    context 'edge cases' do
      it 'handles empty string values' do
        template = NotificationTemplate.create!(
          template_id: 'empty',
          channel: 'email',
          body: 'Hello {{name}}'
        )
        result = template.render({ name: '' })
        expect(result).to eq('Hello ')
      end

      it 'handles numeric values' do
        template = NotificationTemplate.create!(
          template_id: 'numeric',
          channel: 'email',
          body: 'Order {{order_id}}'
        )
        result = template.render({ order_id: 12345 })
        expect(result).to eq('Order 12345')
      end

      it 'handles variables with underscores' do
        template = NotificationTemplate.create!(
          template_id: 'underscore',
          channel: 'email',
          body: 'Hello {{user_name}}'
        )
        result = template.render({ user_name: 'John' })
        expect(result).to eq('Hello John')
      end

      it 'does not substitute variables outside double curly braces' do
        template = NotificationTemplate.create!(
          template_id: 'edge',
          channel: 'email',
          body: 'Single {name} and {{name}}'
        )
        result = template.render({ name: 'John' })
        expect(result).to eq('Single {name} and John')
      end
    end
  end
end

