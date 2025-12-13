#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'benchmark'

class LoadTester
  BASE_URL = ENV.fetch('BASE_URL', 'http://localhost:3000')
  
  def initialize
    @base_uri = URI(BASE_URL)
    @short_codes = []
  end

  def extract_short_code(short_url)
    return nil if short_url.nil? || short_url.empty?
    # Extract short_code from full URL (e.g., "http://localhost:3000/abc123" -> "abc123")
    uri = URI(short_url)
    short_code = uri.path.gsub(/^\//, '') # Remove leading slash
    # Validate it's 6 characters (Base62)
    short_code.length == 6 ? short_code : nil
  end

  def create_short_url(url)
    uri = URI("#{@base_uri}/api/v1/shorten")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    
    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request.body = { url: url }.to_json
    
    response = http.request(request)
    
    if response.code == '201'
      short_url = JSON.parse(response.body)['short_url']
      extract_short_code(short_url)
    else
      nil
    end
  end

  def redirect(short_code)
    uri = URI("#{@base_uri}/#{short_code}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    
    request = Net::HTTP::Get.new(uri.path)
    response = http.request(request)
    
    response.code
  end

  def get_analytics(short_code)
    uri = URI("#{@base_uri}/api/v1/analytics/#{short_code}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    
    request = Net::HTTP::Get.new(uri.path)
    response = http.request(request)
    
    response.code == '200' ? JSON.parse(response.body) : nil
  end

  def benchmark_create(iterations: 100)
    puts "\n📝 Benchmark: Create Short URLs (#{iterations} iterations)"
    puts "=" * 60
    
    times = []
    successes = 0
    failures = 0
    
    iterations.times do |i|
      url = "https://example.com/test/#{i}?param=#{rand(10000)}"
      
      time = Benchmark.realtime do
        result = create_short_url(url)
        if result
          @short_codes << result
          successes += 1
        else
          failures += 1
        end
      end
      
      times << (time * 1000) # Convert to milliseconds
      
      print "." if (i + 1) % 10 == 0
    end
    
    print_results(times, successes, failures, "Create")
  end

  def benchmark_redirect(iterations: 1000)
    puts "\n🔄 Benchmark: Redirect (#{iterations} iterations)"
    puts "=" * 60
    
    if @short_codes.empty?
      puts "⚠️  No short codes available. Run create benchmark first."
      return
    end
    
    times = []
    successes = 0
    failures = 0
    
    iterations.times do |i|
      short_code = @short_codes.sample
      
      time = Benchmark.realtime do
        code = redirect(short_code)
        if code == '302' || code == '301'
          successes += 1
        else
          failures += 1
        end
      end
      
      times << (time * 1000) # Convert to milliseconds
      
      print "." if (i + 1) % 50 == 0
    end
    
    print_results(times, successes, failures, "Redirect")
  end

  def benchmark_analytics(iterations: 100)
    puts "\n📊 Benchmark: Analytics (#{iterations} iterations)"
    puts "=" * 60
    
    if @short_codes.empty?
      puts "⚠️  No short codes available. Run create benchmark first."
      return
    end
    
    times = []
    successes = 0
    failures = 0
    
    iterations.times do |i|
      short_code = @short_codes.sample
      
      time = Benchmark.realtime do
        result = get_analytics(short_code)
        if result
          successes += 1
        else
          failures += 1
        end
      end
      
      times << (time * 1000) # Convert to milliseconds
      
      print "." if (i + 1) % 10 == 0
    end
    
    print_results(times, successes, failures, "Analytics")
  end

  def benchmark_mixed_load(create_ratio: 0.1, redirect_ratio: 0.8, analytics_ratio: 0.1, total: 1000)
    puts "\n🎯 Benchmark: Mixed Load (#{total} requests)"
    puts "  Create: #{create_ratio * 100}% | Redirect: #{redirect_ratio * 100}% | Analytics: #{analytics_ratio * 100}%"
    puts "=" * 60
    
    create_count = (total * create_ratio).to_i
    redirect_count = (total * redirect_ratio).to_i
    analytics_count = total - create_count - redirect_count
    
    times = { create: [], redirect: [], analytics: [] }
    stats = { create: { success: 0, fail: 0 }, redirect: { success: 0, fail: 0 }, analytics: { success: 0, fail: 0 } }
    
    # Create some initial URLs
    create_count.times do |i|
      url = "https://example.com/mixed/#{i}?param=#{rand(10000)}"
      time = Benchmark.realtime do
        result = create_short_url(url)
        if result
          @short_codes << result
          stats[:create][:success] += 1
        else
          stats[:create][:fail] += 1
        end
      end
      times[:create] << (time * 1000)
    end
    
    # Redirect requests
    redirect_count.times do
      next if @short_codes.empty?
      short_code = @short_codes.sample
      time = Benchmark.realtime do
        code = redirect(short_code)
        if code == '302' || code == '301'
          stats[:redirect][:success] += 1
        else
          stats[:redirect][:fail] += 1
        end
      end
      times[:redirect] << (time * 1000)
    end
    
    # Analytics requests
    analytics_count.times do
      next if @short_codes.empty?
      short_code = @short_codes.sample
      time = Benchmark.realtime do
        result = get_analytics(short_code)
        if result
          stats[:analytics][:success] += 1
        else
          stats[:analytics][:fail] += 1
        end
      end
      times[:analytics] << (time * 1000)
    end
    
    puts "\n📈 Results:"
    [:create, :redirect, :analytics].each do |type|
      next if times[type].empty?
      print_results(times[type], stats[type][:success], stats[type][:fail], type.to_s.capitalize)
    end
  end

  private

  def print_results(times, successes, failures, label)
    return if times.empty?
    
    sorted = times.sort
    p50 = sorted[times.length / 2]
    p95 = sorted[(times.length * 0.95).to_i]
    p99 = sorted[(times.length * 0.99).to_i]
    
    avg = times.sum / times.length
    min = times.min
    max = times.max
    
    puts "\n#{label} Results:"
    puts "  Success: #{successes} | Failures: #{failures}"
    puts "  Average: #{avg.round(2)}ms"
    puts "  Min: #{min.round(2)}ms | Max: #{max.round(2)}ms"
    puts "  p50: #{p50.round(2)}ms | p95: #{p95.round(2)}ms | p99: #{p99.round(2)}ms"
    puts "  Throughput: #{(1000 / avg).round(2)} req/s"
  end
end

# Main execution
if __FILE__ == $0
  tester = LoadTester.new
  
  puts "\n🚀 URL Shortener Load Testing"
  puts "=" * 60
  puts "Base URL: #{ENV.fetch('BASE_URL', 'http://localhost:3000')}"
  
  # Run benchmarks
  tester.benchmark_create(iterations: 100)
  tester.benchmark_redirect(iterations: 1000)
  tester.benchmark_analytics(iterations: 100)
  tester.benchmark_mixed_load(total: 1000)
  
  puts "\n✅ Benchmark complete!"
end



