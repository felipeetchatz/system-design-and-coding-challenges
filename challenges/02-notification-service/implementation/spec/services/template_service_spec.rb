require 'rails_helper'

RSpec.describe TemplateService, type: :service do
  let(:redis) { instance_double('Redis') }
  let(:service) { described_class.new(redis: redis) }

  let!(:template) do
    NotificationTemplate.create!(
      template_id: 'welcome_email',
      channel: 'email',
      body: 'Hello {{name}}'
    )
  end

  describe '#load' do
    context 'when cache hit' do
      let(:cached_value) { template.attributes.to_json }

      it 'returns template from cache without hitting the database' do
        expect(redis).to receive(:get).with('template:welcome_email').and_return(cached_value)

        # We still expect NotificationTemplate not to query DB via find/find_by!
        expect(NotificationTemplate).not_to receive(:find_by!)

        loaded = service.load('welcome_email')

        expect(loaded.template_id).to eq('welcome_email')
        expect(loaded.body).to eq('Hello {{name}}')
      end
    end

    context 'when cache miss' do
      it 'loads from database and writes to cache with TTL' do
        expect(redis).to receive(:get).with('template:welcome_email').and_return(nil)
        expect(redis).to receive(:setex) do |key, ttl, value|
          expect(key).to eq('template:welcome_email')
          expect(ttl).to eq(TemplateService::CACHE_TTL)

          parsed = JSON.parse(value)
          expect(parsed['template_id']).to eq('welcome_email')
          expect(parsed['body']).to eq('Hello {{name}}')
        end

        loaded = service.load('welcome_email')

        expect(loaded).to be_a(NotificationTemplate)
        expect(loaded.template_id).to eq('welcome_email')
      end
    end

    context 'when redis is not configured' do
      let(:service_without_redis) { described_class.new }

      it 'loads from database without using cache' do
        loaded = service_without_redis.load('welcome_email')

        expect(loaded).to be_a(NotificationTemplate)
        expect(loaded.id).to eq(template.id)
      end
    end

    context 'when template does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect(redis).to receive(:get).with('template:unknown').and_return(nil)

        expect do
          service.load('unknown')
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#render' do
    context 'with valid template and variables' do
      it 'renders content using the loaded template' do
        allow(redis).to receive(:get).and_return(nil)
        allow(redis).to receive(:setex)

        result = service.render('welcome_email', name: 'John')

        expect(result).to eq('Hello John')
      end
    end

    context 'when template is missing' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(redis).to receive(:get).with('template:missing').and_return(nil)

        expect do
          service.render('missing', name: 'John')
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when required variables are missing' do
      it 'raises ArgumentError from NotificationTemplate#render' do
        allow(redis).to receive(:get).and_return(nil)
        allow(redis).to receive(:setex)

        expect do
          service.render('welcome_email', {})
        end.to raise_error(ArgumentError, /Missing required variable/)
      end
    end
  end
end


