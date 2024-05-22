# frozen_string_literal: true

require 'action_dispatch/middleware/static'

class PublicFileServerMiddleware
  SERVICE_WORKER_TTL = 7.days.to_i
  CACHE_TTL          = 28.days.to_i

  def initialize(app)
    @app = app
    @file_handler = ActionDispatch::FileHandler.new(Rails.application.paths['public'].first)
  end

  def call(env)
    # Moments Specific: Start
    if ENV['PROTECT_PUBLIC_SYSTEM'] == 'true' && env['REQUEST_PATH'].start_with?(paperclip_root_url)
      client_ip =
        if env['HTTP_X_FORWARDED_FOR'].present?
          env['HTTP_X_FORWARDED_FOR'].split(',').first.strip
        else
          env['REMOTE_ADDR']
        end
      # Use SessionActivation table to short cut
      allowed_access = SessionActivation.exists?(ip: client_ip) || UserIp.exists?(ip: client_ip)
      Rails.logger.info "#{client_ip} trying accessing #{env['REQUEST_PATH']}, allowed_access=#{allowed_access}"
      return [403, { 'Content-Type' => 'text/plain' }, ['403 Forbidden']] unless allowed_access
    end
    # Moments Specific: End

    file = @file_handler.attempt(env)

    # If the request is not a static file, move on!
    return @app.call(env) if file.nil?

    status, headers, response = file

    # Set cache headers on static files. Some paths require different cache headers
    headers['Cache-Control'] = begin
      request_path = env['REQUEST_PATH']

      if request_path.start_with?('/sw.js')
        "public, max-age=#{SERVICE_WORKER_TTL}, must-revalidate"
      elsif request_path.start_with?(paperclip_root_url)
        "public, max-age=#{CACHE_TTL}, immutable"
      else
        "public, max-age=#{CACHE_TTL}, must-revalidate"
      end
    end

    # Override the default CSP header set by the CSP middleware
    headers['Content-Security-Policy'] = "default-src 'none'; form-action 'none'" if request_path.start_with?(paperclip_root_url)

    headers['X-Content-Type-Options'] = 'nosniff'

    [status, headers, response]
  end

  private

  def paperclip_root_url
    ENV.fetch('PAPERCLIP_ROOT_URL', '/system')
  end
end
