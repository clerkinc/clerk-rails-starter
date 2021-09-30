require "clerk"

class AuthV2Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @env = env
    @req = Rack::Request.new(env)
    @env["clerk"] = ClerkProxy.new(session_token: nil)
    @header_token = @req.env["HTTP_AUTHORIZATION"]&.strip
    @cookie_token = @req.cookies["__session"]
    @client_uat = @req.cookies["__client_uat"]

    log "processing... \n"                              \
        "\t\t Authorization=#{@header_token.inspect}\n" \
        "\t\t __session cookie=#{@cookie_token.inspect}"

    ##########################################################################
    #                                                                        #
    #                          HEADER AUTHENTICATION                         #
    #                                                                        #
    ##########################################################################
    if @header_token
      return signed_out if !sdk.decode_token(@header_token) # malformed JWT

      token = verify_token(@header_token)
      return signed_in(token) if token

      # Clerk.js should refresh the token and retry
      return unknown(interstitial: false)
    end

    # in cross-origin XHRs the use of Authorization header is mandatory.
    if cross_origin_request?(@req) && @header_token.nil?
      log "cross-origin request without authorization header"

      return signed_out
    end

    ##########################################################################
    #                                                                        #
    #                             COOKIE AUTHENTICATION                      #
    #                                                                        #
    ##########################################################################
    log "proceeding to cookie authentication..."

    if development_or_staging? && (@req.referrer.nil? || cross_origin_request?(@req))
      log "development + empty referrer or cross-origin request"

      return unknown(interstitial: true)
    end

    if production? && @client_uat.nil?
      log "production? && client_uat.nil"
      return signed_out
    end

    if @client_uat == "0"
      return signed_out
    end

    token = verify_token(@cookie_token)

    if token && token["iat"] && @client_uat && Integer(@client_uat) <= token["iat"]
      return signed_in(token)
    end

    log "fallthrough (client_uat: #{@client_uat} | cookie_token: #{@cookie_token})"
    log "token: #{token}"

    unknown(interstitial: true)
  end

  private

  # Outcome A
  def signed_in(token)
    log "200 signed_in"

    @env["clerk"] = ClerkProxy.new(session_token: token)

    #[200, {}, ["200 - You may pass!\n"]]

    @app.call(@env)
  end

  # Outcome B
  def signed_out
    log "403 signed-out (client_uat=#{@client_uat})"

    #[403, {}, ["403 - Signed out\n"]]
    #
    @app.call(@env)
  end

  # Outcome C
  def unknown(interstitial: false)
    log "401 unknown (interstitial=#{interstitial})"

    return [401, {}, []] if !interstitial

    script_url = ENV["CLERKJS_SCRIPT_URL"].presence ||
      "https://#{ENV.fetch('CLERK_FRONTEND_API')}/npm/@clerk/clerk-js@staging/dist/clerk.browser.js"

    # Load Clerk.js to update the __session and __client_uat cookies.
    [401, {"Content-Type" => "text/html"}, [%Q(
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8" />
        </head>
        <body>
          <script>
            window.startClerk = async () => {
              const Clerk = window.Clerk;

              try {
                await Clerk.load({authVersion: 2});
                window.location.replace(new URL(window.location.toString()));
              } catch (err) {
                console.error('Clerk: ', err);
              }
            };

            (() => {
              const frontendApi = '#{ENV['CLERK_FRONTEND_API']}';
              const script = document.createElement('script');
              script.setAttribute('data-clerk-frontend-api', frontendApi);
              script.async = true;
              script.src = `#{script_url}`;
              script.addEventListener('load', startClerk);
              document.body.appendChild(script);
            })();
          </script>
        </body>
      </html>
    )
  ]]
  end

  def development_or_staging?
    Clerk.configuration.api_key.start_with?("test_")
  end

  def production?
    !development_or_staging?
  end

  def cross_origin_request?(req)
    return true if req.params["crossorigin"] # TMP for testing

    origin = req.env["HTTP_ORIGIN"]
    origin && origin != req.host
  end

  def verify_token(token)
    return false if token.nil? || token.strip.empty?

    begin
      @session = sdk.verify_token(token)
    rescue JWT::DecodeError, JWT::RequiredDependencyError => e
      log(e)
      false
    end
  end

  def sdk
    @sdk ||= Clerk::SDK.new
  end

  def log(s)
    Rails.logger.debug "\t[clerk] path=#{@req.path} #{s}"
  end
end

class ClerkProxy
  attr_reader :session_token

  def initialize(session_token: nil)
    @session_token = session_token
  end

  def session
    return nil if @session_token.nil?


    raise "TODO"
  end

  def user
    return nil if user_id.nil?
    # TODO: return the actual user info
    user_id
  end

  def user_id
    return nil if @session_token.nil?

    @session_token["sub"]
  end
end
